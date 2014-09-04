//
//  MTStudentChallengeRoomContentViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 9/2/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MTExplorePostCollectionView.h"
#import "MTMyClassTableViewController.h"
#import "MTMentorChallengeInfoViewController.h"

@interface MTStudentChallengeRoomContentViewController : UIViewController <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (nonatomic, strong) PFChallenges *challenge;
@property (nonatomic, strong) NSString *challengeNumber;

@property (strong, nonatomic) NSArray *viewControllers;
@property (strong, nonatomic) UIPageViewController *pageViewController;

@property (nonatomic, strong) MTExplorePostCollectionView *exploreCollectionView;
@property (nonatomic, strong) MTMyClassTableViewController  *myClassTableView;
@property (nonatomic, strong) MTMentorChallengeInfoViewController *challengeInfoView;

@end
