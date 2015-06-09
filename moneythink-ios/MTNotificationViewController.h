//
//  MTNotificationViewController.h
//  moneythink-ios
//
//  Created by dsica on 6/9/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTNotificationViewController : PFQueryTableViewController

@property (nonatomic, strong) NSArray *classNotifications;
@property (nonatomic, strong) NSString *actionableNotificationId;

@end
