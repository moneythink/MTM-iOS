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

@property (nonatomic, strong) IBOutlet UITextView *postText;
@property (nonatomic, strong) IBOutlet UIScrollView *viewFields;
@property (nonatomic, strong) IBOutlet UIButton *chooseImageButton;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UIButton *doneButton;
@property (nonatomic, strong) IBOutlet UILabel *chooseImageLabel;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) PFImageView *postImage;
@property (nonatomic, strong) PFChallengePost *challengePost;
@property (nonatomic, strong) UIImage *updatedPostImage;
@property (nonatomic) BOOL removedPostPhoto;

@end

@implementation MTCommentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.cancelButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];

    if (self.editPost) {
        self.title = @"Edit Post";
        self.postText.text = self.post[@"post_text"];
        
        if (self.post[@"picture"]) {
            self.postImage = [[PFImageView alloc] init];
            self.postImage.file = self.post[@"picture"];

            MTMakeWeakSelf();
            [self.postImage loadInBackground:^(UIImage *image, NSError *error) {
                if (!error) {
                    if (image) {
                        weakSelf.postImage.image = image;
                        [weakSelf.chooseImageButton setImage:image forState:UIControlStateNormal];
                    }
                    else {
                        image = nil;
                    }
                } else {
                    NSLog(@"error - %@", error);
                }
            }];

            self.chooseImageLabel.text = @"Change Photo";
        }
        else {
            self.chooseImageLabel.text = @"Add Photo";
        }

        UIBarButtonItem *shareBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveEdit)];
        self.navigationItem.rightBarButtonItem = shareBarButton;
        
        UIBarButtonItem *cancelEditButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelEdit)];
        self.navigationItem.leftBarButtonItem = cancelEditButton;
    }
    else {
        self.title = @"Create Post";
        self.postText.text = @"";
        
        UIBarButtonItem *shareBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStylePlain target:self action:@selector(saveNew)];
        self.navigationItem.rightBarButtonItem = shareBarButton;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!self.editPost) {
        [self.postText becomeFirstResponder];
    }
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
            addPostImage = [[UIActionSheet alloc] initWithTitle:@"Change Photo" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Remove Existing Photo" otherButtonTitles:@"Take Photo", @"Choose from Library", nil];
        }
        else {
            addPostImage = [[UIActionSheet alloc] initWithTitle:@"Add Photo" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Photo", @"Choose from Library", nil];
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
        self.chooseImageLabel.text = @"Add Photo";
        self.updatedPostImage = nil;
        self.removedPostPhoto = YES;
        
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
            self.updatedPostImage = image;
            self.removedPostPhoto = NO;
            [self.chooseImageButton setImage:image forState:UIControlStateNormal];
            self.chooseImageLabel.text = @"Change Photo";
            
            [UIView animateWithDuration:0.2f animations:^{
                self.chooseImageButton.alpha = 1.0f;
                self.chooseImageLabel.alpha = 1.0f;
            }];
        }];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Edit Post Methods -
- (void)cancelEdit
{
    // Confirm cancel if changes
    BOOL dirty = NO;
    
    if (self.updatedPostImage) {
        dirty = YES;
    }
    else {
        if (self.removedPostPhoto) {
            dirty = YES;
        }
    }
    
    NSString *postText = self.post[@"post_text"] ? self.post[@"post_text"] : @"";
    if (![self.postText.text isEqualToString:postText]) {
        dirty = YES;
    }
    
    if (dirty) {
        NSString *title = @"Save Changes?";
        if ([UIAlertController class]) {
            UIAlertController *saveSheet = [UIAlertController
                                            alertControllerWithTitle:title
                                            message:@"You have changed some post information. Choose an option:"
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
                                             [weakSelf saveEdit];
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
            UIActionSheet *saveSheet = [UIActionSheet bk_actionSheetWithTitle:title];
            
            [saveSheet bk_setDestructiveButtonWithTitle:@"Save Changes" handler:^{
                [weakSelf saveEdit];
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

- (void)saveEdit
{
    if (![MTUtil internetReachable]) {
        [UIAlertView showNoInternetAlert];
        return;
    }
    
    if (IsEmpty(self.postText.text)) {
        
        NSString *title = @"Text Missing";
        NSString *message = @"Post text is required.";
        if ([UIAlertController class]) {
            UIAlertController *changeSheet = [UIAlertController
                                              alertControllerWithTitle:title
                                              message:message
                                              preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:@"OK"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
                                       }];
            
            [changeSheet addAction:okAction];
            [self presentViewController:changeSheet animated:YES completion:nil];
        } else {
            [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
        
        return;
    }
    
    self.post[@"post_text"] = self.postText.text;
    
    if (self.updatedPostImage && self.postImage.image) {
        NSString *fileName = @"post_image.png";
        NSData *imageData = UIImageJPEGRepresentation(self.postImage.image, 0.5f);
        
        self.postImage.file = [PFFile fileWithName:fileName data:imageData];
        if (self.postImage.file) {
            // if there's a picture, then update the Parse post
            self.post[@"picture"] = self.postImage.file;
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveEditPostNotification object:self.post];
        
        MTMakeWeakSelf();
        [self.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [[PFUser currentUser] fetchInBackground];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidSaveEditPostNotification object:self.post];
                });
            }
            else {
                NSLog(@"Post Edit Save with picture error - %@", error);
                [weakSelf.post saveEventually];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kFailedSaveEditPostNotification object:self];
                });
            }
        }];
    }
    else {
        if (self.removedPostPhoto) {
            [self.post removeObjectForKey:@"picture"];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveEditPostNotification object:self.post];
        
        MTMakeWeakSelf();
        [self.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [[PFUser currentUser] fetchInBackground];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidSaveEditPostNotification object:self];
                });
            }
            else {
                NSLog(@"Post Edit Save error - %@", error);
                [weakSelf.challengePost saveEventually];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kFailedSaveEditPostNotification object:self];
                });
            }
        }];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - New Post Method -
- (void)saveNew
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
            if (self.postImage.file) {
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
        
        [self performSegueWithIdentifier:@"unwindToChallengeRoom" sender:nil];
    }
}


#pragma mark - New Comment on Post Method -
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
