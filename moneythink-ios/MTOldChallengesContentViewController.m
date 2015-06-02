//
//  MTChallengesContentViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTOldChallengesContentViewController.h"

#import "MTChallengesViewController.h"

@interface MTOldChallengesContentViewController ()

@property (weak, nonatomic) IBOutlet UILabel *challengeState;
@property (weak, nonatomic) IBOutlet UILabel *challengeNumber;
@property (weak, nonatomic) IBOutlet UILabel *challengeTitle;
@property (weak, nonatomic) IBOutlet UITextView *challengeDescription;
@property (weak, nonatomic) IBOutlet UILabel *challengePoints;

@property (nonatomic, strong) IBOutlet UIImageView *challengeIcon;

@property (strong, nonatomic) IBOutlet UIView *leftPanel;
@property (strong, nonatomic) IBOutlet UIView *rightPanel;
@property (nonatomic, strong) IBOutlet UIView *separatorView;
@property (nonatomic, strong) IBOutlet UIButton *activateButton;

@property (assign, nonatomic) BOOL activated;
@property (nonatomic) BOOL openChallenge;
@property (nonatomic) BOOL queriedForOpenness;

@end

@implementation MTOldChallengesContentViewController

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
    
    self.challengeState.alpha = 0.0f;
    self.rightPanel.alpha = 0.0f;
    self.challengeIcon.alpha = 0.0f;
    self.rightPanel.layer.cornerRadius = 4.0f;

    [self.activateButton addTarget:self action:@selector(exploreChallenge) forControlEvents:UIControlEventTouchUpInside];
    [self.activateButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithWhite:0.0f alpha:0.4f] size:self.activateButton.frame.size] forState:UIControlStateHighlighted];
    [self.activateButton setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor] size:self.activateButton.frame.size] forState:UIControlStateNormal];
    self.activateButton.layer.cornerRadius = 4.0f;
    self.activateButton.layer.masksToBounds = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.challengeState.alpha = 0.0f;
    self.rightPanel.alpha = 0.0f;
    self.challengeIcon.alpha = 0.0f;
    
    NSString *userClass = [PFUser currentUser][@"class"];
    NSString *userSchool = [PFUser currentUser][@"school"];
    
    self.challengeState.text = self.challengeStateText;
    self.challengeTitle.text = self.challengeTitleText;
    self.challengeNumber.text = self.challengeNumberText;
    self.challengeDescription.text = self.challengeDescriptionText;
    self.challengePoints.text = [self.challengePointsText stringByAppendingString:@" pts"];

    // Pull challenge info
    if (!self.queriedForOpenness) {
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Refreshing Challenge...";
        hud.dimBackground = YES;
    }
    else {
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

    // Pre-configure cell before requesting updates if already queried
    if (self.queriedForOpenness) {
        [self configureContentViewForCurrentState];
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
            
            dispatch_async(dispatch_get_main_queue(), ^{

                weakSelf.queriedForOpenness = YES;
                
                if ([[PFUser currentUser][@"type"] isEqualToString:@"mentor"]) {
                    weakSelf.activated = YES;
                } else {
                    weakSelf.activated = (number > 0);
                }
            
                weakSelf.openChallenge = (number > 0);
                [weakSelf configureContentViewForCurrentState];
                
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            });
        }];

    } afterDelay:0.35f];
}

#pragma mark - Private Methods -
- (void)configureContentViewForCurrentState
{
    NSString *pillar = self.challengePillarText;
    self.challengeDescription.editable = YES;

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
    
    if ([pillar isEqualToString:@"Money Manager"]) {
        self.leftPanel.backgroundColor = [UIColor mutedOrange];
        self.rightPanel.layer.borderColor = [UIColor primaryOrange].CGColor;
        
        if (self.openChallenge) {
            self.rightPanel.backgroundColor = [UIColor primaryOrange];
            self.rightPanel.layer.borderWidth = 0.0f;
            self.challengeDescription.textColor = [UIColor whiteColor];
            self.challengeTitle.textColor = [UIColor whiteColor];
            self.challengePoints.textColor = [UIColor whiteColor];
        }
        else {
            self.rightPanel.backgroundColor = [UIColor clearColor];
            self.rightPanel.layer.borderWidth = 1.0f;
            self.challengeDescription.textColor = [UIColor primaryOrange];
            self.challengeTitle.textColor = [UIColor primaryOrange];
            self.challengePoints.textColor = [UIColor primaryOrange];
            self.separatorView.backgroundColor = [UIColor primaryOrange];
        }
        
    } else {
        self.leftPanel.backgroundColor = [UIColor mutedGreen];
        self.rightPanel.layer.borderColor = [UIColor primaryGreen].CGColor;
        
        if (self.openChallenge) {
            self.rightPanel.backgroundColor = [UIColor primaryGreen];
            self.rightPanel.layer.borderWidth = 0.0f;
            self.challengeDescription.textColor = [UIColor whiteColor];
            self.challengeTitle.textColor = [UIColor whiteColor];
            self.challengePoints.textColor = [UIColor whiteColor];
        }
        else {
            self.rightPanel.backgroundColor = [UIColor clearColor];
            self.rightPanel.layer.borderWidth = 1.0f;
            self.challengeDescription.textColor = [UIColor primaryGreen];
            self.challengeTitle.textColor = [UIColor primaryGreen];
            self.challengePoints.textColor = [UIColor primaryGreen];
            self.separatorView.backgroundColor = [UIColor primaryGreen];
        }
    }
    
    //
    // Weird bug that doesn't re-draw (update textColor) on UITextView unless you toggle editable
    //  http://stackoverflow.com/questions/19113673/uitextview-setting-font-not-working-with-ios-6-on-xcode-5
    //
    self.challengeDescription.editable = NO;

    self.challengeState.alpha = 1.0f;
    self.rightPanel.alpha = 1.0f;
    self.challengeIcon.alpha = 1.0f;
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


#pragma mark - Actions -
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
//    MTChallengesViewController *destination = (MTChallengesViewController *)[segue destinationViewController];
//    
//    destination.challenge = self.challenge;
//    destination.challengeNumber = [self.challenge[@"challenge_number"] stringValue];
}


@end
