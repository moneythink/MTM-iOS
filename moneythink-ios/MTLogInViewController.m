//
//  MTLogInViewController.m
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "MTLogInViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "MTStudentTabBarViewController.h"
#import "MTMentorTabBarViewControlle.h"

@interface MTLogInViewController ()

@property (strong, nonatomic) IBOutlet UIView *view;
@property (strong, nonatomic) IBOutlet UIScrollView *viewFields;

@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UITextField *password;

@property (strong, nonatomic) IBOutlet UIButton *loginButton;

@end

@implementation MTLogInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    [self.email setDelegate:self];
    [self.password setDelegate:self];

    self.view.backgroundColor = [UIColor lightGrey];
    
    [self.loginButton setTitle:@"LOGIN" forState:UIControlStateNormal];
    self.loginButton.layer.cornerRadius = 4.0f;
    [self.loginButton setBackgroundColor:[UIColor mutedOrange]];
    [self.loginButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f];
    label.text = @"Login";
    [label sizeToFit];
    self.navigationItem.titleView = label;
    
    [self textFieldsConfigure];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.email becomeFirstResponder];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)textFieldsConfigure {
    UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                                    self.email.frame.size.height - 1.0f,
                                                                    self.email.frame.size.width,
                                                                    1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    UIView *rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.email.frame.size.width - 1.0f,
                                                                   0.0f,
                                                                   1.0f,
                                                                   self.email.frame.size.height)];
    rightBorder.backgroundColor = [UIColor primaryOrange];
    
    [self.email addSubview:bottomBorder];
    [self.email addSubview:rightBorder];
    [self.email setBackgroundColor:[UIColor white]];
    
    bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                            self.password.frame.size.height - 1.0f,
                                                            self.password.frame.size.width,
                                                            1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.password.frame.size.width - 1.0f,
                                                           0.0f,
                                                           1.0f,
                                                           self.password.frame.size.height)];
    rightBorder.backgroundColor = [UIColor primaryOrange];
    
    [self.password addSubview:bottomBorder];
    [self.password addSubview:rightBorder];
    [self.password setBackgroundColor:[UIColor white]];
}

- (IBAction)resetTapped:(id)sender {
    UIAlertView *confirm = [[UIAlertView alloc] initWithTitle:nil message:@"Would you like to receive an email to reset your password?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    
    [confirm show];
}

- (IBAction)loginTapped:(id)sender {
    PFUser *user = [PFUser user];
    
    user.username = self.email.text;
    user.password = self.password.text;
    
    [PFUser logInWithUsernameInBackground:self.email.text password:self.password.text block:^(PFUser *user, NSError *error) {
        NSString *errorString = [error userInfo][@"error"];

        if (!error) {
            if ([[[PFUser currentUser] valueForKey:@"type"] isEqualToString:@"student"]) {
                [self performSegueWithIdentifier:@"studentLoggedIn" sender:self];
            } else {
                [self performSegueWithIdentifier:@"pushMentorLoggedIn" sender:self];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Login Error" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
    }];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: // Cancel
            break;
            
        default: // OK
            [PFUser requestPasswordResetForEmailInBackground:self.email.text];
            break;
    }
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSInteger nextTag = textField.tag + 1;
    // Try to find next responder
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
    } else {
        // Not found, so remove keyboard.
        [textField resignFirstResponder];
    }
    return NO; // We do not want UITextField to insert line-breaks.
}


@end
