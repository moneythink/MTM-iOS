//
//  MTAddSchoolViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 8/15/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTAddSchoolViewController.h"

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

#pragma mark

- (IBAction)doneButtonTapped:(id)sender {
    self.schoolName = self.schoolNameText.text;
    PFSchools *createSchool = [[PFSchools alloc] initWithClassName:@"Schools"];
    createSchool[@"name"] = self.schoolName;
    [createSchool save];
    
    [self performSegueWithIdentifier:@"unwindToSignupView" sender:self];
}


@end
