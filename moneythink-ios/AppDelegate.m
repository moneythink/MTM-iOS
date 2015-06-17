//
//  AppDelegate.m
//  moneythink-ios
//
//  Created by jdburgie on 7/10/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "UIColor+Palette.h"
#import "MTNotificationViewController.h"
#import "MTSupportViewController.h"
#import "MTMenuViewController.h"
#import "MTPostViewController.h"

#ifdef STAGE
    static NSString *applicationID = @"OFZ4TDvgCYnu40A5bKIui53PwO43Z2x5CgUKJRWz";
    static NSString *clientKey = @"2OBw9Ggbl5p0gJ0o6Y7n8rK7gxhFTGcRQAXH6AuM";
#else
    static NSString *applicationID = @"9qekFr9m2QTFAEmdw9tXSesLn31cdnmkGzLjOBxo";
    static NSString *clientKey = @"k5hfuAu2nAgoi9vNk149DJL0YEGCObqwEEZhzWQh";
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Fabric with:@[CrashlyticsKit]];
    
    [Parse setApplicationId:applicationID clientKey:clientKey];
    //[Parse enableLocalDatastore];
    
    // AFTER Parse setup
    [self clearZendesk];
    [self setupZendesk];
    
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    [PFChallengeBanner registerSubclass];
    [PFChallengePost registerSubclass];
    [PFChallengePostButtonsClicked registerSubclass];
    [PFSignupCodes registerSubclass];
    [PFChallengePost registerSubclass];
    [PFSignupCodes registerSubclass];
    [PFChallengePost registerSubclass];
    [PFSignupCodes registerSubclass];
    [PFChallengePost registerSubclass];
    [PFSignupCodes registerSubclass];
    [PFChallengePost registerSubclass];
    [PFSignupCodes registerSubclass];
    [PFStudentPointDetails registerSubclass];
    
    // Set default ACLs
    PFACL *defaultACL = [PFACL ACL];
    [defaultACL setPublicReadAccess:YES];
    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
    
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
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }
    
    // Set up Reachability
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    self.reachability = [Reachability reachabilityForInternetConnection];
    self.reachable = [MTUtil internetReachable];
    [self.reachability startNotifier];
    
    [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:YES];
    
    if ([PFUser currentUser] && [MTUtil internetReachable]) {
        [[PFUser currentUser] fetchInBackground];
    }

    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:YES];
    if ([PFUser currentUser] && [MTUtil internetReachable]) {
        [[PFUser currentUser] fetchInBackground];
    }
}


#pragma mark - Push Notifications -
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken
{
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    currentInstallation.channels = @[@"global"];
    [currentInstallation saveInBackground];
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

                if ([UIAlertController class]) {
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
    PFUser *currentUser = [PFUser currentUser];
    if (currentUser && [MTUtil internetReachable]) {
        [currentUser fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (handler) {
                handler(UIBackgroundFetchResultNewData);
            }
        }];
    }
    else {
        if (handler) {
            handler(UIBackgroundFetchResultNoData);
        }
    }
}

- (void)handleActionNotificationWithUserInfo:(NSDictionary *)userInfo
{
    NSString *notificationType = [userInfo valueForKey:@"notificationType"];
    NSString *notificationId = [userInfo valueForKey:@"notificationId"];
    
    if (IsEmpty(notificationType) || IsEmpty(notificationId)) {
        return;
    }
    
    [MTNotificationViewController markReadForNotificationId:notificationId];
    
    if ([notificationType isEqualToString:kNotificationPostComment] ||
        [notificationType isEqualToString:kNotificationNewChallenge] ||
        [notificationType isEqualToString:kNotificationPostLiked] ||
        [notificationType hasPrefix:kNotificationInactivity] ||
        [notificationType isEqualToString:kNotificationVerifyPost]) {
        
        SWRevealViewController *revealVC = (SWRevealViewController *)self.window.rootViewController;
        MTMenuViewController *menuVC = (MTMenuViewController *)revealVC.rearViewController;
        [menuVC openNotificationsWithId:notificationId withType:notificationType];
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

- (void)updateParseInstallationState
{
    if (![PFUser currentUser]) {
        NSLog(@"Have no user object to update installation with");
        return;
    }
    
    PFUser *user = [PFUser currentUser];

    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    
    // Don't update if Installation doesn't have a deviceToken (i.e simulator)
    if (IsEmpty(currentInstallation.deviceToken)) {
        return;
    }
    
    [currentInstallation setObject:user forKey:@"user"];

    NSString *className = user[@"class"];
    NSString *schoolName = user[@"school"];
    
    if (!IsEmpty(className)) {
        [currentInstallation setObject:className forKey:@"class_name"];
    }
    if (!IsEmpty(schoolName)) {
        [currentInstallation setObject:schoolName forKey:@"school_name"];
    }
    
    currentInstallation.channels = @[@"global"];
    [currentInstallation saveInBackground];
}

- (void)checkForCustomPlaylistContentWithRefresh:(BOOL)refresh;
{
    // Only need to do this if we have custom playlists
    NSString *userClass = [PFUser currentUser][@"class"];
    NSString *userSchool = [PFUser currentUser][@"school"];
    
    PFQuery *userClassQuery = [PFQuery queryWithClassName:[PFClasses parseClassName]];
    [userClassQuery whereKey:@"name" equalTo:userClass];
    [userClassQuery whereKey:@"school" equalTo:userSchool];
    userClassQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    if (refresh) {
        hud.labelText = @"Refreshing Content...";
    }
    else {
        hud.labelText = @"Loading Content...";
    }
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [userClassQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                if (!IsEmpty(objects)) {
                    PFClasses *userClass = [objects firstObject];
                    NSLog(@"%@", userClass);
                    
                    // Next, determine if this class has custom challenges
                    __block PFQuery *customPlaylist = [PFQuery queryWithClassName:[PFPlaylist parseClassName]];
                    [customPlaylist whereKey:@"class" equalTo:userClass];
                    customPlaylist.cachePolicy = kPFCachePolicyNetworkElseCache;
                    
                    [customPlaylist findObjectsInBackgroundWithBlock:^(NSArray *playlistObjects, NSError *error) {
                        if (!error) {
                            if (!IsEmpty(playlistObjects)) {
                                // Pre-load the content
                                [weakSelf loadCustomChallengesForPlaylist:[playlistObjects firstObject]];
                            }
                            else {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                                });
                            }
                        }
                        else {
                            NSLog(@"Error loading custom playlists: %@", [error localizedDescription]);
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                            });
                        }
                    }];
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                    });
                }
            }
            else {
                NSLog(@"Error loading custom playlists: %@", [error localizedDescription]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
            }
        }];
    } afterDelay:0.35f];
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
- (void)loadCustomChallengesForPlaylist:(PFPlaylist *)playlist
{
    PFQuery *allCustomChallenges = [PFQuery queryWithClassName:[PFPlaylistChallenges parseClassName]];
    [allCustomChallenges whereKey:@"playlist" equalTo:playlist];
    [allCustomChallenges orderByAscending:@"ordering"];
    [allCustomChallenges includeKey:@"challenge"];
    
    [allCustomChallenges findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        });
        
        if (!error) {
            for (PFPlaylistChallenges *thisPlaylistChallenge in objects) {
                PFCustomChallenges *thisChallenge = thisPlaylistChallenge[@"challenge"];
                NSInteger ordering = [thisPlaylistChallenge[@"ordering"] integerValue];
                [MTUtil setOrdering:ordering forChallengeObjectId:thisChallenge.objectId];
            }
        }
        else {
            NSLog(@"Unable to load custom challenges");
        }
    }];
}

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
    [[ZDKConfig instance] initializeWithAppId:@"654c0b54d71d4ec0aee909890c4191c391d5f35430d46d8c"
                                   zendeskUrl:@"https://moneythink.zendesk.com"
                                  andClientId:@"mobile_sdk_client_aa71675d30d20f4e22dd"];

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
    PFUser *userCurrent = [PFUser currentUser];
    if (userCurrent) {
        ZDKAnonymousIdentity *newIdentity = [ZDKAnonymousIdentity new];
        newIdentity.name = [NSString stringWithFormat:@"%@ %@", userCurrent[@"first_name"], userCurrent[@"last_name"]];
        newIdentity.email = userCurrent[@"email"];
        newIdentity.externalId = [userCurrent objectId];
        [[ZDKConfig instance] setUserIdentity:newIdentity];
    }
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
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:revealController action:@selector(revealToggle:)];
        
        __block SWRevealViewController *weakReveal = revealController;
        tap = [[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
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


@end
