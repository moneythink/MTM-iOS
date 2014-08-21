//
//  MTAddClassViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 8/15/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTAddClassViewController.h"

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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - IBAction

- (IBAction)doneButtonTapped:(id)sender {
    self.className = self.classNameText.text;

    [self performSegueWithIdentifier:@"unwindToSignupView" sender:self];
}


@end
