//
//  MTNotificationViewController.h
//  moneythink-ios
//
//  Created by dsica on 6/9/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTNotificationViewController : PFQueryTableViewController <UITextViewDelegate>

@property (nonatomic, strong) NSArray *classNotifications;
@property (nonatomic, strong) NSString *actionableNotificationId;

+ (void)markReadForNotificationId:(NSString *)notificationId;
+ (void)markReadForNotification:(PFNotifications *)notification;
+ (void)requestNotificationUnreadCountUpdateUsingCache:(BOOL)useCache;

@end
