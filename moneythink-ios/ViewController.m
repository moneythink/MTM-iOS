//
//  ViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/10/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "ViewController.h"
#import <Parse/Parse.h>
#import "UIColor+Palette.h"
#import "ChallengePost.h"

@interface ViewController ()

@property (nonatomic, strong) UIImageView *fieldsBackground;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ChallengePost *challengePost = [[ChallengePost alloc] init];
    
    [self.view setBackgroundColor:[UIColor primaryGreen]];
    
//    [self.labelUsername setBackgroundColor:[UIColor mutedOrange]];
//    [self.labelVersion setBackgroundColor:[UIColor primaryGreen]];
//    [self.labelStatus setBackgroundColor:[UIColor mutedGreen]];
    
    [self.buttonSignupStudent setBackgroundColor:[UIColor mutedOrange]];
    self.buttonSignupStudent.layer.cornerRadius = 5.0f;
    self.buttonSignupStudent.clipsToBounds = YES;
    
    [self.buttonSignupMentor setBackgroundColor:[UIColor mutedGreen]];
    self.buttonSignupMentor.layer.cornerRadius = 5.0f;
    self.buttonSignupMentor.clipsToBounds = YES;

    [self.buttonLogin setBackgroundColor:[UIColor primaryGreen]];
    
    [self.buttonLogout setBackgroundColor:[UIColor redOrange]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
//    if (![PFUser currentUser]) { // No user logged in
//                                 // Create the log in view controller
//        PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
//        [logInViewController setDelegate:self]; // Set ourselves as the delegate
//        
//            // Create the sign up view controller
//        PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
//        [signUpViewController setDelegate:self]; // Set ourselves as the delegate
//        
//            // Assign our sign up controller to be displayed from the login controller
//        [logInViewController setSignUpController:signUpViewController];
//        
//        logInViewController.fields = PFLogInFieldsDefault;
//        
//        
//            // Present the log in view controller
//        [self presentViewController:logInViewController animated:YES completion:NULL];
//    } else {
//        UIAlertView *logout = [[UIAlertView alloc] initWithTitle:@"logout" message:@"logout" delegate:self cancelButtonTitle:@"logout" otherButtonTitles:nil, nil];
//        [logout show];
//        [PFUser logOut];
//    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if ([PFUser currentUser]) {
//        self.labelStatus.text = [NSString stringWithFormat:NSLocalizedString(@"Welcome %@!", nil), [[PFUser currentUser] username]];
//        self.buttonLogin.hidden = YES;
    } else {
//        self.labelStatus.text = NSLocalizedString(@"Not logged in", nil);
//        self.buttonLogin.hidden = NO;
    }
    
    
    
//    self.buttonLogout.hidden = !self.buttonLogin.hidden;
    
//    self.labelUsername.text = [[PFUser currentUser] username];
//    self.labelVersion.text = [[[PFUser currentUser] allKeys] description];
//    NSArray *allKeys = [[PFUser currentUser] allKeys];
    
//    NSString *userStrings = @"";
    
//    for (NSString *key in allKeys) {
//        NSLog(@"%@", key);
//        userStrings = [NSString stringWithFormat:@"%@%@ : ", userStrings, key];
//        userStrings = [NSString stringWithFormat:@"%@%@\r", userStrings, [[PFUser currentUser] valueForKeyPath:key]];
//    }
//    self.labelVersion.text = userStrings;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
        // Set frame for elements
//    [self.logInView.dismissButton setFrame:CGRectMake(10.0f, 10.0f, 87.5f, 45.5f)];
//    [self.logInView.logo setFrame:CGRectMake(66.5f, 70.0f, 187.0f, 58.5f)];
//    [self.logInView.facebookButton setFrame:CGRectMake(35.0f, 287.0f, 120.0f, 40.0f)];
//    [self.logInView.twitterButton setFrame:CGRectMake(35.0f+130.0f, 287.0f, 120.0f, 40.0f)];
//    [self.logInView.signUpButton setFrame:CGRectMake(35.0f, 385.0f, 250.0f, 40.0f)];
//    [self.logInView.usernameField setFrame:CGRectMake(35.0f, 145.0f, 250.0f, 50.0f)];
//    [self.logInView.passwordField setFrame:CGRectMake(35.0f, 195.0f, 250.0f, 50.0f)];
//    [self.fieldsBackground setFrame:CGRectMake(35.0f, 145.0f, 250.0f, 100.0f)];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma button actions
- (IBAction)tapStudentSignupButton:(id)sender {
    [self tappedStudentSignupButton:sender];
}

- (IBAction)tapMentorSignupButton:(id)sender {
    [self tappedMentorSignupButton:sender];
}

- (IBAction)tapLoginButton:(id)sender {
    [self tappedLoginButton:sender];
}

- (IBAction)tapLogoutButton:(id)sender {
    [self tappedLogoutButton:sender];
}


- (void)tappedStudentSignupButton:(id)sender {
        // Create the sign up view controller
    PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
    [signUpViewController setDelegate:self]; // Set ourselves as the delegate
    
    signUpViewController.fields = PFSignUpFieldsUsernameAndPassword | PFSignUpFieldsDismissButton | PFSignUpFieldsAdditional;
    signUpViewController.signUpView.additionalField.placeholder = @"Student";
    signUpViewController.signUpView.additionalField.enabled = NO;
    
    signUpViewController.signUpView.backgroundColor = [UIColor primaryGreen];
    [signUpViewController.signUpView.usernameField setBackgroundColor:[UIColor mutedOrange]];
    [signUpViewController.signUpView.passwordField setBackgroundColor:[UIColor mutedGreen]];
    signUpViewController.signUpView.logo = nil;
    
        // Present the sign up view controller
    [self presentViewController:signUpViewController animated:YES completion:NULL];
}

- (void)tappedMentorSignupButton:(id)sender {
        // Create the sign up view controller
    PFSignUpViewController *signUpViewController = [[PFSignUpViewController alloc] init];
    [signUpViewController setDelegate:self]; // Set ourselves as the delegate
    
    signUpViewController.fields = PFSignUpFieldsUsernameAndPassword | PFSignUpFieldsDismissButton | PFSignUpFieldsAdditional;
    signUpViewController.signUpView.additionalField.placeholder = @"Mentor";
    signUpViewController.signUpView.additionalField.enabled = NO;
    
    signUpViewController.signUpView.backgroundColor = [UIColor primaryGreen];

        // Present the sign up view controller
    [self presentViewController:signUpViewController animated:YES completion:NULL];
}

- (void)tappedLoginButton:(id)sender {
    PFLogInViewController *logInViewController = [[PFLogInViewController alloc] init];
    [logInViewController setDelegate:self]; // Set ourselves as the delegate
    
    logInViewController.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsPasswordForgotten | PFLogInFieldsDismissButton;
    
    logInViewController.logInView.backgroundColor = [UIColor primaryGreen];

        // Present the log in view controller
    [self presentViewController:logInViewController animated:YES completion:NULL];
}

- (void)tappedLogoutButton:(id)sender {
    [PFUser logOut];
    
    [self.view setNeedsLayout];
}


#pragma - PFLogInViewControllerDelegate Delegate Methods

-(BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password
{
    return YES;
}

-(void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error
{
    NSDictionary *userInfo = error.userInfo;
    NSLog(@"didFailToLogInWithError");
    NSLog(@"code - %@", [userInfo valueForKey:@"code"]);
    NSLog(@"error - %@", [userInfo valueForKey:@"error"]);
    UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Login failed" message:[userInfo description] delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
    [errorAlert show];

//    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user
{
    NSLog(@"didLogInUser");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

-(void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController
{
    NSLog(@"logInViewControllerDidCancelLogIn");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma - PFSignUpViewControllerDelegate Delegate Methods

- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info
{
    return YES;
}

- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error
{
    NSLog(@"didFailToSignUpWithError");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user
{
    NSLog(@"didSignUpUser");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController
{
    NSLog(@"signUpViewControllerDidCancelSignUp");
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
