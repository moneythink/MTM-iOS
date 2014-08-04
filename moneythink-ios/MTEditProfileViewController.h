//
//  MTEditProfileViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/25/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MTEditProfileViewController;

@protocol MTEditProfileViewControllerDelegate <NSObject>

- (void)editProfileViewControllerDidSave:(MTEditProfileViewController *)editProfileViewController;

@end

@interface MTEditProfileViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UITextInputDelegate, UIActionSheetDelegate>

@property (nonatomic, weak) id <MTEditProfileViewControllerDelegate> delegate;

@end

