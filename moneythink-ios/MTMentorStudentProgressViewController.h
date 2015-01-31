//
//  MTMentorStudentProgressViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
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
    MTProgressNextStepStateDone
} MTProgressNextStepState;

@interface MTMentorStudentProgressViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *classStudents;

@end
