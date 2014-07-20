    //
    //  MTHomeViewController.m
    //  moneythink-ios
    //
    //  Created by jdburgie on 7/10/14.
    //  Copyright (c) 2014 Moneythink. All rights reserved.
    //

#import "MTHomeViewController.h"
#import "MTUserViewController.h"
#import "MTLogInViewController.h"
#import "MTSignUpViewController.h"

@interface MTHomeViewController ()

@end

@implementation MTHomeViewController

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
    
    if ([PFUser currentUser]) { // Check if user is logged in
            // Go into classes
    } else {
            // Go to Login/SignUp View
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    if ([PFUser currentUser]) {
//        [self performSegueWithIdentifier:@"challengesView" sender:self];
//    } else {
//        [self performSegueWithIdentifier:@"mtUserViewController" sender:self];
//    }
    
    [self.view setBackgroundColor:[UIColor lightGrey]];
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

- (IBAction)exitToHome:(UIStoryboardSegue *)sender
{
    NSLog(@"foo");
}


@end
