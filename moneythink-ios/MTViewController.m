//
//  MTViewController.m
//  moneythink-ios
//
//  Created by David Sica on 5/26/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTViewController.h"

@interface MTViewController ()

@property (nonatomic, weak) IBOutlet UIBarButtonItem *revealButtonItem;

@end

@implementation MTViewController

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
        [self.revealButtonItem setTarget: self.revealViewController];
        [self.revealButtonItem setAction: @selector(revealToggle:)];
        self.revealButtonItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount];
        
        // Set the gesture
        //  Add tag = 5000 so panGestureRecognizer can be re-added
        self.navigationController.navigationBar.tag = 5000;
    }
}

- (void)unreadCountUpdate:(NSNotification *)note
{
    self.revealButtonItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount];
}


@end
