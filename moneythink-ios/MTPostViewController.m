//
//  MTPostViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTPostViewController.h"
#import "MTMyClassTableViewController.h"

#define NUMBERS_ONLY @"1234567890."
#define CHARACTER_LIMIT 9

@interface MTPostViewController ()

@property (nonatomic, strong) IBOutlet UITextView *postText;
@property (nonatomic, strong) IBOutlet UIScrollView *viewFields;
@property (nonatomic, strong) IBOutlet UIButton *chooseImageButton;
@property (nonatomic, strong) IBOutlet UILabel *chooseImageLabel;
@property (nonatomic, strong) IBOutlet UIView *spentView;
@property (nonatomic, strong) IBOutlet UITextField *spentTextField;
@property (nonatomic, strong) IBOutlet UITextField *savedTextField;
@property (nonatomic, strong) IBOutlet MICheckBox *spentCheckbox;
@property (nonatomic, strong) IBOutlet MICheckBox *savedCheckbox;
@property (nonatomic, strong) IBOutlet MICheckBox *notSureCheckbox;
@property (nonatomic, strong) IBOutlet UIButton *spentDoneButton;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIImage *postImage;
@property (nonatomic, strong) UIImage *updatedPostImage;
@property (nonatomic) BOOL removedPostPhoto;
@property (nonatomic) BOOL displaySpentView;

@end

@implementation MTPostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.displaySpentView = !IsEmpty(self.challenge.postExtraFields);
    self.spentDoneButton.hidden = YES;

    [MTUtil GATrackScreen:@"Post Detail"];
    
    if (self.displaySpentView) {
        self.spentView.hidden = NO;
        
        self.spentCheckbox.uncheckedImage = [UIImage imageNamed:@"unchecked"];
        self.spentCheckbox.checkedImage = [UIImage imageNamed:@"checked"];
        
        self.savedCheckbox.uncheckedImage = [UIImage imageNamed:@"unchecked"];
        self.savedCheckbox.checkedImage = [UIImage imageNamed:@"checked"];
        
        self.notSureCheckbox.uncheckedImage = [UIImage imageNamed:@"unchecked"];
        self.notSureCheckbox.checkedImage = [UIImage imageNamed:@"checked"];
        
        self.spentDoneButton.tintColor = [UIColor primaryGreen];
    }
    else {
        self.spentView.hidden = YES;
    }

    if (self.editPost) {
        self.title = @"Edit Post";
        self.postText.text = self.post.content;
        
        if (self.post.hasPostImage) {
            MTMakeWeakSelf();
            [self.chooseImageButton setImage:[UIImage imageNamed:@"photo_post"] forState:UIControlStateNormal];

            self.postImage = [self.post loadPostImageWithSuccess:^(id responseData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.postImage = [UIImage imageWithData:responseData];
                    [weakSelf.chooseImageButton setImage:weakSelf.postImage forState:UIControlStateNormal];
                });
            } failure:^(NSError *error) {
                NSLog(@"Unable to load post image");
            }];
            [self.chooseImageButton setImage:self.postImage forState:UIControlStateNormal];
            self.chooseImageLabel.text = @"Change Photo";
        }
        else {
            self.chooseImageLabel.text = @"Add Photo";
        }

        UIBarButtonItem *shareBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveEdit)];
        self.navigationItem.rightBarButtonItem = shareBarButton;
        
        UIBarButtonItem *cancelEditButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelEdit)];
        self.navigationItem.leftBarButtonItem = cancelEditButton;
        
        if (self.displaySpentView) {
            [self populateSpentFields];
        }
    }
    else {
        self.title = @"Create Post";
        self.postText.text = @"";
        
        UIBarButtonItem *shareBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStylePlain target:self action:@selector(saveNew)];
        self.navigationItem.rightBarButtonItem = shareBarButton;
    }
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(dismissKeyboard)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
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

- (void)dismissKeyboard
{
    [self.view endEditing:YES];
    self.spentDoneButton.hidden = YES;
}

- (void)populateSpentFields
{
    self.spentTextField.text = @"";
    self.savedTextField.text = @"";
    
    if (!IsEmpty(self.post.extraFields)) {
        NSData *data = [self.post.extraFields dataUsingEncoding:NSUTF8StringEncoding];
        id jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

        if ([jsonDict isKindOfClass:[NSDictionary class]]) {
            NSDictionary *savedSpentDict = (NSDictionary *)jsonDict;
            NSString *spentString = [savedSpentDict objectForKey:@"spent"];
            NSString *currencyString = [self currencyTextForString:spentString];
            if (!IsEmpty(currencyString)) {
                self.spentTextField.text = currencyString;
                if (IsEmpty(self.spentTextField.text)) {
                    self.spentCheckbox.isChecked = NO;
                }
            }
            
            NSString *savedString = [savedSpentDict objectForKey:@"saved"];
            currencyString = [self currencyTextForString:savedString];
            if (!IsEmpty(currencyString)) {
                self.savedTextField.text = [self currencyTextForString:savedString];
                if (IsEmpty(self.savedTextField.text)) {
                    self.savedCheckbox.isChecked = NO;
                }
            }
            
            if (self.spentCheckbox.isChecked || self.savedCheckbox.isChecked) {
                self.notSureCheckbox.isChecked = NO;
            }
        }
    }
}

- (NSDictionary *)dictionaryFromSpentFields
{
    NSMutableDictionary *myDict = [NSMutableDictionary dictionary];
    
    if (!IsEmpty(self.spentTextField.text)) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        NSNumber *number = [formatter numberFromString:self.spentTextField.text];
        NSNumberFormatter *formatterOut = [[NSNumberFormatter alloc] init];
        [formatterOut setNumberStyle:NSNumberFormatterDecimalStyle];
        [formatterOut setUsesGroupingSeparator:NO];
        
        NSString *amountSpent = [formatterOut stringFromNumber:number];
        [myDict setValue:amountSpent forKey:@"spent"];
    }
    else {
        [myDict setValue:@"0" forKey:@"spent"];
    }

    if (!IsEmpty(self.savedTextField.text)) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        NSNumber *number = [formatter numberFromString:self.savedTextField.text];
        NSNumberFormatter *formatterOut = [[NSNumberFormatter alloc] init];
        [formatterOut setNumberStyle:NSNumberFormatterDecimalStyle];
        [formatterOut setUsesGroupingSeparator:NO];
        
        NSString *amountSaved = [formatterOut stringFromNumber:number];
        [myDict setValue:amountSaved forKey:@"saved"];
    }
    else {
        [myDict setValue:@"0" forKey:@"saved"];
    }
    
    return myDict;
}

- (NSString *)currencyTextForString:(NSString *)string
{
    NSString *currencyText = nil;
    
    NSNumberFormatter *decimalFormatter = [[NSNumberFormatter alloc] init];
    [decimalFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [decimalFormatter setUsesGroupingSeparator:NO];
    [decimalFormatter setMaximumFractionDigits:2];
    
    NSNumber *currentNumber = [decimalFormatter numberFromString:string];
    
    if ([currentNumber floatValue] >= 0.01f) {
        NSNumberFormatter *currencyformatter = [[NSNumberFormatter alloc] init];
        [currencyformatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        currencyText = [currencyformatter stringFromNumber:currentNumber];
    }
    else {
        currencyText = @"";
    }
    
    return currencyText;
}


#pragma mark - UIActionSheetDelegate methods
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
            self.postImage = image;
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
    
    NSString *postText = self.post.content ? self.post.content : @"";
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
    
    if (IsEmpty(self.postText.text) && !self.postImage) {
        NSString *title = @"Content Missing";
        NSString *message = @"Post text or photo is required.";
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
    
    NSDictionary *extraFields = nil;
    if (self.displaySpentView) {
        extraFields = [self dictionaryFromSpentFields];
    }
    
    NSData *imageData = nil;

    if (self.postImage) {
        imageData = UIImageJPEGRepresentation(self.postImage, 0.5f);
    }
    
    // Proactively, update object
    BOOL hadImage = self.post.hasPostImage;
    
    __block NSInteger oldPostId = self.post.id;
    __block NSString *oldContent = self.post.content;
    __block MTOptionalImage *oldImage = self.post.postImage;
    __block NSString *oldExtraFields = self.post.extraFields;
    __block NSDate *oldUpdatedAt = self.post.updatedAt;
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    self.post.content = self.postText.text;
    if (!IsEmpty(extraFields)) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extraFields options:0 error:&error];
        if (!error) {
            NSString *extraFieldsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            self.post.extraFields = extraFieldsString;
        }
    }
    else {
        self.post.extraFields = @"";
    }
    
    if (imageData) {
        MTOptionalImage *postImage = self.post.postImage;
        if (!postImage) {
            postImage = [[MTOptionalImage alloc] init];
        }
        
        postImage.isDeleted = NO;
        postImage.imageData = imageData;
        postImage.updatedAt = [NSDate date];
        self.post.postImage = postImage;
        self.post.hasPostImage = YES;
    }
    else {
        self.post.postImage = nil;
        self.post.hasPostImage = NO;
    }

    [realm commitWriteTransaction];

    [[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveEditPostNotification object:nil];
    
    [[MTNetworkManager sharedMTNetworkManager] updatePostId:self.post.id content:self.postText.text postImageData:imageData hadImage:hadImage extraFields:extraFields success:^(AFOAuthCredential *credential) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kDidSaveEditPostNotification object:nil];
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to update post for id:%lu", (long)oldPostId);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // Revert changes
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            MTChallengePost *post = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:oldPostId]];
            if (post && !post.isInvalidated) {
                post.content = oldContent;
                if (oldImage) {
                    post.hasPostImage = YES;
                }
                else {
                    post.hasPostImage = NO;
                }
                post.postImage = oldImage;
                post.extraFields = oldExtraFields;
                post.updatedAt = oldUpdatedAt;
            }
            [realm commitWriteTransaction];

            [[NSNotificationCenter defaultCenter] postNotificationName:kFailedSaveEditPostNotification object:nil];
        });

    }];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - New Post Method -
- (void)saveNew
{
    if (IsEmpty(self.postText.text) && !self.postImage) {
        NSString *title = @"Content Missing";
        NSString *message = @"Post text or photo is required.";
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
    
    if (![MTUtil internetReachable]) {
        [UIAlertView showNoInternetAlert];
        return;
    }
    
    
    NSData *imageData = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveNewChallengePostNotification object:nil];
    
    if (self.postImage) {
        imageData = UIImageJPEGRepresentation(self.postImage, 0.5f);
    }
    
    NSDictionary *extraFields = nil;
    if (self.displaySpentView) {
        extraFields = [self dictionaryFromSpentFields];
    }
    
    [[MTNetworkManager sharedMTNetworkManager] createPostForChallengeId:self.challenge.id content:self.postText.text postImageData:imageData extraFields:extraFields success:^(AFOAuthCredential *credential) {
        if (![MTUser isCurrentUserMentor]) {
            // Update current user (to get current point total)
            [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
                [MTUtil setRefreshedForKey:kRefreshForMeUser];
            } failure:nil];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kSavedMyClassChallengePostNotification object:nil];
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to create post: %@", [error mtErrorDescription]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kFailedMyClassChallengePostNotification object:nil];
        });
    }];
    
    [self performSegueWithIdentifier:@"unwindToChallengeRoom" sender:nil];
}


#pragma mark - UITextFieldDelegate methods -
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSInteger nextTag = textField.tag + 1;
    UIResponder *nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        [nextResponder becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem.enabled = NO;
    
    CGPoint scrollPoint = CGPointMake(0, textField.frame.origin.y - 30.0f);
    [self.viewFields setContentOffset:scrollPoint animated:YES];
    
    self.spentDoneButton.hidden = NO;
    
    if (!IsEmpty(textField.text)) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        
        NSNumber *number = [formatter numberFromString:textField.text];
        
        NSNumberFormatter *formatterOut = [[NSNumberFormatter alloc] init];
        [formatterOut setNumberStyle:NSNumberFormatterDecimalStyle];
        [formatterOut setUsesGroupingSeparator:NO];

        textField.text = [formatterOut stringFromNumber:number];
    }
    
    if (textField == self.spentTextField || textField == self.savedTextField) {
        self.notSureCheckbox.isChecked = NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.navigationItem.rightBarButtonItem.enabled = YES;
    
    [self.viewFields setContentOffset:CGPointMake(0.0f, -64.0f) animated:YES];
    
    self.spentDoneButton.hidden = YES;
    
    if (IsEmpty(textField.text)) {
        if (textField == self.spentTextField) {
            self.spentCheckbox.isChecked = NO;
        }
        else if (textField == self.savedTextField) {
            self.savedCheckbox.isChecked = NO;
        }
    }
    else {
        textField.text = [self currencyTextForString:textField.text];
        if (IsEmpty(textField.text)) {
            if (textField == self.spentTextField) {
                self.spentCheckbox.isChecked = NO;
            }
            else if (textField == self.savedTextField) {
                self.savedCheckbox.isChecked = NO;
            }
        }
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;   // return NO to not change text
{
    // Add iOS 7 compatible string search, had 43 crashes here using containsString
    NSString *delimiter = @".";
    NSRange textFieldRange = [textField.text rangeOfString:delimiter];
    NSRange stringRange = [string rangeOfString:delimiter];
    if (textFieldRange.location != NSNotFound && stringRange.location != NSNotFound) {
        return NO;
    }
    
    NSUInteger newLength = [textField.text length] + [string length] - range.length;
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:NUMBERS_ONLY] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
    if ((![string isEqualToString:filtered]) || (newLength > CHARACTER_LIMIT)) {
        return NO;
    }

    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
    CGFloat newFloat = [newText floatValue];
    
    if (newFloat > 999999.0f) {
        return NO;
    }

    if (!IsEmpty(newText)) {
        if (textField == self.spentTextField) {
            self.spentCheckbox.isChecked = YES;
        }
        else if (textField == self.savedTextField) {
            self.savedCheckbox.isChecked = YES;
        }
    }
    
    return YES;
}


#pragma mark - UITextViewDelegate methods -
- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self.viewFields setContentOffset:CGPointMake(0.0f, -64.0f) animated:YES];
}


#pragma mark - Actions -
- (IBAction)didSelectSpent:(MICheckBox *)sender
{
    if (sender.isChecked) {
        self.spentTextField.text = @"";
    }
    else {
        [self.spentTextField becomeFirstResponder];
    }
    
    if (self.notSureCheckbox.isChecked) {
        self.notSureCheckbox.isChecked = NO;
    }
}

- (IBAction)didSelectSaved:(MICheckBox *)sender
{
    if (sender.isChecked) {
        self.savedTextField.text = @"";
    }
    else {
        [self.savedTextField becomeFirstResponder];
    }

    
    if (self.notSureCheckbox.isChecked) {
        self.notSureCheckbox.isChecked = NO;
    }
}

- (IBAction)didSelectNotSure:(id)sender
{
    if (self.spentCheckbox.isChecked) {
        self.spentCheckbox.isChecked = NO;
    }
    if (self.savedCheckbox.isChecked) {
        self.savedCheckbox.isChecked = NO;
    }

    [self.spentTextField resignFirstResponder];
    [self.savedTextField resignFirstResponder];
    
    self.spentTextField.text = @"";
    self.savedTextField.text = @"";
}

- (IBAction)doneAction:(id)sender
{
    [self dismissKeyboard];
    self.spentDoneButton.hidden = YES;
}


@end
