//
//  MTUtil.m
//  moneythink-ios
//
//  Created by David Sica on 10/03/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTUtil.h"
#import <Google/Analytics.h>
#import "MTUser.h"

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

+ (NSString *)currentUserType
{
    if ([MTUser isCurrentUserMentor]) {
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

+ (void)GATrackScreen:(NSString *)string {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:string];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
    
    NSLog(@"GA Track [Screen]: %@", string);
}

/* View Controllers should call this whenever the user is successfully logged in. */
+ (void)userDidLogin:(MTUser *)user {
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    
    // As per docs here: https://developers.google.com/analytics/devguides/collection/ios/v3/user-id
    [tracker set:@"&uid" value:[NSString stringWithFormat:@"%ld", user.id]];
    
    // Dimension 1: UserID (NO PII!)
    [tracker set:[GAIFields customDimensionForIndex:1] value:[NSString stringWithFormat:@"%ld", user.id]];
    
    // Dimension 2: School Name
    NSString *schoolName = user.organization.name;
    if (schoolName) {
        [tracker set:[GAIFields customDimensionForIndex:2] value:schoolName];
    }
    
    // Dimension 3: Class Name
    NSString *className = user.userClass.name;
    if (className) {
        [tracker set:[GAIFields customDimensionForIndex:3] value:className];
    }
    
    // Dimension 4: School ID
    NSString *schoolID = [NSString stringWithFormat:@"%ld", user.organization.id];
    [tracker set:[GAIFields customDimensionForIndex:4] value:schoolID];
    
    // Dimension 5: Class ID (currently indicates program lead)
    NSString *classID = [NSString stringWithFormat:@"%ld", user.userClass.id];
    [tracker set:[GAIFields customDimensionForIndex:5] value:classID];
    
    // Dimension 6: User Type (student or mentor)
    NSString *type = [MTUtil currentUserType];
    if (type) {
        [tracker set:[GAIFields customDimensionForIndex:6] value:type];
    }
    
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:@"UX"            // Event category (required)
                                                          action:@"User Sign In"  // Event action (required)
                                                           label:nil              // Event label
                                                           value:nil] build]];    // Event value
    
    NSLog(@"GA Track [Event]: %@ Sign In (ID: %ld, School: %@, Class: %@)", [type capitalizedString], user.id, schoolName, className);
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
        if (![key isEqualToString:kForcedUpdateKey] && ![key isEqualToString:kFirstTimeRunKey] &&
            ![key isEqualToString:kPushMessagingRegistrationKey] && ![key isEqualToString:kAPIServerKey]) {
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


+(BOOL) NSStringIsValidEmail:(NSString *)checkString
{
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
    NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

+ (NSArray<NSString *> *)englishAlphabet {
    return [@"A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z" componentsSeparatedByString:@","];
}

@end
