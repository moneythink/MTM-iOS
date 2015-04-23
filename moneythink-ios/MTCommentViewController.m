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
@property (strong, nonatomic) PFChallengePost *challengePost;

@property (strong, nonatomic) IBOutlet UITextView *postText;
@property (strong, nonatomic) IBOutlet UIScrollView *viewFields;
@property (strong, nonatomic) IBOutlet UIButton *chooseImageButton;
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
@property (strong, nonatomic) IBOutlet UIButton *doneButton;
@property (nonatomic, strong) IBOutlet UILabel *chooseImageLabel;

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.postText becomeFirstResponder];
}


#pragma mark - Class methods
- (IBAction)chooseImage:(id)sender {
    [self.view endEditing:YES];
    
    if ([UIAlertController class]) {
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
        
        if (self.postImage) {
            UIAlertAction *removePhoto = [UIAlertAction
                                          actionWithTitle:@"Remove Existing Photo"
                                          style:UIAlertActionStyleDestructive
                                          handler:^(UIAlertAction *action) {
                                              [self removePicture];
                                          }];
            [chooseImage addAction:removePhoto];
        }

        [chooseImage addAction:takePhoto];
        [chooseImage addAction:choosePhoto];
        
        [self presentViewController:chooseImage animated:YES completion:nil];
    }
    else {
        UIActionSheet *addPostImage = nil;
        if (self.postImage) {
            addPostImage = [[UIActionSheet alloc] initWithTitle:@"Edit Image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove Existing Photo" otherButtonTitles:@"Take Photo", @"Choose from Library", nil];
        }
        else {
            addPostImage = [[UIActionSheet alloc] initWithTitle:@"Add Image" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose from Library", nil];
        }

        UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
        if ([window.subviews containsObject:self.view]) {
            [addPostImage showInView:self.view];
        } else {
            [addPostImage showInView:window];
        }
    }
}


#pragma mark - Private Methods -
- (void)removePicture {
    self.postImage = nil;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.chooseImageButton.alpha = 0.0f;
        self.chooseImageLabel.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.chooseImageButton setImage:[UIImage imageNamed:@"photo_post"] forState:UIControlStateNormal];
        self.chooseImageLabel.text = @"Add Image";
        
        [UIView animateWithDuration:0.2f animations:^{
            self.chooseImageButton.alpha = 1.0f;
            self.chooseImageLabel.alpha = 1.0f;
        } completion:^(BOOL finished) {
        }];
    }];
}


#pragma mark - UIACtionSheetDelegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex  // after animation
{
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

- (void)choosePicture
{
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
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
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
    
    [self dismissViewControllerAnimated:YES completion:^{
        [UIView animateWithDuration:0.2f animations:^{
            self.chooseImageButton.alpha = 0.0f;
            self.chooseImageLabel.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.postImage = [[PFImageView alloc] initWithImage:image];
            [self.chooseImageButton setImage:image forState:UIControlStateNormal];
            self.chooseImageLabel.text = @"Edit Image";
            
            [UIView animateWithDuration:0.2f animations:^{
                self.chooseImageButton.alpha = 1.0f;
                self.chooseImageLabel.alpha = 1.0f;
            }];
        }];
    }];
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)commentDoneButton
{
    if (![self.postText.text isEqualToString:@""])
    {
        if (![MTUtil internetReachable])
        {
            [UIAlertView showNoInternetAlert];
            return;
        }

        self.challengePost = [[PFChallengePost alloc] initWithClassName:[PFChallengePost parseClassName]];
        
        if (self.challenge[@"challenge_number"]) {
            self.challengePost[@"challenge_number"] = self.challenge[@"challenge_number"];
        }
        
        if (self.challenge) {
            self.challengePost[@"challenge"] = self.challenge;
        }
        
        self.challengePost[@"post_text"] = self.postText.text;
        self.challengePost[@"class"] = [PFUser currentUser][@"class"];
        self.challengePost[@"school"] = [PFUser currentUser][@"school"];
        self.challengePost[@"user"] = [PFUser currentUser];
        
        if (self.postImage.image)
        {
            NSString *fileName = @"post_image.png";
            NSData *imageData = UIImageJPEGRepresentation(self.postImage.image, 0.5f);
            
            self.postImage.file = [PFFile fileWithName:fileName data:imageData];
            if (self.postImage.file)
            {
                // if there's a picture, then update the Parse post
                self.challengePost[@"picture"] = self.postImage.file;
            }
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveNewChallengePostNotification object:self.challengePost];
            
            [self.challengePost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [[PFUser currentUser] fetchInBackground];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kSavingWithPhotoNewChallengePostNotification object:self.challengePost];
                    });
                }
                else {
                    NSLog(@"Post with picture error - %@", error);
                    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Post with picture error" message:[NSString stringWithFormat:@"%@", error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    //[alert show];
                    [self.challengePost saveEventually];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kFailedMyClassChallengePostsdNotification object:self];
                    });
                }
            }];
        }
        else
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveNewChallengePostNotification object:self.challengePost];
            
            [self.challengePost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error) {
                    [[PFUser currentUser] fetchInBackground];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kSavedMyClassChallengePostsdNotification object:self];
                    });
                }
                else {
                    NSLog(@"Post error - %@", error);
                    //UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Post error" message:[NSString stringWithFormat:@"%@", error] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    //[alert show];
                    [self.challengePost saveEventually];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kFailedMyClassChallengePostsdNotification object:self];
                    });
                }
            }];
        }

        //[[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveNewChallengePostNotification object:self.challengePost];

        /*
        if (self.postImage.image)
        {
            NSString *fileName = @"post_image.png";
            NSData *imageData = UIImageJPEGRepresentation(self.postImage.image, 0.5f);
            
            self.postImage.file = [PFFile fileWithName:fileName data:imageData];
            if (self.postImage.file)
            {
                // if there's a picture, then update the Parse post and save it locally, we shouldn't do that on a successful Parse save only!!
                self.challengePost[@"picture"] = self.postImage.file;
                [self.challengePost saveEventually];
                
                [self.postImage.file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error)
                    {
                        //self.challengePost[@"picture"] = self.postImage.file;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:kSavingWithPhotoNewChallengePostNotification object:self.challengePost];
                        });
                        
                        [self.challengePost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if (!error)
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kSavedMyClassChallengePostsdNotification object:self];
                                });
                            }
                            else
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kFailedMyClassChallengePostsdNotification object:self];
                                });
                                NSLog(@"text error - %@", error);
                            }
                        }];
                    }
                    else
                    {
                        NSLog(@"picture error - %@", error);
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:kFailedMyClassChallengePostsdNotification object:self];
                        });
                    }
                }];
            }
        }
        else
        {
            [self.challengePost saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (!error)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kSavedMyClassChallengePostsdNotification object:self];
                    });
                }
                else
                {
                    NSLog(@"text error - %@", error);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kFailedMyClassChallengePostsdNotification object:self];
                    });
                }
            }];
        }
        */
        
        [self performSegueWithIdentifier:@"unwindToChallengeRoom" sender:nil];
    }
}

- (IBAction)postCommentDone:(id)sender
{
    if (![self.postText.text isEqualToString:@""])
    {
        if (![MTUtil internetReachable])
        {
            [UIAlertView showNoInternetAlert];
            return;
        }

        self.challengePostComment = [[PFChallengePostComment alloc] initWithClassName:[PFChallengePostComment parseClassName]];
        self.challengePostComment[@"challenge_post"] = self.post;
        self.challengePostComment[@"comment_text"] = self.postText.text;
        self.challengePostComment[@"school"] = [PFUser currentUser][@"school"];
        self.challengePostComment[@"class"] = [PFUser currentUser][@"class"];
        self.challengePostComment[@"user"] = [PFUser currentUser];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveNewPostCommentNotification object:nil];
        
        [self.challengePostComment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [[PFUser currentUser] fetchInBackground];
            }
            else {
                NSLog(@"Post text comment error - %@", error);
                [self.challengePostComment saveEventually];
            }
        }];
    }
    
    [self.postText endEditing:YES];
    [self.delegate dismissCommentView];
}

- (IBAction)postCommentCancel:(id)sender
{
    self.postText.text = @"";
    [self postCommentDone:nil];
}


@end
