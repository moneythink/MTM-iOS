//
//  MTSignUpViewController.h
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "MICheckBox.h"

@interface MTSignUpViewController : UIViewController <UIActionSheetDelegate, UITextFieldDelegate>

@property (strong, nonatomic) NSString *signUpTitle;
@property (strong, nonatomic) NSString *signUpType;

@end
