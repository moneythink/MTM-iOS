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
    
    self.useStageCheckbox =[[MICheckBox alloc]initWithFrame:self.useStageButton.frame];
	[self.useStageCheckbox setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self.useStageCheckbox setTitle:@"" forState:UIControlStateNormal];
	[self.viewFields addSubview:self.useStageCheckbox];
    
    self.useStageButton.hidden = YES;
    self.view.backgroundColor = [UIColor white];

    UIImage *logoImage = [UIImage imageNamed:@"logo_actionbar_medium"];
    UIButton *logoButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, logoImage.size.width, logoImage.size.height)];
    
    [logoButton setBackgroundImage:logoImage forState:UIControlStateNormal];
    [logoButton setBackgroundImage:logoImage forState:UIControlStateHighlighted];
        
    [logoButton addTarget:self action:@selector(touchLogoButton) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *barButtonLogo = [[UIBarButtonItem alloc] initWithCustomView:logoButton];

    self.navigationItem.leftBarButtonItem = barButtonLogo;

    self.navigationItem.hidesBackButton = NO;
}

- (IBAction)touchLogoButton
{
    [self performSegueWithIdentifier:@"unwindToSignUpLogin" sender:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)loginTapped:(id)sender {
    if ([self.useStageCheckbox isChecked]) {
        NSString *applicationID = @"OFZ4TDvgCYnu40A5bKIui53PwO43Z2x5CgUKJRWz";
        NSString *clientKey = @"2OBw9Ggbl5p0gJ0o6Y7n8rK7gxhFTGcRQAXH6AuM";
        
        [Parse setApplicationId:applicationID
                      clientKey:clientKey];
    }

    PFUser *user = [PFUser user];
    
    user.username = self.email.text;
    user.password = self.password.text;
    
    [PFUser logInWithUsernameInBackground:self.email.text password:self.password.text block:^(PFUser *user, NSError *error) {
        NSString *errorString = [error userInfo][@"error"];

        if (!error) {
            if ([[[PFUser currentUser] valueForKey:@"type"] isEqualToString:@"student"]) {
                [self performSegueWithIdentifier:@"studentLoggedIn" sender:self];
            } else {
                [self performSegueWithIdentifier:@"mentoroggedIn" sender:self];
            }
        } else {
            self.error.text = errorString;
            [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Please agree to Terms & Conditions before signing up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
    }];
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}


@end
