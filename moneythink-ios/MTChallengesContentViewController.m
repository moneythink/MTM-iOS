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

#import "MTStudentChallengeRoomViewController.h"

@interface MTChallengesContentViewController ()

@property (weak, nonatomic) IBOutlet UILabel *challengeState;
@property (weak, nonatomic) IBOutlet UILabel *challengeNumber;
@property (weak, nonatomic) IBOutlet UILabel *challengeTitle;
@property (weak, nonatomic) IBOutlet UITextView *challengeDescription;
@property (weak, nonatomic) IBOutlet UILabel *challengePoints;

@property (nonatomic, strong) IBOutlet UIImageView *challengeIcon;

@property (strong, nonatomic) IBOutlet UIView *leftPanel;
@property (strong, nonatomic) IBOutlet UIView *rightPanel;
@property (nonatomic, strong) IBOutlet UIView *separatorView;

@property (assign, nonatomic) BOOL activated;
@property (nonatomic) BOOL openChallenge;
@property (nonatomic) BOOL queriedForOpenness;

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
    
    
    self.challengeDescription.textColor = [UIColor white];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(exploreChallenge)];
    
    self.activated = NO;
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSString *userClass = [PFUser currentUser][@"class"];
    NSString *userSchool = [PFUser currentUser][@"school"];
    
    self.challengeState.text = self.challengeStateText;
    self.challengeTitle.text = self.challengeTitleText;
    self.challengeNumber.text = self.challengeNumberText;
    self.challengeDescription.text = self.challengeDescriptionText;
    self.challengePoints.text = [self.challengePointsText stringByAppendingString:@" pts"];
    
    __block NSString *pillar = self.challengePillarText;
    self.rightPanel.layer.cornerRadius = 4.0f;

    // Pull challenge info
    if (!self.queriedForOpenness) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Loading...";
        hud.dimBackground = YES;
        
        self.challengeState.alpha = 0.0f;
        self.rightPanel.alpha = 0.0f;
        self.challengeIcon.alpha = 0.0f;
    }
    else {
        self.challengeState.alpha = 1.0f;
        self.rightPanel.alpha = 1.0f;
        self.challengeIcon.alpha = 1.0f;
        
        if (self.openChallenge) {
            self.challengeState.text = @"OPEN CHALLENGE";
            self.challengeIcon.image = [UIImage imageNamed:@"icon_challenge_open"];
            self.separatorView.alpha = 0.0f;
        }
        else {
            self.challengeState.text = @"FUTURE CHALLENGE";
            self.challengeIcon.image = [UIImage imageNamed:@"icon_challenge_future"];
            self.separatorView.alpha = 1.0f;
        }
    }
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        NSPredicate *challengePredicate = [NSPredicate predicateWithFormat:@"challenge_number = %@", weakSelf.challenge[@"challenge_number"]];
        PFQuery *checkSchedule = [PFQuery queryWithClassName:[PFScheduledActivations parseClassName] predicate:challengePredicate];
        
        if (!weakSelf.queriedForOpenness) {
            checkSchedule.cachePolicy = kPFCachePolicyNetworkElseCache;
        }
        else {
            checkSchedule.cachePolicy = kPFCachePolicyNetworkOnly;
        }

        [checkSchedule whereKey:@"activated" equalTo:@YES];
        [checkSchedule whereKey:@"class" equalTo:userClass];
        [checkSchedule whereKey:@"school" equalTo:userSchool];
        
        [checkSchedule countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
            
            weakSelf.queriedForOpenness = YES;
            
            if ([[PFUser currentUser][@"type"] isEqualToString:@"mentor"]) {
                weakSelf.activated = YES;
            } else {
                weakSelf.activated = number > 0;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                weakSelf.challengeState.alpha = 1.0f;
                weakSelf.rightPanel.alpha = 1.0f;
                weakSelf.challengeIcon.alpha = 1.0f;
                
                weakSelf.openChallenge = (number > 0);
                if (weakSelf.openChallenge) {
                    weakSelf.challengeState.text = @"OPEN CHALLENGE";
                    weakSelf.challengeIcon.image = [UIImage imageNamed:@"icon_challenge_open"];
                    weakSelf.separatorView.alpha = 0.0f;
                }
                else {
                    weakSelf.challengeState.text = @"FUTURE CHALLENGE";
                    weakSelf.challengeIcon.image = [UIImage imageNamed:@"icon_challenge_future"];
                    weakSelf.separatorView.alpha = 1.0f;
                }
                
                if ([pillar isEqualToString:@"Money Manager"]) {
                    weakSelf.leftPanel.backgroundColor = [UIColor mutedOrange];
                    weakSelf.rightPanel.layer.borderColor = [UIColor primaryOrange].CGColor;
                    
                    if (weakSelf.openChallenge) {
                        weakSelf.rightPanel.backgroundColor = [UIColor primaryOrange];
                        weakSelf.rightPanel.layer.borderWidth = 0.0f;
                        weakSelf.challengeDescription.textColor = [UIColor whiteColor];
                        weakSelf.challengeTitle.textColor = [UIColor whiteColor];
                        weakSelf.challengePoints.textColor = [UIColor whiteColor];
                    }
                    else {
                        weakSelf.rightPanel.backgroundColor = [UIColor clearColor];
                        weakSelf.rightPanel.layer.borderWidth = 1.0f;
                        weakSelf.challengeDescription.textColor = [UIColor primaryOrange];
                        weakSelf.challengeTitle.textColor = [UIColor primaryOrange];
                        weakSelf.challengePoints.textColor = [UIColor primaryOrange];
                        weakSelf.separatorView.backgroundColor = [UIColor primaryOrange];
                    }
                    
                } else {
                    weakSelf.leftPanel.backgroundColor = [UIColor mutedGreen];
                    weakSelf.rightPanel.layer.borderColor = [UIColor primaryGreen].CGColor;
                    
                    if (weakSelf.openChallenge) {
                        weakSelf.rightPanel.backgroundColor = [UIColor primaryGreen];
                        weakSelf.rightPanel.layer.borderWidth = 0.0f;
                        weakSelf.challengeDescription.textColor = [UIColor whiteColor];
                        weakSelf.challengeTitle.textColor = [UIColor whiteColor];
                        weakSelf.challengePoints.textColor = [UIColor whiteColor];
                    }
                    else {
                        weakSelf.rightPanel.backgroundColor = [UIColor clearColor];
                        weakSelf.rightPanel.layer.borderWidth = 1.0f;
                        weakSelf.challengeDescription.textColor = [UIColor primaryGreen];
                        weakSelf.challengeTitle.textColor = [UIColor primaryGreen];
                        weakSelf.challengePoints.textColor = [UIColor primaryGreen];
                        weakSelf.separatorView.backgroundColor = [UIColor primaryGreen];
                    }
                }
            });
        }];
    } afterDelay:0.35f];
}

- (void)objectsReturned:(int)number error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
    });

    NSInteger count = number;
    NSString *type = [PFUser currentUser][@"type"];
    
    switch (count) {
        case 0: { // not activated
            if ([type isEqualToString:@"mentor"]) {
                [self performSegueWithIdentifier:@"studentChallengeRoom" sender:self];
            }
        }
            break;
            
        default: {
            [self performSegueWithIdentifier:@"studentChallengeRoom" sender:self];
        }
            break;
    }
}

-(void)exploreChallenge
{
    if (self.activated) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Loading...";
        hud.dimBackground = YES;

        MTMakeWeakSelf();
        [self bk_performBlock:^(id obj) {
            NSPredicate *challengePredicate = [NSPredicate predicateWithFormat:@"challenge_number = %@", weakSelf.challenge[@"challenge_number"]];
            PFQuery *queryActivated = [PFQuery queryWithClassName:[PFChallengesActivated parseClassName] predicate:challengePredicate];
            [queryActivated whereKeyDoesNotExist:@"school"];
            [queryActivated whereKeyDoesNotExist:@"class"];
            
            queryActivated.cachePolicy = kPFCachePolicyNetworkElseCache;
            
            [queryActivated countObjectsInBackgroundWithTarget:weakSelf selector:@selector(objectsReturned:error:)];
        } afterDelay:0.35f];
    }
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    MTStudentChallengeRoomViewController *destination = (MTStudentChallengeRoomViewController *)[segue destinationViewController];
    
    destination.challenge = self.challenge;
    destination.challengeNumber = self.challengeNumberText;
}


@end
