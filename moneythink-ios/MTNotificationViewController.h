//
//  MTNotificationViewController.h
//  moneythink-ios
//
//  Created by dsica on 6/9/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTNotificationViewController : UITableViewController <UITextViewDelegate>

@property (nonatomic, strong) NSArray *classNotifications;
@property (nonatomic) NSInteger actionableNotificationId;

+ (void)markReadForNotificationId:(NSInteger)notificationId;
+ (void)markReadForNotification:(MTNotification *)notification;
+ (void)requestNotificationUnreadCountUpdateUsingCache:(BOOL)useCache;

@end
