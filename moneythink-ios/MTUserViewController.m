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

@end

@implementation MTUserViewController

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if ([PFUser currentUser]) {
        if ([[[PFUser currentUser] valueForKey:@"type"] isEqualToString:@"student"]) {
            [self performSegueWithIdentifier:@"studentMain" sender:self];
        } else {
            [self performSegueWithIdentifier:@"challengesView" sender:self];
        }
    } else {
//        [self performSegueWithIdentifier:@"mtUserViewController" sender:self];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.hidesBackButton = YES;

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

    self.navigationItem.hidesBackButton = YES;
    self.cancelButton.hidden = YES;
    
    UIImage *logoImage = [UIImage imageNamed:@"logo_actionbar_medium"];
    UIBarButtonItem *barButtonLogo = [[UIBarButtonItem alloc] initWithImage:logoImage style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.leftBarButtonItem = barButtonLogo;
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
    
    MTSignUpViewController *signUpViewController = (MTSignUpViewController *)segue.destinationViewController;
    
    if ([segueID isEqualToString:@"studentSignUp"]) {
        signUpViewController.signUpTitle = @"Student Signup";
        signUpViewController.signUpType = @"student";
    } else if ([segueID isEqualToString:@"mentorSignUp"]) {
        signUpViewController.signUpTitle = @"Mentor Signup";
        signUpViewController.signUpType = @"mentor";
    } else {

    }
}

- (IBAction)unwindToSignUpLogin:(UIStoryboardSegue *)sender
{

}

- (IBAction)studentSignUpTapped:(id)sender
{
    
}

- (IBAction)mentorSignUpTapped:(id)sender
{
    
}

- (IBAction)loginTapped:(id)sender
{
    
}



@end
