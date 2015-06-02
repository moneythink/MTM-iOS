//
//  MTSignUpViewController.h
//  moneythink-ios
//
//  Created by dsica on 5/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MICheckBox.h"

@interface MTSignUpViewController : UIViewController <UIActionSheetDelegate, UITextFieldDelegate, UIScrollViewDelegate>

@property (strong, nonatomic) NSString *signUpTitle;
@property (strong, nonatomic) NSString *signUpType;

@end
