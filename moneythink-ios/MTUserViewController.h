//
//  MTUserViewController.h
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTUserViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *studentSignUpButton;
@property (strong, nonatomic) IBOutlet UIButton *mentorSignUpButton;
@property (strong, nonatomic) IBOutlet UIButton *loginButton;


- (IBAction)studentSignUpTapped:(id)sender;
- (IBAction)mentorSignUpTapped:(id)sender;
- (IBAction)loginTapped:(id)sender;

@property (strong, nonatomic) IBOutlet UIButton *cancelButton;

@end
