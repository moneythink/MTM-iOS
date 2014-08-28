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

#ifdef DEBUG
// stage
    static NSString *applicationID = @"OFZ4TDvgCYnu40A5bKIui53PwO43Z2x5CgUKJRWz";
    static NSString *clientKey = @"2OBw9Ggbl5p0gJ0o6Y7n8rK7gxhFTGcRQAXH6AuM";
#else
// production
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
    [application registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeAlert |
     UIRemoteNotificationTypeSound];
    
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
    
    [[UINavigationBar appearance] setBarTintColor:[UIColor white]];
    [[UINavigationBar appearance] setTintColor:[UIColor primaryOrange]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor blackColor], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f]}];
    
    [[UITabBar appearance] setTintColor:[UIColor primaryOrange]];
    [[UITabBar appearance] setBarTintColor:[UIColor lightGrey]];
    
    [Crashlytics startWithAPIKey:@"f79dbd9b335f6c6ed9fc1fa3e3a0534cf5016b0e"];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {
    // Store the deviceToken in the current installation and save it to Parse.
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    [currentInstallation setDeviceTokenFromData:newDeviceToken];
    currentInstallation.channels = @[@"global"];
    [currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
}

@end
