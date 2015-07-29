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

@property (nonatomic, weak) IBOutlet UIView *progressContainerView;
@property (nonatomic, weak) IBOutlet UIButton *hiddenChallengeInfoButton;
@property (nonatomic, weak) IBOutlet UIButton *challengeInfoButton;
@property (nonatomic, weak) IBOutlet UIButton *mentorChallengeInfoButton;
@property (nonatomic, weak) IBOutlet UIView *backgroundProgressView;
@property (nonatomic, weak) IBOutlet UIView *foregroundProgressView;
@property (nonatomic, weak) IBOutlet UIView *maskBorderView;
@property (nonatomic, weak) IBOutlet UILabel *progressLabel;

@property (nonatomic) BOOL challengeInfoModal;

@property (nonatomic) NSInteger challengeProgress;
@property (nonatomic) NSInteger oldChallengeProgress;

@end

@implementation MTChallengeContentViewController

#pragma mark - Lifecycle -
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([MTUtil isCurrentUserMentor]) {
        [self.progressContainerView removeFromSuperview];
        [self.hiddenChallengeInfoButton removeFromSuperview];
        self.challengeInfoButton.hidden = YES;
        self.mentorChallengeInfoButton.hidden = NO;
    }
    else {
        self.challengeInfoButton.hidden = NO;
        self.mentorChallengeInfoButton.hidden = YES;
        [self resetChallengeProgress];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.challengeInfoButton setTitle:self.challengeTitleText forState:UIControlStateNormal];
    [self.mentorChallengeInfoButton setTitle:self.challengeTitleText forState:UIControlStateNormal];
    
    if (![MTUtil isCurrentUserMentor] && !self.challengeInfoModal) {
        [self resetChallengeProgress];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDeleteChallengePost:) name:kDidDeleteChallengePostNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (![MTUtil isCurrentUserMentor]) {
        if (self.challengeInfoModal) {
            self.challengeInfoModal = NO;
        }
        else {
            [self loadChallengeProgress];
        }
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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


#pragma mark - Notifications -
- (void)didDeleteChallengePost:(NSNotification *)notif
{
    PFChallenges *challenge = notif.object;
    if ([challenge.objectId isEqualToString:self.challenge.objectId]) {
        [self loadChallengeProgress];
    }
}


#pragma mark - Navigation -
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueID = [segue identifier];
    if ([segueID isEqualToString:@"challengeInfoSegue"] || [segueID isEqualToString:@"hiddenChallengeInfoSegue"] || [segueID isEqualToString:@"mentorChallengeInfoModal"]) {
        MTChallengeInfoViewController *destinationVC = (MTChallengeInfoViewController *)[segue destinationViewController];
        destinationVC.challenge = self.challenge;
        destinationVC.pageIndex = self.pageIndex;
        self.challengeInfoModal = YES;
    }
}


#pragma mark - Private Methods -
- (void)loadChallengeProgress
{
    NSString *userID = [PFUser currentUser].objectId;
    NSString *challengeID = self.challenge.objectId;
    self.oldChallengeProgress = self.challengeProgress;
    
    MTMakeWeakSelf();
    [PFCloud callFunctionInBackground:@"getChallengeProgress" withParameters:@{@"user_id": userID, @"challenge_id": challengeID} block:^(id object, NSError *error) {
        if (!error) {
            if ([object isKindOfClass:[NSNumber class]]) {
                weakSelf.challengeProgress = [(NSNumber *)object integerValue];
                [weakSelf updateChallengeProgress];
            }
        } else {
            NSLog(@"error retrieving challenge progress - %@", [error localizedDescription]);
        }
    }];
}

- (void)updateChallengeProgress
{
    CGFloat factor = self.challengeProgress;

    CGFloat newWidth = factor/100.0f * (self.backgroundProgressView.frame.size.width - 2.0f);
    CGFloat maskPadding = 3.0f;
    
    if (factor <= 0.0f) {
        factor = 0.0f;
        newWidth = 0.0f;
    }
    else if (factor >= 100.0f) {
        factor = 100.0f;
        maskPadding = 2.0f;
        newWidth = self.backgroundProgressView.frame.size.width - 2.0f;
    }
    else {
        newWidth = factor/100.0f * (self.backgroundProgressView.frame.size.width - 2.0f);
    }
    
    if (factor == 0.0f) {
        
        if (self.oldChallengeProgress > 0.0f) {
            self.oldChallengeProgress = 0.0f;
            
            // animate down first
            [UIView animateWithDuration:0.3f animations:^{
                self.progressLabel.alpha = 0.0f;
                self.maskBorderView.frame = ({
                    CGRect newFrame = self.maskBorderView.frame;
                    newFrame.size.width = 0.0f;
                    newFrame;
                });
                
                self.foregroundProgressView.frame = ({
                    CGRect newFrame = self.foregroundProgressView.frame;
                    newFrame.size.width = 0.0f;
                    newFrame;
                });
            } completion:^(BOOL finished) {
                self.progressLabel.text = @"New Challenge";
                self.progressLabel.textColor = [UIColor colorWithHexString:@"8e8e8d"];
                self.progressLabel.textAlignment = NSTextAlignmentCenter;
                self.progressLabel.frame = ({
                    CGRect newFrame = self.progressLabel.frame;
                    newFrame.origin.x = 0.0f;
                    newFrame.size.width = self.backgroundProgressView.frame.size.width;
                    newFrame;
                });

                [UIView animateWithDuration:0.3f animations:^{
                    self.progressLabel.alpha = 1.0f;
                }];
            }];

        }
        else {
            self.progressLabel.text = @"New Challenge";
            self.progressLabel.textColor = [UIColor colorWithHexString:@"8e8e8d"];
            self.progressLabel.textAlignment = NSTextAlignmentCenter;
            self.progressLabel.frame = ({
                CGRect newFrame = self.progressLabel.frame;
                newFrame.origin.x = 0.0f;
                newFrame.size.width = self.backgroundProgressView.frame.size.width;
                newFrame;
            });

            [UIView animateWithDuration:0.3f animations:^{
                self.progressLabel.alpha = 1.0f;
            }];
        }
        
    }
    else {
        [UIView animateWithDuration:0.5f animations:^{
            self.progressLabel.alpha = 0.0f;
            self.maskBorderView.frame = ({
                CGRect newFrame = self.maskBorderView.frame;
                newFrame.size.width = newWidth + maskPadding;
                newFrame;
            });
            
            self.foregroundProgressView.frame = ({
                CGRect newFrame = self.foregroundProgressView.frame;
                newFrame.size.width = newWidth;
                newFrame;
            });
        } completion:^(BOOL finished) {
            
            if (factor == 100.0f) {
                self.progressLabel.text = @"★ Complete! ★";
                self.progressLabel.textColor = [UIColor whiteColor];
                self.progressLabel.textAlignment = NSTextAlignmentCenter;
                self.progressLabel.frame = ({
                    CGRect newFrame = self.progressLabel.frame;
                    newFrame.origin.x = 0.0f;
                    newFrame.size.width = self.backgroundProgressView.frame.size.width;
                    newFrame;
                });
            }
            else if (factor > 30.0f) {
                self.progressLabel.text = [NSString stringWithFormat:@"%ld%%", (long)self.challengeProgress];
                self.progressLabel.textColor = [UIColor whiteColor];
                self.progressLabel.textAlignment = NSTextAlignmentRight;
                self.progressLabel.frame = ({
                    CGRect newFrame = self.progressLabel.frame;
                    newFrame.origin.x = 2.0f;
                    newFrame.size.width = newWidth - 4.0f;
                    newFrame;
                });
            }
            else {
                self.progressLabel.text = [NSString stringWithFormat:@"%ld%%", (long)self.challengeProgress];
                self.progressLabel.textColor = [UIColor colorWithHexString:@"8e8e8d"];
                self.progressLabel.textAlignment = NSTextAlignmentCenter;
                self.progressLabel.frame = ({
                    CGRect newFrame = self.progressLabel.frame;
                    newFrame.origin.x = 0.0f;
                    newFrame.size.width = self.backgroundProgressView.frame.size.width;
                    newFrame;
                });
            }
            
            [UIView animateWithDuration:0.3f animations:^{
                self.progressLabel.alpha = 1.0f;
            }];
        }];
    }
}

- (void)resetChallengeProgress
{
    self.backgroundProgressView.backgroundColor = [UIColor whiteColor];
    self.backgroundProgressView.layer.cornerRadius = self.backgroundProgressView.frame.size.height/2.0f;
    self.backgroundProgressView.layer.borderWidth = 1.0f;
    self.backgroundProgressView.layer.borderColor = [UIColor colorWithHexString:@"#c07622"].CGColor;
    self.backgroundProgressView.layer.masksToBounds = YES;
    
    self.foregroundProgressView.backgroundColor = [UIColor primaryGreen];
    self.foregroundProgressView.layer.cornerRadius = self.foregroundProgressView.frame.size.height/2.0f;
    self.foregroundProgressView.clipsToBounds = YES;

    self.foregroundProgressView.frame = ({
        CGRect newFrame = self.foregroundProgressView.frame;
        newFrame.size.width = 0.0f;
        newFrame;
    });
    
    self.maskBorderView.backgroundColor = [UIColor clearColor];
    self.maskBorderView.layer.cornerRadius = self.maskBorderView.frame.size.height/2.0f;
    self.maskBorderView.layer.borderWidth = 2.0f;
    self.maskBorderView.layer.borderColor = [UIColor whiteColor].CGColor;
    
    self.maskBorderView.frame = ({
        CGRect newFrame = self.maskBorderView.frame;
        newFrame.size.width = 0.0f;
        newFrame;
    });
    
    self.progressLabel.alpha = 0.0f;
}


@end
