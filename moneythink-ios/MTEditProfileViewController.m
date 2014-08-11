//
//  MTEditProfileViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/25/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTEditProfileViewController.h"

@interface MTEditProfileViewController ()

@property (strong, nonatomic) IBOutlet UIScrollView *viewFields;

@property (strong, nonatomic) IBOutlet UITextField *userSchool;
@property (strong, nonatomic) IBOutlet UITextField *userClassName;
@property (strong, nonatomic) IBOutlet UITextField *firstName;
@property (strong, nonatomic) IBOutlet UITextField *lastName;
@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UITextField *userPassword;
@property (strong, nonatomic) IBOutlet UITextField *confirmPassword;

@property (strong, nonatomic) IBOutlet UITextField *signUpCode;


@property (strong, nonatomic) PFImageView *profileImage;
@property (strong, nonatomic) UIImage *updatedProfileImage;

@property (strong, nonatomic) IBOutlet UIButton *buttonUserProfile;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@property (assign, nonatomic) CGRect oldViewFieldsRect;
@property (assign, nonatomic) CGSize oldViewFieldsContentSize;

@property (nonatomic, strong) PFUser *userCurrent;

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
    
    NSPredicate *signUpCode = [NSPredicate predicateWithFormat:@"class = %@ AND type = %@", self.userCurrent[@"class"], @"student"];
    PFQuery *querySignUpCodes = [PFQuery queryWithClassName:[PFSignupCodes parseClassName] predicate:signUpCode];
    [querySignUpCodes findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.signUpCode.text = [objects firstObject][@"code"];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
    
    
    PFFile *profileImageFile = [PFUser currentUser][@"profile_picture"];
    
    self.profileImage = [[PFImageView alloc] init];
    [self.profileImage setFile:profileImageFile];
    [self.profileImage loadInBackground:^(UIImage *image, NSError *error) {
        self.buttonUserProfile.imageView.image = self.profileImage.image;
        self.buttonUserProfile.imageView.layer.cornerRadius = round(self.buttonUserProfile.imageView.frame.size.width / 2.0f);
        self.buttonUserProfile.imageView.layer.masksToBounds = YES;
        
        [self.buttonUserProfile setImage:self.profileImage.image forState:UIControlStateNormal];
        
        [self.view setNeedsDisplay];
    }];


    
    for(UIView *subview in self.view.subviews) {
        if([subview isKindOfClass: [UIScrollView class]]) {
            for(UIScrollView *scrollViewSubview in subview.subviews) {
                if([scrollViewSubview isKindOfClass: [UITextView class]]) {
                    ((UITextView*)scrollViewSubview).delegate = (id) self;
                }
                
                if([scrollViewSubview isKindOfClass: [UITextField class]]) {
                    ((UITextField*)scrollViewSubview).delegate = (id) self;
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
    if (self.profileImage.image) {
    }
}

#pragma mark - methods

- (IBAction)shareSignUpCode:(id)sender {
    NSString *signUpCade = [NSString stringWithFormat:@"Student sign up code for class '%@' is '%@'", self.userClassName.text, self.signUpCode.text];
    NSArray *dataToShare = @[signUpCade];
    
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:dataToShare
                                      applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:^{}];
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
    CGFloat h = fieldsFrame.size.height - kbTop + 60.0f;
    
    CGRect fieldsContentRect = CGRectMake( x, y, w, h);
    
    fieldsContentRect   = CGRectMake(x, y, w, kbTop + 320.0f);
    
    self.viewFields.contentSize = fieldsContentRect.size;
    
    self.viewFields.frame = fieldsFrame;
    
}

- (void)keyboardWasDismissed:(NSNotification *)notification
{
    self.viewFields.frame = self.oldViewFieldsRect;
    self.viewFields.contentSize = self.oldViewFieldsContentSize;
}


#pragma mark - Get and save image

- (void)saveProfileChanges {
    
    
    if (self.firstName.text) {
        self.userCurrent[@"first_name"] = self.firstName.text;
    }
    
    if (self.lastName.text) {
        self.userCurrent[@"last_name"] = self.lastName.text;
    }
    
    if (![self.self.userPassword.text isEqual:@""]) {
        self.userCurrent[@"password"] = self.userPassword.text;
    }
    
    [self.userCurrent setEmail:self.email.text];
    [self.userCurrent setUsername:self.email.text];
    
    //    self.userCurrent[@"password"] = self.userPassword.text;
    
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

        } else {
            NSLog(@"error - %@", error);
        }
    }];
    
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)buttonDone:(id)sender {
    [self saveProfileChanges];
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

    [self presentViewController:self.imagePickerController animated:YES completion:nil];
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
    UIImage *image = [[UIImage alloc] init];
    
    if ([info objectForKey:UIImagePickerControllerEditedImage]) {
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    } else {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
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
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
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

@end
