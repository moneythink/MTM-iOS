//
//  MTChallengesContentViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTChallengesContentViewController.h"
#import "MTPostsTabBarViewController.h"
#import "MTPostsTableViewController.h"

@interface MTChallengesContentViewController ()

@property (weak, nonatomic) IBOutlet UILabel *challengeState;
@property (weak, nonatomic) IBOutlet UILabel *challengeNumber;
@property (weak, nonatomic) IBOutlet UILabel *challengeTitle;
@property (weak, nonatomic) IBOutlet UITextView *challengeDescription;
@property (weak, nonatomic) IBOutlet UILabel *challengePoints;

@property (nonatomic, strong) IBOutlet UIImageView *challengeIcon;

@property (strong, nonatomic) IBOutlet UIView *viewChallengeInfo;

@property (strong, nonatomic) IBOutlet UIView *leftPanel;
@property (strong, nonatomic) IBOutlet UIView *rightPanel;

@end

@implementation MTChallengesContentViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.viewChallengeInfo.layer.cornerRadius = 4.0f;
    self.leftPanel.backgroundColor = [UIColor mutedOrange];
    self.rightPanel.backgroundColor = [UIColor primaryOrange];
    
    self.challengeDescription.textColor = [UIColor redColor];
    
    
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
    self.challengePoints.text = [self.challengePointsText stringByAppendingString:@" pts"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)exploreChallenge {
    NSPredicate *challengePredicate = [NSPredicate predicateWithFormat:@"challenge_number = %@", self.challenge[@"challenge_number"]];
    PFQuery *queryActivated = [PFQuery queryWithClassName:[PFChallengesActivated parseClassName] predicate:challengePredicate];
    
    __block NSInteger count;
    
    [queryActivated countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            count = number;

            NSString *type = [PFUser currentUser][@"type"];
            switch (count) {
                case 0: // not activated
                    if ([type isEqualToString:@"mentor"]) {
                        [self performSegueWithIdentifier:@"exploreChallenge" sender:self];
                    }
                    break;
                    
                default: {
                    [self performSegueWithIdentifier:@"exploreChallenge" sender:self];
                }
                    break;
            }
        }
    }];
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    MTPostsTabBarViewController *destination = (MTPostsTabBarViewController *)[segue destinationViewController];
    
    destination.challenge = self.challenge;
    destination.challengeNumber = self.challengeNumberText;
    destination.challenge = self.challenge;
    
}

@end
