//
//  MTChallenge.m
//  moneythink-ios
//
//  Created by David Sica on 8/17/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTChallenge.h"

@implementation MTChallenge

+ (NSDictionary *)defaultPropertyValues {
    return @{@"autoVerify" : @NO,
             @"challengeDescription": @"",
             @"difficulty": @"",
             @"goal": @"",
             @"isActive": @NO,
             @"isPrivate": @NO,
             @"maxPoints": @0,
             @"mentorInstructions": @"",
             @"outcome": @"",
             @"pointsPerPost": @0,
             @"ranking": @0,
             @"studentInstructions": @"",
             @"tagline": @"",
             @"postExtraFields": @"",
             @"title": @"",
             @"rewardsInfo": @"",
             @"isPlaylistChallenge": @NO,
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
             @"autoVerify": @"autoVerify",
             @"createdAt": @"createdAt",
             @"description": @"challengeDescription",
             @"difficulty": @"difficulty",
             @"goal": @"goal",
             @"isActive": @"isActive",
             @"isPrivate": @"isPrivate",
             @"maxPoints": @"maxPoints",
             @"mentorInstructions": @"mentorInstructions",
             @"outcome": @"outcome",
             @"pointsPerPost": @"pointsPerPost",
             @"studentInstructions": @"studentInstructions",
             @"tagline": @"tagline",
             @"title": @"title",
             @"rewardsInfo": @"rewardsInfo",
             @"updatedAt": @"updatedAt",
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"id": @"id",
             @"autoVerify": @"autoVerify",
             @"createdAt": @"createdAt",
             @"challengeDescription": @"description",
             @"difficulty": @"difficulty",
             @"goal": @"goal",
             @"isActive": @"isActive",
             @"isPrivate": @"isPrivate",
             @"maxPoints": @"maxPoints",
             @"mentorInstructions": @"mentorInstructions",
             @"outcome": @"outcome",
             @"studentInstructions": @"studentInstructions",
             @"tagline": @"tagline",
             @"title": @"title",
             @"rewardsInfo": @"rewardsInfo",
             @"updatedAt": @"updatedAt",
             };
}


#pragma mark - Custom Methods -
+ (void)markAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *allObjects = [MTChallenge allObjects];
    NSInteger count = [allObjects count];
    for (MTChallenge *thisObject in allObjects) {
        thisObject.isDeleted = YES;
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Marked MTChallenge (%ld) deleted", (long)count);
}

+ (void)removeAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *deletedObjects = [MTChallenge objectsWhere:@"isDeleted = YES"];
    NSInteger count = [deletedObjects count];
    if (!IsEmpty(deletedObjects)) {
        [realm deleteObjects:deletedObjects];
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Removed deleted MTChallenge (%ld) objects", (long)count);
}

- (UIImage *)loadBannerImageWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    BOOL shouldFetchBanner = NO;
    
    if (!self.banner.imageData || self.banner.isDeleted) {
        shouldFetchBanner = YES;
    }
    else if ([self.updatedAt timeIntervalSince1970] > [self.banner.updatedAt timeIntervalSince1970]) {
        shouldFetchBanner = YES;
    }
    
    if (shouldFetchBanner) {
        [[MTNetworkManager sharedMTNetworkManager] getChallengeBannerImageForChallengeId:self.id success:^(id responseData) {
            if (success) {
                success(responseData);
            }
        } failure:^(NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
    }
    
    if (self.banner.imageData) {
        return [UIImage imageWithData:self.banner.imageData];
    }
    else {
        return nil;
    }
}


@end
