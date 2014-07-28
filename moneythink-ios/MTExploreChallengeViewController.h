//
//  MTExploreChallengeViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/23/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTExploreChallengeViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *explorePostsTableView;

@property (nonatomic, strong) NSArray *challenges;
@property (nonatomic, assign) NSInteger challengeNumber;

@end

