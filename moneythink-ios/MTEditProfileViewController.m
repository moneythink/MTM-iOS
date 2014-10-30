//
//  MTEditProfileViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/25/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTEditProfileViewController.h"
#import "Reachability.h"
#import "MTAddSchoolViewController.h"
#import "MTAddClassViewController.h"

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

@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UIButton *saveButton;

@property (nonatomic, strong) IBOutletCollection(UIView) NSArray *separatorViews;

@property (assign, nonatomic) BOOL isMentor;
@property (strong, nonatomic) PFImageView *profileImage;
@property (strong, nonatomic) UIImage *updatedProfileImage;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (assign, nonatomic) CGRect oldViewFieldsRect;
@property (assign, nonatomic) CGSize oldViewFieldsContentSize;
@property (nonatomic, strong) PFUser *userCurrent;
@property (assign, nonatomic) BOOL reachable;
@property (assign, nonatomic) BOOL schoolIsNew;
@property (strong, nonatomic) NSArray *schools;
@property (strong, nonatomic) PFSchools *school;
@property (assign, nonatomic) BOOL classIsNew;
@property (strong, nonatomic) NSArray *classes;
@property (strong, nonatomic) PFClasses *userClass;
@property (nonatomic, strong) NSString *confirmationString;
@property (nonatomic) BOOL unwinding;
@property (nonatomic) BOOL showingKeyboard;

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
    
    self.isMentor = [[PFUser currentUser][@"type"] isEqualToString:@"mentor"];
    
    self.userSchool.enabled = self.isMentor;
    self.userClassName.enabled = self.isMentor;

    self.navigationItem.title = @"Edit Profile";

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveChanges:)];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.userCurrent = [PFUser currentUser];
    
    self.userSchool.text = self.userCurrent[@"school"];
    self.userClassName.text = self.userCurrent[@"class"];

    self.firstName.text = self.userCurrent[@"first_name"];
    self.lastName.text = self.userCurrent[@"last_name"];
    self.email.text = self.userCurrent[@"email"];
    
    PFFile *profileImageFile = [PFUser currentUser][@"profile_picture"];
    
    self.profileImage = [[PFImageView alloc] init];
    [self.profileImage setFile:profileImageFile];
    [self.profileImage loadInBackground:^(UIImage *image, NSError *error) {
        if (!error) {
            if (image) {
                self.profileImageLabel.text = @"Edit Photo";
                self.profileImage.image = image;
            } else {
                self.profileImageLabel.text = @"Add Photo";
                self.profileImage.image = [UIImage imageNamed:@"profile_image.png"];
            }
        }
        self.userProfileButton.imageView.image = self.profileImage.image;
        self.userProfileButton.imageView.layer.cornerRadius = round(self.userProfileButton.imageView.frame.size.width / 2.0f);
        self.userProfileButton.imageView.layer.masksToBounds = YES;
        
        [self.userProfileButton setImage:self.profileImage.image forState:UIControlStateNormal];
        
        [[PFUser currentUser] refresh];
        [self.view setNeedsLayout];
    }];
    
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.parentViewController.navigationItem.title = @"Settings";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[MTUtil getAppDelegate] setWhiteNavBarAppearanceForNavigationBar:self.navigationController.navigationBar];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self dismissKeyboard];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Actions -
- (IBAction)schoolNameButton:(id)sender
{
    if (!self.isMentor) {
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Loading Schools...";
    hud.dimBackground = YES;

    [self bk_performBlock:^(id obj) {
        PFQuery *querySchools = [PFQuery queryWithClassName:[PFSchools parseClassName]];
        querySchools.cachePolicy = kPFCachePolicyNetworkElseCache;
        
        [querySchools findObjectsInBackgroundWithTarget:self selector:@selector(schoolsSheet:error:)];
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
        if ([self.userSchool.text isEqualToString:thisSchoolName]) {
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
            
            for (NSInteger buttonItem = 0; buttonItem < schoolNames.count; buttonItem++) {
                schoolName = [UIAlertAction
                              actionWithTitle:schoolNames[buttonItem]
                              style:UIAlertActionStyleDefault
                              handler:^(UIAlertAction *action) {
                                  self.schoolIsNew = NO;
                                  self.userSchool.text = [self stringWithoutConfirmation:schoolNames[buttonItem]];
                                  self.userClassName.text = @"";
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
        [names addObject:object[@"name"]];
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
                                 weakSelf.userClassName.text = [weakSelf stringWithoutConfirmation:classNames[buttonItem]];
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
    
    if (![self.userSchool.text isEqualToString:self.userCurrent[@"school"]]) {
        dirty = YES;
    }
    if (![self.userClassName.text isEqualToString:self.userCurrent[@"class"]]) {
        dirty = YES;
    }
    if (![self.firstName.text isEqualToString:self.userCurrent[@"first_name"]]) {
        dirty = YES;
    }
    if (![self.lastName.text isEqualToString:self.userCurrent[@"last_name"]]) {
        dirty = YES;
    }
    if (![self.email.text isEqualToString:self.userCurrent[@"email"]]) {
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


#pragma mark - Private
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

-(void)dismissKeyboard
{
    [self.view endEditing:YES];
}

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
    
    CGRect fieldsContentRect = CGRectMake( x, y, w, h);
    
    [UIView animateWithDuration:0.35f animations:^{
        self.viewFields.contentSize = fieldsContentRect.size;
        self.viewFields.contentOffset = CGPointMake(0.0f, 184.0f);
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


#pragma mark - Get and save image

- (void)saveProfileChanges
{
    if (self.userClassName.text) {
        self.userCurrent[@"class"] = self.userClassName.text;
    }
    
    if (self.firstName.text) {
        self.userCurrent[@"school"] = self.userSchool.text;
    }
    
    if (self.firstName.text) {
        self.userCurrent[@"first_name"] = self.firstName.text;
    }
    
    if (self.lastName.text) {
        self.userCurrent[@"last_name"] = self.lastName.text;
    }
    
    BOOL passwordsMatch = [self.userPassword.text isEqualToString:self.confirmPassword.text];
    if (![self.self.userPassword.text isEqual:@""] && passwordsMatch) {
        self.userCurrent.password = self.userPassword.text;
    } else if (!passwordsMatch){
        UIAlertView *noMatch = [[UIAlertView alloc] initWithTitle:@"Password error" message:@"Passwords do not match." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
        [noMatch show];
        return;
    }
    
    if (self.schoolIsNew) {
        PFSchools *createSchool = [[PFSchools alloc] initWithClassName:@"Schools"];
        createSchool[@"name"] = self.userSchool.text;
        [createSchool saveInBackground];
    }
    
    if (self.classIsNew) {
        PFClasses *createClass = [[PFClasses alloc] initWithClassName:@"Classes"];
        createClass[@"name"] = self.userClassName.text;
        createClass[@"school"] = self.userSchool.text;
        [createClass saveInBackground];
        
        PFSignupCodes *signupCodeForStudent = [[PFSignupCodes alloc] initWithClassName:@"SignupCodes"];
        signupCodeForStudent[@"code"] = [PFCloud callFunction:@"generateSignupCode" withParameters:@{@"": @""}];
        signupCodeForStudent[@"class"] = self.userClassName.text;
        signupCodeForStudent[@"school"] = self.userSchool.text;
        signupCodeForStudent[@"type"] = @"student";
        
        [signupCodeForStudent saveInBackground];
    }
    
    [self.userCurrent setEmail:self.email.text];
    [self.userCurrent setUsername:self.email.text];
    
    if (self.updatedProfileImage) {
        
        self.profileImage = [[PFImageView alloc] initWithImage:self.updatedProfileImage];
        NSString *fileName = @"profile_image.png";
        NSData *imageData = UIImageJPEGRepresentation(self.updatedProfileImage, 0.8f);
        self.profileImage.file = [PFFile fileWithName:fileName data:imageData];
        if (self.profileImage.file) {
            self.userCurrent[@"profile_picture"] = self.profileImage.file;
            [self.profileImage.file saveInBackground];
        }
    }
    
    [self.userCurrent saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [[PFUser currentUser] refresh];
            
            // Update for Push Notifications
            [[MTUtil getAppDelegate] updateParseInstallationState];
        } else {
            [UIAlertView bk_showAlertViewWithTitle:@"Unable to Save Changes" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            NSLog(@"error - %@", error);
        }
    }];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)editProfileImageButton:(id)sender {
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
        [editProfileImage addAction:takePhoto];
        [editProfileImage addAction:choosePhoto];
        
        [self presentViewController:editProfileImage animated:YES completion:nil];
        
    } else {
        UIActionSheet *editProfileImage = [[UIActionSheet alloc] initWithTitle:@"Change Profile Image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose from Library", nil];
        
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
                                            message:@"Monrythink doesn't have permission to use Camera, please change privacy settings"
                                           delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            });
        }
    }];
}

- (void)choosePicture {
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    
    imagePickerController.allowsEditing = YES;
    
    self.imagePickerController = imagePickerController;

    [self presentViewController:self.imagePickerController animated:NO completion:nil];
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
            self.schoolIsNew = NO;
            self.userSchool.text = [self stringWithoutConfirmation:buttonTitle];
            self.userClassName.text = @"";
        } else { // Cancel
            self.schoolIsNew = NO;
        }
    } else if ([title isEqualToString:@"Choose Class"]) {
        if ([buttonTitle isEqualToString:@"New class"]) {
            self.classIsNew = YES;
            [self performSegueWithIdentifier:@"addClass" sender:self];
        } else if (![buttonTitle isEqualToString:@"Cancel"]) {
            self.classIsNew = NO;
            self.userClassName.text = [self stringWithoutConfirmation:buttonTitle];
        } else { // Cancel
            self.classIsNew = NO;
        }
    }
    else {
        // Photo picker
        switch (buttonIndex) {
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


#pragma mark - UIImagePickerControllerDelegate methods
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
        } completion:^(BOOL finished) {
            weakSelf.userProfileButton.imageView.image = self.updatedProfileImage;
            
            [UIView animateWithDuration:0.2f animations:^{
                weakSelf.userProfileButton.alpha = 1.0f;
            } completion:^(BOOL finished) {
            }];
        }];
    } afterDelay:0.35f];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:NO completion:NULL];
}


#pragma mark - UITextFieldDelegate delegate methods

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
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


#pragma mark - Notification
-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    if([reach isReachable]) {
        self.reachable = YES;
    } else {
        self.reachable = NO;
    }
}


#pragma mark - Unwind
- (IBAction)unwindToEditProfileView:(UIStoryboardSegue *)sender {
    self.unwinding = YES;
    
    UIStoryboardSegue *returned = sender;
    id sourceVC = [returned sourceViewController];
    if ([sourceVC class] == [MTAddSchoolViewController class]) {
        MTAddSchoolViewController *schoolVC = sourceVC;
        
        if (IsEmpty(schoolVC.schoolName)) {
            return;
        }
        
        self.userSchool.text = schoolVC.schoolName;
        self.userClassName.text = @"";
    } else if ([sourceVC class] == [MTAddClassViewController class]) {
        MTAddClassViewController *classVC = sourceVC;
        
        if (IsEmpty(classVC.className)) {
            return;
        }
        
        self.userClassName.text = classVC.className;
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
