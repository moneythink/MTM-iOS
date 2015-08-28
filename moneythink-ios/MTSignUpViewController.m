//
//  MTSignUpViewController.m
//  moneythink-ios
//
//  Created by dsica on 5/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTSignUpViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+Palette.h"
#import "MTWebViewController.h"
#import "MTNotificationViewController.h"
#import "JGActionSheet.h"
#import <Google/Analytics.h>

#define NUMBERS_ONLY @"1234567890"

@interface MTSignUpViewController ()

@property (weak, nonatomic) IBOutlet UITextField *firstName;
@property (weak, nonatomic) IBOutlet UITextField *lastName;
@property (weak, nonatomic) IBOutlet UITextField *email;
@property (weak, nonatomic) IBOutlet UITextField *phoneNumber;
@property (weak, nonatomic) IBOutlet UITextField *birthdate;
@property (weak, nonatomic) IBOutlet UITextField *zipCode;
@property (weak, nonatomic) IBOutlet UITextField *ethnicity;
@property (weak, nonatomic) IBOutlet UITextField *moneyOptions;
@property (weak, nonatomic) IBOutlet UITextField *password;
@property (weak, nonatomic) IBOutlet UITextField *registrationCode;
@property (weak, nonatomic) IBOutlet UITextField *error;
@property (weak, nonatomic) IBOutlet UIButton *agreeButton;
@property (weak, nonatomic) IBOutlet UIButton *mentorAgreeButton;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;
@property (weak, nonatomic) IBOutlet UIButton *termsButton;
@property (weak, nonatomic) IBOutlet UIButton *mentorTermsButton;

@property (strong, nonatomic) IBOutlet MICheckBox *agreeCheckbox;
@property (strong, nonatomic) IBOutlet MICheckBox *mentorAgreeCheckbox;
@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *separatorViews;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceConstraint;

@property (nonatomic) BOOL reachable;
@property (nonatomic, strong) NSString *confirmationString;
@property (nonatomic) BOOL keyboardShowing;
@property (nonatomic) BOOL showPrivacy;
@property (nonatomic, strong) NSArray *ethnicities;
@property (nonatomic, strong) NSArray *moneyOptionsArray;
@property (nonatomic, strong) NSDate *selectedBirthdate;
@property (nonatomic, strong) NSDictionary *selectedEthnicity;
@property (nonatomic, strong) NSMutableArray *selectedMoneyOptions;
@property (nonatomic) BOOL allowEmptyEthnicities;
@property (nonatomic) BOOL allowEmptyMoneyOptions;
@property (nonatomic, strong) NSDictionary *organizationsDict;
@property (nonatomic, strong) NSDictionary *classesDict;
@property (nonatomic, strong) UIActionSheet *currentActionSheet;
@property (nonatomic, strong) id currentAlertController;
@property (nonatomic, strong) NSNumber *selectedOrganizationId;
@property (nonatomic, strong) NSNumber *selectedClassId;
@property (nonatomic, strong) NSString *mentorNewClassName;

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
    
    self.selectedMoneyOptions = [NSMutableArray array];
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
    
    if (![self.signUpType isEqualToString:@"mentor"]) {
        [self loadEthnicities];
        [self loadMoneyOptions];
        
        UIDatePicker *datePicker = [[UIDatePicker alloc]init];
        [datePicker setDate:[NSDate date]];
        datePicker.datePickerMode = UIDatePickerModeDate;
        [datePicker addTarget:self action:@selector(dateTextField:) forControlEvents:UIControlEventValueChanged];
        [self.birthdate setInputView:datePicker];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // GA Track - 'Sign Up: Student'
    // GA Track - 'Sign Up: Mentor'
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    NSString *signupTypeCapitalized = [MTUtil capitalizeFirstLetter:self.signUpType];
    NSString *screenName = [NSString stringWithFormat:@"Sign Up: %@", signupTypeCapitalized];
    [tracker set:kGAIScreenName value:screenName];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];

    [[MTUtil getAppDelegate] setWhiteNavBarAppearanceForNavigationBar:self.navigationController.navigationBar];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillDismiss:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - IBActions
- (IBAction)ethnicityButton:(id)sender
{
    [self dismissKeyboard];
    if (!IsEmpty(self.ethnicities)) {
        [self ethnicitiesSheet:self.ethnicities loading:NO error:nil];
    }
    else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Loading Ethnicities...";
        hud.dimBackground = YES;
        
        MTMakeWeakSelf();
        [[MTNetworkManager sharedMTNetworkManager] getEthnicitiesWithSuccess:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf ethnicitiesSheet:responseData error:nil];
            });

        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf ethnicitiesSheet:nil error:error];
            });
        }];
    }
}

- (void)ethnicitiesSheet:(NSArray *)objects error:(NSError *)error
{
    [self ethnicitiesSheet:objects loading:YES error:error];
}

- (void)ethnicitiesSheet:(NSArray *)objects loading:(BOOL)loading error:(NSError *)error
{
    CGFloat delay = 0.35f;
    if (loading) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        });
    }
    else {
        delay = 0.0f;
    }
    
    if (error) {
        if (![MTUtil internetReachable]) {
            [UIAlertView showNoInternetAlert];
        }
        else {
            self.allowEmptyEthnicities = YES;
            [[[UIAlertView alloc] initWithTitle:@"Load Error" message:@"Unable to load ethnicities. Leave empty or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }

        return;
    }
    
    self.ethnicities = [NSArray arrayWithArray:objects];
    
    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (id object in objects) {
        if (!IsEmpty(object[@"name"])) {
            [names addObject:object[@"name"]];
        }
    }
    
    __block NSMutableArray *ethnicityNames = [NSMutableArray arrayWithCapacity:[names count]];
    for (NSString *thisEthnicityName in names) {
        NSString *name = thisEthnicityName;
        if ([self.ethnicity.text isEqualToString:thisEthnicityName]) {
            name = [NSString stringWithFormat:@"%@%@", self.confirmationString, thisEthnicityName];
        }
        [ethnicityNames addObject:name];
    }
    
    [self bk_performBlock:^(id obj) {
        if ([UIAlertController class]) {
            UIAlertController *ethnicitySheet = [UIAlertController
                                              alertControllerWithTitle:@""
                                              message:@"Choose Ethnicity"
                                              preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction *cancel = [UIAlertAction
                                     actionWithTitle:@"Cancel"
                                     style:UIAlertActionStyleCancel
                                     handler:^(UIAlertAction *action) {
                                     }];
            
            UIAlertAction *ethnicityName;
            
            MTMakeWeakSelf();
            for (NSInteger buttonItem = 0; buttonItem < ethnicityNames.count; buttonItem++) {
                ethnicityName = [UIAlertAction
                              actionWithTitle:ethnicityNames[buttonItem]
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *action) {
                                  weakSelf.ethnicity.text = [weakSelf stringWithoutConfirmation:ethnicityNames[buttonItem]];
                                  weakSelf.selectedEthnicity = [weakSelf.ethnicities objectAtIndex:buttonItem];
                              }];
                [ethnicitySheet addAction:ethnicityName];
            }
            
            [ethnicitySheet addAction:cancel];
            
            self.currentAlertController = ethnicitySheet;
            [self presentViewController:ethnicitySheet animated:YES completion:nil];
        } else {
            UIActionSheet *ethnicitySheet = [[UIActionSheet alloc]
                                          initWithTitle:@"Choose Ethnicity"
                                          delegate:self
                                          cancelButtonTitle:nil
                                          destructiveButtonTitle:nil
                                          otherButtonTitles:nil, nil];
            
            for (NSInteger buttonItem = 0; buttonItem < ethnicityNames.count; buttonItem++) {
                [ethnicitySheet addButtonWithTitle:ethnicityNames[buttonItem]];
            }
            
            [ethnicitySheet addButtonWithTitle:@"Cancel"];
            ethnicitySheet.cancelButtonIndex = ethnicityNames.count;
            self.currentActionSheet = ethnicitySheet;
            
            UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
            if ([window.subviews containsObject:self.view]) {
                [ethnicitySheet showInView:self.view];
            } else {
                [ethnicitySheet showInView:window];
            }
        }
        
    } afterDelay:delay];
}

- (IBAction)moneyOptionsButton:(id)sender
{
    [self dismissKeyboard];
    if (!IsEmpty(self.moneyOptionsArray)) {
        [self moneyOptionsSheet:self.moneyOptionsArray loading:NO error:nil];
    }
    else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Loading...";
        hud.dimBackground = YES;
        
        MTMakeWeakSelf();
        [[MTNetworkManager sharedMTNetworkManager] getMoneyOptionsWithSuccess:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf moneyOptionsSheet:responseData error:nil];
            });
            
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf moneyOptionsSheet:nil error:error];
            });
        }];
    }
}

- (void)moneyOptionsSheet:(NSArray *)objects error:(NSError *)error
{
    [self moneyOptionsSheet:objects loading:YES error:error];
}

- (void)moneyOptionsSheet:(NSArray *)objects loading:(BOOL)loading error:(NSError *)error
{
    CGFloat delay = 0.35f;
    if (loading) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        });
    }
    else {
        delay = 0.0f;
    }
    
    if (error) {
        if (![MTUtil internetReachable]) {
            [UIAlertView showNoInternetAlert];
        }
        else {
            self.allowEmptyMoneyOptions = YES;
            [[[UIAlertView alloc] initWithTitle:@"Load Error" message:@"Unable to load options. Leave empty or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
        
        return;
    }
    
    self.moneyOptionsArray = [NSArray arrayWithArray:objects];
    
    __block NSMutableArray *moneyOptionNames = [NSMutableArray arrayWithCapacity:[self.moneyOptionsArray count]];
    for (NSDictionary *thisMoneyOptionDict in self.moneyOptionsArray) {
        [moneyOptionNames addObject:[thisMoneyOptionDict objectForKey:@"name"]];
    }
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        JGActionSheetSection *section1 = [JGActionSheetSection sectionWithTitle:@"I keep money..."
                                                                        message:@"(Select all that apply)"
                                                                   buttonTitles:moneyOptionNames
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
        
        for (NSDictionary *thisMoneyOption in self.selectedMoneyOptions) {
            [section1 setButtonStyle:JGActionSheetButtonStyleGreen forButtonAtIndex:[self.moneyOptionsArray indexOfObject:thisMoneyOption]];
        }
        JGActionSheetSection *doneSection = [JGActionSheetSection sectionWithTitle:nil message:nil buttonTitles:@[@"Done"] buttonStyle:JGActionSheetButtonStyleCancel];
        
        NSArray *sections = @[section1, doneSection];
        
        JGActionSheet *sheet = [JGActionSheet actionSheetWithSections:sections];
        
        [sheet setButtonPressedBlock:^(JGActionSheet *sheet, NSIndexPath *indexPath) {
            if (indexPath.section == 0) {
                NSInteger thisIndex = indexPath.row;
                NSArray *sections = [sheet sections];
                JGActionSheetSection *section1 = [sections objectAtIndex:0];
                
                NSDictionary *thisMoneyOption = [weakSelf.moneyOptionsArray objectAtIndex:thisIndex];
                if ([weakSelf.selectedMoneyOptions containsObject:thisMoneyOption]) {
                    [weakSelf.selectedMoneyOptions removeObject:thisMoneyOption];
                    [section1 setButtonStyle:JGActionSheetButtonStyleDefault forButtonAtIndex:thisIndex];
                }
                else {
                    [weakSelf.selectedMoneyOptions addObject:thisMoneyOption];
                    [section1 setButtonStyle:JGActionSheetButtonStyleGreen forButtonAtIndex:thisIndex];
                }
            }
            else if (indexPath.section == 1) {
                if (!IsEmpty(weakSelf.selectedMoneyOptions)) {
                    NSString *selectedText = @"";
                    
                    for (int i=0; i<[weakSelf.selectedMoneyOptions count]; i++) {
                        NSDictionary *thisMoneyOption = [self.selectedMoneyOptions objectAtIndex:i];
                        if (i==0) {
                            selectedText = [selectedText stringByAppendingString:[thisMoneyOption objectForKey:@"name"]];
                        }
                        else {
                            selectedText = [selectedText stringByAppendingString:[NSString stringWithFormat:@", %@", [thisMoneyOption objectForKey:@"name"]]];
                        }
                    }
                    
                    weakSelf.moneyOptions.text = selectedText;
                }
                else {
                    weakSelf.moneyOptions.text = @"";
                }
                [sheet dismissAnimated:YES];
            }
        }];
        
        [sheet showInView:self.view animated:YES];
    } afterDelay:delay];
}

- (IBAction)tappedSignUpButton:(id)sender
{
    BOOL isMentor = [self.signUpType isEqualToString:@"mentor"];

    if ([self validate]) {
        if (isMentor) {
            [self loadMentorOrganizations];
        }
        else {
            [self processStudentSignup];
        }
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
                [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Please agree to the Mentor Release before signing up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }
            else {
                [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Please agree to the End User License Agreement & Privacy Policy before signing up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }
        }
        else {
            [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Please agree to the End User License Agreement & Privacy Policy before signing up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
        
        return NO;
    }
    
    if (IsEmpty(self.email.text)) {
        [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Email is required" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
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

    if (!isMentor) {
        if (IsEmpty(self.birthdate.text)) {
            [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Birthdate is required" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            return NO;
        }
        
        if (IsEmpty(self.zipCode.text)) {
            [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Zip Code is required" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            return NO;
        }
        
        if (!self.allowEmptyEthnicities && IsEmpty(self.ethnicity.text)) {
            [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Ethnicity is required" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            return NO;
        }
        
        if (!self.allowEmptyMoneyOptions && IsEmpty(self.selectedMoneyOptions)) {
            [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"I keep money is required" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            return NO;
        }
    }

    return YES;
}

- (IBAction)termsAndPrivacyTapped:(id)sender
{
    if ([UIAlertController class]) {
        UIAlertController *viewSheet = [UIAlertController
                                          alertControllerWithTitle:@"View Content"
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *option1 = [UIAlertAction
                                   actionWithTitle:@"End User License Agreement"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action) {
                                       [self performSegueWithIdentifier:@"showWebView" sender:self];
                                   }];

        UIAlertAction *option2 = [UIAlertAction
                                  actionWithTitle:@"Privacy Policy"
                                  style:UIAlertActionStyleDefault
                                  handler:^(UIAlertAction *action) {
                                      self.showPrivacy = YES;
                                      [self performSegueWithIdentifier:@"showWebView" sender:self];
                                  }];

        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction *action) {
                                 }];
        
        
        [viewSheet addAction:option1];
        [viewSheet addAction:option2];
        [viewSheet addAction:cancel];
        
        self.currentAlertController = viewSheet;
        [self presentViewController:viewSheet animated:YES completion:nil];
    }
    else {
        MTMakeWeakSelf();
        UIActionSheet *sheet = [[UIActionSheet alloc] bk_initWithTitle:@"View Content"];
        [sheet bk_addButtonWithTitle:@"End User License Agreement" handler:^{
            [weakSelf performSegueWithIdentifier:@"showWebView" sender:weakSelf];
        }];
        
        [sheet bk_addButtonWithTitle:@"Privacy Policy" handler:^{
            weakSelf.showPrivacy = YES;
            [weakSelf performSegueWithIdentifier:@"showWebView" sender:weakSelf];
        }];
        
        [sheet bk_setCancelButtonWithTitle:@"Cancel" handler:^{
        }];
        
        self.currentActionSheet = sheet;
        [sheet showInView:[UIApplication sharedApplication].keyWindow];
    }
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

- (void)loadEthnicities
{
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] getEthnicitiesWithSuccess:^(id responseData) {
        weakSelf.ethnicities = responseData;
    } failure:^(NSError *error) {
        NSLog(@"loadEthnicities failure: %@", [error mtErrorDescription]);
    }];
}

- (void)loadMoneyOptions
{
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] getMoneyOptionsWithSuccess:^(id responseData) {
        weakSelf.moneyOptionsArray = responseData;
    } failure:^(NSError *error) {
        NSLog(@"loadMoneyOptions failure: %@", [error mtErrorDescription]);
    }];
}

- (void)dateTextField:(id)sender
{
    UIDatePicker *picker = (UIDatePicker *)self.birthdate.inputView;
    [picker setMaximumDate:[NSDate date]];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    NSDate *eventDate = picker.date;
    [dateFormat setDateFormat:@"MM/dd/yyyy"];
    
    NSString *dateString = [dateFormat stringFromDate:eventDate];
    self.selectedBirthdate = picker.date;
    self.birthdate.text = [NSString stringWithFormat:@"%@",dateString];
}

-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

- (void)loadMentorOrganizations
{
    [self dismissKeyboard];
    
    if (!IsEmpty(self.organizationsDict)) {
        [self presentOrganizationsSheet];
    }
    else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Loading Schools...";
        hud.dimBackground = YES;
        
        MTMakeWeakSelf();
        [[MTNetworkManager sharedMTNetworkManager] getOrganizationsWithSignupCode:weakSelf.registrationCode.text success:^(id responseData) {
            weakSelf.organizationsDict = responseData;
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                [weakSelf presentOrganizationsSheet];
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                
                if (![MTUtil internetReachable]) {
                    [UIAlertView showNoInternetAlert];
                }
                else {
                    [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Invalid Registration Code" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                }
            });
        }];
    }
}

- (void)presentOrganizationsSheet
{
    NSArray *sortedOrganizations = [[self.organizationsDict allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    MTMakeWeakSelf();
    NSString *message = @"Choose School";
    if ([UIAlertController class]) {
        UIAlertController *organizationSheet = [UIAlertController
                                         alertControllerWithTitle:@""
                                         message:message
                                         preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction *action) {
                                 }];
        
        UIAlertAction *organizationName;
        
        for (NSInteger buttonItem = 0; buttonItem < [sortedOrganizations count]; buttonItem++) {
            organizationName = [UIAlertAction
                         actionWithTitle:sortedOrganizations[buttonItem]
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction *action) {
                             NSNumber *newOrganizationId = [weakSelf.organizationsDict objectForKey:sortedOrganizations[buttonItem]];
                             if (!weakSelf.selectedOrganizationId || [weakSelf.selectedOrganizationId integerValue] != [newOrganizationId integerValue]) {
                                 weakSelf.classesDict = nil;
                             }
                             weakSelf.selectedOrganizationId = [weakSelf.organizationsDict objectForKey:sortedOrganizations[buttonItem]];
                             [weakSelf loadMentorClasses];
                         }];
            [organizationSheet addAction:organizationName];
        }
        
        [organizationSheet addAction:cancel];
        
        self.currentAlertController = organizationSheet;
        [weakSelf presentViewController:organizationSheet animated:YES completion:nil];
    } else {
        UIActionSheet *organizationSheet = [[UIActionSheet alloc] initWithTitle:message delegate:weakSelf cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil, nil];
        
        for (NSInteger buttonItem = 0; buttonItem < [sortedOrganizations count]; buttonItem++) {
            [organizationSheet addButtonWithTitle:sortedOrganizations[buttonItem]];
        }
        
        [organizationSheet addButtonWithTitle:@"Cancel"];
        organizationSheet.cancelButtonIndex = sortedOrganizations.count;
        self.currentActionSheet = organizationSheet;
        
        UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
        if ([window.subviews containsObject:weakSelf.view]) {
            [organizationSheet showInView:weakSelf.view];
        } else {
            [organizationSheet showInView:window];
        }
    }
}

- (void)loadMentorClasses
{
    [self dismissKeyboard];
    
    if (!IsEmpty(self.classesDict)) {
        [self presentClassesSheet];
    }
    else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Loading Classes...";
        hud.dimBackground = YES;
        
        MTMakeWeakSelf();
        [[MTNetworkManager sharedMTNetworkManager] getClassesWithSignupCode:weakSelf.registrationCode.text organizationId:[self.selectedOrganizationId integerValue] success:^(id responseData) {
            weakSelf.classesDict = responseData;
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                [weakSelf presentClassesSheet];
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                
                if (![MTUtil internetReachable]) {
                    [UIAlertView showNoInternetAlert];
                }
                else {
                    [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Invalid Registration Code" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                }
            });
        }];
    }
}

- (void)presentClassesSheet
{
    NSArray *sortedClasses = [[self.classesDict allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSString *message = @"Choose Class";
    MTMakeWeakSelf();
    if ([UIAlertController class]) {
        UIAlertController *classSheet = [UIAlertController
                                         alertControllerWithTitle:@""
                                         message:message
                                         preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction *action) {
                                 }];
        
        UIAlertAction *className;
        
        for (NSInteger buttonItem = 0; buttonItem < sortedClasses.count; buttonItem++) {
            className = [UIAlertAction
                         actionWithTitle:sortedClasses[buttonItem]
                         style:UIAlertActionStyleDefault
                         handler:^(UIAlertAction *action) {
                             weakSelf.selectedClassId = [weakSelf.classesDict objectForKey:sortedClasses[buttonItem]];
                             [weakSelf processMentorSignup];
                         }];
            [classSheet addAction:className];
        }
        
        UIAlertAction *destruct = [UIAlertAction
                                   actionWithTitle:@"New Class"
                                   style:UIAlertActionStyleDestructive
                                   handler:^(UIAlertAction *action) {
                                       [weakSelf promptForNewClassName];
                                   }];

        [classSheet addAction:destruct];
        [classSheet addAction:cancel];
        
        self.currentAlertController = classSheet;
        [weakSelf presentViewController:classSheet animated:YES completion:nil];
    } else {
        UIActionSheet *classSheet = [[UIActionSheet alloc] initWithTitle:message delegate:weakSelf cancelButtonTitle:nil destructiveButtonTitle:@"New Class" otherButtonTitles:nil, nil];
        
        for (NSInteger buttonItem = 0; buttonItem < sortedClasses.count; buttonItem++) {
            [classSheet addButtonWithTitle:sortedClasses[buttonItem]];
        }
        
        [classSheet addButtonWithTitle:@"Cancel"];
        classSheet.cancelButtonIndex = sortedClasses.count + 1;
        self.currentActionSheet = classSheet;
        
        UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
        if ([window.subviews containsObject:weakSelf.view]) {
            [classSheet showInView:weakSelf.view];
        } else {
            [classSheet showInView:window];
        }
    }
}

- (void)promptForNewClassName
{
    MTMakeWeakSelf();
    NSString *title = @"Enter New Class Name";
    if ([UIAlertController class]) {
        UIAlertController *newClassAlert = [UIAlertController
                                         alertControllerWithTitle:title
                                         message:nil
                                         preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction *action) {
                                 }];
        
        [newClassAlert addAction:cancel];
        
        UIAlertAction *submit = [UIAlertAction
                                 actionWithTitle:@"Submit"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction *action) {
                                     self.mentorNewClassName = ((UITextField *)[newClassAlert.textFields firstObject]).text;
                                     [self processMentorSignup];
                                 }];
        
        [newClassAlert addAction:submit];

        [newClassAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"New Class Name";
        }];
        

        self.currentAlertController = newClassAlert;
        [weakSelf presentViewController:newClassAlert animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Submit", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].placeholder = @"New Class Name";
        [alert show];
    }
}

- (void)processMentorSignup
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Registering...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] mentorSignupForEmail:self.email.text
                                                           password:self.password.text
                                                         signupCode:self.registrationCode.text
                                                          firstName:self.firstName.text
                                                           lastName:self.lastName.text
                                                        phoneNumber:self.phoneNumber.text
                                                     organizationId:self.selectedOrganizationId
                                                            classId:self.selectedClassId
                                                       newClassName:self.mentorNewClassName
                                                            success:^(id responseData) {
                                                                
                                                                [[MTUtil getAppDelegate] configureZendesk];
                                                                
                                                                // Update for Push Notifications
                                                                [[MTUtil getAppDelegate] updatePushMessagingInfo];
                                                                
                                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                                                                    
                                                                    [weakSelf.navigationController popViewControllerAnimated:YES];
                                                                    
                                                                    // Update Notification count for this user.
                                                                    [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
                                                                    
                                                                    MTOnboardingController *onboardingController = [[MTOnboardingController alloc] init];
                                                                    if (![onboardingController checkForOnboarding]) {
                                                                        id challengesVC = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"challengesViewControllerNav"];
                                                                        [weakSelf.revealViewController setFrontViewController:challengesVC animated:YES];
                                                                    }
                                                                });

                                                            } failure:^(NSError *error) {
                                                                // See if we have a validation message
                                                                NSString *errorMessage = [error localizedDescription];
                                                                if ([error firstValidationMessage]) {
                                                                    errorMessage = [error firstValidationMessage];
                                                                }
                                                                else if ([error detailMessage]) {
                                                                    errorMessage = [error detailMessage];
                                                                }
                                                                
                                                                weakSelf.selectedOrganizationId = nil;
                                                                weakSelf.selectedClassId = nil;
                                                                weakSelf.mentorNewClassName = nil;

                                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                                                                    
                                                                    if (![MTUtil internetReachable]) {
                                                                        [UIAlertView showNoInternetAlert];
                                                                    }
                                                                    else {
                                                                        [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                                                                    }
                                                                });
                                                            }];
}

- (void)processStudentSignup
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Registering...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] studentSignupForEmail:self.email.text
                                                            password:self.password.text
                                                          signupCode:self.registrationCode.text
                                                           firstName:self.firstName.text
                                                            lastName:self.lastName.text
                                                             zipCode:self.zipCode.text
                                                         phoneNumber:self.phoneNumber.text
                                                           birthdate:self.selectedBirthdate
                                                           ethnicity:self.selectedEthnicity
                                                        moneyOptions:self.selectedMoneyOptions
                                                            success:^(id responseData) {
                                                                
                                                                [[MTUtil getAppDelegate] configureZendesk];
                                                                
                                                                // Update for Push Notifications
                                                                [[MTUtil getAppDelegate] updatePushMessagingInfo];
                                                                
                                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                                                                    
                                                                    [weakSelf.navigationController popViewControllerAnimated:YES];
                                                                    
                                                                    // Update Notification count for this user.
                                                                    [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
                                                                    
                                                                    MTOnboardingController *onboardingController = [[MTOnboardingController alloc] init];
                                                                    if (![onboardingController checkForOnboarding]) {
                                                                        id challengesVC = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"challengesViewControllerNav"];
                                                                        [weakSelf.revealViewController setFrontViewController:challengesVC animated:YES];
                                                                    }
                                                                });
                                                                
                                                            } failure:^(NSError *error) {
                                                                // See if we have a validation message
                                                                NSString *errorMessage = [error localizedDescription];
                                                                if ([error firstValidationMessage]) {
                                                                    errorMessage = [error firstValidationMessage];
                                                                }
                                                                else if ([error detailMessage]) {
                                                                    errorMessage = [error detailMessage];
                                                                }
                                                                
                                                                dispatch_async(dispatch_get_main_queue(), ^{
                                                                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                                                                    
                                                                    if (![MTUtil internetReachable]) {
                                                                        [UIAlertView showNoInternetAlert];
                                                                    }
                                                                    else {
                                                                        [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                                                                    }
                                                                });
                                                            }];
}


#pragma mark - UIActionSheetDelegate methods -
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex  // after animation
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *title = [actionSheet title];
    if ([title isEqualToString:@"Choose School"]) {
        if (![buttonTitle isEqualToString:@"Cancel"]) {
            NSNumber *newOrganizationId = [self.organizationsDict objectForKey:[actionSheet buttonTitleAtIndex:buttonIndex]];
            if (!self.selectedOrganizationId || [self.selectedOrganizationId integerValue] != [newOrganizationId integerValue]) {
                self.classesDict = nil;
            }
            self.selectedOrganizationId = [self.organizationsDict objectForKey:[actionSheet buttonTitleAtIndex:buttonIndex]];
            [self loadMentorClasses];
        }
    }
    else if ([title isEqualToString:@"Choose Class"]) {
        if ([buttonTitle isEqualToString:@"New Class"]) {
            [self promptForNewClassName];
        }
        else if (![buttonTitle isEqualToString:@"Cancel"]) {
            // Minus 1 to account for New Class button
            self.selectedClassId = [self.classesDict objectForKey:[actionSheet buttonTitleAtIndex:buttonIndex]];
            [self processMentorSignup];
        }
    }
    else if ([title isEqualToString:@"Choose Ethnicity"]) {
        self.ethnicity.text = [self stringWithoutConfirmation:buttonTitle];
        for (NSDictionary *thisEthnicity in self.ethnicities) {
            if ([thisEthnicity[@"name"] isEqualToString:self.ethnicity.text]) {
                self.selectedEthnicity = thisEthnicity;
                break;
            }
        }
    }
}


#pragma mark - UIAlertViewDelegate methods -
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Enter New Class Name"]) {
        self.mentorNewClassName = [alertView textFieldAtIndex:0].text;
        [self processMentorSignup];
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;   // return NO to not change text
{
    if (textField != self.phoneNumber) {
        return YES;
    }
    
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:NUMBERS_ONLY] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    if (![string isEqualToString:filtered]) {
        return NO;
    }
    
    return YES;
}


#pragma mark - Navigation -
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueName = [segue identifier];
    id destinationVC = [segue destinationViewController];
    if ([segueName isEqualToString:@"showWebView"]) {
        MTWebViewController *webViewVC = (MTWebViewController *)destinationVC;
        
        if (self.showPrivacy) {
            webViewVC.fileName = @"PrivacyPolicy";
            self.showPrivacy = NO;
        }
        else {
            webViewVC.fileName = @"EndUserAgreement";
        }
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

- (void)didEnterBackground:(NSNotification *)notification
{
    if (self.currentActionSheet) {
        [self.currentActionSheet dismissWithClickedButtonIndex:self.currentActionSheet.cancelButtonIndex animated:NO];
        self.currentActionSheet = nil;
    }
    else if (self.currentAlertController) {
        UIAlertController *alertController = (UIAlertController *)self.currentAlertController;
        [alertController dismissViewControllerAnimated:NO completion:nil];
        self.currentAlertController = nil;
    }
}


@end
