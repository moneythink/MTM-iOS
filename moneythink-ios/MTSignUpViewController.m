//
//  MTSignUpViewController.m
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "MTSignUpViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+Palette.h"
#import "MTStudentTabBarViewController.h"
#import "MTMentorTabBarViewControlle.h"
#import "MTAddClassViewController.h"
#import "MTAddSchoolViewController.h"

@interface MTSignUpViewController ()

@property (weak, nonatomic) IBOutlet UIView *view;
@property (weak, nonatomic) IBOutlet UITextField *firstName;
@property (weak, nonatomic) IBOutlet UITextField *lastName;
@property (weak, nonatomic) IBOutlet UITextField *email;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *registrationCode;
@property (weak, nonatomic) IBOutlet UITextField *error;
@property (weak, nonatomic) IBOutlet UIButton *agreeButton;
@property (weak, nonatomic) IBOutlet UIButton *mentorAgreeButton;
@property (weak, nonatomic) IBOutlet UIButton *addSchoolButton;
@property (weak, nonatomic) IBOutlet UITextField *schoolName;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *addClassButton;
@property (weak, nonatomic) IBOutlet UITextField *className;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIButton *termsButton;
@property (weak, nonatomic) IBOutlet UIButton *mentorTermsButton;

@property (strong, nonatomic) IBOutlet MICheckBox *agreeCheckbox;
@property (strong, nonatomic) IBOutlet MICheckBox *mentorAgreeCheckbox;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *separatorViews;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceConstraint;

@property (nonatomic) BOOL schoolIsNew;
@property (nonatomic) BOOL classIsNew;
@property (nonatomic) BOOL reachable;
@property (strong, nonatomic) NSArray *schools;
@property (strong, nonatomic) PFSchools *school;
@property (strong, nonatomic) UIActionSheet *schoolSheet;
@property (strong, nonatomic) NSArray *classes;
@property (strong, nonatomic) PFClasses *userClass;
@property (strong, nonatomic) UIActionSheet *classSheet;
@property (strong, nonatomic) NSString *confirmationString;
@property (nonatomic) BOOL keyboardShowing;

@end

@implementation MTSignUpViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.confirmationString = @"✓ ";
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f];
    label.textColor = [UIColor blackColor];
    label.text = self.signUpTitle;
    [label sizeToFit];
    self.navigationItem.titleView = label;
    
    self.agreeCheckbox.uncheckedImage = [UIImage imageNamed:@"check-unactive"];
    self.agreeCheckbox.checkedImage = [UIImage imageNamed:@"check-active"];
    self.agreeCheckbox.isChecked = NO;
    
    self.agreeButton.hidden = YES;
    
    self.mentorAgreeCheckbox.uncheckedImage = [UIImage imageNamed:@"check-unactive"];
    self.mentorAgreeCheckbox.checkedImage = [UIImage imageNamed:@"check-active"];
    self.mentorAgreeCheckbox.isChecked = NO;
    
    self.mentorAgreeButton.hidden = YES;
    
    self.signUpButton.layer.cornerRadius = 5.0f;
    self.signUpButton.layer.masksToBounds = YES;
    [self.signUpButton setBackgroundImage:[UIImage imageWithColor:[UIColor primaryOrange] size:self.signUpButton.frame.size] forState:UIControlStateNormal];
    [self.signUpButton setBackgroundImage:[UIImage imageWithColor:[UIColor primaryOrangeDark] size:self.signUpButton.frame.size] forState:UIControlStateHighlighted];
    [self.signUpButton setTitleColor:[UIColor white] forState:UIControlStateNormal];
    [self.signUpButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];

    [self.termsButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
    [self.mentorTermsButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    Reachability * reach = [Reachability reachabilityWithHostname:@"www.parse.com"];
    
    reach.reachableBlock = ^(Reachability * reachability) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.reachable = YES;
        });
    };

    reach.unreachableBlock = ^(Reachability * reachability) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.reachable = NO;
        });
    };
    
    [reach startNotifier];
    
    MTMakeWeakSelf();
    UISwipeGestureRecognizer *swipeUp = [UISwipeGestureRecognizer bk_recognizerWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        [weakSelf.view endEditing:YES];
        if (!weakSelf.keyboardShowing) {
            [weakSelf resetLayout];
        }
    }];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.view addGestureRecognizer:swipeUp];
    
    UISwipeGestureRecognizer *swipeDown = [UISwipeGestureRecognizer bk_recognizerWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        [weakSelf.view endEditing:YES];
        if (!weakSelf.keyboardShowing) {
            [weakSelf resetLayout];
        }
    }];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
    
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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - IBActions
- (IBAction)schoolNameButton:(id)sender
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Loading Schools...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        PFQuery *querySchools = [PFQuery queryWithClassName:[PFSchools parseClassName]];
        querySchools.cachePolicy = kPFCachePolicyNetworkElseCache;
        
        [querySchools findObjectsInBackgroundWithTarget:weakSelf selector:@selector(schoolsSheet:error:)];
    } afterDelay:0.35f];
}

- (void)schoolsSheet:(NSArray *)objects error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });

    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (id object in objects) {
        [names addObject:object[@"name"]];
    }
    
    NSArray *sortedNames = [names sortedArrayUsingSelector:
                            @selector(localizedCaseInsensitiveCompare:)];
    
    NSMutableArray *schoolNames = [NSMutableArray arrayWithCapacity:[sortedNames count]];
    for (NSString *thisSchoolName in sortedNames) {
        NSString *name = thisSchoolName;
        if ([self.schoolName.text isEqualToString:thisSchoolName]) {
            name = [NSString stringWithFormat:@"%@%@", self.confirmationString, thisSchoolName];
        }
        [schoolNames addObject:name];
    }
    
    [self bk_performBlock:^(id obj) {
        if ([UIAlertController class]) {
            UIAlertController *schoolSheet = [UIAlertController
                                              alertControllerWithTitle:@""
                                              message:@"Choose School"
                                              preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction *cancel = [UIAlertAction
                                     actionWithTitle:@"Cancel"
                                     style:UIAlertActionStyleCancel
                                     handler:^(UIAlertAction *action) {
                                         self.schoolIsNew = NO;
                                     }];
            
            UIAlertAction *destruct = [UIAlertAction
                                       actionWithTitle:@"New school"
                                       style:UIAlertActionStyleDestructive
                                       handler:^(UIAlertAction *action) {
                                           self.schoolIsNew = YES;
                                           [self performSegueWithIdentifier:@"addSchool" sender:self];
                                       }];
            
            UIAlertAction *schoolName;
            
            [schoolSheet addAction:destruct];
            
            MTMakeWeakSelf();
            for (NSInteger buttonItem = 0; buttonItem < schoolNames.count; buttonItem++) {
                schoolName = [UIAlertAction
                              actionWithTitle:schoolNames[buttonItem]
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *action) {
                                  weakSelf.schoolIsNew = NO;
                                  weakSelf.schoolName.text = [weakSelf stringWithoutConfirmation:schoolNames[buttonItem]];
                                  weakSelf.className.text = @"";
                              }];
                [schoolSheet addAction:schoolName];
            }
            
            [schoolSheet addAction:cancel];
            
            [self presentViewController:schoolSheet animated:YES completion:nil];
        } else {
            UIActionSheet *schoolSheet = [[UIActionSheet alloc]
                                          initWithTitle:@"Choose School"
                                          delegate:self
                                          cancelButtonTitle:nil
                                          destructiveButtonTitle:@"New school"
                                          otherButtonTitles:nil, nil];
            
            for (NSInteger buttonItem = 0; buttonItem < schoolNames.count; buttonItem++) {
                [schoolSheet addButtonWithTitle:schoolNames[buttonItem]];
            }
            
            [schoolSheet addButtonWithTitle:@"Cancel"];
            schoolSheet.cancelButtonIndex = schoolNames.count + 1;
            
            UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
            if ([window.subviews containsObject:self.view]) {
                [schoolSheet showInView:self.view];
            } else {
                [schoolSheet showInView:window];
            }
        }
 
    } afterDelay:0.35f];
}

- (IBAction)classNameButton:(id)sender
{
    if ([self.schoolName.text isEqualToString:@""]) {
        UIAlertView *chooseSchoolAlert = [[UIAlertView alloc] initWithTitle:@"No school selected" message:@"Choose or add a school before selecting a class." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [chooseSchoolAlert show];
    } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Loading Classes...";
        hud.dimBackground = YES;
        
        MTMakeWeakSelf();
        [self bk_performBlock:^(id obj) {
            NSPredicate *classesForSchool = [NSPredicate predicateWithFormat:@"school = %@", weakSelf.schoolName.text];
            PFQuery *querySchools = [PFQuery queryWithClassName:[PFClasses parseClassName] predicate:classesForSchool];
            querySchools.cachePolicy = kPFCachePolicyNetworkElseCache;
            
            [querySchools findObjectsInBackgroundWithTarget:weakSelf selector:@selector(classesSheet:error:)];
        } afterDelay:0.35f];
    }
}

- (void)classesSheet:(NSArray *)objects error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
    });

    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (id object in objects) {
        [names addObject:object[@"name"]];
    }
    
    NSArray *sortedNames = [names sortedArrayUsingSelector:
                            @selector(localizedCaseInsensitiveCompare:)];
    
    NSMutableArray *classNames = [NSMutableArray arrayWithCapacity:[sortedNames count]];
    for (NSString *thisClassName in sortedNames) {
        NSString *name = thisClassName;
        if ([self.className.text isEqualToString:thisClassName]) {
            name = [NSString stringWithFormat:@"%@%@", self.confirmationString, thisClassName];
        }
        [classNames addObject:name];
    }
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        if ([UIAlertController class]) {
            UIAlertController *classSheet = [UIAlertController
                                             alertControllerWithTitle:@""
                                             message:@"Choose Class"
                                             preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction *cancel = [UIAlertAction
                                     actionWithTitle:@"Cancel"
                                     style:UIAlertActionStyleCancel
                                     handler:^(UIAlertAction *action) {
                                         weakSelf.classIsNew = NO;
                                     }];
            
            UIAlertAction *destruct = [UIAlertAction
                                       actionWithTitle:@"New class"
                                       style:UIAlertActionStyleDestructive
                                       handler:^(UIAlertAction *action) {
                                           weakSelf.classIsNew = YES;
                                           [weakSelf performSegueWithIdentifier:@"addClass" sender:weakSelf];
                                       }];
            
            UIAlertAction *className;
            [classSheet addAction:destruct];
            
            for (NSInteger buttonItem = 0; buttonItem < classNames.count; buttonItem++) {
                className = [UIAlertAction
                             actionWithTitle:classNames[buttonItem]
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction *action) {
                                 weakSelf.classIsNew = NO;
                                 weakSelf.className.text = [weakSelf stringWithoutConfirmation:classNames[buttonItem]];
                             }];
                [classSheet addAction:className];
            }
            
            [classSheet addAction:cancel];
            
            [weakSelf presentViewController:classSheet animated:YES completion:nil];
        } else {
            UIActionSheet *classSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Class" delegate:weakSelf cancelButtonTitle:nil destructiveButtonTitle:@"New class" otherButtonTitles:nil, nil];
            
            for (NSInteger buttonItem = 0; buttonItem < classNames.count; buttonItem++) {
                [classSheet addButtonWithTitle:classNames[buttonItem]];
            }
            
            [classSheet addButtonWithTitle:@"Cancel"];
            classSheet.cancelButtonIndex = classNames.count + 1;
            
            UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
            if ([window.subviews containsObject:weakSelf.view]) {
                [classSheet showInView:weakSelf.view];
            } else {
                [classSheet showInView:window];
            }
        }
    } afterDelay:0.35f];
}

- (IBAction)tappedSignUpButton:(id)sender
{
    BOOL isMentor = [self.signUpType isEqualToString:@"mentor"];

    if ([self validate]) {
        NSPredicate *codePredicate = [NSPredicate predicateWithFormat:@"code = %@ AND type = %@", self.registrationCode.text, self.signUpType];
        
        PFQuery *findCode = [PFQuery queryWithClassName:[PFSignupCodes parseClassName] predicate:codePredicate];
        
        findCode.cachePolicy = kPFCachePolicyNetworkOnly;
        
        __block BOOL showedSignupError = NO;
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Registering...";
        hud.dimBackground = YES;
        
        MTMakeWeakSelf();
        [self bk_performBlock:^(id obj) {
            [findCode findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    NSArray *codes = objects;
                    
                    if ([codes count] > 0) {
                        PFSignupCodes *code = [codes firstObject];
                        
                        PFUser *user = [PFUser user];
                        
                        user.username = weakSelf.email.text;
                        user.password = weakSelf.password.text;
                        user.email = weakSelf.email.text;
                        
                        // other fields can be set just like with PFObject
                        user[@"first_name"] = weakSelf.firstName.text;
                        user[@"last_name"] = weakSelf.lastName.text;
                        
                        user[@"type"] = weakSelf.signUpType;
                        
                        if (weakSelf.schoolIsNew) {
                            PFSchools *createSchool = [[PFSchools alloc] initWithClassName:@"Schools"];
                            createSchool[@"name"] = weakSelf.schoolName.text;
                            [createSchool saveInBackground];
                        }
                        
                        if (weakSelf.classIsNew) {
                            PFClasses *createClass = [[PFClasses alloc] initWithClassName:@"Classes"];
                            createClass[@"name"] = weakSelf.className.text;
                            createClass[@"school"] = weakSelf.schoolName.text;
                            [createClass saveInBackground];
                            
                            PFSignupCodes *signupCodeForStudent = [[PFSignupCodes alloc] initWithClassName:@"SignupCodes"];
                            signupCodeForStudent[@"code"] = [PFCloud callFunction:@"generateSignupCode" withParameters:@{@"": @""}];
                            signupCodeForStudent[@"class"] = weakSelf.className.text;
                            signupCodeForStudent[@"school"] = weakSelf.schoolName.text;
                            signupCodeForStudent[@"type"] = @"student";
                            
                            [signupCodeForStudent saveInBackground];
                            
                        }
                        
                        if (isMentor) {
                            user[@"school"] = weakSelf.schoolName.text;
                            user[@"class"] = weakSelf.className.text;
                        } else {
                            user[@"school"] = code[@"school"];
                            user[@"class"] = code[@"class"];
                        }
                        
                        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                            });
                            
                            [weakSelf bk_performBlock:^(id obj) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (!error) {
                                        [[PFUser currentUser] refreshInBackgroundWithTarget:weakSelf selector:nil];
                                        
                                        // Update for Push Notifications
                                        [[MTUtil getAppDelegate] updateParseInstallationState];
                                        
                                        if ([[[PFUser currentUser] valueForKey:@"type"] isEqualToString:@"student"]) {
                                            [weakSelf performSegueWithIdentifier:@"studentSignedUp" sender:weakSelf];
                                        } else {
                                            [weakSelf performSegueWithIdentifier:@"pushMentorSignedUp" sender:weakSelf];
                                        }
                                        
                                    } else {
                                        // Ignore parse cache errors for now
                                        if (error.code != 120) {
                                            NSString *errorString = [error userInfo][@"error"];
                                            weakSelf.error.text = errorString;
                                            [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                                        }
                                    }
                                });

                            } afterDelay:0.35f];
                            
                        }];
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                        });
                        
                        [weakSelf bk_performBlock:^(id obj) {
                            if (!showedSignupError) {
                                showedSignupError = YES;
                                [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"There was an error with the registration code." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                            }
                            else {
                                showedSignupError = NO;
                            }
                        } afterDelay:0.35f];
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                    });
                    
                    [weakSelf bk_performBlock:^(id obj) {
                        // Ignore parse cache errors for now
                        if (error.code != 120) {
                            [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:[error userInfo][@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                        }
                    } afterDelay:0.35f];
                }
            }];
        } afterDelay:0.35f];

    }
}

- (BOOL)validate
{
    BOOL isMentor = [self.signUpType isEqualToString:@"mentor"];
    BOOL agreed = [self.agreeCheckbox isChecked];
    if (isMentor) {
        agreed &= [self.mentorAgreeCheckbox isChecked];
    }
    
    if (!agreed) {
        if (isMentor) {
            if ([self.agreeCheckbox isChecked]) {
                [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Please agree to Mentor Release before signing up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }
            else {
                [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Please agree to Terms & Conditions before signing up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Please agree to Terms & Conditions before signing up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
        
        return NO;
    }
    
    if (IsEmpty(self.password.text)) {
        [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Password is required" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        return NO;
    }
    
    if (IsEmpty(self.registrationCode.text)) {
        [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Registration Code is required" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        return NO;
    }

    if (isMentor && IsEmpty(self.schoolName.text)) {
        [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"School Name is required" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        return NO;
    }

    if (isMentor && IsEmpty(self.className.text)) {
        [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Class Name is required" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        return NO;
    }

    return YES;
}


#pragma mark - Private -
- (NSString *)stringWithoutConfirmation:(NSString *)oldString
{
    if ([oldString hasPrefix:self.confirmationString]) {
        NSString *newString = [oldString substringFromIndex:[oldString rangeOfString:self.confirmationString].length];
        return newString;
    }
    else {
        return oldString;
    }
}

- (void)adjustLayout
{
    [self.view layoutIfNeeded];
    CGFloat yOffset = 0.0f;
    UIView *firstResponder = [self.view findViewThatIsFirstResponder];
    
    CGFloat adjustment = self.firstName.frame.size.height;
    
    if (firstResponder) {
        if (firstResponder.tag == 0) {
            yOffset = 54.0f;
        }
        else {
            yOffset = 54.0f + adjustment - (adjustment * firstResponder.tag);
        }
    }
    self.verticalSpaceConstraint.constant = yOffset;
    [UIView animateWithDuration:0.35f animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)resetLayout
{
    [self.view layoutIfNeeded];
    self.verticalSpaceConstraint.constant = 54.0f;
    [UIView animateWithDuration:0.35f animations:^{
        [self.view layoutIfNeeded];
    }];
}


#pragma mark - UIActionSheetDelegate methods -
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex  // after animation
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *title = [actionSheet title];
    if ([title isEqualToString:@"Choose School"]) {
        if ([buttonTitle isEqualToString:@"New school"]) {
            self.schoolIsNew = YES;
            [self performSegueWithIdentifier:@"addSchool" sender:self];
        } else if (![buttonTitle isEqualToString:@"Cancel"]) {
            self.schoolIsNew = NO;
            self.schoolName.text = [self stringWithoutConfirmation:buttonTitle];
            self.className.text = @"";
            
        } else { // Cancel
            self.schoolIsNew = NO;
        }
    } else if ([title isEqualToString:@"Choose Class"]) {
        if ([buttonTitle isEqualToString:@"New class"]) {
            self.classIsNew = YES;
            [self performSegueWithIdentifier:@"addClass" sender:self];
        } else if (![buttonTitle isEqualToString:@"Cancel"]) {
            self.classIsNew = NO;
            self.className.text = [self stringWithoutConfirmation:buttonTitle];
        } else { // Cancel
            self.classIsNew = NO;
        }
    }
}


#pragma mark - Keyboard methods -
- (void)keyboardWillShow:(NSNotification *)nsNotification
{
    self.keyboardShowing = YES;
    [self adjustLayout];
}

- (void)keyboardWillDismiss:(NSNotification *)notification
{
    [self.view layoutIfNeeded];
    self.verticalSpaceConstraint.constant = 54.0f;
    [UIView animateWithDuration:0.35f animations:^{
        [self.view layoutIfNeeded];
        self.keyboardShowing = NO;
    }];
}


#pragma mark - UITextFieldDelegate methods -
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSInteger nextTag = textField.tag + 1;
    UIResponder *nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        [nextResponder becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self adjustLayout];
}


#pragma mark - Navigation -
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueName = [segue identifier];
    id destinationVC = [segue destinationViewController];
    if ([segueName isEqualToString:@"addSchool"]) {

    } else if ([segueName isEqualToString:@"addClass"]) {
        MTAddClassViewController *addClassVC = (MTAddClassViewController *)destinationVC;
        addClassVC.schoolName = self.schoolName.text;
    }
}


#pragma mark Notification -
-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    if([reach isReachable]) {
        self.reachable = YES;
    } else {
        self.reachable = NO;
    }
}


#pragma mark - Unwind -
- (IBAction)unwindToSignupView:(UIStoryboardSegue *)sender
{
    UIStoryboardSegue *returned = sender;
    id sourceVC = [returned sourceViewController];
    if ([sourceVC class] == [MTAddSchoolViewController class]) {
        MTAddSchoolViewController *schoolVC = sourceVC;
        
        if (IsEmpty(schoolVC.schoolName)) {
            return;
        }

        self.schoolName.text = schoolVC.schoolName;
        self.className.text = @"";
    } else if ([sourceVC class] == [MTAddClassViewController class]) {
        MTAddClassViewController *classVC = sourceVC;
        
        if (IsEmpty(classVC.className)) {
            return;
        }

        self.className.text = classVC.className;
    }
}


@end
