//
//  MTUser.m
//  moneythink-ios
//
//  Created by David Sica on 7/13/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTUser.h"

@implementation MTUser

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues {
    return @{@"username" : @"", @"email": @"", @"firstName": @"", @"lastName": @"", @"phoneNumber": @"", @"roleCode": @"", @"avatar": @""};
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

+ (NSString *)primaryKey {
    return @"userId";
}


#pragma mark - Custom Methods -
+ (void)logout
{
    // Removes all keys, except onboarding
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *defaultsDictionary = [[NSUserDefaults standardUserDefaults] persistentDomainForName: appDomain];
    for (NSString *key in [defaultsDictionary allKeys]) {
        if (![key isEqualToString:kUserHasOnboardedKey]) {
            NSLog(@"removing user pref for %@", key);
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[ZDKConfig instance] setUserIdentity:nil];
    [[ZDKSdkStorage instance] clearUserData];
    [[ZDKSdkStorage instance].settingsStorage deleteStoredData];
    
    // TODO: Clear out database?
    [[RLMRealm defaultRealm] beginWriteTransaction];
    [[RLMRealm defaultRealm] deleteAllObjects];
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [AFOAuthCredential deleteCredentialWithIdentifier:MTNetworkServiceOAuthCredentialKey];
}

+ (BOOL)isCurrentUserMentor
{
    // TODO: implement
    return NO;
}

+ (BOOL)isUserMe:(MTUser *)user
{
    // TODO: implement
    return NO;
}

+ (BOOL)isUserLoggedIn
{
    if ([AFOAuthCredential retrieveCredentialWithIdentifier:MTNetworkServiceOAuthCredentialKey]) {
        return YES;
    }
    else {
        return NO;
    }
}

+ (MTUser *)getMeUser
{
    return nil;
}


@end
