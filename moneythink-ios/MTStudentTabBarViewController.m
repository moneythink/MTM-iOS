//
//  MTStudentTabBarViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/25/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentTabBarViewController.h"

#ifdef DEBUG
static BOOL button1 = YES;
#else
static BOOL button1 = NO;
#endif
@interface MTStudentTabBarViewController ()

@end

@implementation MTStudentTabBarViewController

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

    [self.navigationController setNavigationBarHidden:NO animated:YES];

    self.navigationItem.hidesBackButton = YES;

    self.delegate = self;

//    if (button1) {
//        UIBarButtonItem *button1 = [[UIBarButtonItem alloc]
//                                    initWithTitle:@"x"
//                                    style:UIBarButtonItemStyleBordered
//                                    target:self
//                                    action:@selector(tappedButtonItem1:)];
//        
//        self.navigationItem.rightBarButtonItem = button1;
//    }
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationItem.title = @"Challenges";
//    self.parentViewController.navigationItem.title = @"Challenges";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}


#pragma mark - Button selectors

- (void)tappedButtonItem1:(id)sender
{
    UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Logout", nil];
    
    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    if ([window.subviews containsObject:self.view]) {
        [logoutSheet showInView:self.view];
    } else {
        [logoutSheet showInView:window];
    }

}


#pragma mark - Navigation

/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
