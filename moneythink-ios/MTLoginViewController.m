//
//  MTLoginViewController.m
//  moneythink-ios
//
//  Created by dsica on 5/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTLoginViewController.h"

@interface MTLoginViewController ()

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

@end

@implementation MTLoginViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {

    }
    return self;
}


#pragma mark - Lifecycle -
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
    
    ((AppDelegate *)[MTUtil getAppDelegate]).userViewController = self.navigationController;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self updateView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetBecameReachable:) name:kInternetDidBecomeReachableNotification object:nil];
    
    [[MTUtil getAppDelegate] setDarkNavBarAppearanceForNavigationBar:self.navigationController.navigationBar];
}

- (void)viewWillDisappear:(BOOL) animated
{
    [super viewWillDisappear:animated];
    
    self.emailTextField.text = @"";
    self.passwordTextField.text = @"";
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[MTUtil getAppDelegate] setWhiteNavBarAppearanceForNavigationBar:self.navigationController.navigationBar];
}


#pragma mark - Private -
- (BOOL)validate
{
    NSString *title = @"Login Error";
    NSString *message = nil;
    if (IsEmpty(self.emailTextField.text)) {
        
        message = @"Email is required";
        if ([UIAlertController class]) {
            UIAlertController *changeSheet = [UIAlertController
                                              alertControllerWithTitle:title
                                              message:message
                                              preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:@"OK"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
                                       }];
            
            [changeSheet addAction:okAction];
            [self presentViewController:changeSheet animated:YES completion:nil];
        } else {
            [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }

        return NO;
    }
    
    if (IsEmpty(self.passwordTextField.text)) {
        message = @"Password is required";
        if ([UIAlertController class]) {
            UIAlertController *changeSheet = [UIAlertController
                                              alertControllerWithTitle:title
                                              message:message
                                              preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:@"OK"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
                                       }];
            
            [changeSheet addAction:okAction];
            [self presentViewController:changeSheet animated:YES completion:nil];
        } else {
            [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }

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
                
                weakSelf.revealViewController.delegate = [MTUtil getAppDelegate];

                [[MTUtil getAppDelegate] configureZendesk];
                
                MTOnboardingController *onboardingController = [[MTOnboardingController alloc] init];
                if (![onboardingController checkForOnboarding]) {
                    id challengesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"challengesViewControllerNav"];
                    [weakSelf.revealViewController setFrontViewController:challengesVC animated:YES];
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
    
    MTMakeWeakSelf();
    [PFUser logInWithUsernameInBackground:self.emailTextField.text password:self.passwordTextField.text block:^(PFUser *user, NSError *error) {
        NSString *errorString = [error userInfo][@"error"];
        
        if (!error) {
            weakSelf.revealViewController.delegate = [MTUtil getAppDelegate];

            [[MTUtil getAppDelegate] configureZendesk];

            // Update for Push Notifications
            [[MTUtil getAppDelegate] updateParseInstallationState];
            
            // Check for custom playlist for this class
            [[MTUtil getAppDelegate] checkForCustomPlaylistContentWithRefresh:NO];
            
            MTOnboardingController *onboardingController = [[MTOnboardingController alloc] init];
            if (![onboardingController checkForOnboarding]) {
                id challengesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"challengesViewControllerNav"];
                [weakSelf.revealViewController setFrontViewController:challengesVC animated:YES];
            }
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Login Error" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
    }];
}


#pragma mark - UIAlertViewDelegate methods -
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Sending Password Reset...";

        MTMakeWeakSelf();
        [self bk_performBlock:^(id obj) {
            NSError *error = nil;
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];

            if (error) {
                NSLog(@"Error resetting password: %@", [error localizedDescription]);
            }
            
            [PFUser requestPasswordResetForEmailInBackground:weakSelf.emailTextField.text block:^(BOOL succeeded, NSError *error) {
                if (succeeded) {
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
                    hud.labelText = @"Reset successfully sent.";
                    hud.mode = MBProgressHUDModeText;
                    [hud hide:YES afterDelay:1.5f];
                }
                else {
                    NSString *title = @"Reset Failed";
                    NSString *detailMessage = [NSString stringWithFormat:@"No account was found with email %@.", weakSelf.emailTextField.text];
                    
                    NSString *generatedError = [[error userInfo] valueForKey:@"error"];
                    if (!IsEmpty(generatedError)) {
                        detailMessage = generatedError;
                    }
                    
                    if ([UIAlertController class]) {
                        UIAlertController *changeSheet = [UIAlertController
                                                          alertControllerWithTitle:title
                                                          message:detailMessage
                                                          preferredStyle:UIAlertControllerStyleAlert];
                        
                        UIAlertAction *okAction = [UIAlertAction
                                                   actionWithTitle:@"OK"
                                                   style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                   }];
                        
                        [changeSheet addAction:okAction];
                        [self presentViewController:changeSheet animated:YES completion:nil];
                    } else {
                        [[[UIAlertView alloc] initWithTitle:title message:detailMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                    }
                }
            }];
            
        } afterDelay:0.35f];
    }
}


#pragma mark - UITextFieldDelegate methods -
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


@end
