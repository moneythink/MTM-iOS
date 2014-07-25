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
        if ([[[PFUser currentUser] valueForKey:@"type"] isEqualToString:@"student"]) {
            [self performSegueWithIdentifier:@"studentMain" sender:self];
        } else {
            [self performSegueWithIdentifier:@"challengesView" sender:self];
        }
    } else {
        [self performSegueWithIdentifier:@"mtUserViewController" sender:self];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
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

- (IBAction)exitToHome:(UIStoryboardSegue *)sender
{
    NSLog(@"exitToHome");
}


@end
