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

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) Reachability *reachability;
@property (nonatomic) BOOL reachable;
@property (nonatomic, strong) UINavigationController *userViewController;
@property (nonatomic) NSInteger currentUnreadCount;
@property (nonatomic) NSString *logoutReason;

- (void)setDarkNavBarAppearanceForNavigationBar:(UINavigationBar *)navigationBar;
- (void)setWhiteNavBarAppearanceForNavigationBar:(UINavigationBar *)navigationBar;
- (void)updatePushMessagingInfo;
- (void)configureZendesk;
- (BOOL)shouldForceUpdate;
- (void)clearLogoutReason;

@end
