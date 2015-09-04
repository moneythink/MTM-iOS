//
//  MTUtil.h
//  moneythink-ios
//
//  Created by David Sica on 10/03/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

@interface MTUtil : NSObject

+ (BOOL)internetReachable;
+ (id)getAppDelegate;

+ (NSInteger)orderingForChallengeObjectId:(NSString *)objectId;
+ (void)setOrdering:(NSInteger)ordering forChallengeObjectId:(NSString *)objectId;
+ (BOOL)isCurrentUserMentor;
+ (BOOL)isUserMe:(PFUser *)user;

+ (NSString *)lastViewedChallengeId;
+ (void)setLastViewedChallengedId:(NSString *)challengeId;

+ (BOOL)userChangedClass;
+ (void)setUserChangedClass:(BOOL)userChangedClass;

+ (NSDate *)lastNotificationFetchDate;
+ (void)setLastNotificationFetchDate:(NSDate *)fetchDate;

+ (NSInteger)pushMessagingRegistrationId;
+ (void)setPushMessagingRegistrationId:(NSInteger)pushMessagingRegistrationId;

@end
