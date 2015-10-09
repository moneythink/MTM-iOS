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
             @"points": @0,
             @"onboardingComplete": @NO,
             @"isDeleted": @NO};
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
             @"onboardingComplete": @"onboardingComplete",
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
+ (void)markAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *allObjects = [MTUser allObjects];
    NSInteger count = [allObjects count];
    for (MTUser *thisObject in allObjects) {
        thisObject.isDeleted = YES;
        thisObject.currentUser = NO;
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Marked MTUser (%ld) deleted", (long)count);
}

+ (void)removeAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *deletedObjects = [MTUser objectsWhere:@"isDeleted = YES"];
    NSInteger count = [deletedObjects count];
    if (!IsEmpty(deletedObjects)) {
        [realm deleteObjects:deletedObjects];
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Removed deleted MTUser (%ld) objects", (long)count);
}

- (UIImage *)loadAvatarImageWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    BOOL shouldFetchAvatar = NO;
    
    if (self.hasAvatar && !self.userAvatar) {
        shouldFetchAvatar = YES;
    }
    else if (self.hasAvatar && self.userAvatar && self.userAvatar.isDeleted) {
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

+ (BOOL)isCurrentUserMentor
{
    NSString *role = [[MTUser currentUser].roleCode uppercaseString];
    if ([role isEqualToString:@"MENTOR"] ||
        [role isEqualToString:@"LEAD"] ||
        [role isEqualToString:@"ADMIN"]) {
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
    RLMResults *meUsers = [MTUser objectsWhere:@"isDeleted = NO AND currentUser = YES"];
    return [meUsers firstObject];
}


@end
