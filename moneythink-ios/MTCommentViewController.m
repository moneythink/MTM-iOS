//
//  MTCommentViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTCommentViewController.h"
#import "MTMyClassTableViewController.h"

#define NUMBERS_ONLY @"1234567890."
#define CHARACTER_LIMIT 9

@interface MTCommentViewController ()

@property (nonatomic, strong) IBOutlet UITextView *postText;
@property (nonatomic, strong) IBOutlet UIScrollView *viewFields;
@property (nonatomic, strong) IBOutlet UIButton *chooseImageButton;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UIButton *doneButton;
@property (nonatomic, strong) IBOutlet UILabel *chooseImageLabel;
@property (nonatomic, strong) IBOutlet UIView *spentView;
@property (nonatomic, strong) IBOutlet UITextField *spentTextField;
@property (nonatomic, strong) IBOutlet UITextField *savedTextField;
@property (nonatomic, strong) IBOutlet MICheckBox *spentCheckbox;
@property (nonatomic, strong) IBOutlet MICheckBox *savedCheckbox;
@property (nonatomic, strong) IBOutlet MICheckBox *notSureCheckbox;
@property (nonatomic, strong) IBOutlet UIButton *spentDoneButton;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) PFImageView *postImage;
@property (nonatomic, strong) PFChallengePost *challengePost;
@property (nonatomic, strong) UIImage *updatedPostImage;
@property (nonatomic) BOOL removedPostPhoto;
@property (nonatomic) BOOL displaySpentView;

@end

@implementation MTCommentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.displaySpentView = [self.challenge[@"display_extra_fields"] boolValue];
    self.spentDoneButton.hidden = YES;
    
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
    if (!IsEmpty(self.post[@"extra_fields"])) {
        NSData *data = [self.post[@"extra_fields"] dataUsingEncoding:NSUTF8StringEncoding];
        id jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];

        if ([jsonArray isKindOfClass:[NSArray class]]) {
            NSArray *spentFieldsArray = (NSArray *)jsonArray;
            for (id thisDict in spentFieldsArray) {
                if ([thisDict isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *dict = (NSDictionary *)thisDict;
                    NSString *nameForDict = [dict objectForKey:@"name"];
                    
                    if ([nameForDict isEqualToString:@"Spent"]) {
                        self.spentCheckbox.isChecked = [[dict objectForKey:@"checked"] boolValue];
                        if (self.spentCheckbox.isChecked) {
                            NSString *spentString = [[dict objectForKey:@"value"] stringValue];
                            self.spentTextField.text = [self currencyTextForString:spentString];
                            if (IsEmpty(self.spentTextField.text)) {
                                self.spentCheckbox.isChecked = NO;
                            }
                        }
                    }
                    else if ([nameForDict isEqualToString:@"Saved"]) {
                        self.savedCheckbox.isChecked = [[dict objectForKey:@"checked"] boolValue];
                        if (self.savedCheckbox.isChecked) {
                            NSString *spentString = [[dict objectForKey:@"value"] stringValue];
                            self.savedTextField.text = [self currencyTextForString:spentString];
                            if (IsEmpty(self.savedTextField.text)) {
                                self.savedCheckbox.isChecked = NO;
                            }
                        }
                    }
                    else {
                        self.notSureCheckbox.isChecked = [[dict objectForKey:@"checked"] boolValue];
                        if (self.notSureCheckbox.isChecked) {
                            self.spentCheckbox.isChecked = NO;
                            self.spentTextField.text = @"";
                            self.savedCheckbox.isChecked = NO;
                            self.savedTextField.text = @"";
                        }
                    }
                }
            }
        }
    }
}

- (NSString *)jsonStringFromSpentFields
{
    NSString *jsonString = nil;
    NSMutableArray *myArray = [NSMutableArray array];
    
    NSDictionary *spentDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0.0f], @"value", @NO, @"checked", @"Spent", @"name", nil];
    NSDictionary *savedDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0.0f], @"value", @NO, @"checked", @"Saved", @"name", nil];
    NSDictionary *notSureDict;

    if (self.notSureCheckbox.isChecked) {
        notSureDict = [NSDictionary dictionaryWithObjectsAndKeys:@YES, @"checked", @"I'm not sure", @"name", nil];
    }
    else {
        notSureDict = [NSDictionary dictionaryWithObjectsAndKeys:@NO, @"checked", @"I'm not sure", @"name", nil];
        
        if (!IsEmpty(self.spentTextField.text)) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            NSNumber *number = [formatter numberFromString:self.spentTextField.text];
            NSNumberFormatter *formatterOut = [[NSNumberFormatter alloc] init];
            [formatterOut setNumberStyle:NSNumberFormatterDecimalStyle];
            [formatterOut setUsesGroupingSeparator:NO];
            
            NSString *amountSpent = [formatterOut stringFromNumber:number];
            spentDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:[amountSpent floatValue]], @"value", @YES, @"checked", @"Spent", @"name", nil];
        }
        
        if (!IsEmpty(self.savedTextField.text)) {
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setNumberStyle:NSNumberFormatterCurrencyStyle];
            NSNumber *number = [formatter numberFromString:self.savedTextField.text];
            NSNumberFormatter *formatterOut = [[NSNumberFormatter alloc] init];
            [formatterOut setNumberStyle:NSNumberFormatterDecimalStyle];
            [formatterOut setUsesGroupingSeparator:NO];
            
            NSString *amountSaved = [formatterOut stringFromNumber:number];
            savedDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:[amountSaved floatValue]], @"value", @YES, @"checked", @"Saved", @"name", nil];
        }
    }
    
    [myArray addObject:spentDict];
    [myArray addObject:savedDict];
    [myArray addObject:notSureDict];
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:myArray options:0 error:&error];
    jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return jsonString;
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
    
    if (self.displaySpentView) {
        self.post[@"extra_fields"] = [self jsonStringFromSpentFields];
    }
    
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
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidSaveEditPostNotification object:weakSelf.post];
                });
            }
            else {
                NSLog(@"Post Edit Save with picture error - %@", error);
                [weakSelf.post saveEventually];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kFailedSaveEditPostNotification object:weakSelf];
                });
            }
        }];
    }
    else {
        if (self.removedPostPhoto) {
            [self.post removeObjectForKey:@"picture"];
        }

        [[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveEditPostNotification object:self.post];
        
        __block PFChallengePost *weakPost = self.post;
        
        MTMakeWeakSelf();
        [self.post saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                [[PFUser currentUser] fetchInBackground];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidSaveEditPostNotification object:weakPost];
                });
            }
            else {
                NSLog(@"Post Edit Save error - %@", error);
                [weakSelf.challengePost saveEventually];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kFailedSaveEditPostNotification object:weakSelf];
                });
            }
        }];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}


#pragma mark - New Post Method -
- (void)saveNew
{
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
    
    if (![MTUtil internetReachable]) {
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
    
    if (self.displaySpentView) {
        self.challengePost[@"extra_fields"] = [self jsonStringFromSpentFields];
    }
    
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
                [self.challengePost saveEventually];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kFailedMyClassChallengePostsdNotification object:self];
                });
            }
        }];
    }
    
    [self performSegueWithIdentifier:@"unwindToChallengeRoom" sender:nil];
}


#pragma mark - New Comment on Post Method -
- (IBAction)postCommentDone:(id)sender
{
    if (![self.postText.text isEqualToString:@""]) {
        if (![MTUtil internetReachable]) {
            [UIAlertView showNoInternetAlert];
            return;
        }

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Posting Comment...";
        hud.dimBackground = YES;

        self.challengePostComment = [[PFChallengePostComment alloc] initWithClassName:[PFChallengePostComment parseClassName]];
        self.challengePostComment[@"challenge_post"] = self.post;
        self.challengePostComment[@"comment_text"] = self.postText.text;
        self.challengePostComment[@"school"] = [PFUser currentUser][@"school"];
        self.challengePostComment[@"class"] = [PFUser currentUser][@"class"];
        self.challengePostComment[@"user"] = [PFUser currentUser];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveNewPostCommentNotification object:nil];
        
        MTMakeWeakSelf();
        [self.challengePostComment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kDidSaveNewPostCommentNotification object:nil];
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            });

            if (!error) {
                [[PFUser currentUser] fetchInBackground];
            }
            else {
                NSLog(@"Post text comment error - %@", error);
                [weakSelf.challengePostComment saveEventually];
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
    
    [self jsonStringFromSpentFields];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;   // return NO to not change text
{
    if ([textField.text containsString:@"."] && [string containsString:@"."]) {
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
    
    [self jsonStringFromSpentFields];
}

- (IBAction)doneAction:(id)sender
{
    [self dismissKeyboard];
    self.spentDoneButton.hidden = YES;
}


@end
