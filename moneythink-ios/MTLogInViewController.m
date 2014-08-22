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

//#ifdef DEBUG
//    static BOOL useStage = YES;
//#else
    static BOOL useStage = NO;
//#endif

@interface MTLogInViewController ()

@property (strong, nonatomic) IBOutlet UIView *view;
@property (strong, nonatomic) IBOutlet UIScrollView *viewFields;

@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UITextField *password;

@property (strong, nonatomic) IBOutlet UITextField *error;

@property (strong, nonatomic) IBOutlet UIButton *useStageButton;
//@property (strong, nonatomic) IBOutlet MICheckBox *useStageCheckbox;

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

//    self.useStageCheckbox =[[MICheckBox alloc]initWithFrame:self.useStageButton.frame];
//	[self.useStageCheckbox setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//	[self.useStageCheckbox setTitle:@"" forState:UIControlStateNormal];
//	[self.viewFields addSubview:self.useStageCheckbox];
    
//    self.useStageCheckbox.isChecked = useStage;
    
    self.useStageButton.hidden = YES;
    
    self.view.backgroundColor = [UIColor white];
    
    [[self.loginButton layer] setBorderWidth:1.0f];
    [[self.loginButton layer] setCornerRadius:5.0f];
    [[self.loginButton layer] setBorderColor:[UIColor mutedOrange].CGColor];

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)resetTapped:(id)sender {
    UIAlertView *confirm = [[UIAlertView alloc] initWithTitle:nil message:@"Would you like to receive an email to reset your password?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
    
    [confirm show];
}

- (IBAction)loginTapped:(id)sender {
//    if ([self.useStageCheckbox isChecked]) {
//        NSString *applicationID = @"OFZ4TDvgCYnu40A5bKIui53PwO43Z2x5CgUKJRWz";
//        NSString *clientKey = @"2OBw9Ggbl5p0gJ0o6Y7n8rK7gxhFTGcRQAXH6AuM";
//        
//        [Parse setApplicationId:applicationID
//                      clientKey:clientKey];
//    }

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
            self.error.text = errorString;
            [[[UIAlertView alloc] initWithTitle:@"Login Error" message:self.error.text delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
    }];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: // Cancel
            break;
            
        default: // OK
            [PFUser requestPasswordResetForEmailInBackground:self.email.text block:^(BOOL succeeded, NSError *error) {
                if (!error) {

                } else {

                }
            }];
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
