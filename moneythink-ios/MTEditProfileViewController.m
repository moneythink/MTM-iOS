//
//  MTEditProfileViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/25/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
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
@property (nonatomic, strong) NSArray *classes;
@property (nonatomic, strong) NSString *confirmationString;
@property (nonatomic) BOOL unwinding;
@property (nonatomic) BOOL showingKeyboard;
@property (nonatomic) BOOL removedProfilePhoto;

@end

@implementation MTEditProfileViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    self.confirmationString = @"✓ ";
    
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
        UIImage *profileImage = [UIImage imageWithData:self.userCurrent.userAvatar.avatarData];
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
- (IBAction)classNameButton:(id)sender
{
    if (!self.isMentor) {
        return;
    }

    if ([self.userSchool.text isEqualToString:@""]) {
        UIAlertView *chooseSchoolAlert = [[UIAlertView alloc] initWithTitle:@"No school selected" message:@"Choose or add a school before selecting a class." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [chooseSchoolAlert show];
    } else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Loading Classes...";
        hud.dimBackground = YES;

        [self bk_performBlock:^(id obj) {
            NSPredicate *classesForSchool = [NSPredicate predicateWithFormat:@"school = %@", self.userSchool.text];
            PFQuery *querySchools = [PFQuery queryWithClassName:[PFClasses parseClassName] predicate:classesForSchool];
            querySchools.cachePolicy = kPFCachePolicyNetworkElseCache;
            
            [querySchools findObjectsInBackgroundWithTarget:self selector:@selector(classesSheet:error:)];
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
        if (!IsEmpty(object[@"name"])) {
            [names addObject:object[@"name"]];
        }
    }
    
    NSArray *sortedNames = [names sortedArrayUsingSelector:
                            @selector(localizedCaseInsensitiveCompare:)];
    
    NSMutableArray *classNames = [NSMutableArray arrayWithCapacity:[sortedNames count]];
    for (NSString *thisClassName in sortedNames) {
        NSString *name = thisClassName;
        if ([self.userClassName.text isEqualToString:thisClassName]) {
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
                                     }];
            
            UIAlertAction *className;
            
            for (NSInteger buttonItem = 0; buttonItem < classNames.count; buttonItem++) {
                className = [UIAlertAction
                             actionWithTitle:classNames[buttonItem]
                             style:UIAlertActionStyleDefault
                             handler:^(UIAlertAction *action) {
                                 weakSelf.userClassName.text = [weakSelf stringWithoutConfirmation:classNames[buttonItem]];
                             }];
                [classSheet addAction:className];
            }
            
            [classSheet addAction:cancel];
            
            [weakSelf presentViewController:classSheet animated:YES completion:nil];
        } else {
            // DWS: Tried moving New school button to bottom but maybe iOS bug preventing this?
            UIActionSheet *classSheet = [[UIActionSheet alloc] initWithTitle:@"Choose Class"
                                                                    delegate:weakSelf
                                                           cancelButtonTitle:nil
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:nil, nil];
            
            for (NSInteger buttonItem = 0; buttonItem < classNames.count; buttonItem++) {
                [classSheet addButtonWithTitle:classNames[buttonItem]];
            }
            
            classSheet.cancelButtonIndex = [classSheet addButtonWithTitle:@"Cancel"];
            
            UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
            if ([window.subviews containsObject:weakSelf.view]) {
                [classSheet showInView:weakSelf.view];
            } else {
                [classSheet showInView:window];
            }
        }
    } afterDelay:0.35f];
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

//    BOOL newClass = NO;
//    if (![self.userCurrent.userClass.name isEqualToString:self.userClassName.text]) {
//        newClass = YES;
//    }
//
//    if (self.userClassName.text) {
//        self.userCurrent.userClass.name = self.userClassName.text;
//    }
//    
//    if (newClass) {
//        // Check for custom playlist for this class
//        [[MTUtil getAppDelegate] checkForCustomPlaylistContentWithRefresh:YES];
//        [[NSNotificationCenter defaultCenter] postNotificationName:kUserDidChangeClass object:nil];
//        
//        // Reset prompts
//        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserActivatedChallenges];
//        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserInvitedStudents];
//        [[NSUserDefaults standardUserDefaults] synchronize];
//    }
    
//    if (self.firstName.text) {
//        self.userCurrent.firstName = self.firstName.text;
//    }
//
//    if (self.lastName.text) {
//        self.userCurrent.firstName = self.lastName.text;
//    }
//    
//    if (self.phoneNumber.text) {
//        self.userCurrent.phoneNumber = self.phoneNumber.text;
//    }

    BOOL passwordsMatch = [self.userPassword.text isEqualToString:self.confirmPassword.text];
    if (!passwordsMatch){
        UIAlertView *noMatch = [[UIAlertView alloc] initWithTitle:@"Password error" message:@"Passwords do not match." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [noMatch show];
        return;
    }
    
//    self.userCurrent.email = self.email.text;
//    self.userCurrent.username = self.email.text;
    
    if (self.updatedProfileImage) {
        NSData *imageData = UIImageJPEGRepresentation(self.updatedProfileImage, 0.6f);
        [[MTNetworkManager sharedMTNetworkManager] setAvatarForUserId:self.userCurrent.id withImageData:imageData success:^(id responseData) {
            NSLog(@"Successfully updated user avatar");
        } failure:^(NSError *error) {
            NSLog(@"Failed to save user avatar");
        }];
        
        self.updatedProfileImage = nil;
    }
    else {
        if (self.removedProfilePhoto) {
            [[MTNetworkManager sharedMTNetworkManager] setAvatarForUserId:self.userCurrent.id withImageData:nil success:^(id responseData) {
                NSLog(@"Successfully removed user avatar");
            } failure:^(NSError *error) {
                NSLog(@"Failed to remove user avatar");
            }];

            self.removedProfilePhoto = NO;
        }
    }
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] updateCurrentUserWithFirstName:self.firstName.text lastName:self.lastName.text email:self.email.text phoneNumber:self.phoneNumber.text password:self.userPassword.text success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.userCurrent = [MTUser currentUser];
            [weakSelf updateViewForCurrentUser];
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kUserSavedProfileChanges object:nil];
            
            if (weakSelf.presentingViewController) {
                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }
            else {
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
                hud.labelText = @"Saved!";
                hud.mode = MBProgressHUDModeText;
                [hud hide:YES afterDelay:1.0f];
            }
            
            // Update for Push Notifications
//            [[MTUtil getAppDelegate] updateParseInstallationState];
        });

    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:@"Unable to Save Changes" message:[error mtErrorDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];

            weakSelf.userCurrent = [MTUser currentUser];
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
//    [self.profileImage setFile:nil];
    
    [UIView animateWithDuration:0.2f animations:^{
        self.userProfileButton.alpha = 0.0f;
        self.profileImageLabel.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.userProfileButton setImage:[UIImage imageNamed:@"profile_image.png"] forState:UIControlStateNormal];
        
        self.profileImageLabel.text = @"Add Photo";
//        self.profileImage.image = nil;
        
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
    if ([title isEqualToString:@"Choose Class"]) {
        if (![buttonTitle isEqualToString:@"Cancel"]) {
            self.userClassName.text = [self stringWithoutConfirmation:buttonTitle];
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
