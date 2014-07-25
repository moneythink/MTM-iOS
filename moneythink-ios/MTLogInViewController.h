//
//  MTLogInViewController.h
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "MICheckBox.h"

@interface MTLogInViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *view;
@property (strong, nonatomic) IBOutlet UIScrollView *viewFields;

@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UITextField *password;

@property (strong, nonatomic) IBOutlet UITextField *error;

@property (strong, nonatomic) IBOutlet UIButton *useStageButton;
@property (strong, nonatomic) IBOutlet MICheckBox *useStageCheckbox;

@property (strong, nonatomic) IBOutlet UIButton *loginButton;

@end
