//
//  MTChallengeContentViewController.m
//  moneythink-ios
//
//  Created by David Sica on 5/28/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTChallengeContentViewController.h"
#import "MTChallengeInfoViewController.h"

@interface MTChallengeContentViewController ()

@property (nonatomic, weak) IBOutlet UILabel *challengeTitle;

@end

@implementation MTChallengeContentViewController

#pragma mark - Lifecycle -
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.challengeTitle.text = self.challengeTitleText;
}


#pragma mark - Actions -
- (IBAction)leftButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(leftButtonTapped)]) {
        [self.delegate leftButtonTapped];
    }
}

- (IBAction)rightButtonAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(rightButtonTapped)]) {
        [self.delegate rightButtonTapped];
    }
}

- (IBAction)didTapChallengeList:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(didTapChallengeList)]) {
        [self.delegate didTapChallengeList];
    }
}


#pragma mark - Navigation -
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueID = [segue identifier];
    if ([segueID isEqualToString:@"challengeInfoSegue"]) {
        MTChallengeInfoViewController *destinationVC = (MTChallengeInfoViewController *)[segue destinationViewController];
        destinationVC.challenge = self.challenge;
        destinationVC.pageIndex = self.pageIndex;
    }
}


@end
