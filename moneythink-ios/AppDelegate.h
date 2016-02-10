//
//  AppDelegate.h
//  moneythink-ios
//
//  Created by jdburgie on 7/10/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Reachability.h"
#import "MTLoginViewController.h"
#import <LayerKit/LayerKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) Reachability *reachability;
@property (nonatomic) BOOL reachable;
@property (nonatomic, strong) UINavigationController *userViewController;
@property (nonatomic) NSInteger currentUnreadCount;
@property (nonatomic) NSString *logoutReason;
@property (nonatomic) LYRClient *layerClient;

- (void)setDarkNavBarAppearanceForNavigationBar:(UINavigationBar *)navigationBar;
- (void)setWhiteNavBarAppearanceForNavigationBar:(UINavigationBar *)navigationBar;
- (void)configureZendesk;
- (void)registerForPushNotifications;
- (void)initializeZendesk;
- (BOOL)shouldForceUpdate;
- (void)clearLogoutReason;

- (void)authenticateCurrentUserWithLayerSDK;

@end
