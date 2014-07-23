//
//  MTChallengesContentViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTChallengesContentViewController.h"

@interface MTChallengesContentViewController ()

@end

@implementation MTChallengesContentViewController

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
    
    self.challengeState.text = self.challengeStateText;
    self.challengeNumber.text = self.challengeNumberText;
    self.challengeTitle.text = self.challengeTitleText;
    self.challengeDescription.text = self.challengeDescriptionText;
    self.challengePoints.text = self.challengePointsText;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(exploreChallenge)];
    
    [self.view addGestureRecognizer:tap];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)exploreChallenge {
    [self performSegueWithIdentifier:@"exploreChallenge" sender:self];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueID = [segue identifier];
    
//    MTSignUpViewController *signUpViewController = (MTSignUpViewController *)segue.destinationViewController;
//    
//    if ([segueID isEqualToString:@"studentSignUp"]) {
//        signUpViewController.signUpTitle = @"Student Signup";
//        signUpViewController.signUpType = @"student";
//    } else if ([segueID isEqualToString:@"mentorSignUp"]) {
//        signUpViewController.signUpTitle = @"Mentor Signup";
//        signUpViewController.signUpType = @"mentor";
//    } else {
//        
//    }
}

@end
