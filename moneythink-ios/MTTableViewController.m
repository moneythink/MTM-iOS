//
//  MTViewController.m
//  moneythink-ios
//
//  Created by David Sica on 5/26/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTTableViewController.h"

@interface MTTableViewController ()

@end

@implementation MTTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self customSetup];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unreadCountUpdate:) name:kUnreadNotificationCountNotification object:nil];
    [self.navigationController.navigationBar addGestureRecognizer:self.revealViewController.panGestureRecognizer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    for (UIGestureRecognizer *thisGesture in [self.navigationController.navigationBar gestureRecognizers]) {
        [self.navigationController.navigationBar removeGestureRecognizer:thisGesture];
    }
}

- (void)customSetup
{
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController) {
        UIButton *customButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [customButton addTarget:self.revealViewController action:@selector(revealToggle:) forControlEvents:UIControlEventTouchUpInside];
        [customButton setImage:[UIImage imageNamed:@"icon_main_nav.png"] forState:UIControlStateNormal];
        BBBadgeBarButtonItem *barButton = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:customButton];
        barButton.badgeOriginX = 13;
        barButton.badgeOriginY = -9;
        barButton.badgeValue = [NSString stringWithFormat:@"%ld", (long)((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount];
        self.navigationItem.leftBarButtonItem = barButton;
        
        // Set the gesture
        //  Add tag = 5000 so panGestureRecognizer can be re-added
        self.navigationController.navigationBar.tag = 5000;
    }
}

- (void)unreadCountUpdate:(NSNotification *)note
{
    BBBadgeBarButtonItem *barButton = (BBBadgeBarButtonItem *)self.navigationItem.leftBarButtonItem;
    barButton.badgeValue = [NSString stringWithFormat:@"%ld", (long)((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount];
}


@end
