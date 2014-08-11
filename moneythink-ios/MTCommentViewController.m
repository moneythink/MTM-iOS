//
//  MTCommentViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTCommentViewController.h"

@interface MTCommentViewController ()

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@property (strong, nonatomic) IBOutlet PFImageView *postImage;
@property (strong, nonatomic) IBOutlet UITextView *postText;

@property (strong, nonatomic) PFChallengePost *challengePost;

@property (strong, nonatomic) IBOutlet UIScrollView *viewFields;

@end

@implementation MTCommentViewController

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {

    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.postText.text = @"";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


- (IBAction)chooseImage:(id)sender {
    UIActionSheet *editProfileImage = [[UIActionSheet alloc] initWithTitle:@"Choose Image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose from Library", nil];
    
    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    if ([window.subviews containsObject:self.view]) {
        [editProfileImage showInView:self.view];
    } else {
        [editProfileImage showInView:window];
    }
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
    
    self.postImage.image = image;
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)commentCancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)commentDoneButton:(id)sender {
    if (![self.postText.text isEqualToString:@""]) {
        self.challengePost = [[PFChallengePost alloc] initWithClassName:[PFChallengePost parseClassName]];
        
        self.challengePost[@"challenge_number"] = self.challenge[@"challenge_number"];
        self.challengePost[@"class"] = [PFUser currentUser][@"class"];
        self.challengePost[@"school"] = [PFUser currentUser][@"school"];
        self.challengePost[@"user"] = [PFUser currentUser];
        self.challengePost[@"post_text"] = self.postText.text;
        
        [self.challengePost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                NSLog(@"text saved");
            } else {
                NSLog(@"text error - %@", error);
            }
        }];

        if (self.postImage) {
            NSString *fileName = @"post_image.png";
            NSData *imageData = UIImageJPEGRepresentation(self.postImage.image, 0.8f);

            self.postImage.file = [PFFile fileWithName:fileName data:imageData];
            
            if (self.postImage.file) {
                [self.postImage.file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error) {
                        self.challengePost[@"picture"] = self.postImage.file;

                        [self.challengePost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (!error) {
                                NSLog(@"text saved");
                            } else {
                                NSLog(@"text error - %@", error);
                            }
                        }];
                        
                        NSLog(@"picture saved");
                    } else {
                        NSLog(@"picture error - %@", error);
                    }
                }];
            }
        }
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void) keyboardWasShown:(NSNotification *)nsNotification {
    CGRect viewFrame = self.view.frame;
    CGRect fieldsFrame = self.viewFields.frame;
    
    NSDictionary *userInfo = [nsNotification userInfo];
    CGRect kbRect = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGSize kbSize = kbRect.size;
    NSInteger kbTop = viewFrame.origin.y + viewFrame.size.height - kbSize.height;
    
    CGRect fieldFrameSize = CGRectMake(fieldsFrame.origin.x ,
                                       fieldsFrame.origin.y,
                                       fieldsFrame.size.width,
                                       fieldsFrame.size.height - kbSize.height + 40.0f);
    
    fieldFrameSize = CGRectMake(0.0f, 0.0f, viewFrame.size.width, kbTop);
    
    self.viewFields.contentSize = CGSizeMake(viewFrame.size.width, kbTop + 160.0f);
    
    self.viewFields.frame = fieldFrameSize;
}

- (void)keyboardWasDismissed:(NSNotification *)notification
{
    self.viewFields.frame = self.view.frame;
}


#pragma mark - UITextFieldDelegate methods

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


@end
