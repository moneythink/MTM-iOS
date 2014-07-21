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

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];

//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
//    label.textAlignment = NSTextAlignmentCenter;
//    label.text = @"Using Custom Fonts";
    
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
    
    [self.view setBackgroundColor:[UIColor primaryGreen]];
    
    [self.studentSignUpButton setTitle:@"SIGN UP AS STUDENT" forState:UIControlStateNormal];
    [self.mentorSignUpButton setTitle:@"SIGN UP AS MENTOR" forState:UIControlStateNormal];
    [self.loginButton setTitle:@"LOGIN" forState:UIControlStateNormal];
    
    
    UIFont *fontRoboto = [UIFont fontWithName:@"Roboto-Black" size:18.0f];

    self.studentSignUpButton.titleLabel.font = fontRoboto;
    self.mentorSignUpButton.titleLabel.font = fontRoboto;
    self.loginButton.titleLabel.font = fontRoboto;
    
    
    CGFloat radius = 4.0f;

    self.studentSignUpButton.layer.cornerRadius = radius;
    self.mentorSignUpButton.layer.cornerRadius = radius;
    self.loginButton.layer.cornerRadius = radius;
    
    
    [self.studentSignUpButton setBackgroundColor:[UIColor mutedOrange]];
    [self.mentorSignUpButton setBackgroundColor:[UIColor mutedGreen]];
    [self.loginButton setBackgroundColor:[UIColor primaryGreen]];
    
    
    [self.studentSignUpButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
    [self.mentorSignUpButton setTitleColor:[UIColor white] forState:UIControlStateNormal];
    [self.loginButton setTitleColor:[UIColor white] forState:UIControlStateNormal];

    self.navigationItem.hidesBackButton = YES;
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
//    [self presented]
    UIButton *senderButton = sender;
    NSString *titleLabel = senderButton.titleLabel.text;
    NSString *segueID = [segue identifier];
    
    MTSignUpViewController *signUpViewController = (MTSignUpViewController *)segue.destinationViewController;
    
    if ([segueID isEqualToString:@"studentSignUp"]) {
        signUpViewController.signUpTitle = @"Student Signup";
        signUpViewController.signUpType = @"student";
    } else if ([segueID isEqualToString:@"mentorSignUp"]) {
        signUpViewController.signUpTitle = @"Mentor Signup";
        signUpViewController.signUpType = @"mentor";
    } else {

    }
}


#pragma mark - IBActions


- (IBAction)studentSignUpTapped:(id)sender {
    NSLog(@"studentSignUpTapped");
}

- (IBAction)mentorSignUpTapped:(id)sender {
    NSLog(@"mentorSignUpTapped");
}

- (IBAction)loginTapped:(id)sender {
//    MTLogInViewController *logInViewController = [[MTLogInViewController alloc] init];
//    
//    logInViewController.view.backgroundColor = [UIColor primaryGreen];
//    
//        // Present the log in view controller
//    [self presentViewController:logInViewController animated:YES completion:NULL];
}

@end
