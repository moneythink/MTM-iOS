//
//  MTUserViewController.m
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "MTUserViewController.h"

@interface MTUserViewController ()

@property (strong, nonatomic) IBOutlet UIButton *studentSignUpButton;
@property (strong, nonatomic) IBOutlet UIButton *mentorSignUpButton;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;

@property (strong, nonatomic) MTSignUpViewController *signUpViewController;

@end

@implementation MTUserViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {

    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self.view setBackgroundColor:[UIColor primaryGreen]];
    [self updateView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetBecameReachable:) name:kInternetDidBecomeReachableNotification object:nil];
}

- (void)viewWillDisappear:(BOOL) animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateView
{
    if ([PFUser currentUser]) {
        self.studentSignUpButton.hidden = YES;
        self.mentorSignUpButton.hidden = YES;
        self.loginButton.hidden = YES;

        PFUser *user = [PFUser currentUser];
        [PFCloud callFunctionInBackground:@"userLoggedIn" withParameters:@{@"user_id": [user objectId]} block:^(id object, NSError *error) {
            if (!error) {
                if ([[[PFUser currentUser] valueForKey:@"type"] isEqualToString:@"student"]) {
                    [self performSegueWithIdentifier:@"studentMain" sender:self];
                } else {
                    [self performSegueWithIdentifier:@"pushMentorNotificationView" sender:self];
                }
            } else {
                NSLog(@"error - %@", error);
                
                if (![MTUtil internetReachable]) {
                    [UIAlertView showNoInternetAlert];
                }
                else {
                    [UIAlertView showNetworkAlertWithError:error];
                }
            }
        }];
    } else {
        self.studentSignUpButton.hidden = NO;
        self.mentorSignUpButton.hidden = NO;
        self.loginButton.hidden = NO;
        
        [self.studentSignUpButton setTitle:@"SIGN UP AS STUDENT" forState:UIControlStateNormal];
        [self.mentorSignUpButton setTitle:@"SIGN UP AS MENTOR" forState:UIControlStateNormal];
        [self.loginButton setTitle:@"LOGIN" forState:UIControlStateNormal];
        
        CGFloat radius = 4.0f;
        
        self.studentSignUpButton.layer.cornerRadius = radius;
        self.mentorSignUpButton.layer.cornerRadius = radius;
        self.loginButton.layer.cornerRadius = radius;
        
        [self.studentSignUpButton setBackgroundColor:[UIColor mutedOrange]];
        [self.mentorSignUpButton setBackgroundColor:[UIColor mutedGreen]];
        [self.loginButton setBackgroundColor:[UIColor primaryGreen]];
        
        [self.studentSignUpButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
        [self.mentorSignUpButton setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [self.loginButton setTitleColor:[UIColor white] forState:UIControlStateNormal];

    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueID = [segue identifier];
    id segueDVC = [segue destinationViewController];

    if ([segueID isEqualToString:@"studentSignup"]) {
        self.signUpViewController = (MTSignUpViewController *)segueDVC;
        self.signUpViewController.signUpTitle = @"Student Signup";
        self.signUpViewController.signUpType = @"student";
    } else if ([segueID isEqualToString:@"mentorSignup"]) {
        self.signUpViewController = (MTSignUpViewController *)segueDVC;
        self.signUpViewController.signUpTitle = @"Mentor Signup";
        self.signUpViewController.signUpType = @"mentor";
    }
}

- (IBAction)unwindToSignUpLogin:(UIStoryboardSegue *)sender
{
    [self reloadInputViews];
}


#pragma mark - Internet Notifications -
- (void)internetBecameReachable:(NSNotification *)aNotification
{
    [self updateView];
}



@end
