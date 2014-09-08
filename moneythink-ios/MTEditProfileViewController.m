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

@property (strong, nonatomic) IBOutlet UITextField *userSchool;
@property (strong, nonatomic) IBOutlet UITextField *userClassName;
@property (strong, nonatomic) IBOutlet UITextField *firstName;
@property (strong, nonatomic) IBOutlet UITextField *lastName;
@property (strong, nonatomic) IBOutlet UITextField *email;

@property (strong, nonatomic) IBOutlet UITextField *userPassword;
@property (strong, nonatomic) IBOutlet UITextField *confirmPassword;

@property (assign, nonatomic) BOOL isMentor;

@property (strong, nonatomic) PFImageView *profileImage;
@property (strong, nonatomic) UIImage *updatedProfileImage;

@property (strong, nonatomic) IBOutlet UIButton *userProfileButton;
@property (strong, nonatomic) IBOutlet UILabel *profileImageLabel;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@property (assign, nonatomic) CGRect oldViewFieldsRect;
@property (assign, nonatomic) CGSize oldViewFieldsContentSize;

@property (nonatomic, strong) PFUser *userCurrent;

@property (assign, nonatomic) BOOL reachable;

@property (strong, nonatomic) IBOutlet UIView *fieldBackground;
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

    [self.viewFields setBackgroundColor:[UIColor lightGrey]];
    
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    self.parentViewController.navigationItem.title = @"Settings";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasDismissed:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self dismissKeyboard];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

#pragma mark - methods

- (void)textFieldsConfigure {
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
}

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
    CGFloat h = kbTop + 380.0f;
    
    CGRect fieldsContentRect = CGRectMake( x, y, w, h);
    
    self.viewFields.contentSize = fieldsContentRect.size;
    self.viewFields.contentOffset = CGPointMake(0.0f, 94.0f);
}

- (void)keyboardWasDismissed:(NSNotification *)notification
{
    self.viewFields.frame = self.oldViewFieldsRect;
    self.viewFields.contentSize = self.oldViewFieldsContentSize;
}


#pragma mark - Get and save image

- (void)saveProfileChanges {
    
    
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
        } else {
            NSLog(@"error - %@", error);
        }
    }];
    
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)saveChanges:(id)sender {
    [self saveProfileChanges];
}

- (IBAction)editProfileImageButton:(id)sender {
    UIActionSheet *editProfileImage = [[UIActionSheet alloc] initWithTitle:@"Change Profile Image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose from Library", nil];
    
    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    if ([window.subviews containsObject:self.view]) {
        [editProfileImage showInView:self.view];
    } else {
        [editProfileImage showInView:window];
    }
}

#pragma mark - Navigation

/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
 */

- (void)takePicture {
    
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
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


#pragma mark - UIACtionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex  // after animation
{
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
    
    [self dismissViewControllerAnimated:NO completion:NULL];
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


#pragma mark Notification

-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    if([reach isReachable]) {
        self.reachable = YES;
    } else {
        self.reachable = NO;
    }
}


@end
