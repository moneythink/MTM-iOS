//
//  MTPostsTableViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/31/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <Parse/Parse.h>

@interface MTPostsTableViewController : PFQueryTableViewController

@property (nonatomic, strong) NSString *challengeNumber;

@end
