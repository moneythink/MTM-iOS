//
//  MTUserViewController.m
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "MTUserViewController.h"
#import "MTLogInViewController.h"
#import "MTSignUpViewController.h"
#import "MTStudentTabBarViewController.h"

@interface MTUserViewController ()

@property (strong, nonatomic) IBOutlet UIButton *studentSignUpButton;
@property (strong, nonatomic) IBOutlet UIButton *mentorSignUpButton;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;

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

    if ([PFUser currentUser]) {
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
            }
        }];
    } else {
        self.studentSignUpButton.hidden = NO;
        self.mentorSignUpButton.hidden = NO;
        self.loginButton.hidden = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
    [self.view setBackgroundColor:[UIColor primaryGreen]];
    
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueID = [segue identifier];
    
    if ([segueID isEqualToString:@"studentSignUp"]) {
        MTSignUpViewController *signUpViewController = (MTSignUpViewController *)segue.destinationViewController;
        signUpViewController.signUpTitle = @"Student Signup";
        signUpViewController.signUpType = @"student";
    } else if ([segueID isEqualToString:@"mentorSignUp"]) {
        MTSignUpViewController *signUpViewController = (MTSignUpViewController *)segue.destinationViewController;
        signUpViewController.signUpTitle = @"Mentor Signup";
        signUpViewController.signUpType = @"mentor";
    }
}

- (IBAction)unwindToSignUpLogin:(UIStoryboardSegue *)sender
{
    [self reloadInputViews];
}


@end
