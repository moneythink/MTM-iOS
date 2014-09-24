//
//  MTCommentViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTCommentViewController.h"
#import "MTMyClassTableViewController.h"

@interface MTCommentViewController ()

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@property (strong, nonatomic) PFImageView *postImage;
@property (strong, nonatomic) IBOutlet UITextView *postText;

@property (strong, nonatomic) PFChallengePost *challengePost;

@property (strong, nonatomic) IBOutlet UIScrollView *viewFields;

@property (strong, nonatomic) IBOutlet UIButton *chooseImageButton;

@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *doneButton;

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

    [self.cancelButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];

    self.title = @"Create Post";
    
    self.postText.text = @"";
    
    UIBarButtonItem *shareBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStylePlain target:self action:@selector(commentDoneButton)];
    self.navigationItem.rightBarButtonItem = shareBarButton;
    
}

- (void)viewDidAppear:(BOOL)animated {
    [self.postText becomeFirstResponder];
}

- (void)viewWillUnload {
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


#pragma mark - Class methods

- (IBAction)chooseImage:(id)sender {
    [self.view endEditing:YES];
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        UIAlertController *chooseImage = [UIAlertController
                                          alertControllerWithTitle:@""
                                          message:@"Choose Image"
                                          preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction *action) {}];
        
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
        
        [chooseImage addAction:cancel];
        [chooseImage addAction:takePhoto];
        [chooseImage addAction:choosePhoto];
        
        [self presentViewController:chooseImage animated:YES completion:nil];
    } else {
        UIActionSheet *addPostImage = [[UIActionSheet alloc] initWithTitle:@"Choose Image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose from Library", nil];
        
        UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
        if ([window.subviews containsObject:self.view]) {
            [addPostImage showInView:self.view];
        } else {
            [addPostImage showInView:window];
        }
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
    NSString *mediaType = AVMediaTypeVideo;
    
    [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
        if (granted) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
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
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
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
    
    self.postImage = [[PFImageView alloc] initWithImage:image];
    [self.chooseImageButton setImage:image forState:UIControlStateNormal];
    
    [self dismissViewControllerAnimated:NO completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:NO completion:NULL];
}

- (void)commentDoneButton {
    if (![self.postText.text isEqualToString:@""]) {
        self.challengePost = [[PFChallengePost alloc] initWithClassName:[PFChallengePost parseClassName]];
        
        self.challengePost[@"challenge_number"] = self.challenge[@"challenge_number"];
        self.challengePost[@"class"] = [PFUser currentUser][@"class"];
        self.challengePost[@"school"] = [PFUser currentUser][@"school"];
        self.challengePost[@"user"] = [PFUser currentUser];
        self.challengePost[@"post_text"] = self.postText.text;
        
        if (self.postImage.image) {
            NSString *fileName = @"post_image.png";
            NSData *imageData = UIImageJPEGRepresentation(self.postImage.image, 0.8f);
            
            self.postImage.file = [PFFile fileWithName:fileName data:imageData];
            
            if (self.postImage.file) {
                [self.postImage.file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error) {
                        self.challengePost[@"picture"] = self.postImage.file;
                        
                        [self.challengePost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (!error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kReloadMyClassChallengePostsdNotification object:self];
                                });
                            } else {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kFailedMyClassChallengePostsdNotification object:self];
                                });
                                NSLog(@"text error - %@", error);
                            }
                        }];
                    } else {
                        NSLog(@"picture error - %@", error);
                    }
                }];
            }
        } else {
            [self.challengePost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                } else {
                    NSLog(@"text error - %@", error);
                }
            }];
        }
        if ([self.delegate respondsToSelector:@selector(dismissPostView)]) {
            [self.delegate dismissPostView];
        }
        [self performSegueWithIdentifier:@"unwindToChallengeRoom" sender:nil];
    }
}
- (IBAction)postCommentDone:(id)sender {
    if (![self.postText.text isEqualToString:@""]) {
        self.challengePostComment = [[PFChallengePostComment alloc] initWithClassName:[PFChallengePostComment parseClassName]];
        
        self.challengePostComment[@"challenge_post"] = self.post;
        self.challengePostComment[@"comment_text"] = self.postText.text;
        self.challengePostComment[@"school"] = [PFUser currentUser][@"school"];
        self.challengePostComment[@"class"] = [PFUser currentUser][@"class"];
        self.challengePostComment[@"user"] = [PFUser currentUser];
        
        [self.challengePostComment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
            } else {
                NSLog(@"text error - %@", error);
            }
        }];
    }
    [self.delegate dismissCommentView];
}
- (IBAction)postCommentCancel:(id)sender {
    self.postText.text = @"";
    [self postCommentDone:nil];
}


@end
