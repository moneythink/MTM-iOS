//
//  OnboardingContentViewController.h
//  Onboard
//
//  Created by Mike on 8/17/14.
//  Copyright (c) 2014 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OnboardingViewController;

@interface OnboardingContentViewController : UIViewController {
    NSString *_titleText;
    NSString *_body;
    UIImage *_image;
    NSString *_buttonText;
    
    UIImageView *_imageView;
    UILabel *_mainTextLabel;
    UILabel *_subTextLabel;
    UIButton *_actionButton;
}

@property (nonatomic) OnboardingViewController *delegate;

@property (nonatomic) BOOL movesToNextViewController;

@property (nonatomic) CGFloat iconHeight;
@property (nonatomic) CGFloat iconWidth;

@property (nonatomic, strong) UIColor *titleTextColor;
@property (nonatomic, strong) UIColor *bodyTextColor;
@property (nonatomic, strong) UIColor *buttonTextColor;

@property (nonatomic, strong) NSString *titleFontName;
@property (nonatomic) CGFloat titleFontSize;

@property (nonatomic, strong) NSString *bodyFontName;
@property (nonatomic) CGFloat bodyFontSize;

@property (nonatomic, strong) NSString *buttonFontName;
@property (nonatomic) CGFloat buttonFontSize;

@property (nonatomic) CGFloat topPadding;
@property (nonatomic) CGFloat underIconPadding;
@property (nonatomic) CGFloat underTitlePadding;
@property (nonatomic) CGFloat bottomPadding;
@property (nonatomic) CGFloat underPageControlPadding;
@property (nonatomic) CGFloat underProfileImagePickerPadding;
@property (nonatomic) BOOL hasProfileImagePickerButton;
@property (nonatomic) BOOL hasDoLaterButton;
@property (nonatomic, strong) PFFile *profileFile;
@property (nonatomic, strong) UIImage *profileImage;
@property (nonatomic, strong) UIButton *profileImageButton;
@property (nonatomic) BOOL changedProfileImage;

@property (nonatomic, copy) dispatch_block_t buttonActionHandler;

@property (nonatomic, copy) dispatch_block_t viewWillAppearBlock;
@property (nonatomic, copy) dispatch_block_t viewDidAppearBlock;
@property (nonatomic, copy) dispatch_block_t viewWillDisappearBlock;
@property (nonatomic, copy) dispatch_block_t viewDidDisappearBlock;

+ (instancetype)contentWithTitle:(NSString *)title body:(NSString *)body image:(UIImage *)image buttonText:(NSString *)buttonText action:(dispatch_block_t)action;
- (instancetype)initWithTitle:(NSString *)title body:(NSString *)body image:(UIImage *)image buttonText:(NSString *)buttonText action:(dispatch_block_t)action;

- (void)updateAlphas:(CGFloat)newAlpha;
- (void)setProfileImageFile:(PFFile *)profileImageFile;

@end
