//
//  AppDelegate.m
//  moneythink-ios
//
//  Created by jdburgie on 7/10/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import "MTHomeViewController.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import "UIColor+Palette.h"
#import "MTMentorTabBarViewControlle.h"
#import "MTStudentTabBarViewController.h"
#import "MTMentorNotificationViewController.h"

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
    
    [[ZDKConfig instance] initializeWithAppId:@"654c0b54d71d4ec0aee909890c4191c391d5f35430d46d8c"
                               zendeskUrl:@"https://moneythink.zendesk.com"
                              andClientId:@"mobile_sdk_client_aa71675d30d20f4e22dd"];
    
    [Parse setApplicationId:applicationID clientKey:clientKey];
    //[Parse enableLocalDatastore];
    
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
    
    [self setDefaultNavBarAppearanceForNavigationBar:nil];
    
    [[UITabBar appearance] setTintColor:[UIColor primaryOrange]];
    [[UITabBar appearance] setBarTintColor:[UIColor lightGrey]];
    [[UISwitch appearance] setOnTintColor:[UIColor primaryGreen]];
    
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    
    // Register for push notifications
    if ([application respondsToSelector:@selector(registerForRemoteNotifications)])
    {
        [application registerForRemoteNotifications];
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    else
    {
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }
    
    // Set up Reachability
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
    self.reachability = [Reachability reachabilityForInternetConnection];
    self.reachable = [MTUtil internetReachable];
    [self.reachability startNotifier];
    
    return YES;
}

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
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError: %@", [error localizedDescription]);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [PFPush handlePush:userInfo];
    
    // Open Notifications tab, if appropriate
    NSDictionary *apsDict = [userInfo objectForKey:@"aps"];
    if ([apsDict valueForKey:@"category"]) {
        NSString *category = [apsDict valueForKey:@"category"];
        if (![[category uppercaseString] isEqualToString:@"NOTIFICATIONS"]) {
            return;
        }
    }
    else {
        return;
    }
    
    id rootVC = self.window.rootViewController;
    if ([rootVC isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)rootVC;
        
        id tabBar = nav.topViewController;
        if (![tabBar isKindOfClass:[UITabBarController class]]) {
            return;
        }
        
        NSInteger indexOfNotificationVC = -1;

        if ([tabBar isKindOfClass:[MTMentorTabBarViewController class]]) {
            // Mentor
            NSInteger index = 0;
            NSArray *viewControllers = ((MTMentorTabBarViewController *)tabBar).viewControllers;
            for (UIViewController *vc in viewControllers) {
                if ([vc isKindOfClass:[UINavigationController class]]) {
                    id topVC = ((UINavigationController *)vc).topViewController;
                    if ([topVC isKindOfClass:[MTMentorNotificationViewController class]]) {
                        indexOfNotificationVC = index;
                        break;
                    }
                }
                index++;
            }
        }
        else if ([tabBar isKindOfClass:[MTStudentTabBarViewController class]]) {
            // Student
            NSInteger index = 0;
            NSArray *viewControllers = ((MTStudentTabBarViewController *)tabBar).viewControllers;
            for (UIViewController *vc in viewControllers) {
                if ([vc isKindOfClass:[UINavigationController class]]) {
                    id topVC = ((UINavigationController *)vc).topViewController;
                    if ([topVC isKindOfClass:[MTMentorNotificationViewController class]]) {
                        indexOfNotificationVC = index;
                        break;
                    }
                }
                index++;
            }
        }
        else {
            return;
        }
        
        NSArray *viewControllers = ((UITabBarController *)tabBar).viewControllers;
        if (indexOfNotificationVC != -1 && [viewControllers count] > indexOfNotificationVC) {
            [((UITabBarController *)tabBar) setSelectedIndex:indexOfNotificationVC];
        }
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
- (void)setDefaultNavBarAppearanceForNavigationBar:(UINavigationBar *)navigationBar
{
    [[UINavigationBar appearance] setBarTintColor:[UIColor primaryOrange]];
    [[UINavigationBar appearance] setTintColor:[UIColor white]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor white], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f]}];
    
    [navigationBar setBarTintColor:[UIColor primaryOrange]];
    [navigationBar setTintColor:[UIColor white]];
    [navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor white], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f]}];

    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)setWhiteNavBarAppearanceForNavigationBar:(UINavigationBar *)navigationBar
{
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTintColor:[UIColor primaryOrange]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f]}];
    
    [navigationBar setBarTintColor:[UIColor whiteColor]];
    [navigationBar setTintColor:[UIColor primaryOrange]];
    [navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f]}];

    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (void)setGrayNavBarAppearanceForNavigationBar:(UINavigationBar *)navigationBar
{
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithHexString:@"ECEBF3"]];
    [[UINavigationBar appearance] setTintColor:[UIColor primaryOrange]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f]}];
    
    [navigationBar setBarTintColor:[UIColor colorWithHexString:@"ECEBF3"]];
    [navigationBar setTintColor:[UIColor primaryOrange]];
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
    // Default to no custom playlist
    [MTUtil setDisplayingCustomPlaylist:YES];

    // Only need to do this if we have custom playlists
    NSString *userClass = [PFUser currentUser][@"class"];
    NSString *userSchool = [PFUser currentUser][@"school"];
    
    PFQuery *userClassQuery = [PFQuery queryWithClassName:[PFClasses parseClassName]];
    [userClassQuery whereKey:@"name" equalTo:userClass];
    [userClassQuery whereKey:@"school" equalTo:userSchool];
    userClassQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    [MTUtil setDisplayingCustomPlaylist:NO];
    
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
                                [MTUtil setDisplayingCustomPlaylist:YES];
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


#pragma mark - Private Methods -
- (void)loadCustomChallengesForPlaylist:(PFPlaylist *)playlist
{
    [MTUtil setDisplayingCustomPlaylist:YES];
    
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


@end
