//
//  OnboardingContentViewController.m
//  Onboard
//
//  Created by Mike on 8/17/14.
//  Copyright (c) 2014 Mike Amaral. All rights reserved.
//

#import "OnboardingContentViewController.h"
#import "OnboardingViewController.h"
#import <AVFoundation/AVFoundation.h>

static NSString * const kDefaultOnboardingFont = @"Helvetica-Light";

#define DEFAULT_TEXT_COLOR [UIColor whiteColor];

static CGFloat const kContentWidthMultiplier = 0.82;
static CGFloat const kDefaultImageViewSize = 100;
static CGFloat const kDefaultTopPadding = 60;
static CGFloat const kDefaultUnderIconPadding = 30;
static CGFloat const kDefaultUnderTitlePadding = 30;
static CGFloat const kDefaultBottomPadding = 0;
static CGFloat const kDefaultUnderPageControlPadding = 0;
static CGFloat const kDefaultTitleFontSize = 38;
static CGFloat const kDefaultBodyFontSize = 28;
static CGFloat const kDefaultButtonFontSize = 24;

static CGFloat const kActionButtonHeight = 50;
static CGFloat const kMainPageControlHeight = 35;

@interface OnboardingContentViewController () <UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, strong) UIButton *profileImageButton;
@property (nonatomic, strong) UIImage *profileImage;
@property (nonatomic, strong) UIButton *doLaterButton;
@property (nonatomic, strong) UIImageView *profileBackgroundImageView;

@end

@implementation OnboardingContentViewController

+ (instancetype)contentWithTitle:(NSString *)title body:(NSString *)body image:(UIImage *)image buttonText:(NSString *)buttonText action:(dispatch_block_t)action {
    OnboardingContentViewController *contentVC = [[self alloc] initWithTitle:title body:body image:image buttonText:buttonText action:action];
    return contentVC;
}

- (instancetype)initWithTitle:(NSString *)title body:(NSString *)body image:(UIImage *)image buttonText:(NSString *)buttonText action:(dispatch_block_t)action {
    self = [super init];

    // hold onto the passed in parameters, and set the action block to an empty block
    // in case we were passed nil, so we don't have to nil-check the block later before
    // calling
    _titleText = title;
    _body = body;
    _image = image;
    _buttonText = buttonText;

    self.buttonActionHandler = action;
    
    // default auto-navigation
    self.movesToNextViewController = NO;
    
    // default icon properties
    if(_image) {
		self.iconHeight = _image.size.height;
		self.iconWidth = _image.size.width;
	}
    
    else {
		self.iconHeight = kDefaultImageViewSize;
		self.iconWidth = kDefaultImageViewSize;
	}
    
    // default title properties
    self.titleFontName = kDefaultOnboardingFont;
    self.titleFontSize = kDefaultTitleFontSize;
    
    // default body properties
    self.bodyFontName = kDefaultOnboardingFont;
    self.bodyFontSize = kDefaultBodyFontSize;
    
    // default button properties
    self.buttonFontName = kDefaultOnboardingFont;
    self.buttonFontSize = kDefaultButtonFontSize;
    
    // default padding values
    self.topPadding = kDefaultTopPadding;
    self.underIconPadding = kDefaultUnderIconPadding;
    self.underTitlePadding = kDefaultUnderTitlePadding;
    self.bottomPadding = kDefaultBottomPadding;
    self.underPageControlPadding = kDefaultUnderPageControlPadding;
    
    // default colors
    self.titleTextColor = DEFAULT_TEXT_COLOR;
    self.bodyTextColor = DEFAULT_TEXT_COLOR;
    self.buttonTextColor = DEFAULT_TEXT_COLOR;
    
    // default blocks
    self.viewWillAppearBlock = ^{};
    self.viewDidAppearBlock = ^{};
    self.viewWillDisappearBlock = ^{};
    self.viewDidDisappearBlock = ^{};

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // now that the view has loaded we can generate the content
    [self generateView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // if we have a delegate set, mark ourselves as the next page now that we're
    // about to appear
    if (self.delegate) {
        [self.delegate setNextPage:self];
    }
    
    // call our view will appear block
    if (self.viewWillAppearBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.viewWillAppearBlock();
        });
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // if we have a delegate set, mark ourselves as the current page now that
    // we've appeared
    if (self.delegate) {
        [self.delegate setCurrentPage:self];
    }
    
    // call our view did appear block
    if (self.viewDidAppearBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.viewDidAppearBlock();
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    // call our view will disappear block
    if (self.viewWillDisappearBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.viewWillDisappearBlock();
        });
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    // call our view did disappear block
    if (self.viewDidDisappearBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.viewDidDisappearBlock();
        });
    }
}

- (void)setButtonActionHandler:(dispatch_block_t)action {
    _buttonActionHandler = action ?: ^{};
}

- (void)generateView {
    // we want our background to be clear so we can see through it to the image provided
    self.view.backgroundColor = [UIColor clearColor];
    
    // do some calculation for some common values we'll need, namely the width of the view,
    // the center of the width, and the content width we want to fill up, which is some
    // fraction of the view width we set in the multipler constant
    CGFloat viewWidth = CGRectGetWidth(self.view.frame);
    CGFloat horizontalCenter = viewWidth / 2;
    CGFloat contentWidth = viewWidth * kContentWidthMultiplier;
    
    // create the image view with the appropriate image, size, and center in on screen
    _imageView = [[UIImageView alloc] initWithImage:_image];
    [_imageView setFrame:CGRectMake(horizontalCenter - (self.iconWidth / 2), self.topPadding, self.iconWidth, self.iconHeight)];
    
    [_imageView setFrame:self.view.frame];
    _imageView.contentMode = UIViewContentModeTop;
    [self.view addSubview:_imageView];
    
    // create and configure the main text label sitting underneath the icon with the provided padding
    _mainTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_imageView.frame) + self.underIconPadding, contentWidth, 0)];
    _mainTextLabel.text = _titleText;
    _mainTextLabel.textColor = self.titleTextColor;
    _mainTextLabel.font = [UIFont fontWithName:self.titleFontName size:self.titleFontSize];
    _mainTextLabel.numberOfLines = 0;
    _mainTextLabel.textAlignment = NSTextAlignmentCenter;
    [_mainTextLabel sizeToFit];
    _mainTextLabel.center = CGPointMake(horizontalCenter, _mainTextLabel.center.y);
    [self.view addSubview:_mainTextLabel];
    
    // create and configure the sub text label
    _subTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_mainTextLabel.frame) + self.underTitlePadding, contentWidth, 0)];
    _subTextLabel.text = _body;
    _subTextLabel.textColor = self.bodyTextColor;
    _subTextLabel.font = [UIFont fontWithName:self.bodyFontName size:self.bodyFontSize];
    _subTextLabel.numberOfLines = 0;
    _subTextLabel.textAlignment = NSTextAlignmentCenter;
    [_subTextLabel sizeToFit];
    _subTextLabel.center = CGPointMake(horizontalCenter, _subTextLabel.center.y);
    [self.view addSubview:_subTextLabel];
    
    // create the action button if we were given button text
    if (_buttonText) {
        _actionButton = [[UIButton alloc] initWithFrame:CGRectMake((CGRectGetMaxX(self.view.frame) / 2) - (contentWidth / 2), CGRectGetMaxY(self.view.frame) - self.underPageControlPadding - kMainPageControlHeight - kActionButtonHeight - self.bottomPadding, contentWidth, kActionButtonHeight)];
        _actionButton.titleLabel.font = [UIFont fontWithName:self.buttonFontName size:self.buttonFontSize];
        [_actionButton setTitle:_buttonText forState:UIControlStateNormal];
        [_actionButton setTitleColor:self.buttonTextColor forState:UIControlStateNormal];
        [_actionButton setTitleColor:[UIColor darkerColorForColor:self.buttonTextColor] forState:UIControlStateHighlighted];

        [_actionButton addTarget:self action:@selector(handleButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [_actionButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithWhite:0.0f alpha:0.65f] size:_actionButton.frame.size] forState:UIControlStateNormal];
        [_actionButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithWhite:0.0f alpha:0.9f] size:_actionButton.frame.size] forState:UIControlStateHighlighted];
        _actionButton.layer.cornerRadius = 5.0f;
        _actionButton.layer.masksToBounds = YES;
        [self.view addSubview:_actionButton];
    }
    
    // Add profile image picker button
    if (self.hasProfileImagePickerButton) {
        CGRect photoFrame = CGRectMake((self.view.frame.size.width-230.0f)/2.0f, self.view.frame.size.height-230.0f-self.underProfileImagePickerPadding, 230.0f, 230.0f);
        self.profileBackgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"onboarding_profile_placeholder"]];
        self.profileBackgroundImageView.frame = photoFrame;
        self.profileBackgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.view addSubview:self.profileBackgroundImageView];
        
        self.profileImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [[self.profileImageButton imageView] setContentMode: UIViewContentModeScaleAspectFill];

        self.profileImageButton.frame = photoFrame;
        [self.profileImageButton setImage:nil forState:UIControlStateNormal];
        [self.profileImageButton setImage:[UIImage imageWithColor:[UIColor colorWithWhite:0.0f alpha:0.2f] size:self.profileImageButton.frame.size] forState:UIControlStateHighlighted];
        [self.profileImageButton addTarget:self action:@selector(profileImageButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.profileImageButton];
    }
    
    if (self.hasDoLaterButton) {
        self.doLaterButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.doLaterButton.frame = CGRectMake(0.0f, self.view.frame.size.height - 40.0f, self.view.frame.size.width, 20.0f);
        NSString *theMessage = @"Do This Later";
        NSMutableAttributedString *theAttributedTitle = [[NSMutableAttributedString alloc] initWithString:theMessage];
        [theAttributedTitle addAttribute:NSFontAttributeName value:[UIFont mtFontOfSize:11.0f] range:[theMessage rangeOfString:theMessage]];
        [theAttributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:[theMessage rangeOfString:theMessage]];
        [theAttributedTitle addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:[theMessage rangeOfString:theMessage]];
        [self.doLaterButton setAttributedTitle:theAttributedTitle forState:UIControlStateNormal];
        
        NSMutableAttributedString *theHighlightedAttributedTitle = [[NSMutableAttributedString alloc] initWithString:theMessage];
        [theHighlightedAttributedTitle addAttribute:NSFontAttributeName value:[UIFont mtFontOfSize:11.0f] range:[theMessage rangeOfString:theMessage]];
        [theHighlightedAttributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:[theMessage rangeOfString:theMessage]];
        [theHighlightedAttributedTitle addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:[theMessage rangeOfString:theMessage]];
        [self.doLaterButton setAttributedTitle:theHighlightedAttributedTitle forState:UIControlStateHighlighted];
        
        [self.doLaterButton addTarget:self action:@selector(handleButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.doLaterButton];
    }
}


#pragma mark - Transition alpha

- (void)updateAlphas:(CGFloat)newAlpha {
    _imageView.alpha = newAlpha;
    _mainTextLabel.alpha = newAlpha;
    _subTextLabel.alpha = newAlpha;
    _actionButton.alpha = newAlpha;
}


#pragma mark - action button callback

- (void)handleButtonPressed {
    // if we want to navigate to the next view controller, tell our delegate
    // to handle it
    if (self.movesToNextViewController) {
        [self.delegate moveNextPage];
    }
    
    // call the provided action handler
    if (_buttonActionHandler) {
        _buttonActionHandler();
    }
}


#pragma mark - Profile Photo Methods -
- (void)setProfileImageFile:(PFFile *)profileImageFile
{
    self.profileFile = profileImageFile;
    
    MTMakeWeakSelf();
    [profileImageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage *profileImage = [UIImage imageWithData:data];

                [UIView animateWithDuration:0.2f animations:^{
                    weakSelf.profileImageButton.alpha = 0.0f;
                } completion:^(BOOL finished) {
                    [weakSelf.profileImageButton setImage:profileImage forState:UIControlStateNormal];
                    [weakSelf.profileImageButton setImage:nil forState:UIControlStateHighlighted];

                    [UIView animateWithDuration:0.2f animations:^{
                        weakSelf.profileImageButton.alpha = 1.0f;
                    }];
                }];
            });
        }
    }];
}

- (void)profileImageButtonAction
{    
    if ([UIAlertController class]) {
        UIAlertController *editProfileImage = [UIAlertController
                                               alertControllerWithTitle:@""
                                               message:@"Add Profile Picture"
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
        
        if (self.profileFile) {
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
        
        if (self.profileFile) {
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
    self.profileFile = nil;
    self.profileImage = nil;
    
    [UIView animateWithDuration:0.2f animations:^{
        self.profileImageButton.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self.profileImageButton setImage:nil forState:UIControlStateNormal];
        [self.profileImageButton setImage:[UIImage imageWithColor:[UIColor colorWithWhite:0.0f alpha:0.2f] size:self.profileImageButton.frame.size] forState:UIControlStateHighlighted];

        [UIView animateWithDuration:0.2f animations:^{
            self.profileImageButton.alpha = 1.0f;
        } completion:^(BOOL finished) {
            [self saveUserPhoto];
        }];
    }];
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    imagePickerController.allowsEditing = YES;
    
    [self presentViewController:imagePickerController animated:YES completion:nil];
}

- (void)saveUserPhoto
{
    PFUser *currentUser = [PFUser currentUser];
    
    if (self.profileImage) {
        NSString *fileName = @"profile_image.png";
        NSData *imageData = UIImageJPEGRepresentation(self.profileImage, 0.8f);
        PFFile *file = [PFFile fileWithName:fileName data:imageData];

        if (file) {
            self.profileFile = file;
            currentUser[@"profile_picture"] = file;
        }
    }
    else {
        self.profileFile = nil;
        if ([currentUser objectForKey:@"profile_picture"]) {
            [currentUser removeObjectForKey:@"profile_picture"];
        }
    }
    
    [currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [UIAlertView bk_showAlertViewWithTitle:@"Unable to Save Changes" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            NSLog(@"error - %@", error);
        }
    }];
    
    if (self.movesToNextViewController) {
        [self.delegate moveNextPage];
    }
}


#pragma mark - UIActionSheetDelegate methods -
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex  // after animation
{
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


#pragma mark - UIImagePickerControllerDelegate methods -
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    if ([info objectForKey:UIImagePickerControllerEditedImage]) {
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    }
    
    CGFloat maxSize = 480.0f;
    if (image.size.width > maxSize) {
        CGFloat scale = maxSize / image.size.width;
        CGFloat heightNew = scale * image.size.height;
        CGSize sizeNew = CGSizeMake(maxSize, heightNew);
        UIGraphicsBeginImageContext(sizeNew);
        [image drawInRect:CGRectMake(0,0,sizeNew.width,sizeNew.height)];
        UIGraphicsEndImageContext();
    }
    
    self.profileImage = image;
    [self saveUserPhoto];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}


@end
