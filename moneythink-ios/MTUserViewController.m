//
//  MTUserViewController.m
//  LogInAndSignUpDemo
//
//  Created by Mattieu Gamache-Asselin on 6/15/12.
//  Copyright (c) 2013 Parse. All rights reserved.
//

#import "MTUserViewController.h"
#import "MTLogInViewController.h"
#import "MTSignUpViewController.h"

@interface MTUserViewController ()

@end

@implementation MTUserViewController

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([PFUser currentUser]) {
        NSLog(@"Logged in");
    } else {
        NSLog(@"Not logged in");
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
        // Check if user is logged in
    if ([PFUser currentUser]) {
        // go into classes
//    } else {
//            // Customize the Log In View Controller
//        MTLogInViewController *logInViewController = [[MTLogInViewController alloc] init];
//        logInViewController.delegate = self;
//        logInViewController.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsDismissButton;
//
//            // Customize the Sign Up View Controller
//        MTSignUpViewController *signUpViewController = [[MTSignUpViewController alloc] init];
//        signUpViewController.delegate = self;
//        signUpViewController.fields = PFSignUpFieldsDefault | PFSignUpFieldsAdditional;
//        logInViewController.signUpController = signUpViewController;
//
//            // Present Log In View Controller
//        [self presentViewController:logInViewController animated:YES completion:NULL];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
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

#pragma mark - IBActions


- (IBAction)studentSignUpTapped:(id)sender {
    NSLog(@"studentSignUpTapped");
}

- (IBAction)mentorSignUpTapped:(id)sender {
    NSLog(@"mentorSignUpTapped");
}

- (IBAction)loginTapped:(id)sender {
    MTLogInViewController *logInViewController = [[MTLogInViewController alloc] init];
    
    logInViewController.view.backgroundColor = [UIColor primaryGreen];
    
        // Present the log in view controller
    [self presentViewController:logInViewController animated:YES completion:NULL];
}

@end
