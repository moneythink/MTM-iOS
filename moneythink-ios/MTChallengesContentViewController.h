//
//  MTChallengesContentViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTChallengesContentViewController : UIViewController <UIActionSheetDelegate, UITabBarControllerDelegate, UITabBarDelegate>

@property (strong, nonatomic) IBOutlet UIView *viewChallengeInfo;

@property (weak, nonatomic) IBOutlet UILabel *challengeState;
@property (weak, nonatomic) IBOutlet UILabel *challengeNumber;
@property (weak, nonatomic) IBOutlet UILabel *challengeTitle;
@property (weak, nonatomic) IBOutlet UITextView *challengeDescription;
@property (weak, nonatomic) IBOutlet UILabel *challengePoints;

@property (nonatomic) NSUInteger pageIndex;
@property (nonatomic, strong) IBOutlet UIImageView *challengeIcon;

@property (nonatomic, strong) NSString *challengeStateText;
@property (nonatomic, strong) NSString *challengeNumberText;
@property (nonatomic, strong) NSString *challengeTitleText;
@property (nonatomic, strong) NSString *challengeDescriptionText;
@property (nonatomic, strong) NSString *challengePointsText;

@end
