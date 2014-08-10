//
//  MTSignUpOrSignInViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 8/9/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTSignUpOrSignInViewController.h"

@interface MTSignUpOrSignInViewController ()

@end

@implementation MTSignUpOrSignInViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([PFUser currentUser]) {
        PFUser *user = [PFUser currentUser];
        [PFCloud callFunctionInBackground:@"userLoggedIn" withParameters:@{@"user_id": [user objectId]} block:^(id object, NSError *error) {
            if (!error) {
                if ([[[PFUser currentUser] valueForKey:@"type"] isEqualToString:@"student"]) {
                    [self performSegueWithIdentifier:@"studentMain" sender:self];
                } else {
                    [self performSegueWithIdentifier:@"pushMentorNotificationView" sender:self];
                }
            } else {
                NSLog(@"error - %@", error);
            }
        }];
    } else {
        [self performSegueWithIdentifier:@"signUpSignIn" sender:self];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view setBackgroundColor:[UIColor primaryGreen]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
}

@end
