//
//  MTChallengesViewController.h
//  moneythink-ios
//
//  Created by dsica on 5/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MTCommentViewController.h"
#import "MTChallengeContentViewController.h"
#import "MTChallengeListViewController.h"
#import "MTEmojiPickerCollectionView.h"


@interface MTChallengesViewController : MTViewController <MTCommentViewProtocol, UIPageViewControllerDelegate, UIPageViewControllerDataSource, MTChallengeContentViewControllerDelegate, MTChallengeListViewControllerDelegate>

@property (nonatomic, strong) NSString *actionableChallengeId;

@end
