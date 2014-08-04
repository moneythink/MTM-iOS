//
//  MTMentorNotificationViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTMentorNotificationViewController : PFQueryTableViewController
@property (nonatomic, strong) NSArray *classNotifications;

@property (strong, nonatomic) IBOutlet UITableView *notificationsTableView;


@end
