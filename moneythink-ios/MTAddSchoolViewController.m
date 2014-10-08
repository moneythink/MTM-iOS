//
//  MTAddSchoolViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 8/15/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTAddSchoolViewController.h"
#import "MTEditProfileViewController.h"

@interface MTAddSchoolViewController ()

@property (strong, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation MTAddSchoolViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[self.doneButton layer] setCornerRadius:5.0f];
    [[self.doneButton layer] setBorderWidth:1.0f];
    [[self.doneButton layer] setBorderColor:[UIColor mutedOrange].CGColor];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:YES];
}


#pragma mark - IBAction
- (IBAction)doneButtonTapped:(id)sender {
    self.schoolName = self.schoolNameText.text;
    UINavigationController *navController = (UINavigationController *)self.presentingViewController;
    if ([navController.topViewController isKindOfClass:[MTEditProfileViewController class]]) {
        [self performSegueWithIdentifier:@"unwindToEditProfileView" sender:self];
    }
    else {
        [self performSegueWithIdentifier:@"unwindToSignupView" sender:self];
    }
}


@end
