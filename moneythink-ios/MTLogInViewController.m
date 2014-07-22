//
//  MTLogInViewController.m
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "MTLogInViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface MTLogInViewController ()

@end

@implementation MTLogInViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.view.backgroundColor = [UIColor white];
    
    UIFont *fontRoboto = [UIFont fontWithName:@"Roboto-Thin" size:17.0f];
    
    self.email.font = fontRoboto;
    self.password.font = fontRoboto;
    
    fontRoboto = [UIFont fontWithName:@"Roboto-Thin" size:11.0f];
    self.error.textColor = [UIColor redColor];
    self.error.font = fontRoboto;

    self.cancelButton.hidden = YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)loginTapped:(id)sender {
    PFUser *user = [PFUser user];
    
    user.username = self.email.text;
    user.password = self.password.text;
    
    [PFUser logInWithUsernameInBackground:self.email.text password:self.password.text block:^(PFUser *user, NSError *error) {
        NSString *errorString = [error userInfo][@"error"];

        if (!error) {
            self.error.text = @"Logged in";
            self.error.textColor = [UIColor primaryOrange];
            
            [self.cancelButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        } else {
            self.error.text = errorString;
        }
    }];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}


@end
