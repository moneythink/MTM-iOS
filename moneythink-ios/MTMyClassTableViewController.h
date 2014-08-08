//
//  MTMyClassTableViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 8/4/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTMyClassTableViewController : PFQueryTableViewController

@property (nonatomic, strong) PFChallenges *challenge;
@property (nonatomic, strong) NSString *challengeNumber;
@property (nonatomic, strong) NSString *className;

@end

