//
//  MTUtil.m
//  moneythink-ios
//
//  Created by David Sica on 10/03/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTUtil.h"
#import <Google/Analytics.h>

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

+ (NSString *)currentUserType
{
    if ([self isCurrentUserMentor]) {
        return @"mentor";
    } else {
        return @"student";
    }
}

+ (NSString *)currentUserTypeCapitalized
{
    return [self capitalizeFirstLetter:[self currentUserType]];
}

+ (NSString *)capitalizeFirstLetter:(NSString *)string
{
    NSString *firstLetter = [[string substringToIndex:1] capitalizedString];
    NSString *remainder = [string substringFromIndex:1];
    return [firstLetter stringByAppendingString:remainder];
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

+ (void)GATrackScreen:(NSString *)string {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:string];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    NSLog(@"GA Track [Screen]: %@", string);
}

/* View Controllers should call this whenever the user is successfully logged in. */
+ (void)userDidLogin:(PFUser *)user {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    // As per docs here: https://developers.google.com/analytics/devguides/collection/ios/v3/user-id
    [tracker set:@"&uid" value:[user objectId]];
    
    NSString *classId = @"";
    PFClasses *class_p = user[@"class_p"];
    if (class_p != nil) {
        classId = class_p.objectId;
    }
    [tracker set:@"&class_p" value:classId];
    
    NSString *schoolId = @"";
    PFClasses *school_p = user[@"school_p"];
    if (school_p != nil) {
        schoolId = school_p.objectId;
    }
    [tracker set:@"&school_p" value:schoolId];
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UX"            // Event category (required)
                                                          action:@"User Sign In"  // Event action (required)
                                                           label:nil              // Event label
                                                           value:nil] build]];    // Event value
    
    NSLog(@"GA Track [Event]: User Sign In (ID: %@, School ID: %@, Class ID: %@)", [user objectId], schoolId, classId);
}
+ (void)setRefreshedForKey:(NSString *)key
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)shouldRefreshForKey:(NSString *)key
{
    NSDate *lastRefreshTime = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if ([[NSDate date] timeIntervalSince1970] - [lastRefreshTime timeIntervalSince1970] > 86400.0f) {
        return YES;
    }
    else {
        return NO;
    }
}

+ (void)markDatabaseDeleted
{
    [MTUserPostPropertyCount markAllDeleted];
    [MTOptionalImage markAllDeleted];
    [MTNotification markAllDeleted];
    [MTEmoji markAllDeleted];
    [MTChallengeProgress markAllDeleted];
    [MTChallengePostComment markAllDeleted];
    [MTChallengePostLike markAllDeleted];
    [MTChallengeButtonClick markAllDeleted];
    [MTChallengeButton markAllDeleted];
    [MTChallengePost markAllDeleted];
    [MTChallenge markAllDeleted];
    [MTClass markAllDeleted];
    [MTOrganization markAllDeleted];
    [MTUser markAllDeleted];
}

+ (void)cleanDeletedItemsInDatabase
{
    [MTUserPostPropertyCount removeAllDeleted];
    [MTOptionalImage removeAllDeleted];
    [MTNotification removeAllDeleted];
    [MTEmoji removeAllDeleted];
    [MTChallengeProgress removeAllDeleted];
    [MTChallengePostComment removeAllDeleted];
    [MTChallengePostLike removeAllDeleted];
    [MTChallengeButtonClick removeAllDeleted];
    [MTChallengeButton removeAllDeleted];
    [MTChallengePost removeAllDeleted];
    [MTChallenge removeAllDeleted];
    [MTClass removeAllDeleted];
    [MTOrganization removeAllDeleted];
    [MTUser removeAllDeleted];
}

+ (void)logout
{
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *defaultsDictionary = [[NSUserDefaults standardUserDefaults] persistentDomainForName: appDomain];
    for (NSString *key in [defaultsDictionary allKeys]) {
        if (![key isEqualToString:kForcedUpdateKey] && ![key isEqualToString:kFirstTimeRunKey] && ![key isEqualToString:kPushMessagingRegistrationKey]) {
            NSLog(@"Removing user pref for %@", key);
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    ((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount = 0;
    
    [[ZDKConfig instance] setUserIdentity:nil];
    [[ZDKSdkStorage instance] clearUserData];
    [[ZDKSdkStorage instance].settingsStorage deleteStoredData];
    
    [MTUtil markDatabaseDeleted];
    
    [AFOAuthCredential deleteCredentialWithIdentifier:MTNetworkServiceOAuthCredentialKey];
}


@end
