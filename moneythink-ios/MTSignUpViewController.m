//
//  MTSignUpViewController.m
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "MTSignUpViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+Palette.h"

@interface MTSignUpViewController ()

@end

@implementation MTSignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];

    self.view.backgroundColor = [UIColor primaryGreen];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - IBActions


- (IBAction)tappedAgreeButton:(id)sender {
    
}

- (IBAction)tappedUseStageButton:(id)sender {
    
}

- (IBAction)tappedSignUpButton:(id)sender {
//    PFSignupCodes *validCode = [PFSignupCodes validSignUpCode:self.registrationCode.text];
//    
//    if (validCode) {
//        PFUser *user = [PFUser user];
//        user.username = @"jdburgie@gmail.com";
//        user.password = @"my pass";
//        user.email = @"jdburgie@gmail.com";
//        
//            // other fields can be set just like with PFObject
//        user[@"phone"] = @"415-392-0202";
//        
//        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
//            if (!error) {
//                    // Hooray! Let them use the app now.
//            } else {
//                NSString *errorString = [error userInfo][@"error"];
//                    // Show the errorString somewhere and let the user try again.
//            }
////        }];
//    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}


@end
