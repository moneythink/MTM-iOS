//
//  MTLoginViewController.m
//  moneythink-ios
//
//  Created by dsica on 5/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTLoginViewController.h"
#import "MTNotificationViewController.h"

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
@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *separatorViews;

@property (nonatomic, strong) MTSignUpViewController *signUpViewController;
@property (nonatomic, strong) UIAlertView *forcedUpdateAlert;
@property (nonatomic, strong) id forcedUpdateAlertController;
@property (nonatomic) BOOL presentingForcedUpdateAlert;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

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
    if ([((AppDelegate *)[MTUtil getAppDelegate]) shouldForceUpdate]) {
        if (self.presentingForcedUpdateAlert) {
            return;
        }
        
        self.presentingForcedUpdateAlert = YES;
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
        
        NSString *title = @"Update Required";
        NSString *message = @"You have an unsupported version installed. Please update in the App Store to continue using Moneythink.";
        if ([UIAlertController class]) {
            UIAlertController *updateAlert = [UIAlertController
                                              alertControllerWithTitle:title
                                              message:message
                                              preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *openAction = [UIAlertAction
                                       actionWithTitle:@"Open App Store"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
                                           self.presentingForcedUpdateAlert = NO;
                                           NSString *iTunesLink = @"https://itunes.apple.com/us/app/moneythink/id907176836?mt=8";
                                           [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
                                       }];
        
            [updateAlert addAction:openAction];
            self.forcedUpdateAlertController = updateAlert;
            [self presentViewController:updateAlert animated:YES completion:nil];
        } else {
            self.forcedUpdateAlert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:@"Open App Store", nil];
            [self.forcedUpdateAlert show];
        }
    }
    else if ([MTUser isUserLoggedIn]) {
        [[MTUtil getAppDelegate] configureZendesk];
        
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
        
        // Update Notification count for this user.
        [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];

        MTOnboardingController *onboardingController = [[MTOnboardingController alloc] init];
        if (![onboardingController checkForOnboarding]) {
            
            // TODO: change back
            //            id challengesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"challengesViewControllerNav"];
            id challengesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"supportVCNav"];
            [self.revealViewController setFrontViewController:challengesVC animated:YES];
        }
    }
    else {
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

- (void)shouldUpdateView
{
    [self updateView];
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
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Logging In...";

    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] authenticateForUsername:self.emailTextField.text withPassword:self.passwordTextField.text success:^(id responseData) {
        
        [[MTNetworkManager sharedMTNetworkManager] getClassesWithSignupCode:@"1234code" success:^(id responseData) {
            //
        } failure:^(NSError *error) {
            //
        }];
        
        // Get this user
        [[MTUtil getAppDelegate] configureZendesk];
        
        // Update for Push Notifications
//        [[MTUtil getAppDelegate] updateParseInstallationState];
        
        // Check for custom playlist for this class
//        [[MTUtil getAppDelegate] checkForCustomPlaylistContentWithRefresh:NO];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            
            // Check for custom playlist for this class
//            [[MTUtil getAppDelegate] checkForCustomPlaylistContentWithRefresh:NO];
            
            // Update Notification count for this user.
//            [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
            
            MTOnboardingController *onboardingController = [[MTOnboardingController alloc] init];
            if (![onboardingController checkForOnboarding]) {
                
                // TODO: change back
                // id challengesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"challengesViewControllerNav"];
                id challengesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"supportVCNav"];
                [weakSelf.revealViewController setFrontViewController:challengesVC animated:YES];
            }
        });

    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            [[[UIAlertView alloc] initWithTitle:@"Login Error" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        });

    }];
}


#pragma mark - UIAlertViewDelegate methods -
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.forcedUpdateAlert) {
        self.presentingForcedUpdateAlert = NO;
        if (buttonIndex != alertView.cancelButtonIndex) {
            NSString *iTunesLink = @"https://itunes.apple.com/us/app/moneythink/id907176836?mt=8";
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
        }
        self.forcedUpdateAlert = nil;
    }
    else if (buttonIndex != alertView.cancelButtonIndex) {
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


#pragma mark - Notifications -
- (void)internetBecameReachable:(NSNotification *)aNotification
{
    [self updateView];
}

- (void)didEnterBackground:(NSNotification *)notification
{
    if (self.forcedUpdateAlert) {
        [self.forcedUpdateAlert dismissWithClickedButtonIndex:self.forcedUpdateAlert.cancelButtonIndex animated:NO];
        self.forcedUpdateAlert = nil;
    }
    else if (self.forcedUpdateAlertController) {
        UIAlertController *alertController = (UIAlertController *)self.forcedUpdateAlertController;
        [alertController dismissViewControllerAnimated:NO completion:nil];
        self.forcedUpdateAlertController = nil;
    }
    self.presentingForcedUpdateAlert = NO;
}

- (void)willEnterForeground:(NSNotification *)notification
{
    [self updateView];
}


@end
