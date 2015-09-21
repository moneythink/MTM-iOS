//
//  MTMentorDashboardViewController.h
//  moneythink-ios
//
//  Created by dsica on 5/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum {
    MTProgressSectionEditProfile=0,
    MTProgressSectionStudents
} MTProgressSectionType;


@interface MTMentorDashboardViewController : MTViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
