//
//  MTMenuViewController.h
//  moneythink-ios
//
//  Created by David Sica on 5/26/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTMenuViewController : UIViewController <UIActionSheetDelegate>

- (void)openLeaderboard;
- (void)openNotificationsWithId:(NSString *)notificationId withType:(NSString *)notificationType;
- (void)openChallengesForChallengeId:(NSString *)challengeId;

@end
