//
//  MTChallengesContentViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTChallengesContentViewController.h"
#import "MTPostsTabBarViewController.h"

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
        
    self.viewChallengeInfo.layer.cornerRadius = 4.0f;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(exploreChallenge)];
    
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.challengeState.text = self.challengeStateText;
    self.challengeTitle.text = self.challengeTitleText;
    self.challengeNumber.text = self.challengeNumberText;
    self.challengeDescription.text = self.challengeDescriptionText;
    self.challengePoints.text = self.challengePointsText;
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
    MTPostsTabBarViewController *destinationViewController = segue.destinationViewController;
    
    destinationViewController.challengeNumber = [self.challengeNumberText integerValue];
}

#pragma mark - UITabBarDelegate methods

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item; // called when a new view is selected by the user (but not programatically)
{
    
}

#pragma mark - UITabBarControllerDelegate methods



@end
