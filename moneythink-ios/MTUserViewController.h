//
//  MTUserViewController.h
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTLogInViewController.h"
#import "MTSignUpViewController.h"
#import "MTStudentTabBarViewController.h"
#import "MBProgressHUD.h"

@interface MTUserViewController : UIViewController <UINavigationControllerDelegate>

@property (strong, nonatomic) MTSignUpViewController *signUpViewController;

@end
