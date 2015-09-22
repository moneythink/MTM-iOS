//
//  MTEditProfileViewController.m
//  moneythink-ios
//
//  Created by dsica on 8/31/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTEditProfileViewController.h"
#import "Reachability.h"

@interface MTEditProfileViewController ()

@property (strong, nonatomic) IBOutlet UIScrollView *viewFields;
@property (strong, nonatomic) IBOutlet UITextField *firstName;
@property (strong, nonatomic) IBOutlet UITextField *lastName;
@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UITextField *userPassword;
@property (strong, nonatomic) IBOutlet UITextField *confirmPassword;
@property (strong, nonatomic) IBOutlet UIButton *userProfileButton;
@property (strong, nonatomic) IBOutlet UILabel *profileImageLabel;
@property (strong, nonatomic) IBOutlet UIView *fieldBackground;
@property (strong, nonatomic) IBOutlet UITextField *userSchool;
@property (strong, nonatomic) IBOutlet UITextField *userClassName;
@property (strong, nonatomic) IBOutlet UITextField *phoneNumber;

@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UIButton *saveButton;

@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *separatorViews;

@property (assign, nonatomic) BOOL isMentor;
@property (nonatomic, strong) UIImage *updatedProfileImage;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (assign, nonatomic) CGRect oldViewFieldsRect;
@property (assign, nonatomic) CGSize oldViewFieldsContentSize;
@property (nonatomic, strong) MTUser *userCurrent;
@property (assign, nonatomic) BOOL reachable;
@property (nonatomic) BOOL unwinding;
@property (nonatomic) BOOL showingKeyboard;
@property (nonatomic) BOOL removedProfilePhoto;
@property (nonatomic, strong) NSDictionary *organizationsDict;
@property (nonatomic, strong) NSDictionary *classesDict;
@property (nonatomic, strong) NSNumber *selectedOrganizationId;
@property (nonatomic, strong) NSNumber *selectedClassId;
@property (nonatomic, strong) NSString *mentorNewClassName;
@property (nonatomic, strong) NSString *mentorCode;
@property (nonatomic) BOOL showedEmailWarning;

@end

@implementation MTEditProfileViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    BOOL shouldDim = YES;
    AppDelegate *appDelegate = [MTUtil getAppDelegate];
    if (appDelegate.logoutReason && appDelegate.logoutReason.length > 0) {
        shouldDim = NO;
    }
    
    self.viewFields.delegate = self;
    
    self.isMentor = [MTUser isCurrentUserMentor];
    
    self.userSchool.enabled = self.isMentor;
    self.userClassName.enabled = self.isMentor;

    self.navigationItem.title = @"Edit Profile";

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveChanges:)];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.userCurrent = [MTUser currentUser];
    [self updateViewForCurrentUser];
    
    [self.profileImageLabel setBackgroundColor:[UIColor clearColor]];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reachabilityChanged:)
                                                 name:kReachabilityChangedNotification
                                               object:nil];
    
    Reachability * reach = [Reachability reachabilityWithHostname:@"www.parse.com"];
    
    [reach startNotifier];
    
    reach.reachableBlock = ^(Reachability * reachability) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.reachable = YES;
        });
    };
    
    reach.unreachableBlock = ^(Reachability * reachability)     {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.reachable = NO;
        });
    };
    
    [self textFieldsConfigure];
    
    for(UIView *subview in self.view.subviews) {
        if([subview isKindOfClass: [UIScrollView class]]) {
            for(UIScrollView *scrollViewSubview in subview.subviews) {
                if([scrollViewSubview isKindOfClass: [UITextView class]]) {
                    ((UITextView*)scrollViewSubview).delegate = (id) self;
                    [((UITextView*)scrollViewSubview) setBackgroundColor:[UIColor white]];
                }
                
                if([scrollViewSubview isKindOfClass: [UITextField class]]) {
                    ((UITextField*)scrollViewSubview).delegate = (id) self;
                    [((UITextField*)scrollViewSubview) setBackgroundColor:[UIColor white]];
                }
                if([scrollViewSubview isKindOfClass: [UILabel class]]) {
                    [((UILabel*)scrollViewSubview) setBackgroundColor:[UIColor clearColor]];
                }
            }
        }
    }
    
    [self.cancelButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[UIColor primaryOrangeDark] forState:UIControlStateHighlighted];
    [self.saveButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
    [self.saveButton setTitleColor:[UIColor primaryOrangeDark] forState:UIControlStateHighlighted];
    
    self.userProfileButton.imageView.layer.cornerRadius = round(self.userProfileButton.imageView.frame.size.width / 2.0f);
    self.userProfileButton.imageView.layer.masksToBounds = YES;
    
    self.userProfileButton.imageView.contentMode = UIViewContentModeScaleAspectFill;

    if (self.userCurrent.userAvatar) {
        self.profileImageLabel.text = @"Change Photo";

        self.userProfileButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
        UIImage *profileImage = [UIImage imageWithData:self.userCurrent.userAvatar.imageData];
        [self.userProfileButton setImage:profileImage forState:UIControlStateNormal];
    }
    else {
        self.profileImageLabel.text = @"Add Photo";
        [self.userProfileButton setImage:[UIImage imageNamed:@"profile_image.png"] forState:UIControlStateNormal];
    }
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_actionbar"]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    AppDelegate *appDelegate = [MTUtil getAppDelegate];
    if (appDelegate.logoutReason && appDelegate.logoutReason.length > 0) {
        [[[UIAlertView alloc] initWithTitle:@"Class Archived" message:appDelegate.logoutReason delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        [appDelegate clearLogoutReason];

        [self bk_performBlockInBackground:^(id obj) {
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        } afterDelay:1.0];
    }
    
    [MTUtil GATrackScreen:@"Edit Profile"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openMenuAction:) name:kWillMoveToOpenMenuPositionNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self dismissKeyboard];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Actions -
- (IBAction)loadMentorOrganizations
{
    if (!self.isMentor) {
        return;
    }
    
    [self dismissKeyboard];
    [self promptForMentorCode];
}

- (void)promptForMentorCode
{
    MTMakeWeakSelf();
    NSString *title = @"Provide Mentor Code";
    NSString *message = @"Please provide your mentor code to view all schools.";
    if ([UIAlertController class]) {
        UIAlertController *newClassAlert = [UIAlertController
                                            alertControllerWithTitle:title
                                            message:message
                                            preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction *action) {
                                 }];
        
        [newClassAlert addAction:cancel];
        
        UIAlertAction *submit = [UIAlertAction
                                 actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction *action) {
                                     self.mentorCode = ((UITextField *)[newClassAlert.textFields firstObject]).text;
                                     [self getMentorOrganizations];
                                 }];
        
        [newClassAlert addAction:submit];
        
        [newClassAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"Mentor Code";
        }];
        
        [weakSelf presentViewController:newClassAlert animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].placeholder = @"Mentor Code";
        [alert show];
    }
}

- (void)getMentorOrganizations
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Loading Schools...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] getOrganizationsWithSignupCode:self.mentorCode success:^(id responseData) {
        weakSelf.organizationsDict = responseData;
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
            [weakSelf presentOrganizationsSheet];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
            [[[UIAlertView alloc] initWithTitle:@"Load Error" message:[NSString stringWithFormat:@"Unable to load schools with this mentor code: %@", weakSelf.mentorCode] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        });
    }];
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
                                    weakSelf.userSchool.text = sortedOrganizations[buttonItem];
                                    [weakSelf loadMentorClasses];
                                }];
            [organizationSheet addAction:organizationName];
        }
        
        [organizationSheet addAction:cancel];
        
        [weakSelf presentViewController:organizationSheet animated:YES completion:nil];
    } else {
        UIActionSheet *organizationSheet = [[UIActionSheet alloc] initWithTitle:message delegate:weakSelf cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil, nil];
        
        for (NSInteger buttonItem = 0; buttonItem < [sortedOrganizations count]; buttonItem++) {
            [organizationSheet addButtonWithTitle:sortedOrganizations[buttonItem]];
        }
        
        [organizationSheet addButtonWithTitle:@"Cancel"];
        organizationSheet.cancelButtonIndex = sortedOrganizations.count;
        
        UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
        if ([window.subviews containsObject:weakSelf.view]) {
            [organizationSheet showInView:weakSelf.view];
        } else {
            [organizationSheet showInView:window];
        }
    }
}

- (IBAction)loadMentorClasses
{
    if (!self.isMentor) {
        return;
    }

    [self dismissKeyboard];
    
    if (!IsEmpty(self.classesDict)) {
        [self presentClassesSheet];
    }
    else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Loading Classes...";
        hud.dimBackground = YES;
        
        MTMakeWeakSelf();
        if (self.selectedOrganizationId && [self.selectedOrganizationId integerValue] != self.userCurrent.organization.id) {
            [[MTNetworkManager sharedMTNetworkManager] getClassesWithSignupCode:self.mentorCode organizationId:[self.selectedOrganizationId integerValue] success:^(id responseData) {
                weakSelf.classesDict = responseData;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                    [weakSelf presentClassesSheet];
                });
            } failure:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                    [[[UIAlertView alloc] initWithTitle:@"Load Error" message:@"Unable to Load Classes" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                });
            }];
        }
        else {
            [[MTNetworkManager sharedMTNetworkManager] getClassesWithSuccess:^(id responseData) {
                weakSelf.classesDict = responseData;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                    [weakSelf presentClassesSheet];
                });
            } failure:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                    [[[UIAlertView alloc] initWithTitle:@"Load Error" message:@"Unable to Load Classes" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                });
            }];
        }
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
                             weakSelf.userClassName.text = sortedClasses[buttonItem];
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
        
        [weakSelf presentViewController:classSheet animated:YES completion:nil];
    } else {
        UIActionSheet *classSheet = [[UIActionSheet alloc] initWithTitle:message delegate:weakSelf cancelButtonTitle:nil destructiveButtonTitle:@"New Class" otherButtonTitles:nil, nil];
        
        for (NSInteger buttonItem = 0; buttonItem < sortedClasses.count; buttonItem++) {
            [classSheet addButtonWithTitle:sortedClasses[buttonItem]];
        }
        
        [classSheet addButtonWithTitle:@"Cancel"];
        classSheet.cancelButtonIndex = sortedClasses.count + 1;
        
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
                                 actionWithTitle:@"OK"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction *action) {
                                     self.mentorNewClassName = ((UITextField *)[newClassAlert.textFields firstObject]).text;
                                     self.userClassName.text = self.mentorNewClassName;
                                 }];
        
        [newClassAlert addAction:submit];
        
        [newClassAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"New Class Name";
        }];
        
        
        [weakSelf presentViewController:newClassAlert animated:YES completion:nil];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].placeholder = @"New Class Name";
        [alert show];
    }
}

- (IBAction)saveChanges:(id)sender
{
    [self saveProfileChanges];
}


- (IBAction)cancelChanges:(id)sender
{
    BOOL dirty = NO;
    
    if (self.updatedProfileImage) {
        dirty = YES;
    }
    else {
        if (self.removedProfilePhoto) {
            dirty = YES;
        }
    }
    
    dirty = [self haveUpdatedUserInfoToSave];
    
    if (dirty) {
        if ([UIAlertController class]) {
            UIAlertController *saveSheet = [UIAlertController
                                                  alertControllerWithTitle:@"Save Changes?"
                                                  message:@"You have changed some profile information. Choose an option:"
                                                  preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction *cancel = [UIAlertAction
                                     actionWithTitle:@"Cancel"
                                     style:UIAlertActionStyleCancel
                                     handler:^(UIAlertAction *action) {
                                     }];
            
            MTMakeWeakSelf();
            UIAlertAction *saveAction = [UIAlertAction
                                     actionWithTitle:@"Save Changes"
                                     style:UIAlertActionStyleDestructive
                                     handler:^(UIAlertAction *action) {
                                         [weakSelf saveProfileChanges];
                                     }];
            
            UIAlertAction *discardAction = [UIAlertAction
                                         actionWithTitle:@"Discard Changes"
                                         style:UIAlertActionStyleDefault
                                         handler:^(UIAlertAction *action) {
                                             [weakSelf updateViewForCurrentUser];
                                             [weakSelf dismissViewControllerAnimated:YES completion:NULL];
                                         }];

            [saveSheet addAction:saveAction];
            [saveSheet addAction:discardAction];

            [saveSheet addAction:cancel];

            [self presentViewController:saveSheet animated:YES completion:nil];
        } else {
            
            MTMakeWeakSelf();
            UIActionSheet *saveSheet = [UIActionSheet bk_actionSheetWithTitle:@"Save Changes?"];
            
            [saveSheet bk_setDestructiveButtonWithTitle:@"Save Changes" handler:^{
                [weakSelf saveProfileChanges];
            }];
            [saveSheet bk_addButtonWithTitle:@"Discard Changes" handler:^{
                [weakSelf updateViewForCurrentUser];
                [weakSelf dismissViewControllerAnimated:YES completion:NULL];
            }];
            [saveSheet bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
            [saveSheet showInView:[UIApplication sharedApplication].keyWindow];
        }

    }
    else {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}


#pragma mark - Private -
- (BOOL)haveUpdatedUserInfoToSave
{
    BOOL dirty = NO;
    
    NSString *schoolName = self.userCurrent.organization.name ? self.userCurrent.organization.name : @"";
    if (![self.userSchool.text isEqualToString:schoolName]) {
        dirty = YES;
    }
    
    NSString *className = self.userCurrent.userClass.name ? self.userCurrent.userClass.name : @"";
    if (![self.userClassName.text isEqualToString:className]) {
        dirty = YES;
    }
    
    NSString *first = self.userCurrent.firstName ? self.userCurrent.firstName : @"";
    if (![self.firstName.text isEqualToString:first]) {
        dirty = YES;
    }
    
    NSString *last = self.userCurrent.lastName ? self.userCurrent.lastName : @"";
    if (![self.lastName.text isEqualToString:last]) {
        dirty = YES;
    }
    
    NSString *emailAddress = self.userCurrent.email ? self.userCurrent.email : @"";
    if (![self.email.text isEqualToString:emailAddress]) {
        dirty = YES;
    }
    
    NSString *phone = self.userCurrent.phoneNumber ? self.userCurrent.phoneNumber : @"";
    if (![self.phoneNumber.text isEqualToString:phone]) {
        dirty = YES;
    }
    
    return dirty;
}

- (void)textFieldsConfigure
{
    UIView *bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                                    self.userSchool.frame.size.height - 1.0f,
                                                                    self.userSchool.frame.size.width,
                                                                    1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    UIView *rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.userSchool.frame.size.width - 1.0f,
                                                                   0.0f,
                                                                   1.0f,
                                                                   self.userSchool.frame.size.height)];
    rightBorder.backgroundColor = [UIColor primaryOrange];
    
    [self.userSchool addSubview:bottomBorder];
    [self.userSchool addSubview:rightBorder];
    [self.userSchool setBackgroundColor:[UIColor white]];
    
    bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                            self.userSchool.frame.size.height - 1.0f,
                                                            self.userSchool.frame.size.width,
                                                            1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.userSchool.frame.size.width - 1.0f,
                                                           0.0f,
                                                           1.0f,
                                                           self.userSchool.frame.size.height)];
    rightBorder.backgroundColor = [UIColor primaryOrange];
    
    [self.userClassName addSubview:bottomBorder];
    [self.userClassName addSubview:rightBorder];
    [self.userClassName setBackgroundColor:[UIColor white]];
    
    bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                            self.firstName.frame.size.height - 1.0f,
                                                            self.firstName.frame.size.width,
                                                            1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.firstName.frame.size.width - 1.0f,
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
                                                            self.phoneNumber.frame.size.height - 1.0f,
                                                            self.phoneNumber.frame.size.width,
                                                            1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.phoneNumber.frame.size.width - 1.0f,
                                                           0.0f,
                                                           1.0f,
                                                           self.phoneNumber.frame.size.height)];
    rightBorder.backgroundColor = [UIColor primaryOrange];
    
    [self.phoneNumber addSubview:bottomBorder];
    [self.phoneNumber addSubview:rightBorder];
    [self.phoneNumber setBackgroundColor:[UIColor white]];

    bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                            self.userPassword.frame.size.height - 1.0f,
                                                            self.userPassword.frame.size.width,
                                                            1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.userPassword.frame.size.width - 1.0f,
                                                           0.0f,
                                                           1.0f,
                                                           self.userPassword.frame.size.height)];
    rightBorder.backgroundColor = [UIColor primaryOrange];
    
    [self.userPassword addSubview:bottomBorder];
    [self.userPassword addSubview:rightBorder];
    [self.userPassword setBackgroundColor:[UIColor white]];
    
    bottomBorder = [[UIView alloc] initWithFrame:CGRectMake(0.0f,
                                                            self.confirmPassword.frame.size.height - 1.0f,
                                                            self.confirmPassword.frame.size.width,
                                                            1.0f)];
    bottomBorder.backgroundColor = [UIColor primaryOrange];
    rightBorder = [[UIView alloc] initWithFrame:CGRectMake(self.confirmPassword.frame.size.width - 1.0f,
                                                           0.0f,
                                                           1.0f,
                                                           self.confirmPassword.frame.size.height)];
    rightBorder.backgroundColor = [UIColor primaryOrange];
    
    [self.confirmPassword addSubview:bottomBorder];
    [self.confirmPassword addSubview:rightBorder];
    [self.confirmPassword setBackgroundColor:[UIColor white]];
    
    for (UIView *thisView in self.separatorViews) {
        [self.viewFields bringSubviewToFront:thisView];
    }
}

- (void)dismissKeyboard
{
    [self.view endEditing:YES];
}

- (void)updateViewForCurrentUser
{
    self.userSchool.text = self.userCurrent.organization.name;
    self.userClassName.text = self.userCurrent.userClass.name;
    
    self.firstName.text = self.userCurrent.firstName;
    self.lastName.text = self.userCurrent.lastName;
    self.email.text = self.userCurrent.email;
    self.phoneNumber.text = self.userCurrent.phoneNumber;
    self.userPassword.text = @"";
    self.confirmPassword.text = @"";
}


#pragma mark - Notifications -
- (void)keyboardDidShow:(NSNotification *)nsNotification
{
    self.showingKeyboard = YES;
}

- (void)keyboardWillShow:(NSNotification *)nsNotification
{
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
    CGFloat h = kbTop + 380.0f;
    
    CGRect fieldsContentRect = CGRectMake(x, y, w, h);
    
    [UIView animateWithDuration:0.35f animations:^{
        self.viewFields.contentSize = fieldsContentRect.size;
        self.viewFields.contentOffset = CGPointMake(0.0f, 214.0f);
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    self.showingKeyboard = NO;
    if (self.unwinding) {
        self.unwinding = NO;
    }
    else {
        [UIView animateWithDuration:0.35f animations:^{
            self.viewFields.frame = self.oldViewFieldsRect;
            self.viewFields.contentSize = self.oldViewFieldsContentSize;
        }];
    }
}

- (void)openMenuAction:(NSNotification *)notification
{
    [self cancelChanges:nil];
}


#pragma mark - Get and save image -
- (void)saveProfileChanges
{
    [self.view endEditing:YES];

    BOOL passwordsMatch = [self.userPassword.text isEqualToString:self.confirmPassword.text];
    if (!passwordsMatch){
        UIAlertView *noMatch = [[UIAlertView alloc] initWithTitle:@"Password error" message:@"Passwords do not match." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [noMatch show];
        return;
    }

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Saving...";
    hud.dimBackground = YES;

    if (!IsEmpty(self.mentorNewClassName)) {
        // Create class first, then update user
        MTMakeWeakSelf();
        NSInteger orgId = self.selectedOrganizationId ? [self.selectedOrganizationId integerValue] : self.userCurrent.organization.id;
        [[MTNetworkManager sharedMTNetworkManager] createClassWithName:self.mentorNewClassName organizationId:orgId success:^(id responseData) {
            NSDictionary *newClassDict = responseData;
            if ([newClassDict objectForKey:weakSelf.mentorNewClassName]) {
                weakSelf.selectedClassId = [newClassDict objectForKey:weakSelf.mentorNewClassName];
                weakSelf.organizationsDict = nil;
                weakSelf.classesDict = nil;
                [weakSelf submitUserSave];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                    UIAlertView *noMatch = [[UIAlertView alloc] initWithTitle:@"New Class Error" message:@"Unable to create new class" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                    [noMatch show];
                });
            }
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                UIAlertView *noMatch = [[UIAlertView alloc] initWithTitle:@"New Class Error" message:[NSString stringWithFormat:@"Unable to create new class: %@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [noMatch show];
            });
        }];
    }
    else {
        // Just update user
        [self submitUserSave];
    }
}

- (void)submitUserSave
{
    MTMakeWeakSelf();
    BOOL haveUpdatedInfo = [self haveUpdatedUserInfoToSave];
    
    if (self.updatedProfileImage) {
        NSData *imageData = UIImageJPEGRepresentation(self.updatedProfileImage, 0.6f);
        [[MTNetworkManager sharedMTNetworkManager] setMyAvatarWithImageData:imageData success:^(id responseData) {
            NSLog(@"Successfully updated user avatar");
            
            if (haveUpdatedInfo) {
                [weakSelf submitUserInfoUpdate];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
            }
        } failure:^(NSError *error) {
            NSLog(@"Failed to save user avatar");
            
            if (haveUpdatedInfo) {
                [weakSelf submitUserInfoUpdate];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
            }
        }];
        
        self.updatedProfileImage = nil;
    }
    else {
        if (self.removedProfilePhoto) {
            [[MTNetworkManager sharedMTNetworkManager] setMyAvatarWithImageData:nil success:^(id responseData) {
                NSLog(@"Successfully removed user avatar");
                
                if (haveUpdatedInfo) {
                    [weakSelf submitUserInfoUpdate];
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                    });
                }
            } failure:^(NSError *error) {
                NSLog(@"Failed to remove user avatar");
                
                if (haveUpdatedInfo) {
                    [weakSelf submitUserInfoUpdate];
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                    });
                }
            }];
            
            self.removedProfilePhoto = NO;
        }
        else {
            [self submitUserInfoUpdate];
        }
    }
}

- (void)submitUserInfoUpdate
{
    NSInteger orgId = self.selectedOrganizationId ? [self.selectedOrganizationId integerValue] : 0;
    NSInteger classId = self.selectedClassId ? [self.selectedClassId integerValue] : 0;
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] updateCurrentUserWithFirstName:self.firstName.text lastName:self.lastName.text email:self.email.text phoneNumber:self.phoneNumber.text
                                                                     password:self.userPassword.text
                                                               organizationId:orgId
                                                                      classId:classId
                                                                      success:^(id responseData) {
                                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                                              [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                                                                              
                                                                              weakSelf.organizationsDict = nil;
                                                                              weakSelf.classesDict = nil;
                                                                              
                                                                              [weakSelf updateViewForCurrentUser];
                                                                              
                                                                              if (classId > 0) {
                                                                                  [MTUtil setUserChangedClass:YES];
                                                                              }
                                                                              [[NSNotificationCenter defaultCenter] postNotificationName:kUserSavedProfileChanges object:nil];
                                                                              
                                                                              if (weakSelf.presentingViewController) {
                                                                                  [weakSelf dismissViewControllerAnimated:YES completion:nil];
                                                                              }
                                                                          });
                                                                          
                                                                      } failure:^(NSError *error) {
                                                                          dispatch_async(dispatch_get_main_queue(), ^{
                                                                              weakSelf.organizationsDict = nil;
                                                                              weakSelf.classesDict = nil;
                                                                              
                                                                              [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                                                                              [[[UIAlertView alloc] initWithTitle:@"Unable to Save Changes" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                                                                              [weakSelf updateViewForCurrentUser];
                                                                          });
                                                                      }];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)editProfileImageButton:(id)sender
{
    [self.view endEditing:YES];
    
    if ([UIAlertController class]) {
        UIAlertController *editProfileImage = [UIAlertController
                                               alertControllerWithTitle:@""
                                               message:@"Change Profile Image"
                                               preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction *action) { }];
        
        UIAlertAction *takePhoto = [UIAlertAction
                                    actionWithTitle:@"Take Photo"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction *action) {
                                        [self takePicture];
                                    }];
        
        UIAlertAction *choosePhoto = [UIAlertAction
                                      actionWithTitle:@"Choose from Library"
                                      style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction *action) {
                                          [self choosePicture];
                                      }];

        [editProfileImage addAction:cancel];
        
        if ([self.profileImageLabel.text isEqualToString:@"Change Photo"]) {
            UIAlertAction *removePhoto = [UIAlertAction
                                          actionWithTitle:@"Remove Existing Photo"
                                          style:UIAlertActionStyleDestructive
                                          handler:^(UIAlertAction *action) {
                                              [self removePicture];
                                          }];
            [editProfileImage addAction:removePhoto];
        }

        [editProfileImage addAction:takePhoto];
        [editProfileImage addAction:choosePhoto];
        
        [self presentViewController:editProfileImage animated:YES completion:nil];
        
    } else {
        UIActionSheet *editProfileImage = nil;
        
        if ([self.profileImageLabel.text isEqualToString:@"Change Photo"]) {
            editProfileImage = [[UIActionSheet alloc] initWithTitle:@"Change Profile Image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove Existing Photo" otherButtonTitles:@"Take Photo", @"Choose from Library", nil];
        }
        else {
            editProfileImage = [[UIActionSheet alloc] initWithTitle:@"Change Profile Image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose from Library", nil];
        }
        
        UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
        if ([window.subviews containsObject:self.view]) {
            [editProfileImage showInView:self.view];
        } else {
            [editProfileImage showInView:window];
        }
    }
}

- (void)takePicture
{
    NSString *mediaType = AVMediaTypeVideo;
    
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
            });
        } else {
            //Not granted access to mediaType
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"Camera Access Alert!"
                                            message:@"Moneythink doesn't have permission to use Camera, please change privacy settings"
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            });
        }
    }];
}

- (void)choosePicture
{
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)removePicture
{
    self.updatedProfileImage = nil;
    self.removedProfilePhoto = YES;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.userProfileButton.alpha = 0.0f;
        self.profileImageLabel.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.userProfileButton setImage:[UIImage imageNamed:@"profile_image.png"] forState:UIControlStateNormal];
        
        self.profileImageLabel.text = @"Add Photo";
        
        [UIView animateWithDuration:0.2f animations:^{
            self.userProfileButton.alpha = 1.0f;
            self.profileImageLabel.alpha = 1.0f;
        } completion:^(BOOL finished) {
        }];
    }];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    
    imagePickerController.allowsEditing = YES;
    
    self.imagePickerController = imagePickerController;

    [self presentViewController:self.imagePickerController animated:YES completion:nil];
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
            self.userSchool.text = [actionSheet buttonTitleAtIndex:buttonIndex];
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
            self.userClassName.text = [actionSheet buttonTitleAtIndex:buttonIndex];
        }
    }
    else {
        // Photo picker
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [self removePicture];
        }
        else {
            NSInteger adjustedIndex = buttonIndex;
            if (actionSheet.firstOtherButtonIndex != 0) {
                adjustedIndex = buttonIndex-1;
            }
            switch (adjustedIndex) {
                case 0:
                    [self takePicture];
                    break;
                    
                case 1:
                    [self choosePicture];
                    break;
                    
                default:
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
        self.userClassName.text = self.mentorNewClassName;
    }
    else if ([alertView.title isEqualToString:@"Provide Mentor Code"]) {
        self.mentorCode = [alertView textFieldAtIndex:0].text;
        [self getMentorOrganizations];
    }
}


#pragma mark - UIImagePickerControllerDelegate methods -
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if ([info objectForKey:UIImagePickerControllerEditedImage]) {
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    }
    
    if (image.size.width > 480.0f) {
        CGFloat scale = 480.0f / image.size.width;
        CGFloat heightNew = scale * image.size.height;
        CGSize sizeNew = CGSizeMake(480.0f, heightNew);
        UIGraphicsBeginImageContext(sizeNew);
        [image drawInRect:CGRectMake(0,0,sizeNew.width,sizeNew.height)];
        UIGraphicsEndImageContext();
    }
    
    self.updatedProfileImage = image;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [UIView animateWithDuration:0.2f animations:^{
            weakSelf.userProfileButton.alpha = 0.0f;
            weakSelf.profileImageLabel.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [weakSelf.userProfileButton setImage:self.updatedProfileImage forState:UIControlStateNormal];

            weakSelf.profileImageLabel.text = @"Change Photo";

            [UIView animateWithDuration:0.2f animations:^{
                weakSelf.userProfileButton.alpha = 1.0f;
                weakSelf.profileImageLabel.alpha = 1.0f;

            } completion:^(BOOL finished) {
            }];
        }];
    } afterDelay:0.35f];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - UITextFieldDelegate delegate methods -
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

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


#pragma mark - Notification -
-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    if([reach isReachable]) {
        self.reachable = YES;
    } else {
        self.reachable = NO;
    }
}


#pragma mark - UIScrollViewDelegate -
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.showingKeyboard) {
        [self dismissKeyboard];
    }
}


@end
