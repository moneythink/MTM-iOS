//
//  AppDelegate.m
//  moneythink-ios
//
//  Created by jdburgie on 7/10/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "AppDelegate.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <Google/Analytics.h>
#import "UIColor+Palette.h"
#import "MTNotificationViewController.h"
#import "MTSupportViewController.h"
#import "MTMenuViewController.h"
#import "MTPostDetailViewController.h"
#import "AFNetworkActivityIndicatorManager.h"

#ifdef DEVELOPMENT
    static NSString *apiServerKey = @"DEVELOPMENT";
    static NSString *layerEnvironmentName = @"development";
#elif STAGE
    static NSString *apiServerKey = @"STAGE";
    static NSString *layerEnvironmentName = @"staging";
#else
    static NSString *apiServerKey = @"PRODUCTION";
    static NSString *layerEnvironmentName = @"production";
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Do first, in case there's a migration
    [self setupRealm];

    [Fabric with:@[CrashlyticsKit]];
    
    [self clearZendesk];
    [self setupZendesk];
    
    // If switching between staging and production, logout user
    NSString *previousServer = [[NSUserDefaults standardUserDefaults] objectForKey:kAPIServerKey];
    if (IsEmpty(previousServer) || ![previousServer isEqualToString:apiServerKey]) {
        [MTUtil logout];
        
        // Also, specifically, remove the push messaging key (which usually doesn't get wiped on logout)
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPushMessagingRegistrationKey];
    }
    [[NSUserDefaults standardUserDefaults] setObject:apiServerKey forKey:kAPIServerKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // Clear keychain on first run in case of reinstallation
    if (![[NSUserDefaults standardUserDefaults] objectForKey:kFirstTimeRunKey]) {
        // Delete values from keychain here
        [[NSUserDefaults standardUserDefaults] setValue:@"1strun" forKey:kFirstTimeRunKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [AFOAuthCredential deleteCredentialWithIdentifier:MTNetworkServiceOAuthCredentialKey];
    }

    // ------------------------------
    // START: Set up Google Analytics
    //
    // Configure tracker from GoogleService-Info.plist.
    NSError *configureError;
    [[GGLContext sharedInstance] configureWithError:&configureError];
    NSAssert(!configureError, @"Error configuring Google services: %@", configureError);
    
    // Optional: configure GAI options.
    GAI *gai = [GAI sharedInstance];
    gai.trackUncaughtExceptions = NO;  // do not report uncaught exceptions; we have a lot of tracking already!
    // gai.logger.logLevel = kGAILogLevelVerbose;
    
    NSString *GADryRun = [[NSProcessInfo processInfo] environment][@"GA_DRY_RUN"];
    if ([GADryRun isEqualToString:@"true"]) {
        NSLog(@"Setting Google Analytics instance to Dry Run; will not send hits.");
        [[GAI sharedInstance] setDryRun:YES];
    }
    
    // ----------------------------
    // END: Set up Google Analytics
    
    [self setWhiteNavBarAppearanceForNavigationBar:nil];
    
    [[UITabBar appearance] setTintColor:[UIColor primaryOrange]];
    [[UITabBar appearance] setBarTintColor:[UIColor lightGrey]];
    [[UISwitch appearance] setOnTintColor:[UIColor primaryGreen]];
        
    // Register for push notifications
    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        [application registerForRemoteNotifications];
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    else {
        [self registerForPushNotifications];
    }
    
    // Set up Reachability
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    self.reachability = [Reachability reachabilityForInternetConnection];
    self.reachable = [MTUtil internetReachable];
    [self.reachability startNotifier];
    
    [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:YES];
    id revealVC = self.window.rootViewController;
    if ([revealVC isKindOfClass:[SWRevealViewController class]]) {
        ((SWRevealViewController *)revealVC).delegate = [MTUtil getAppDelegate];
    }

    if ([MTUser isUserLoggedIn] && [MTUser currentUser] && [MTUtil internetReachable] && [MTUtil shouldRefreshForKey:kRefreshForMeUser]) {
        [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
            [MTUtil setRefreshedForKey:kRefreshForMeUser];
        } failure:^(NSError *error) {
            //
        }];
    }
    
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    // Set up LayerKit (http://layer.com)
    NSURL *appID = [NSURL URLWithString:@"layer:///apps/staging/d242b6d8-b640-11e5-befe-c52f5f090bc5"];
    self.layerClient = [LYRClient clientWithAppID:appID];

    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
    if ([MTUser isUserLoggedIn] && [MTUser currentUser] && [MTUtil internetReachable] && [MTUtil shouldRefreshForKey:kRefreshForMeUser]) {
        [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
            [MTUtil setRefreshedForKey:kRefreshForMeUser];
        } failure:^(NSError *error) {
            //
        }];
    }
}

- (void)applicationDidEnterBackground:(UIApplication*)application
{
    [self purgeDeletedData];
}


#pragma mark - Push Notifications -
- (void)registerForPushNotifications {
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
    // Update the API with new devicetoken.
    [self updatePushMessagingInfoWithToken:newDeviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
#if !(TARGET_IPHONE_SIMULATOR)
    // Device
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@", [error localizedDescription]);
#endif
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler
{
    [self handleRemoteNotificationForApplication:application withUserInfo:userInfo fetchCompletionHandler:handler];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self handleRemoteNotificationForApplication:application withUserInfo:userInfo fetchCompletionHandler:nil];
}

- (void)handleRemoteNotificationForApplication:(UIApplication *)application withUserInfo:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler
{
    NSDictionary *apsDict = [userInfo objectForKey:@"aps"];
    NSString *category = nil;
    NSString *alertMessage = [apsDict objectForKey:@"alert"];

    if ([apsDict valueForKey:@"category"]) {
        category = [apsDict valueForKey:@"category"];
        if ([[category uppercaseString] isEqualToString:@"NOTIFICATIONS"]) {
            
            UIApplicationState state = [application applicationState];

            if (state == UIApplicationStateActive) {
                NSString *title = @"Moneythink Alert";
                NSString *messageToDisplay = !IsEmpty(alertMessage) ? alertMessage : @"";

                if (NSClassFromString(@"UIAlertController")) {
                    UIAlertController *changeSheet = [UIAlertController
                                                      alertControllerWithTitle:title
                                                      message:messageToDisplay
                                                      preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *close = [UIAlertAction
                                             actionWithTitle:@"Close"
                                             style:UIAlertActionStyleCancel
                                             handler:^(UIAlertAction *action) {
                                                 [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
                                             }];
                    
                    UIAlertAction *view = [UIAlertAction
                                               actionWithTitle:@"View"
                                               style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction *action) {
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       [self handleActionNotificationWithUserInfo:userInfo];
                                                   });
                                               }];
                    
                    [changeSheet addAction:close];
                    [changeSheet addAction:view];
                    
                    [self.window.rootViewController presentViewController:changeSheet animated:YES completion:nil];
                } else {
                    MTMakeWeakSelf();
                    __block NSDictionary *weakUserInfo = userInfo;
                    [UIAlertView bk_showAlertViewWithTitle:title message:messageToDisplay cancelButtonTitle:@"Close" otherButtonTitles:[NSArray arrayWithObject:@"View"] handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                        if (buttonIndex != alertView.cancelButtonIndex) {
                            [weakSelf handleActionNotificationWithUserInfo:weakUserInfo];
                        }
                        else {
                            [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
                        }
                    }];
                }

            }
            else {
                [self handleActionNotificationWithUserInfo:userInfo];
            }

        }
        else if ([[category uppercaseString] isEqualToString:@"USER_UPDATE"]) {
            [self handleUserUpdateWithfetchCompletionHandler:handler];
            return;
        }
    }
    
    // Make sure this gets called if not caught with "USER_UPDATE", shouldn't get here
    if (handler) {
        handler(UIBackgroundFetchResultNoData);
    }
}


- (void)handleUserUpdateWithfetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))handler
{
    MTUser *currentUser = [MTUser currentUser];
    if (currentUser && [MTUtil internetReachable]) {
        if ([MTUser currentUser] && [MTUtil internetReachable]) {
            [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
                [MTUtil setRefreshedForKey:kRefreshForMeUser];

                if (handler) {
                    handler(UIBackgroundFetchResultNewData);
                }
            } failure:^(NSError *error) {
                if (handler) {
                    handler(UIBackgroundFetchResultNewData);
                }
            }];
        }
    }
    else {
        if (handler) {
            handler(UIBackgroundFetchResultNoData);
        }
    }
}

- (void)handleActionNotificationWithUserInfo:(NSDictionary *)userInfo
{
    if (![MTUser currentUser]) {
        return;
    }

    NSString *notificationType = [userInfo valueForKey:@"notificationType"];
    NSString *notificationId = [userInfo valueForKey:@"notificationId"];
    
    BOOL unknownNotification = NO;
    if (IsEmpty(notificationType) || IsEmpty(notificationId)) {
        unknownNotification = YES;
    }
    
    if (!IsEmpty(notificationId)) {
        [MTNotificationViewController markReadForNotificationId:[notificationId integerValue]];
    }
    
    if (unknownNotification || [notificationType isEqualToString:kNotificationPostComment] ||
        [notificationType isEqualToString:kNotificationChallengeActivated] ||
        [notificationType isEqualToString:kNotificationPostLiked] ||
        [notificationType isEqualToString:kNotificationStudentInactivity] ||
        [notificationType isEqualToString:kNotificationMentorInactivity] ||
        [notificationType isEqualToString:kNotificationVerifyPost]) {
        
        SWRevealViewController *revealVC = (SWRevealViewController *)self.window.rootViewController;
        MTMenuViewController *menuVC = (MTMenuViewController *)revealVC.rearViewController;
        [menuVC openNotificationsWithId:[notificationId integerValue]];
    }
    else if ([notificationType isEqualToString:kNotificationLeaderOn] ||
             [notificationType isEqualToString:kNotificationLeaderOff]) {
        
        SWRevealViewController *revealVC = (SWRevealViewController *)self.window.rootViewController;
        MTMenuViewController *menuVC = (MTMenuViewController *)revealVC.rearViewController;
        [menuVC openLeaderboard];
    }
}


#pragma mark - Reachability Methods -
- (void)reachabilityDidChange:(NSNotification *)note
{
    BOOL reachable = (self.reachability.currentReachabilityStatus != NotReachable);
    if (reachable != self.reachable){
        // State Changed. Inform the user if necessary.
        if (reachable){
            // Connected.
            [[NSNotificationCenter defaultCenter] postNotificationName:kInternetDidBecomeReachableNotification object:nil];
        } else {
            // Lost connection.
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Lost Internet" message:@"Please check the network connection under Settings." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
    }
    self.reachable = reachable;
}


#pragma mark - Public Methods -
- (void)setDarkNavBarAppearanceForNavigationBar:(UINavigationBar *)navigationBar
{
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor navbarGrey]];
    
    [navigationBar setTintColor:[UIColor white]];

    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)setWhiteNavBarAppearanceForNavigationBar:(UINavigationBar *)navigationBar
{
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor navbarGrey]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f]}];
    
    [navigationBar setBarTintColor:[UIColor whiteColor]];
    [navigationBar setTintColor:[UIColor navbarGrey]];
    [navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f]}];

    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (void)updatePushMessagingInfoWithToken:(NSData *)deviceToken
{
    if (![MTUser isUserLoggedIn] || ![MTUser currentUser]) {
        return;
    }
    
    // Don't update if Installation doesn't have a deviceToken (i.e simulator)
    if (IsEmpty(deviceToken)) {
        return;
    }
    
    NSString *deviceTokenString = [MTUtil stringFromAPNSTokenData:deviceToken];
    
    if ([MTUtil pushMessagingRegistrationId]) {
        // Update
        [[MTNetworkManager sharedMTNetworkManager] updatePushMessagingRegistrationId:[MTUtil pushMessagingRegistrationId] withDeviceToken:deviceTokenString success:^(id responseData) {
            NSLog(@"Successfully updated push messaging registration");
        } failure:^(NSError *error) {
            NSLog(@"Unable to update push messaging registration: %@", [error mtErrorDescription]);
        }];
    }
    else {
        // Create
        [[MTNetworkManager sharedMTNetworkManager] createPushMessagingRegistrationWithDeviceToken:deviceTokenString success:^(id responseData) {
            NSLog(@"Successfully created push messaging registration");
        } failure:^(NSError *error) {
            NSLog(@"Unable to create push messaging registration: %@", [error mtErrorDescription]);
        }];
    }
}

- (UINavigationController *)userViewController
{
    if (_userViewController) {
        return _userViewController;
    }
    else {
        id userVC = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"mtUserViewControllerNav"];
        self.userViewController = userVC;
        return userVC;
    }
}


#pragma mark - Private Methods -
- (void)setupZendesk
{
    [self configureZendesk];

    /////////////////////////////////////////////////////////////////////////////////////////////////////
    // OPTIONAL - Customize appearance
    /////////////////////////////////////////////////////////////////////////////////////////////////////
    
    // request creation screen
    [[ZDKCreateRequestView appearance] setPlaceholderTextColor:[UIColor lightGrayColor]];
    [[ZDKCreateRequestView appearance] setTextEntryColor:[UIColor colorWithWhite:0.2627f alpha:1.0f]];
    [[ZDKCreateRequestView appearance] setViewBackgroundColor:[UIColor whiteColor]];
    [[ZDKCreateRequestView appearance] setTextEntryFont:[UIFont systemFontOfSize:12.0f]];
    
    [[ZDKCreateRequestView appearance] setAutomaticallyHideNavBarOnLandscape:@1];
    
//    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
//    spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
//    [[ZDKCreateRequestView appearance] setSpinner:(id<ZDKSpinnerDelegate>)spinner];
    
    // request list
    [[ZDKRequestListTable appearance] setTableBackgroundColor:[UIColor clearColor]];
    [[ZDKRequestListTable appearance] setCellSeparatorColor:[UIColor colorWithWhite:0.90f alpha:1.0f]];
    
    // loading cell
//    UIActivityIndicatorView *requestListSpinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(20, 20, 20, 20)];
//    requestListSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
//    [[ZDRequestListLoadingTableCell appearance] setSpinner:(id<ZDKSpinnerDelegate>)requestListSpinner];
    
    // request list cells
    [[ZDKRequestListTableCell appearance] setDescriptionFont:[UIFont systemFontOfSize:15]];
    [[ZDKRequestListTableCell appearance] setCreatedAtFont:[UIFont systemFontOfSize:13]];
    [[ZDKRequestListTableCell appearance] setUnreadColor:[UIColor colorWithRed:0.47059 green:0.6392 blue:0 alpha:1.0]];
    [[ZDKRequestListTableCell appearance] setDescriptionColor:[UIColor colorWithWhite:0.26f alpha:1.0f]];
    [[ZDKRequestListTableCell appearance] setCreatedAtColor:[UIColor colorWithWhite:0.54f alpha:1.0f]];
    [[ZDKRequestListTableCell appearance] setVerticalMargin:@20.0f];
    [[ZDKRequestListTableCell appearance] setDescriptionTimestampMargin:@5.0f];
    [[ZDKRequestListTableCell appearance] setLeftInset:@25.0f];
    [[ZDKRequestListTableCell appearance] setCellBackgroundColor:[UIColor whiteColor]];
    
    // no requests cell
    [[ZDRequestListEmptyTableCell appearance] setMessageFont:[UIFont systemFontOfSize:11.0f]];
    [[ZDRequestListEmptyTableCell appearance] setMessageColor:[UIColor colorWithWhite:0.3f alpha:1.0f]];
    
    // comments list agent comment cells
    [[ZDKAgentCommentTableCell appearance] setAvatarSize:@40.0f];
    [[ZDKAgentCommentTableCell appearance] setAgentNameFont:[UIFont systemFontOfSize:14.0f]];
    [[ZDKAgentCommentTableCell appearance] setAgentNameColor:[UIColor colorWithWhite:0.25f alpha:1.0f]];
    [[ZDKAgentCommentTableCell appearance] setTimestampFont:[UIFont systemFontOfSize:11.0f]];
    [[ZDKAgentCommentTableCell appearance] setTimestampColor:[UIColor colorWithWhite:0.721f alpha:1.0f]];
    [[ZDKAgentCommentTableCell appearance] setBodyFont:[UIFont systemFontOfSize:15.0f]];
    [[ZDKAgentCommentTableCell appearance] setBodyColor:[UIColor colorWithWhite:0.38f alpha:1.0f]];
    [[ZDKAgentCommentTableCell appearance] setCellBackground:[UIColor whiteColor]];
    
    // comments list end user comment cells
    [[ZDKEndUserCommentTableCell appearance] setTimestampFont:[UIFont systemFontOfSize:11.0f]];
    [[ZDKEndUserCommentTableCell appearance] setTimestampColor:[UIColor colorWithWhite:0.721f alpha:1.0f]];
    [[ZDKEndUserCommentTableCell appearance] setBodyFont:[UIFont systemFontOfSize:15.0f]];
    [[ZDKEndUserCommentTableCell appearance] setBodyColor:[UIColor colorWithWhite:0.38f alpha:1.0f]];
    [[ZDKEndUserCommentTableCell appearance] setCellBackground:[UIColor colorWithWhite:0.976f alpha:1.0f]];
    
    // comments list loading cell
//    UIActivityIndicatorView * commentListSpinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
//    commentListSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
//    [[ZDKCommentsListLoadingTableCell appearance] setSpinner:(id<ZDKSpinnerDelegate>)commentListSpinner];
    [[ZDKCommentsListLoadingTableCell appearance] setCellBackground:[UIColor whiteColor]];
    [[ZDKCommentsListLoadingTableCell appearance] setLeftInset:@25.0f];
    
    // comment entry area
//    [[ZDKCommentEntryView appearance] setTopBorderColor:[UIColor colorWithWhite:0.831f alpha:1.0f]];
//    [[ZDKCommentEntryView appearance] setTextEntryFont:[UIFont systemFontOfSize:15]];
//    [[ZDKCommentEntryView appearance] setTextEntryColor:[UIColor colorWithWhite:0.4f alpha:1.0f]];
//    [[ZDKCommentEntryView appearance] setTextEntryBackgroundColor:[UIColor colorWithWhite:0.945f alpha:1.0f]];
//    [[ZDKCommentEntryView appearance] setTextEntryBorderColor:[UIColor colorWithWhite:0.831f alpha:1.0f]];
//    [[ZDKCommentEntryView appearance] setSendButtonFont:[UIFont systemFontOfSize:12]];
//    [[ZDKCommentEntryView appearance] setSendButtonColor:[UIColor colorWithWhite:0.2627f alpha:1.0f]];
//    [[ZDKCommentEntryView appearance] setAreaBackgroundColor:[UIColor whiteColor]];
    
    //Rate My App
    [[ZDKRMADialogView appearance] setHeaderBackgroundColor:[UIColor whiteColor]];
    [[ZDKRMADialogView appearance] setHeaderColor:[UIColor colorWithWhite:0.2627f alpha:1.0f]];
    [[ZDKRMADialogView appearance] setHeaderFont:[UIFont systemFontOfSize:16.0f]];
    [[ZDKRMADialogView appearance] setButtonBackgroundColor:[UIColor colorWithWhite:0.9451f alpha:1.0f]];
    [[ZDKRMADialogView appearance] setButtonSelectedBackgroundColor:[UIColor whiteColor]];
    [[ZDKRMADialogView appearance] setButtonColor:[UIColor colorWithWhite:0.2627f alpha:1.0f]];
    [[ZDKRMADialogView appearance] setButtonFont:[UIFont systemFontOfSize:14.0f]];
    [[ZDKRMADialogView appearance] setSeparatorLineColor:[UIColor colorWithWhite:0.8470f alpha:1.0f]];
    
    // style thefeedback view
    [[ZDKRMAFeedbackView appearance] setHeaderFont:[UIFont systemFontOfSize:16.0f]];
    [[ZDKRMAFeedbackView appearance] setSubheaderFont:[UIFont systemFontOfSize:12.0f]];
    [[ZDKRMAFeedbackView appearance] setSeparatorLineColor:[UIColor colorWithWhite:0.8470f alpha:1.0f]];
    [[ZDKRMAFeedbackView appearance] setButtonBackgroundColor:[UIColor colorWithWhite:0.9451f alpha:1.0f]];
    [[ZDKRMAFeedbackView appearance] setButtonColor:[UIColor colorWithWhite:0.2627f alpha:1.0f]];
    [[ZDKRMAFeedbackView appearance] setButtonSelectedColor:[UIColor colorWithWhite:0.2627f alpha:0.3f]];
    [[ZDKRMAFeedbackView appearance] setButtonFont:[UIFont systemFontOfSize:14.0f]];
    [[ZDKRMAFeedbackView appearance] setTextEntryFont:[UIFont systemFontOfSize:12.0f]];
    
    // style the help center
    [[ZDKSupportView appearance] setBackgroundColor:[UIColor colorWithWhite:0.94f alpha:1.0f]];
    [[ZDKSupportView appearance] setTableBackgroundColor:[UIColor whiteColor]];
    [[ZDKSupportView appearance] setSearchBarStyle:UIBarStyleDefault];
    [[ZDKSupportView appearance] setSeparatorColor:[UIColor lightGrayColor]];
    [[ZDKSupportView appearance] setNoResultsFoundLabelFont:[UIFont systemFontOfSize:14.0f]];
    [[ZDKSupportView appearance] setNoResultsFoundLabelColor:[UIColor colorWithWhite:0.2627f alpha:1.0f]];
    [[ZDKSupportView appearance] setNoResultsFoundLabelBackground:[UIColor colorWithWhite:0.94f alpha:1.0f]];
    [[ZDKSupportView appearance] setNoResultsContactButtonBackground:[UIColor colorWithWhite:0.94f alpha:1.0f]];
    [[ZDKSupportView appearance] setNoResultsContactButtonBorderColor:[UIColor colorWithWhite:0.2627f alpha:1.0f]];
    [[ZDKSupportView appearance] setNoResultsContactButtonBorderWidth:@1.0f];
    [[ZDKSupportView appearance] setNoResultsContactButtonCornerRadius:@4.0f];
    [[ZDKSupportView appearance] setNoResultsFoundLabelFont:[UIFont systemFontOfSize:14.0f]];
    [[ZDKSupportView appearance] setNoResultsContactButtonEdgeInsets:[NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(12, 22, 12, 22)]];
    [[ZDKSupportView appearance] setNoResultsContactButtonTitleColorNormal:[UIColor colorWithWhite:0.2627f alpha:1.0f]];
    [[ZDKSupportView appearance] setNoResultsContactButtonTitleColorHighlighted:[UIColor colorWithWhite:0.2627f alpha:1.0f]];
    [[ZDKSupportView appearance] setNoResultsContactButtonTitleColorDisabled:[UIColor colorWithWhite:0.2627f alpha:1.0f]];
    
    //HC search cell
    [[ZDKSupportTableViewCell appearance] setBackgroundColor:[UIColor whiteColor]];
    [[ZDKSupportTableViewCell appearance] setTitleLabelBackground:[UIColor whiteColor]];
    [[ZDKSupportTableViewCell appearance] setTitleLabelColor:[UIColor colorWithWhite:0.2627f alpha:1.0f]];
    [[ZDKSupportTableViewCell appearance] setTitleLabelFont:[UIFont systemFontOfSize:18.0f]];
    
    [[ZDKSupportArticleTableViewCell appearance] setBackgroundColor:[UIColor whiteColor]];
    [[ZDKSupportArticleTableViewCell appearance] setArticleParentsLabelFont:[UIFont systemFontOfSize:12.0f]];
    [[ZDKSupportArticleTableViewCell appearance] setArticleParentsLabelColor:[UIColor lightGrayColor]];
    [[ZDKSupportArticleTableViewCell appearance] setArticleParnetsLabelBackground:[UIColor whiteColor]];
    [[ZDKSupportArticleTableViewCell appearance] setTitleLabelFont:[UIFont systemFontOfSize:18.0f]];
    [[ZDKSupportArticleTableViewCell appearance] setTitleLabelColor:[UIColor colorWithWhite:0.2627f alpha:1.0f]];
    [[ZDKSupportArticleTableViewCell appearance] setTitleLabelBackground:[UIColor whiteColor]];
    
    [[ZDKSupportAttachmentCell appearance] setBackgroundColor:[UIColor colorWithWhite:0.94f alpha:1.0f]];
    [[ZDKSupportAttachmentCell appearance] setTitleLabelBackground:[UIColor colorWithWhite:0.94f alpha:1.0f]];
    [[ZDKSupportAttachmentCell appearance] setTitleLabelColor:[UIColor colorWithWhite:0.2627f alpha:1.0f]];
    [[ZDKSupportAttachmentCell appearance] setTitleLabelFont:[UIFont systemFontOfSize:12.0f]];
    [[ZDKSupportAttachmentCell appearance] setFileSizeLabelBackground:[UIColor colorWithWhite:0.94f alpha:1.0f]];
    [[ZDKSupportAttachmentCell appearance] setFileSizeLabelColor:[UIColor grayColor]];
    [[ZDKSupportAttachmentCell appearance] setFileSizeLabelFont:[UIFont systemFontOfSize:12.0f]];
    
//    UIActivityIndicatorView *rmaSpinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
//    rmaSpinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
//    [[ZDKRMAFeedbackView appearance] setSpinner:(id<ZDKSpinnerDelegate>)rmaSpinner];
}

- (void)clearZendesk
{
    // Call to clear on new launch as preventative for Zendesk connection errors
    [[ZDKConfig instance] setUserIdentity:nil];
    [[ZDKSdkStorage instance] clearUserData];
    [[ZDKSdkStorage instance].settingsStorage deleteStoredData];
}

- (void)configureZendesk
{    
    [ZDKLogger enable:YES];

    [ZDKRequests configure:^(ZDKAccount *account, ZDKRequestCreationConfig *requestCreationConfig) {
        
        // specify any additional tags desired
        NSString *appVersion = [NSString stringWithFormat:@"AppVersion_%@ AppBuild_%@",
                                [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
                                [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
        
        requestCreationConfig.tags = [NSArray arrayWithObjects:[[UIDevice currentDevice].model stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                                      [[UIDevice currentDevice].localizedModel stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                                      [[UIDevice currentDevice].systemName stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                                      [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@" " withString:@"_"],
                                      appVersion,
                                      nil];
        
        // add some custom content to the description
        //NSString *additionalText = @"Some sample extra content.";
        //
        //                    NSString *txt = [NSString stringWithFormat:@"%@%@",
        //                                     [requestCreationConfig contentSeperator],
        //                                     additionalText];
        //
        //                    requestCreationConfig.additionalRequestInfo = txt;
    }];

    // Set Anonymous user info
    MTUser *userCurrent = [MTUser currentUser];
    if (userCurrent) {
        ZDKAnonymousIdentity *newIdentity = [ZDKAnonymousIdentity new];
        newIdentity.name = [NSString stringWithFormat:@"%@ %@", userCurrent.firstName, userCurrent.lastName];
        newIdentity.email = userCurrent.email;
        newIdentity.externalId = [NSString stringWithFormat:@"%ld", (long)userCurrent.id];
        [[ZDKConfig instance] setUserIdentity:newIdentity];
    }
}

// This method should only be called when you're ready to use Zendesk, since
// if it was called on app startup it might generate confusing error messages.
- (void)initializeZendesk {
    [[ZDKConfig instance] initializeWithAppId:@"654c0b54d71d4ec0aee909890c4191c391d5f35430d46d8c"
                                   zendeskUrl:@"https://moneythink.zendesk.com"
                                     ClientId:@"mobile_sdk_client_aa71675d30d20f4e22dd"
                                    onSuccess:^{
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                                        });
                                    } onError:^(NSError *error) {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                                            [UIAlertView bk_showAlertViewWithTitle:@"Unable to connect to Moneythink Support" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                                        });
                                    }];
}

- (void)executeForceUpdateRefresh
{
    SWRevealViewController *revealVC = (SWRevealViewController *)self.window.rootViewController;
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        if (revealVC.frontViewPosition == FrontViewPositionRight) {
            [revealVC revealToggleAnimated:NO];
        }
        
        if (self.userViewController) {
            [self.userViewController popToRootViewControllerAnimated:NO];
            
            id topVC = [self.userViewController topViewController];
            if ([topVC isKindOfClass:[MTLoginViewController class]]) {
                MTLoginViewController *loginVC = (MTLoginViewController *)[self.userViewController topViewController];
                
                if (revealVC.frontViewController != self.userViewController) {
                    [revealVC setFrontViewController:self.userViewController animated:YES];
                }
                else {
                    [loginVC shouldUpdateView];
                }
            }
        }
    });
}

- (BOOL)shouldForceUpdate
{
    // Bypass this for now until we decide whether to keep in.
    return NO;
    
//    return [[NSUserDefaults standardUserDefaults] boolForKey:kForcedUpdateKey];
}

- (void)purgeDeletedData
{
    // Start background task to remove deleted records
    __block UIBackgroundTaskIdentifier bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        bgTask = UIBackgroundTaskInvalid;
    }];
    
    [MTUtil cleanDeletedItemsInDatabase];
    [[UIApplication sharedApplication] endBackgroundTask:bgTask];
}

- (void)authenticateCurrentUserWithLayerSDK {
    MTUser *currentUser = [MTUser currentUser];
    if (currentUser == nil) return;
    if (self.layerClient.authenticatedUserID != nil) return;
    
    [self.layerClient connectWithCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"LYR: Failed to connect to Layer: %@", error);
        } else {
            NSString *userIDString = [NSString stringWithFormat:@"%lu", currentUser.id];
            NSString *environmentName = layerEnvironmentName;
            if (environmentName == nil || [environmentName length] == 0) {
                environmentName = @"development";
            }
            
            userIDString = [NSString stringWithFormat:@"%@-%@", environmentName, userIDString];
            [self authenticateLayerWithUserID:userIDString completion:^(BOOL success, NSError *error) {
                if (!success) {
                    NSLog(@"LYR: Failed Authenticating Layer Client with error:%@", error);
                }
            }];
        }
    }];
}

#pragma mark - SWRevealViewControllerDelegate Methods -
- (void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position;
{
    if (position == FrontViewPositionRight) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kWillMoveToOpenMenuPositionNotification object:nil];
    }
}

- (void)revealController:(SWRevealViewController *)revealController didMoveToPosition:(FrontViewPosition)position
{
    if (revealController.frontViewPosition == FrontViewPositionRight) {
        UIView *lockingView = [UIView new];
        lockingView.translatesAutoresizingMaskIntoConstraints = NO;
                
        __block SWRevealViewController *weakReveal = revealController;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (weakReveal.frontViewPosition == FrontViewPositionRight) {
                [weakReveal revealToggle:nil];
            }
            [[revealController.frontViewController.view viewWithTag:1000] removeFromSuperview];
        }];
        [lockingView addGestureRecognizer:tap];
        [lockingView addGestureRecognizer:revealController.panGestureRecognizer];
        [lockingView setTag:1000];
        [revealController.frontViewController.view addSubview:lockingView];
        
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(lockingView);
        
        [revealController.frontViewController.view addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"|[lockingView]|"
                                                 options:0
                                                 metrics:nil
                                                   views:viewsDictionary]];
        [revealController.frontViewController.view addConstraints:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lockingView]|"
                                                 options:0
                                                 metrics:nil
                                                   views:viewsDictionary]];
        [lockingView sizeToFit];
    }
    else {
        [[revealController.frontViewController.view viewWithTag:1000] removeFromSuperview];
        
        UIView *frontView = [revealController.frontViewController.view viewWithTag:5000];
        if (frontView) {
            [frontView removeGestureRecognizer:revealController.panGestureRecognizer];
            [frontView addGestureRecognizer:revealController.panGestureRecognizer];
        }
    }
}

- (void)clearLogoutReason {
    self.logoutReason = nil;
}


#pragma mark - Realm Methods -
- (void)setupRealm
{
    // Can clear database on launch for testing
//    [[NSFileManager defaultManager] removeItemAtPath:[[RLMRealm defaultRealm] path] error:nil];
//    [MTUtil logout];
    
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    // Set the new schema version. This must be greater than the previously used
    // version (if you've never set a schema version before, the version is 0).
    config.schemaVersion = 40;
    
    // Set the block which will be called automatically when opening a Realm with a
    // schema version lower than the one set above
    config.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        // We haven’t migrated anything yet, so oldSchemaVersion == 0
        if (oldSchemaVersion < 1) {
            // Nothing to do!
            // Realm will automatically detect new properties and removed properties
            // And will update the schema on disk automatically
        }
    };
    
    // Tell Realm to use this new configuration object for the default Realm
    [RLMRealmConfiguration setDefaultConfiguration:config];
    
    // Now that we've told Realm how to handle the schema change, opening the file
    // will automatically perform the migration
    [RLMRealm defaultRealm];
}

#pragma mark - Layer SDK methods
- (void)authenticateLayerWithUserID:(NSString *)userID completion:(void (^)(BOOL success, NSError * error))completion
{
    // Check to see if the layerClient is already authenticated.
    if (self.layerClient.authenticatedUserID) {
        // If the layerClient is authenticated with the requested userID, complete the authentication process.
        if ([self.layerClient.authenticatedUserID isEqualToString:userID]){
            NSLog(@"LYR: Layer Authenticated as User %@", self.layerClient.authenticatedUserID);
            if (completion) completion(YES, nil);
            return;
        } else {
            //If the authenticated userID is different, then deauthenticate the current client and re-authenticate with the new userID.
            [self.layerClient deauthenticateWithCompletion:^(BOOL success, NSError *error) {
                if (!error){
                    [self authenticationTokenWithUserId:userID completion:^(BOOL success, NSError *error) {
                        if (completion){
                            completion(success, error);
                        }
                    }];
                } else {
                    if (completion){
                        completion(NO, error);
                    }
                }
            }];
        }
    } else {
        // If the layerClient isn't already authenticated, then authenticate.
        [self authenticationTokenWithUserId:userID completion:^(BOOL success, NSError *error) {
            if (completion){
                completion(success, error);
            }
        }];
    }
}

- (void)authenticationTokenWithUserId:(NSString *)userID completion:(void (^)(BOOL success, NSError* error))completion{
    
    /*
     * 1. Request an authentication Nonce from Layer
     */
    [self.layerClient requestAuthenticationNonceWithCompletion:^(NSString *nonce, NSError *error) {
        if (!nonce) {
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        
        /*
         * 2. Acquire identity Token from Layer Identity Service
         */
        [[MTNetworkManager sharedMTNetworkManager] requestLayerSDKIdentityTokenForCurrentUserWithAppID:[self.layerClient.appID absoluteString] nonce:nonce completion:^(NSString *identityToken, NSError *error) {
            if (!identityToken) {
                if (completion) {
                    completion(NO, error);
                }
                return;
            }
            
            /*
             * 3. Submit identity token to Layer for validation
             */
            [self.layerClient authenticateWithIdentityToken:identityToken completion:^(NSString *authenticatedUserID, NSError *error) {
                if (authenticatedUserID) {
                    if (completion) {
                        completion(YES, nil);
                    }
                    NSLog(@"Layer Authenticated as User: %@", authenticatedUserID);
                } else {
                    completion(NO, error);
                }
            }];
        }];
    }];
}

- (void)requestLayerSDKIdentityTokenForUserID:(NSString *)userID appID:(NSString *)appID nonce:(NSString *)nonce completion:(void(^)(NSString *identityToken, NSError *error))completion
{
    NSParameterAssert(userID);
    NSParameterAssert(appID);
    NSParameterAssert(nonce);
    NSParameterAssert(completion);
    
    
}

@end
