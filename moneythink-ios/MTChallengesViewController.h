//
//  MTChallengesViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/19/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTChallengesContentViewController.h"

@interface MTChallengesViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (strong, nonatomic) UIPageViewController *pageViewController;

@property (strong, nonatomic) NSArray *challenges;

@end
