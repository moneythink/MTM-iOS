//
//  MTSignUpViewController.h
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

@interface MTSignUpViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *view;

@property (strong, nonatomic) NSString *signUpTitle;
@property (strong, nonatomic) NSString *signUpType;

@property (strong, nonatomic) IBOutlet UILabel *signUpTitleLabel;

@property (strong, nonatomic) IBOutlet UITextField *firstName;
@property (strong, nonatomic) IBOutlet UITextField *lastName;
@property (strong, nonatomic) IBOutlet UITextField *email;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UITextField *registrationCode;
@property (strong, nonatomic) IBOutlet UITextField *error;

@property (strong, nonatomic) IBOutlet UISwitch *agreeButton;
@property (strong, nonatomic) IBOutlet UIButton *signUpButton;

@end
