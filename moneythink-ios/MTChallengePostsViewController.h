//
//  MTChallengePostsViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/26/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTChallengePostsViewController : PFQueryTableViewController

@property (nonatomic, strong) NSString *challengeNumber;
@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) NSString *schoolName;

@end
