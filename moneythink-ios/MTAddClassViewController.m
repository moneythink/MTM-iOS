//
//  MTAddClassViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 8/15/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTAddClassViewController.h"
#import "MTEditProfileViewController.h"

@interface MTAddClassViewController ()

@property (strong, nonatomic) IBOutlet UITextField *classNameText;
@property (strong, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation MTAddClassViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[self.doneButton layer] setCornerRadius:5.0f];
    [[self.doneButton layer] setBorderWidth:1.0f];
    [[self.doneButton layer] setBorderColor:[UIColor mutedOrange].CGColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.classNameText becomeFirstResponder];
}


#pragma mark - IBAction
- (IBAction)doneButtonTapped:(id)sender {
    self.className = self.classNameText.text;
    [self.classNameText resignFirstResponder];
    
    UINavigationController *navController = (UINavigationController *)self.presentingViewController;
    if ([navController.topViewController isKindOfClass:[MTEditProfileViewController class]]) {
        [self performSegueWithIdentifier:@"unwindToEditProfileView" sender:self];
    }
    else {
        [self performSegueWithIdentifier:@"unwindToSignupView" sender:self];
    }
}


@end
