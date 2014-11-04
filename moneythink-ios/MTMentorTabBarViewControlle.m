//
//  MTMentorTabBarViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/25/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMentorTabBarViewControlle.h"
#import "MTMentorStudentProgressViewController.h"
#import "MTMentorChallengeRoomViewController.h"
#import "MTStudentSettingsViewController.h"

@interface MTMentorTabBarViewController ()

@end

@implementation MTMentorTabBarViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    self.navigationItem.hidesBackButton = YES;
    
    self.delegate = self;
    self.tabBarController.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![self.selectedViewController isKindOfClass:[MTStudentSettingsViewController class]]) {
        [[MTUtil getAppDelegate] setDefaultNavBarAppearanceForNavigationBar:self.navigationController.navigationBar];
    }
}


#pragma mark = UITabBarControllerDelegate delegate methods
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController;
{
    return YES;
}


#pragma mark - UIActionSheetDelegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex  // after animation
{
    switch (buttonIndex) {
        case 0:
            [PFUser logOut];
            [self performSegueWithIdentifier:@"unwindToSignUpLogin" sender:nil];
            break;
            
        default:
            break;
    }
}


@end
