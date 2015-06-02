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

- (void)customSetup
{
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController) {
        [self.revealButtonItem setTarget: self.revealViewController];
        [self.revealButtonItem setAction: @selector(revealToggle:)];
        [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    }
}


@end
