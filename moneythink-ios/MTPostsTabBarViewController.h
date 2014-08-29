//
//  MTPostsTabBarViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/27/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTPostsTabBarViewController : UITabBarController

@property (nonatomic, strong) PFChallenges *challenge;

@property (nonatomic, strong) NSString *challengeNumber;

@end
