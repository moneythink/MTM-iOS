//
//  MTMyClassChallengePostsViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/24/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTMyClassChallengePostsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *myClassPostsTableView;

@property (nonatomic, strong) NSArray *posts;
@property (nonatomic, assign) NSInteger challengeNumber;
@property (nonatomic, strong) NSString *class;

@end
