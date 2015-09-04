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
    return @{@"username" : @"",
             @"email": @"",
             @"firstName": @"",
             @"lastName": @"",
             @"phoneNumber": @"",
             @"roleCode": @"",
             @"currentUser": @NO,
             @"hasResume": @NO,
             @"hasBankAccount": @NO,
             @"hasAvatar": @NO,
             @"points": @0};
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

+ (NSString *)primaryKey {
    return @"id";
}


#pragma mark - Realm+JSON Methods -
+ (NSDictionary *)JSONInboundMappingDictionary {
    return @{
             @"id": @"id",
             @"username": @"username",
             @"email": @"email",
             @"firstName": @"firstName",
             @"lastName": @"lastName",
             @"phoneNumber": @"phoneNumber",
             @"updatedAt": @"updatedAt",
             @"createdAt": @"createdAt",
             @"_embedded.role.code": @"roleCode",
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"id": @"id",
             @"username": @"username",
             @"email": @"email",
             @"firstName": @"firstName",
             @"lastName": @"lastName",
             @"phoneNumber": @"phoneNumber",
             };
}


#pragma mark - Custom Methods -
- (UIImage *)loadAvatarImageWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    BOOL shouldFetchAvatar = NO;
    
    if (self.hasAvatar && !self.userAvatar) {
        shouldFetchAvatar = YES;
    }
    else if (self.hasAvatar && self.userAvatar) {
        if ([self.updatedAt timeIntervalSince1970] > [self.userAvatar.updatedAt timeIntervalSince1970]) {
            shouldFetchAvatar = YES;
        }
    }
    
    if (shouldFetchAvatar) {
        [[MTNetworkManager sharedMTNetworkManager] getAvatarForUserId:self.id success:^(id responseData) {
            if (success) {
                success(responseData);
            }
        } failure:^(NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
    }
    
    if (self.hasAvatar && self.userAvatar.imageData) {
        return [UIImage imageWithData:self.userAvatar.imageData];
    }
    else {
        return [UIImage imageNamed:@"profile_image"];
    }
}

+ (void)logout
{
    // Removes all keys, except onboarding
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    NSDictionary *defaultsDictionary = [[NSUserDefaults standardUserDefaults] persistentDomainForName: appDomain];
    for (NSString *key in [defaultsDictionary allKeys]) {
        if (![key isEqualToString:kUserHasOnboardedKey] && ![key isEqualToString:kForcedUpdateKey] &&
            ![key isEqualToString:kFirstTimeRunKey] && ![key isEqualToString:kPushMessagingRegistrationKey]) {
            NSLog(@"removing user pref for %@", key);
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[ZDKConfig instance] setUserIdentity:nil];
    [[ZDKSdkStorage instance] clearUserData];
    [[ZDKSdkStorage instance].settingsStorage deleteStoredData];
    
    [[RLMRealm defaultRealm] beginWriteTransaction];
    [[RLMRealm defaultRealm] deleteAllObjects];
    [[RLMRealm defaultRealm] commitWriteTransaction];
    
    [AFOAuthCredential deleteCredentialWithIdentifier:MTNetworkServiceOAuthCredentialKey];
}

+ (BOOL)isCurrentUserMentor
{
    if ([[[MTUser currentUser].roleCode uppercaseString] isEqualToString:@"MENTOR"]) {
        return YES;
    }
    else {
        return NO;
    }
}

+ (BOOL)isUserMentor:(MTUser *)user
{
    if ([[user.roleCode uppercaseString] isEqualToString:@"MENTOR"]) {
        return YES;
    }
    else {
        return NO;
    }
}

+ (BOOL)isUserMe:(MTUser *)user
{
    return user.currentUser;
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

+ (MTUser *)currentUser;
{
    RLMResults *meUsers = [MTUser objectsWhere:@"currentUser = YES"];
    return [meUsers firstObject];
}


@end
