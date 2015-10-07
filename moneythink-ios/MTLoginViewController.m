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
    
    // GA Track - 'Login'
    [MTUtil GATrackScreen:@"Login"];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self updateView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetBecameReachable:) name:kInternetDidBecomeReachableNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    [[MTUtil getAppDelegate] setDarkNavBarAppearanceForNavigationBar:self.navigationController.navigationBar];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Check for logout reason message
    AppDelegate *appDelegate = [MTUtil getAppDelegate];
    if (appDelegate.logoutReason && [appDelegate.logoutReason lengthOfBytesUsingEncoding:NSUTF8StringEncoding] > 0) {
        [[[UIAlertView alloc] initWithTitle:@"Logged Out" message:appDelegate.logoutReason delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [appDelegate clearLogoutReason];
    }
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
        [self displayForceUpdate];
    }
    else if ([MTUser isUserLoggedIn]) {

        [MTUtil userDidLogin:[MTUser currentUser]];

        [[MTUtil getAppDelegate] configureZendesk];
        if ([MTUtil shouldRefreshForKey:kRefreshForMeUser]) {
            [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
                [MTUtil setRefreshedForKey:kRefreshForMeUser];
            } failure:^(NSError *error) {
                //
            }];
        }
        
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
            id challengesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"challengesViewControllerNav"];
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
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kShouldDisplayAPIMigrationAlertKey]) {
            [self displayAPIMigrationAlert];
        }
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

- (void)displayAPIMigrationAlert
{
    // This is an upgrade installation from 2.0.x to 2.1 (new API sans Parse)
    //  Display alert instructions to user
    NSString *title = @"Moneythink Alert";
    NSString *messageToDisplay = @"Moneythink has been updated. As part of this update, we need to log you out. Don't worry, none of your data will be lost. Please log in again.";
    
    if ([UIAlertController class]) {
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:title
                                              message:messageToDisplay
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *close = [UIAlertAction
                                actionWithTitle:@"Close"
                                style:UIAlertActionStyleCancel
                                handler:^(UIAlertAction *action) {
                                    [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
                                }];
        
        [alertController addAction:close];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        [UIAlertView bk_showAlertViewWithTitle:title message:messageToDisplay cancelButtonTitle:@"Close" otherButtonTitles:nil handler:nil];
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShouldDisplayAPIMigrationAlertKey];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDisplayedAPIMigrationAlertKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)displayForceUpdate
{
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


#pragma mark - Login Methods -
- (IBAction)helpTapped:(id)sender
{
    NSArray *buttons = [[self class] helpActionSheetButtons];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Help and Support" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:buttons[0], buttons[1], nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSArray *actionButtons = [[self class] helpActionSheetButtons];
    if (buttonIndex == actionSheet.cancelButtonIndex || buttonIndex > ([actionButtons count] - 1)) {
        return;
    }
    NSString *buttonTitle = actionButtons[buttonIndex];

    if ([buttonTitle isEqualToString:@"Forgotten Password"]) {
        [self resetTapped:nil];
        return;
    }
    
    if ([buttonTitle isEqualToString:@"Contact Support"]) {
        [ZDKRequests showRequestCreationWithNavController:self.navigationController];
        return;
    }
}

- (IBAction)resetTapped:(id)sender
{
    NSString *email = self.emailTextField.text;
    UIAlertView *confirm = [[UIAlertView alloc] initWithTitle:@"Password Reset" message:@"Enter your email:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Reset", nil];
    confirm.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *emailTextField = [confirm textFieldAtIndex:0];
    if (emailTextField != nil) {
        emailTextField.text = email;
    }
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
        
        [MTUtil userDidLogin:[MTUser currentUser]];

        [[MTUtil getAppDelegate] configureZendesk];
        
        // Update for Push Notifications
        [[MTUtil getAppDelegate] updatePushMessagingInfo];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            
            // Update Notification count for this user.
            [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
            
            MTOnboardingController *onboardingController = [[MTOnboardingController alloc] init];
            if (![onboardingController checkForOnboarding]) {
                id challengesVC = [self.storyboard instantiateViewControllerWithIdentifier:@"challengesViewControllerNav"];
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
    else if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    else if ([alertView.title isEqualToString:@"Enter Token"]) {
        NSString *token = [alertView textFieldAtIndex:0].text;
        NSString *newPassword = [alertView textFieldAtIndex:1].text;
        
        if (IsEmpty(token) || IsEmpty(newPassword)) {
            NSString *title = IsEmpty(token) ? @"Token Required" : @"Password Required";
            if ([UIAlertController class]) {
                UIAlertController *changeSheet = [UIAlertController
                                                  alertControllerWithTitle:title
                                                  message:nil
                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                UIAlertAction *okAction = [UIAlertAction
                                           actionWithTitle:@"OK"
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action) {
                                           }];
                
                [changeSheet addAction:okAction];
                [self presentViewController:changeSheet animated:YES completion:nil];
            } else {
                [[[UIAlertView alloc] initWithTitle:title message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }

            return;
        }
        
        [[MTNetworkManager sharedMTNetworkManager] sendNewPassword:newPassword withToken:token success:^(id responseData) {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
            hud.labelText = @"Password Updated";
            hud.mode = MBProgressHUDModeText;
            [hud hide:YES afterDelay:1.5f];
        } failure:^(NSError *error) {
            NSString *title = @"Password Change Failed";
            NSString *detailMessage = [error mtErrorDescription];
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
        }];
    }
    else if ([alertView.title isEqualToString:@"Password Reset"]) {
        
        if (buttonIndex == 1) {
            // Request Email
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
            hud.labelText = @"Requesting Email...";
            
            MTMakeWeakSelf();
            [self bk_performBlock:^(id obj) {
                [[MTNetworkManager sharedMTNetworkManager] requestPasswordResetEmailForEmail:weakSelf.emailTextField.text success:^(id responseData) {
                    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
                    hud.labelText = @"Email Sent";
                    hud.mode = MBProgressHUDModeText;
                    [hud hide:YES afterDelay:1.5f];
                } failure:^(NSError *error) {
                    NSString *title = @"Email Request Failed";
                    NSString *detailMessage = [error firstValidationMessage];
                    
                    if ([error mtErrorCode] == 404 || [error mtErrorCode] == 422) {
                        detailMessage = [error mtErrorDetail];
                    }
                    else if (!detailMessage) {
                        detailMessage = [error mtErrorDescription];
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
                }];
                
            } afterDelay:0.35f];

        }
        else if (buttonIndex == 2) {
            // Enter Token
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enter Token" message:@"Enter the token received in email and your new password." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Send", nil];
            alert.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
            [alert textFieldAtIndex:0].placeholder = @"Email Token";
            [alert textFieldAtIndex:1].placeholder = @"New Password";
            [alert show];
        }
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

#pragma mark - Constants
+ (NSArray *)helpActionSheetButtons {
    return @[@"Forgotten Password", @"Contact Support"];
}

@end
