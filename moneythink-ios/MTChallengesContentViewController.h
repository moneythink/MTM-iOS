//
//  MTChallengesContentViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTChallengesContentViewController : UIViewController <UIActionSheetDelegate, UITabBarControllerDelegate, UITabBarDelegate>

@property (nonatomic, strong) PFChallenges *challenge;

@property (nonatomic) NSUInteger pageIndex;

@property (nonatomic, strong) NSString *challengeStateText;
@property (nonatomic, strong) NSString *challengeNumberText;
@property (nonatomic, strong) NSString *challengeTitleText;
@property (nonatomic, strong) NSString *challengeDescriptionText;
@property (nonatomic, strong) NSString *challengePointsText;

@end
