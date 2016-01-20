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

+ (NSString *)lastViewedChallengeId;
+ (void)setLastViewedChallengedId:(NSString *)challengeId;

+ (NSString *)currentUserType;
+ (NSString *)currentUserTypeCapitalized;
+ (NSString *)capitalizeFirstLetter:(NSString *)string;

+ (BOOL)userChangedClass;
+ (void)setUserChangedClass:(BOOL)userChangedClass;

+ (NSDate *)lastNotificationFetchDate;
+ (void)setLastNotificationFetchDate:(NSDate *)fetchDate;

+ (NSInteger)pushMessagingRegistrationId;
+ (void)setPushMessagingRegistrationId:(NSInteger)pushMessagingRegistrationId;

+ (void)setRefreshedForKey:(NSString *)key;
+ (BOOL)shouldRefreshForKey:(NSString *)key;

+ (void)markDatabaseDeleted;
+ (void)cleanDeletedItemsInDatabase;
+ (void)logout;

// Google Analytics singleton
+ (void)GATrackScreen:(NSString *)string;

+ (void)userDidLogin:(MTUser *)user;

+ (BOOL)NSStringIsValidEmail:(NSString *)checkString;

+ (NSString *)stringFromAPNSTokenData:(NSData *)deviceToken;

+ (void)setRecentlyLoggedOut:(BOOL)value;
+ (BOOL)userRecentlyLoggedOut;

@end
