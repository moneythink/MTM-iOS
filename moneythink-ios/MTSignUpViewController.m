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

@property (strong, nonatomic) IBOutlet UIView *view;
@property (strong, nonatomic) IBOutlet UIScrollView *viewFields;

@property (strong, nonatomic) IBOutlet UITextField *firstName;
@property (strong, nonatomic) IBOutlet UITextField *lastName;
@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UITextField *registrationCode;

@property (strong, nonatomic) IBOutlet UITextField *error;

@property (strong, nonatomic) IBOutlet UIButton *agreeButton;
@property (strong, nonatomic) IBOutlet UIButton *mentorAgreeButton;

@property (strong, nonatomic) IBOutlet MICheckBox *agreeCheckbox;
@property (strong, nonatomic) IBOutlet MICheckBox *mentorAgreeCheckbox;

@property (strong, nonatomic) IBOutlet UIButton *addSchoolButton;
@property (strong, nonatomic) IBOutlet UITextField *schoolName;
@property (assign, nonatomic) BOOL schoolIsNew;
@property (strong, nonatomic) NSArray *schools;
@property (strong, nonatomic) PFSchools *school;
@property (strong, nonatomic) UIActionSheet *schoolSheet;

@property (strong, nonatomic) IBOutlet UIButton *addClassButton;
@property (strong, nonatomic) IBOutlet UITextField *className;
@property (assign, nonatomic) BOOL classIsNew;
@property (strong, nonatomic) NSArray *classes;
@property (strong, nonatomic) PFClasses *userClass;
@property (strong, nonatomic) UIActionSheet *classSheet;

@property (strong, nonatomic) IBOutlet UIButton *signUpButton;
@property (strong, nonatomic) IBOutlet UIButton *termsButton;
@property (strong, nonatomic) IBOutlet UIButton *mentorTermsButton;

@property (assign, nonatomic) CGRect oldViewFieldsRect;
@property (assign, nonatomic) CGSize oldViewFieldsContentSize;

@property (assign, nonatomic) BOOL reachable;

@end

@implementation MTSignUpViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self textFieldsConfigure];
    
    [self.view setBackgroundColor:[UIColor lightGrey]];
    [self.viewFields setBackgroundColor:[UIColor lightGrey]];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    [self.firstName setDelegate:self];
    [self.lastName setDelegate:self];
    [self.email setDelegate:self];
    [self.password setDelegate:self];
    [self.registrationCode setDelegate:self];
    [self.schoolName setDelegate:self];
    [self.className setDelegate:self];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f];
    label.text = self.signUpTitle;
    [label sizeToFit];
    self.navigationItem.titleView = label;
    
	self.agreeCheckbox =[[MICheckBox alloc]initWithFrame:self.agreeButton.frame];
	[self.agreeCheckbox setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self.agreeCheckbox setTitle:@"" forState:UIControlStateNormal];
    self.agreeCheckbox.isChecked = NO;
	[self.viewFields addSubview:self.agreeCheckbox];
    
    self.agreeButton.hidden = YES;
    
	self.mentorAgreeCheckbox =[[MICheckBox alloc]initWithFrame:self.mentorAgreeButton.frame];
	[self.mentorAgreeCheckbox setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self.mentorAgreeCheckbox setTitle:@"" forState:UIControlStateNormal];
    self.mentorAgreeCheckbox.isChecked = NO;
	[self.viewFields addSubview:self.mentorAgreeCheckbox];
    
    self.mentorAgreeButton.hidden = YES;
    
    [self.signUpButton setTitle:@"SIGN UP" forState:UIControlStateNormal];
    self.signUpButton.layer.cornerRadius = 4.0f;
    [self.signUpButton setBackgroundColor:[UIColor mutedOrange]];
    [self.signUpButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];

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
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.oldViewFieldsRect = self.viewFields.frame;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasDismissed:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self dismissKeyboard];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    
}

- (void)textFieldsConfigure {
    UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                                    self.firstName.frame.size.height - 1.0f,
                                                                    self.firstName.frame.size.width,
                                                                    1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    UIView *rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.firstName.frame.size.width - 1.0f,
                                                                   0.0f,
                                                                   1.0f,
                                                                   self.firstName.frame.size.height)];
    rightBorder.backgroundColor = [UIColor primaryOrange];
    
    [self.firstName addSubview:bottomBorder];
    [self.firstName addSubview:rightBorder];
    [self.firstName setBackgroundColor:[UIColor white]];
    
    bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                            self.lastName.frame.size.height - 1.0f,
                                                            self.lastName.frame.size.width,
                                                            1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.lastName.frame.size.width - 1.0f,
                                                           0.0f,
                                                           1.0f,
                                                           self.lastName.frame.size.height)];
    rightBorder.backgroundColor = [UIColor primaryOrange];
    
    [self.lastName addSubview:bottomBorder];
    [self.lastName addSubview:rightBorder];
    [self.lastName setBackgroundColor:[UIColor white]];

    bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                            self.email.frame.size.height - 1.0f,
                                                            self.email.frame.size.width,
                                                            1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.email.frame.size.width - 1.0f,
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

    bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                            self.registrationCode.frame.size.height - 1.0f,
                                                            self.registrationCode.frame.size.width,
                                                            1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.registrationCode.frame.size.width - 1.0f,
                                                           0.0f,
                                                           1.0f,
                                                           self.registrationCode.frame.size.height)];
    rightBorder.backgroundColor = [UIColor primaryOrange];
    
    [self.registrationCode addSubview:bottomBorder];
    [self.registrationCode addSubview:rightBorder];
    [self.registrationCode setBackgroundColor:[UIColor white]];

    bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                            self.schoolName.frame.size.height - 1.0f,
                                                            self.schoolName.frame.size.width,
                                                            1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.schoolName.frame.size.width - 1.0f,
                                                           0.0f,
                                                           1.0f,
                                                           self.schoolName.frame.size.height)];
    rightBorder.backgroundColor = [UIColor primaryOrange];
    
    [self.schoolName addSubview:bottomBorder];
    [self.schoolName addSubview:rightBorder];
    [self.schoolName setBackgroundColor:[UIColor white]];

    bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                            self.className.frame.size.height - 1.0f,
                                                            self.className.frame.size.width,
                                                            1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.className.frame.size.width - 1.0f,
                                                           0.0f,
                                                           1.0f,
                                                           self.className.frame.size.height)];
    rightBorder.backgroundColor = [UIColor primaryOrange];
    
    [self.className addSubview:bottomBorder];
    [self.className addSubview:rightBorder];
    [self.className setBackgroundColor:[UIColor white]];
}


#pragma mark - IBActions

- (IBAction)schoolNameButton:(id)sender {
    PFQuery *querySchools = [PFQuery queryWithClassName:[PFSchools parseClassName]];
//    querySchools.cachePolicy = kPFCachePolicyCacheThenNetwork;
//    
    [querySchools findObjectsInBackgroundWithTarget:self selector:@selector(schoolsSheet:error:)];
}

- (void)schoolsSheet:(NSArray *)objects error:(NSError *)error {
    UIActionSheet *schoolSheet = [[UIActionSheet alloc] initWithTitle:@"Choose School" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"New school" otherButtonTitles:nil, nil];
    
    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (id object in objects) {
        [names addObject:object[@"name"]];
    }
    
    NSArray *schoolNames = [names sortedArrayUsingSelector:
                            @selector(localizedCaseInsensitiveCompare:)];
    
    for (NSInteger buttonItem = 0; buttonItem < schoolNames.count; buttonItem++) {
        [schoolSheet addButtonWithTitle:names[buttonItem]];
    }

    [schoolSheet addButtonWithTitle:@"Cancel"];
    schoolSheet.cancelButtonIndex = schoolNames.count;

    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    if ([window.subviews containsObject:self.view]) {
        [schoolSheet showInView:self.view];
    } else {
        [schoolSheet showInView:window];
    }
}

- (IBAction)classNameButton:(id)sender {
    if ([self.schoolName.text isEqualToString:@""]) {
        UIAlertView *chooseSchoolAlert = [[UIAlertView alloc] initWithTitle:@"No school selected" message:@"Choose or add a school before selecting a class." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [chooseSchoolAlert show];
    } else {
        NSPredicate *classesForSchool = [NSPredicate predicateWithFormat:@"school = %@", self.schoolName.text];
        PFQuery *querySchools = [PFQuery queryWithClassName:[PFClasses parseClassName] predicate:classesForSchool];
//        querySchools.cachePolicy = kPFCachePolicyCacheThenNetwork;
//        
        [querySchools findObjectsInBackgroundWithTarget:self selector:@selector(classesSheet:error:)];
    }
}

- (void)classesSheet:(NSArray *)objects error:(NSError *)error {
    UIActionSheet *classSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Class" delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"New class" otherButtonTitles:nil, nil];
    
    NSMutableArray *names = [[NSMutableArray alloc] init];
    for (id object in objects) {
        [names addObject:object[@"name"]];
    }
    
    NSArray *classNames = [names sortedArrayUsingSelector:
                            @selector(localizedCaseInsensitiveCompare:)];
    
    
    for (NSInteger buttonItem = 0; buttonItem < classNames.count; buttonItem++) {
        [classSheet addButtonWithTitle:classNames[buttonItem]];
    }
    
    [classSheet addButtonWithTitle:@"Cancel"];
    classSheet.cancelButtonIndex = classNames.count;
    
    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    if ([window.subviews containsObject:self.view]) {
        [classSheet showInView:self.view];
    } else {
        [classSheet showInView:window];
    }
}

- (IBAction)tappedSignUpButton:(id)sender {
    BOOL isMentor = [self.signUpType isEqualToString:@"mentor"];
    BOOL agreed = [self.agreeCheckbox isChecked];
    if (isMentor) {
        agreed &= [self.mentorAgreeCheckbox isChecked];
    }
    
    if (agreed) {
        NSPredicate *codePredicate = [NSPredicate predicateWithFormat:@"code = %@ AND type = %@", self.registrationCode.text, self.signUpType];
        
        PFQuery *findCode = [PFQuery queryWithClassName:[PFSignupCodes parseClassName] predicate:codePredicate];
        
//        findCode.cachePolicy = kPFCachePolicyCacheThenNetwork;
//        
        [findCode findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                NSArray *codes = objects;
                
                if ([codes count] > 0) {
                    PFSignupCodes *code = [codes firstObject];
                    
                    PFUser *user = [PFUser user];
                    
                    user.username = self.email.text;
                    user.password = self.password.text;
                    user.email = self.email.text;
                    
                    // other fields can be set just like with PFObject
                    user[@"first_name"] = self.firstName.text;
                    user[@"last_name"] = self.lastName.text;
                    
                    user[@"type"] = self.signUpType;
                    
                    if (self.schoolIsNew) {
                        PFSchools *createSchool = [[PFSchools alloc] initWithClassName:@"Schools"];
                        createSchool[@"name"] = self.schoolName.text;
                        [createSchool saveInBackground];
                    }
                    
                    if (self.classIsNew) {
                        PFClasses *createClass = [[PFClasses alloc] initWithClassName:@"Classes"];
                        createClass[@"name"] = self.className.text;
                        createClass[@"school"] = self.schoolName.text;
                        [createClass saveInBackground];
                        
                        PFSignupCodes *signupCodeForStudent = [[PFSignupCodes alloc] initWithClassName:@"SignupCodes"];
                        signupCodeForStudent[@"code"] = [PFCloud callFunction:@"generateSignupCode" withParameters:@{@"": @""}];
                        signupCodeForStudent[@"class"] = self.className.text;
                        signupCodeForStudent[@"school"] = self.schoolName.text;
                        signupCodeForStudent[@"type"] = @"student";
                        
                        [signupCodeForStudent saveInBackground];
                        
                    }
                    
                    if (isMentor) {
                        user[@"school"] = self.schoolName.text;
                        user[@"class"] = self.className.text;
                    } else {
                        user[@"school"] = code[@"school"];
                        user[@"class"] = code[@"class"];
                    }
                    
                    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (!error) {
                            [[PFUser currentUser] refreshInBackgroundWithTarget:self selector:nil];
                            
                            if ([[[PFUser currentUser] valueForKey:@"type"] isEqualToString:@"student"]) {
                                [self performSegueWithIdentifier:@"studentSignedUp" sender:self];
                            } else {
                                [self performSegueWithIdentifier:@"pushMentorSignedUp" sender:self];
                            }
                            
                        } else {
                            NSString *errorString = [error userInfo][@"error"];
                            self.error.text = errorString;
                            [[[UIAlertView alloc] initWithTitle:@"Login Error" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                        }
                    }];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"There was an error with the registration code." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                }
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:[error userInfo][@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }
        }];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Please agree to Terms & Conditions before signing up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex  // after animation
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    NSString *title = [actionSheet title];
    if ([title isEqualToString:@"Choose School"]) {
        if ([buttonTitle isEqualToString:@"New school"]) {
            self.schoolIsNew = YES;
            [self performSegueWithIdentifier:@"addSchool" sender:self];
        } else if (![buttonTitle isEqualToString:@"Cancel"]) {
            self.school = self.schools[buttonIndex - 1];
            self.schoolIsNew = NO;
            self.schoolName.text = buttonTitle;
            self.className.text = @"";
        } else { // Cancel
            self.schoolIsNew = NO;
        }
    } else if ([title isEqualToString:@"Choose Class"]) {
        if ([buttonTitle isEqualToString:@"New class"]) {
            self.classIsNew = YES;
            [self performSegueWithIdentifier:@"addClass" sender:self];
        } else if (![buttonTitle isEqualToString:@"Cancel"]) {
            self.userClass = self.classes[buttonIndex - 1];
            self.classIsNew = NO;
            self.className.text = buttonTitle;
        } else { // Cancel
            self.classIsNew = NO;
        }
    }
}


#pragma mark - Keyboard methods

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void) keyboardWasShown:(NSNotification *)nsNotification {
    CGRect viewFrame = self.view.frame;
    self.oldViewFieldsRect = self.viewFields.frame;
    self.oldViewFieldsContentSize = self.viewFields.contentSize;
    
    CGRect fieldsFrame = self.viewFields.frame;
    
    NSDictionary *userInfo = [nsNotification userInfo];
    CGRect kbRect = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGSize kbSize = kbRect.size;
    NSInteger kbTop = viewFrame.origin.y + viewFrame.size.height - kbSize.height;
    
    CGFloat x = fieldsFrame.origin.x;
    CGFloat y = fieldsFrame.origin.y;
    CGFloat w = fieldsFrame.size.width;
    CGFloat h = kbTop + 320.0f;
    
    CGRect fieldsContentRect   = CGRectMake(x, y, w, h);
    
    self.viewFields.contentSize = fieldsContentRect.size;
    
    self.viewFields.frame = fieldsFrame;
    
}

- (void)keyboardWasDismissed:(NSNotification *)notification {
    self.viewFields.frame = self.oldViewFieldsRect;
    self.viewFields.contentSize = self.oldViewFieldsContentSize;
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSInteger nextTag = textField.tag + 1;
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        [nextResponder becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return NO;
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueName = [segue identifier];
    id destinationVC = [segue destinationViewController];
    if ([segueName isEqualToString:@"addSchool"]) {

    } else if ([segueName isEqualToString:@"addClass"]) {
        MTAddClassViewController *addClassVC = (MTAddClassViewController *)destinationVC;
        addClassVC.schoolName = self.schoolName.text;
    }
}


#pragma mark Notification

-(void)reachabilityChanged:(NSNotification*)note {
    Reachability * reach = [note object];
    
    if([reach isReachable]) {
        self.reachable = YES;
    } else {
        self.reachable = NO;
    }
}


#pragma mark - Unwind

- (IBAction)unwindToSignupView:(UIStoryboardSegue *)sender {
    UIStoryboardSegue *returned = sender;
    id sourceVC = [returned sourceViewController];
    if ([sourceVC class] == [MTAddSchoolViewController class]) {
        MTAddSchoolViewController *schoolVC = sourceVC;
        self.schoolName.text = schoolVC.schoolName;
        self.className.text = @"";
    } else if ([sourceVC class] == [MTAddClassViewController class]) {
        MTAddClassViewController *classVC = sourceVC;
        self.className.text = classVC.className;
    }
}

@end
