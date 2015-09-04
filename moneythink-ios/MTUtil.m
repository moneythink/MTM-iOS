//
//  MTUtil.m
//  moneythink-ios
//
//  Created by David Sica on 10/03/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTUtil.h"

@implementation MTUtil

+ (BOOL)internetReachable
{
    Reachability *internetReach = [Reachability reachabilityForInternetConnection];
	NetworkStatus netStatus = [internetReach currentReachabilityStatus];
	if (netStatus == NotReachable)
        return NO;
    return YES;
}

+ (id)getAppDelegate
{
    return [UIApplication sharedApplication].delegate;
}

+ (NSInteger)orderingForChallengeObjectId:(NSString *)objectId
{
    if (IsEmpty(objectId)) {
        return -1;
    }
    
    NSNumber *ordering = [[NSUserDefaults standardUserDefaults] objectForKey:objectId];
    if (ordering) {
        return [ordering integerValue];
    }
    else {
        return -1;
    }
}

+ (void)setOrdering:(NSInteger)ordering forChallengeObjectId:(NSString *)objectId
{
    if (IsEmpty(objectId)) {
        return;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:ordering] forKey:objectId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)lastViewedChallengeId
{
    NSString *challengeId = [[NSUserDefaults standardUserDefaults] objectForKey:kLastViewedChallengeId];
    if (!IsEmpty(challengeId)) {
        return challengeId;
    }
    else {
        return nil;
    }
}

+ (void)setLastViewedChallengedId:(NSString *)challengeId
{
    if (IsEmpty(challengeId)) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastViewedChallengeId];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setObject:challengeId forKey:kLastViewedChallengeId];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


+ (BOOL)userChangedClass
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kUserDidChangeClass];
}

+ (void)setUserChangedClass:(BOOL)userChangedClass
{
    if (!userChangedClass) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDidChangeClass];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserDidChangeClass];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

+ (NSDate *)lastNotificationFetchDate
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:kLastNotificationFetchDateKey];
}

+ (void)setLastNotificationFetchDate:(NSDate *)fetchDate
{
    if (fetchDate) {
        [[NSUserDefaults standardUserDefaults] setObject:fetchDate forKey:kLastNotificationFetchDateKey];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLastNotificationFetchDateKey];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSInteger)pushMessagingRegistrationId
{
    NSNumber *pushId = [[NSUserDefaults standardUserDefaults] objectForKey:kPushMessagingRegistrationKey];
    if (pushId) {
        return [pushId integerValue];
    }
    else {
        return 0;
    }
}

+ (void)setPushMessagingRegistrationId:(NSInteger)pushMessagingRegistrationId
{
    if (pushMessagingRegistrationId > 0) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:pushMessagingRegistrationId] forKey:kPushMessagingRegistrationKey];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kPushMessagingRegistrationKey];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}


+ (BOOL)isCurrentUserMentor
{
    if ([[[PFUser currentUser] valueForKey:@"type"] isEqualToString:@"student"]) {
        return NO;
    } else {
        return YES;
    }

}

+ (BOOL)isUserMe:(PFUser *)user
{
    if ([[PFUser currentUser].objectId isEqualToString:user.objectId]) {
        return YES;
    }
    else{
        return NO;
    }
}


@end
