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

- (void)setDefaultNavBarAppearanceForNavigationBar:(UINavigationBar *)navigationBar;
- (void)setWhiteNavBarAppearanceForNavigationBar:(UINavigationBar *)navigationBar;
- (void)setGrayNavBarAppearanceForNavigationBar:(UINavigationBar *)navigationBar;
- (void)updateParseInstallationState;
- (void)checkForCustomPlaylistContentWithRefresh:(BOOL)refresh;
- (void)selectSettingsTabView;
- (void)configureZendesk;

@end
