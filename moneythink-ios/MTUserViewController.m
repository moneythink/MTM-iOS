//
//  MTUserViewController.m
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "MTUserViewController.h"

@interface MTUserViewController ()

@property (weak, nonatomic) IBOutlet UIButton *studentSignUpButton;
@property (weak, nonatomic) IBOutlet UIButton *mentorSignUpButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIView *topBackgroundView;
@property (weak, nonatomic) IBOutlet UITextField *emailTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UILabel *passwordLabel;
@property (weak, nonatomic) IBOutlet UIButton *forgotPasswordButton;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *separatorViews;

@property (strong, nonatomic) MTSignUpViewController *signUpViewController;
@property (nonatomic) BOOL showedMessage;

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
    
    self.topBackgroundView.backgroundColor = [UIColor primaryOrange];
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(dismissKeyboard)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    if (IS_RETINA) {
        for (UIView *thisSeparatorView in self.separatorViews) {
            thisSeparatorView.frame = ({
                CGRect newFrame = thisSeparatorView.frame;
                newFrame.size.height = 0.5f;
                newFrame;
            });
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self updateView];
    self.showedMessage = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetBecameReachable:) name:kInternetDidBecomeReachableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
    
    [[MTUtil getAppDelegate] setDefaultNavBarAppearanceForNavigationBar:self.navigationController.navigationBar];
}

- (void)viewWillDisappear:(BOOL) animated
{
    [super viewWillDisappear:animated];
    
    self.emailTextField.text = @"";
    self.passwordTextField.text = @"";
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Private -
- (BOOL)validate
{
    if (IsEmpty(self.emailTextField.text)) {
        [[[UIAlertView alloc] initWithTitle:@"Login Error" message:@"Email is required" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        return NO;
    }
    
    if (IsEmpty(self.passwordTextField.text)) {
        [[[UIAlertView alloc] initWithTitle:@"Login Error" message:@"Password is required" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        return NO;
    }
    
    return YES;
}

- (void)dismissKeyboard
{
    [self.view endEditing:YES];
}

- (void)updateView
{
    if ([PFUser currentUser]) {
        self.view.backgroundColor = [UIColor primaryOrange];
        self.emailLabel.hidden = YES;
        self.passwordLabel.hidden = YES;
        self.studentSignUpButton.hidden = YES;
        self.mentorSignUpButton.hidden = YES;
        self.loginButton.hidden = YES;
        self.forgotPasswordButton.hidden = YES;
        self.emailTextField.hidden = YES;
        self.passwordTextField.hidden = YES;
        
        for (UIView *thisView in self.separatorViews) {
            thisView.hidden = YES;
        }

        PFUser *user = [PFUser currentUser];
        
        MTMakeWeakSelf();
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = @"Loading...";
        [PFCloud callFunctionInBackground:@"userLoggedIn" withParameters:@{@"user_id": [user objectId]} block:^(id object, NSError *error) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            if (!error) {
                if ([[[PFUser currentUser] valueForKey:@"type"] isEqualToString:@"student"]) {
                    [weakSelf performSegueWithIdentifier:@"studentLoginSegue" sender:weakSelf];
                } else {
                    [weakSelf performSegueWithIdentifier:@"mentorLoginSegue" sender:weakSelf];
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
        self.view.backgroundColor = [UIColor whiteColor];
        self.emailLabel.hidden = NO;
        self.passwordLabel.hidden = NO;
        self.studentSignUpButton.hidden = NO;
        self.mentorSignUpButton.hidden = NO;
        self.loginButton.hidden = NO;
        self.forgotPasswordButton.hidden = NO;
        self.emailTextField.hidden = NO;
        self.passwordTextField.hidden = NO;
        
        for (UIView *thisView in self.separatorViews) {
            thisView.hidden = NO;
        }
        
        [self.studentSignUpButton setTitle:@"Sign Up as Student" forState:UIControlStateNormal];
        [self.mentorSignUpButton setTitle:@"Sign Up as Mentor" forState:UIControlStateNormal];
        [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
        
        CGFloat radius = 5.0f;
        
        self.studentSignUpButton.layer.cornerRadius = radius;
        self.mentorSignUpButton.layer.cornerRadius = radius;
        self.loginButton.layer.cornerRadius = radius;
        
        self.loginButton.layer.masksToBounds = YES;
        self.studentSignUpButton.layer.masksToBounds = YES;
        self.mentorSignUpButton.layer.masksToBounds = YES;
        
        [self.loginButton setBackgroundImage:[UIImage imageWithColor:[UIColor primaryOrange] size:self.loginButton.frame.size] forState:UIControlStateNormal];
        [self.loginButton setBackgroundImage:[UIImage imageWithColor:[UIColor primaryOrangeDark] size:self.loginButton.frame.size] forState:UIControlStateHighlighted];
        [self.studentSignUpButton setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:self.studentSignUpButton.frame.size] forState:UIControlStateNormal];
        [self.studentSignUpButton setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreenDark] size:self.studentSignUpButton.frame.size] forState:UIControlStateHighlighted];
        [self.mentorSignUpButton setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:self.mentorSignUpButton.frame.size] forState:UIControlStateNormal];
        [self.mentorSignUpButton setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreenDark] size:self.mentorSignUpButton.frame.size] forState:UIControlStateHighlighted];

        [self.loginButton setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [self.loginButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [self.studentSignUpButton setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [self.studentSignUpButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [self.mentorSignUpButton setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [self.mentorSignUpButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [self.forgotPasswordButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueID = [segue identifier];
    id segueDVC = [segue destinationViewController];
    
    if ([segueID isEqualToString:@"studentSignup"]) {
        [[MTUtil getAppDelegate] setWhiteNavBarAppearanceForNavigationBar:self.navigationController.navigationBar];

        self.signUpViewController = (MTSignUpViewController *)segueDVC;
        self.signUpViewController.signUpTitle = @"Student Sign Up";
        self.signUpViewController.signUpType = @"student";
    } else if ([segueID isEqualToString:@"mentorSignup"]) {
        [[MTUtil getAppDelegate] setWhiteNavBarAppearanceForNavigationBar:self.navigationController.navigationBar];

        self.signUpViewController = (MTSignUpViewController *)segueDVC;
        self.signUpViewController.signUpTitle = @"Mentor Sign Up";
        self.signUpViewController.signUpType = @"mentor";
    }
}

- (IBAction)unwindToSignUpLogin:(UIStoryboardSegue *)sender
{
    [self reloadInputViews];
}


#pragma mark - Login Methods -
- (IBAction)resetTapped:(id)sender
{
    if (IsEmpty(self.emailTextField.text)) {
        [[[UIAlertView alloc] initWithTitle:@"Reset Error" message:@"Email is required" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        return;
    }

    UIAlertView *confirm = [[UIAlertView alloc] initWithTitle:nil
                                                      message:@"Would you like to receive an email to reset your password?"
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"OK", nil];
    [confirm show];
}

- (IBAction)loginTapped:(id)sender
{
    if (![self validate]) {
        return;
    }
    
    PFUser *user = [PFUser user];
    
    user.username = self.emailTextField.text;
    user.password = self.passwordTextField.text;
    
    [PFUser logInWithUsernameInBackground:self.emailTextField.text password:self.passwordTextField.text block:^(PFUser *user, NSError *error) {
        NSString *errorString = [error userInfo][@"error"];
        
        if (!error) {
            // Update for Push Notifications
            [[MTUtil getAppDelegate] updateParseInstallationState];

            if ([[[PFUser currentUser] valueForKey:@"type"] isEqualToString:@"student"]) {
                [self performSegueWithIdentifier:@"studentLoginSegue" sender:self];
            } else {
                [self performSegueWithIdentifier:@"mentorLoginSegue" sender:self];
            }
        } else {
            [[[UIAlertView alloc] initWithTitle:@"Login Error" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
    }];
}


#pragma mark - UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        [PFUser requestPasswordResetForEmailInBackground:self.emailTextField.text];
    }
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
        
        if (textField == self.passwordTextField) {
            // submit login
            [self loginTapped:self.loginButton];
        }
    }
    return NO; // We do not want UITextField to insert line-breaks.
}


#pragma mark - Internet Notifications -
- (void)internetBecameReachable:(NSNotification *)aNotification
{
    [self updateView];
}


#pragma mark - Keyboard methods -
- (void)keyboardWillShow:(NSNotification *)nsNotification
{
    if (!self.showedMessage) {
        self.showedMessage = YES;
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.detailsLabelText = @"Swipe down or tap MoneyThink logo to dismiss keyboard.";
        hud.mode = MBProgressHUDModeText;
        hud.yOffset = 30.0f;
        
        [self bk_performBlock:^(id obj) {
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        } afterDelay:2.0f];
    }
}

- (void)keyboardWillDismiss:(NSNotification *)notification
{
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}


@end
