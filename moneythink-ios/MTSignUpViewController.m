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
#import "MTAddClassViewController.h"
#import "MTAddSchoolViewController.h"
#import "MTWebViewController.h"
#import "MTNotificationViewController.h"
#import "JGActionSheet.h"

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
@property (nonatomic, strong) NSArray *schools;
@property (nonatomic, strong) PFSchools *school;
@property (nonatomic, strong) UIActionSheet *schoolSheet;
@property (nonatomic, strong) NSArray *classes;
@property (nonatomic, strong) PFClasses *userClass;
@property (nonatomic, strong) UIActionSheet *classSheet;
@property (nonatomic, strong) NSString *confirmationString;
@property (nonatomic) BOOL keyboardShowing;
@property (nonatomic) BOOL showPrivacy;
@property (nonatomic, strong) NSArray *ethnicities;
@property (nonatomic, strong) NSArray *moneyOptionsArray;
@property (nonatomic, strong) NSDate *selectedBirthdate;
@property (nonatomic, strong) PFEthnicities *selectedEthnicity;
@property (nonatomic, strong) NSMutableArray *selectedMoneyOptions;
@property (nonatomic) BOOL allowEmptyEthnicities;
@property (nonatomic) BOOL allowEmptyMoneyOptions;
@property (nonatomic, strong) NSArray *sortedClasses;
@property (nonatomic, strong) PFClasses *selectedClass;
@property (nonatomic, strong) UIActionSheet *currentActionSheet;
@property (nonatomic, strong) id currentAlertController;

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
- (IBAction)schoolNameButton:(id)sender
{
    [self dismissKeyboard];
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
        if (!IsEmpty(object[@"name"])) {
            [names addObject:object[@"name"]];
        }
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
            
            self.currentAlertController = schoolSheet;
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
            self.currentActionSheet = schoolSheet;
            
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
    [self dismissKeyboard];
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
    NSMutableArray *classes = [NSMutableArray array];
    for (id object in objects) {
        if (!IsEmpty(object[@"name"])) {
            [names addObject:object[@"name"]];
            [classes addObject:object];
        }
    }
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    self.sortedClasses = [classes sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];

    NSMutableArray *classNames = [NSMutableArray arrayWithCapacity:[self.sortedClasses count]];
    for (PFClasses *thisClass in self.sortedClasses) {
        NSString *name = thisClass[@"name"];
        if ([self.className.text isEqualToString:name]) {
            name = [NSString stringWithFormat:@"%@%@", self.confirmationString, name];
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
                                 weakSelf.selectedClass = weakSelf.sortedClasses[buttonItem];
                             }];
                [classSheet addAction:className];
            }
            
            [classSheet addAction:cancel];
            
            self.currentAlertController = classSheet;
            [weakSelf presentViewController:classSheet animated:YES completion:nil];
        } else {
            UIActionSheet *classSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Class" delegate:weakSelf cancelButtonTitle:nil destructiveButtonTitle:@"New class" otherButtonTitles:nil, nil];
            
            for (NSInteger buttonItem = 0; buttonItem < classNames.count; buttonItem++) {
                [classSheet addButtonWithTitle:classNames[buttonItem]];
            }
            
            [classSheet addButtonWithTitle:@"Cancel"];
            classSheet.cancelButtonIndex = classNames.count + 1;
            self.currentActionSheet = classSheet;
            
            UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
            if ([window.subviews containsObject:weakSelf.view]) {
                [classSheet showInView:weakSelf.view];
            } else {
                [classSheet showInView:window];
            }
        }
    } afterDelay:0.35f];
}

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
        [self bk_performBlock:^(id obj) {
            PFQuery *queryEthnicities = [PFQuery queryWithClassName:[PFEthnicities parseClassName]];
            [queryEthnicities orderByAscending:@"order"];
            queryEthnicities.cachePolicy = kPFCachePolicyNetworkElseCache;
            [queryEthnicities findObjectsInBackgroundWithTarget:weakSelf selector:@selector(ethnicitiesSheet:error:)];
        } afterDelay:0.35f];
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
        self.allowEmptyEthnicities = YES;
        [[[UIAlertView alloc] initWithTitle:@"Load Error" message:@"Unable to load ethnicities. Leave empty or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
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
        [self bk_performBlock:^(id obj) {
            PFQuery *queryMoneyOptions = [PFQuery queryWithClassName:[PFMoneyOptions parseClassName]];
            [queryMoneyOptions orderByAscending:@"order"];
            queryMoneyOptions.cachePolicy = kPFCachePolicyNetworkElseCache;
            [queryMoneyOptions findObjectsInBackgroundWithTarget:weakSelf selector:@selector(moneyOptionsSheet:error:)];
        } afterDelay:0.35f];
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
        self.allowEmptyMoneyOptions = YES;
        [[[UIAlertView alloc] initWithTitle:@"Load Error" message:@"Unable to load options. Leave empty or try again later." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        return;
    }
    
    self.moneyOptionsArray = [NSArray arrayWithArray:objects];
    
    __block NSMutableArray *moneyOptionNames = [NSMutableArray arrayWithCapacity:[self.moneyOptionsArray count]];
    for (PFMoneyOptions *thisMoneyOption in self.moneyOptionsArray) {
        [moneyOptionNames addObject:thisMoneyOption[@"name"]];
    }
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        JGActionSheetSection *section1 = [JGActionSheetSection sectionWithTitle:@"I keep money..."
                                                                        message:@"(Select all that apply)"
                                                                   buttonTitles:moneyOptionNames
                                                                    buttonStyle:JGActionSheetButtonStyleDefault];
        
        for (PFMoneyOptions *thisMoneyOption in self.selectedMoneyOptions) {
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
                
                PFMoneyOptions *thisMoneyOption = [weakSelf.moneyOptionsArray objectAtIndex:thisIndex];
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
                        PFMoneyOptions *thisMoneyOption = [self.selectedMoneyOptions objectAtIndex:i];
                        if (i==0) {
                            selectedText = [selectedText stringByAppendingString:thisMoneyOption[@"name"]];
                        }
                        else {
                            selectedText = [selectedText stringByAppendingString:[NSString stringWithFormat:@", %@", thisMoneyOption[@"name"]]];
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
        __block BOOL showedSignupError = NO;
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Registering...";
        hud.dimBackground = YES;
        
        MTMakeWeakSelf();
        [self bk_performBlock:^(id obj) {
            NSDictionary *parameters = @{@"type": weakSelf.signUpType, @"code": weakSelf.registrationCode.text};
            [PFCloud callFunctionInBackground:@"checkSignupCode" withParameters:parameters block:^(id object, NSError *error) {
                if (!error) {
                    BOOL validCode = NO;
                    PFClasses *foundClass = nil;

                    if (isMentor) {
                        validCode = YES;
                    }
                    else {
                        if ([object isKindOfClass:[PFObject class]]) {
                            PFObject *parseObject = (PFObject *)object;
                            if ([parseObject.parseClassName isEqualToString:[PFClasses parseClassName]]) {
                                foundClass = (PFClasses *)object;
                                validCode = YES;
                            }
                        }
                    }
                    
                    if (validCode) {
                        PFUser *user = [PFUser user];
                        
                        user.username = weakSelf.email.text;
                        user.password = weakSelf.password.text;
                        user.email = weakSelf.email.text;
                        
                        // other fields can be set just like with PFObject
                        user[@"first_name"] = weakSelf.firstName.text;
                        user[@"last_name"] = weakSelf.lastName.text;
                        
                        if (!IsEmpty(weakSelf.phoneNumber.text)) {
                            user[@"phone_number"] = weakSelf.phoneNumber.text;
                        }
                        
                        user[@"type"] = weakSelf.signUpType;
                        
                        if (weakSelf.schoolIsNew) {
                            PFSchools *createSchool = [[PFSchools alloc] initWithClassName:@"Schools"];
                            createSchool[@"name"] = weakSelf.schoolName.text;
                            [createSchool saveInBackground];
                        }
                        
                        PFClasses *createClass = nil;
                        if (weakSelf.classIsNew) {
                            createClass = [[PFClasses alloc] initWithClassName:@"Classes"];
                            createClass[@"name"] = weakSelf.className.text;
                            createClass[@"school"] = weakSelf.schoolName.text;
                            
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
                            if (createClass) {
                                NSError *error;
                                [createClass save:&error];
                                if (error && error.code != 120) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                                    });
                                    
                                    [weakSelf bk_performBlock:^(id obj) {
                                        [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:[error userInfo][@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                                    } afterDelay:0.35f];
                                }
                                user[@"class_p"] = createClass;
                            }
                            else {
                                user[@"class_p"] = weakSelf.selectedClass;
                            }
                        } else {
                            user[@"class_p"] = foundClass;
                            user[@"class"] = foundClass[@"name"];
                            
                            if (foundClass[@"school_p"]) {
                                PFSchools *school = foundClass[@"school_p"];
                                [school fetchIfNeeded];
                                user[@"school"] = school[@"name"];
                            }
                            
                            if (!IsEmpty(weakSelf.birthdate.text) && weakSelf.selectedBirthdate) {
                                user[@"birthdate"] = weakSelf.selectedBirthdate;
                            }
                            
                            if (!IsEmpty(weakSelf.zipCode.text)) {
                                user[@"zip_code"] = weakSelf.zipCode.text;
                            }
                            
                            if (!IsEmpty(weakSelf.ethnicity.text) && weakSelf.selectedEthnicity) {
                                user[@"ethnicity"] = weakSelf.selectedEthnicity;
                            }
                            
                            if (!IsEmpty(weakSelf.selectedMoneyOptions)) {
                                [user setObject:weakSelf.selectedMoneyOptions forKey:@"moneyOptions_selected"];
                            }
                        }
                        
                        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                            });
                            
                            [weakSelf bk_performBlock:^(id obj) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (!error) {
                                        [[PFUser currentUser] fetchInBackgroundWithTarget:weakSelf selector:nil];
                                        
                                        // Update for Push Notifications
                                        [[MTUtil getAppDelegate] updateParseInstallationState];
                                        
                                        // Check for custom playlist for this class
                                        [[MTUtil getAppDelegate] checkForCustomPlaylistContentWithRefresh:NO];
                                        
                                        // Update Notification count for new user
                                        //  Should be none but check anyway in case we decide to generate notifications for
                                        //  new users.
                                        [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
                                        
                                        [self.navigationController popViewControllerAnimated:NO];
                                        
                                        MTOnboardingController *onboardingController = [[MTOnboardingController alloc] init];
                                        [onboardingController initiateOnboarding];
                                        
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
                }
                else {
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
    PFQuery *queryEthnicities = [PFQuery queryWithClassName:[PFEthnicities parseClassName]];
    [queryEthnicities orderByAscending:@"order"];
    queryEthnicities.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    MTMakeWeakSelf();
    [queryEthnicities findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            weakSelf.ethnicities = objects;
        }
        else {
            NSLog(@"Unable to load Ethnicities: %@", [error localizedDescription]);
        }
    }];
}

- (void)loadMoneyOptions
{
    PFQuery *queryMoneyOptions = [PFQuery queryWithClassName:[PFMoneyOptions parseClassName]];
    [queryMoneyOptions orderByAscending:@"order"];
    queryMoneyOptions.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    MTMakeWeakSelf();
    [queryMoneyOptions findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            weakSelf.moneyOptionsArray = objects;
        }
        else {
            NSLog(@"Unable to load Ethnicities: %@", [error localizedDescription]);
        }
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
            // Minus 1 to account for New Class button
            self.selectedClass = [self.sortedClasses objectAtIndex:buttonIndex-1];
            self.className.text = [self stringWithoutConfirmation:buttonTitle];
        } else { // Cancel
            self.classIsNew = NO;
        }
    } else if ([title isEqualToString:@"Choose Ethnicity"]) {
        self.ethnicity.text = [self stringWithoutConfirmation:buttonTitle];
        for (PFEthnicities *thisEthnicity in self.ethnicities) {
            if ([thisEthnicity[@"name"] isEqualToString:self.ethnicity.text]) {
                self.selectedEthnicity = thisEthnicity;
                break;
            }
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
    else if ([segueName isEqualToString:@"showWebView"]) {
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
