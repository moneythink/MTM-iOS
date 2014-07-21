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
    
    self.view.backgroundColor = [UIColor white];
    self.signUpTitleLabel.text = self.signUpTitle;
    
    /*
     Roboto-Thin
     Roboto-Italic
     Roboto-BlackItalic
     Roboto-Light
     Roboto-BoldItalic
     Roboto-LightItalic
     Roboto-ThinItalic
     Roboto-Black
     Roboto-Bold
     Roboto-Regular
     Roboto-Medium
     Roboto-MediumItalic
     */
    
    UIFont *fontRoboto = [UIFont fontWithName:@"Roboto-Thin" size:17.0f];
    
    self.firstName.font = fontRoboto;
    self.lastName.font = fontRoboto;
    self.email.font = fontRoboto;
    self.password.font = fontRoboto;
    self.registrationCode.font = fontRoboto;

    fontRoboto = [UIFont fontWithName:@"Roboto-Thin" size:11.0f];
    self.error.textColor = [UIColor redColor];
    self.error.font = fontRoboto;

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - IBActions


- (IBAction)tappedAgreeButton:(id)sender { }

- (IBAction)tappedUseStageButton:(id)sender { }

- (IBAction)tappedSignUpButton:(id)sender {
    
    NSPredicate *codePredicate = [NSPredicate predicateWithFormat:@"code = %@ AND type = %@", @"student4", @"student"];
//    NSPredicate *codePredicate = [NSPredicate predicateWithFormat:@"code = %@ AND type = %@", self.registrationCode.text, self.signUpType];
    
    PFQuery *findCode = [PFQuery queryWithClassName:[PFSignupCodes parseClassName] predicate:codePredicate];
    
    [findCode findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSArray *codes = objects;
            
            if ([codes count] == 1) {
                PFSignupCodes *code = [codes firstObject];
                
                PFUser *user = [PFUser user];
                
                user.username = self.email.text;
                user.password = self.password.text;
                user.email = self.email.text;
                
                    // other fields can be set just like with PFObject
                user[@"first_name"] = self.firstName.text;
                user[@"last_name"] = self.lastName.text;
                
                NSString *aString = (NSString *)[code valueForUndefinedKey:@"class"];
                user[@"class"] = aString;
                
                aString = (NSString *)[code valueForUndefinedKey:@"school"];
                user[@"school"] = aString;
                
                [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error) {
                            // Hooray! Let them use the app now.
                        NSLog(@"errorString - nil");
                        [self dismissViewControllerAnimated:YES completion:nil];
                    } else {
                        NSString *errorString = [error userInfo][@"error"];
                        NSLog(@"errorString - %@", errorString);
                            // Show the errorString somewhere and let the user try again.
                        self.error.text = errorString;
//                        [self.view setNeedsLayout];
                    }
                }];
            } else {
                
            }
        } else {
            NSLog(@"error");
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    
//    PFSignupCodes *validCode = [PFSignupCodes validSignUpCode:@"student4" type:@"student"];
//    if (validCode) {
//    }
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}


- (IBAction)tappedCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
