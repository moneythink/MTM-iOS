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
#import <Crashlytics/Crashlytics.h>
#import "UIColor+Palette.h"

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
    [Parse setApplicationId:applicationID
                  clientKey:clientKey];
    
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
    
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];
    
    // Register for push notifications
    if ([application respondsToSelector:@selector(registerForRemoteNotifications)]) {
        [application registerForRemoteNotifications];
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:(UIRemoteNotificationTypeBadge
                                                                                             |UIRemoteNotificationTypeSound
                                                                                             |UIRemoteNotificationTypeAlert) categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    else {
        [application registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound)];
    }
    
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
    
    [Crashlytics startWithAPIKey:@"f79dbd9b335f6c6ed9fc1fa3e3a0534cf5016b0e"];
    
    // Set up Reachability
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityDidChange:)
                                                 name:kReachabilityChangedNotification object:nil];
    
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


@end
