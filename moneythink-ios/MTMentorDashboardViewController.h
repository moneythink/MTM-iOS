//
//  MTMentorDashboardViewController.h
//  moneythink-ios
//
//  Created by dsica on 5/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    MTProgressSectionNextStep = 0,
    MTProgressSectionEditProfile,
    MTProgressSectionChallenges,
    MTProgressSectionStudents
} MTProgressSectionType;

typedef enum {
    MTProgressNextStepStateEditProfile = 0,
    MTProgressNextStepStateScheduleChallenges,
    MTProgressNextStepStateInviteStudents,
    MTProgressNextStepStateDone
} MTProgressNextStepState;

@interface MTMentorDashboardViewController : MTViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *classStudents;

@end
