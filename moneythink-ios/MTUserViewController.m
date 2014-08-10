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

@interface MTUserViewController ()

@property (strong, nonatomic) IBOutlet UIButton *studentSignUpButton;
@property (strong, nonatomic) IBOutlet UIButton *mentorSignUpButton;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;

@end

@implementation MTUserViewController

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    [self.navigationController setNavigationBarHidden:YES animated:YES];
//    self.navigationController.navigationItem.hidesBackButton = YES;
    self.navigationItem.hidesBackButton = YES;
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

}


@end
