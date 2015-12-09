//
//  MTChallengePost.m
//  moneythink-ios
//
//  Created by David Sica on 8/19/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTChallengePost.h"

@implementation MTChallengePost

+ (NSDictionary *)defaultPropertyValues {
    return @{@"isVerified" : @NO,
             @"hasPostImage": @NO,
             @"extraFields": @"",
             @"content": @"",
             @"isCrossPost": @NO,
             @"isDeleted": @NO,
             @"challengeRanking": @1};
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
             @"content": @"content",
             @"isVerified": @"isVerified",
             @"createdAt": @"createdAt",
             @"updatedAt": @"updatedAt",
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"id": @"id",
             @"content": @"content",
             @"isVerified": @"isVerified",
             @"createdAt": @"createdAt",
             @"updatedAt": @"updatedAt",
             };
}

#pragma mark - Custom Methods -
+ (void)markAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *allObjects = [MTChallengePost allObjects];
    NSInteger count = [allObjects count];
    for (MTChallengePost *thisObject in allObjects) {
        thisObject.isDeleted = YES;
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Marked MTChallengePost (%ld) deleted", (long)count);
}

+ (void)removeAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *deletedObjects = [MTChallengePost objectsWhere:@"isDeleted = YES"];
    NSInteger count = [deletedObjects count];
    if (!IsEmpty(deletedObjects)) {
        [realm deleteObjects:deletedObjects];
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Removed deleted MTChallengePost (%ld) objects", (long)count);
}

- (UIImage *)loadPostImageWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    BOOL shouldFetchImage = NO;
    
    if (self.hasPostImage && !self.postImage) {
        shouldFetchImage = YES;
    }
    else if (self.hasPostImage && self.postImage && self.postImage.isDeleted) {
        shouldFetchImage = YES;
    }
    else if (self.hasPostImage && self.postImage) {
        if ([self.updatedAt timeIntervalSince1970] > [self.postImage.updatedAt timeIntervalSince1970]) {
            shouldFetchImage = YES;
        }
    }
    
    if (shouldFetchImage) {
        [[MTNetworkManager sharedMTNetworkManager] getImageForPostId:self.id success:^(id responseData) {
            if (success) {
                success(responseData);
            }
        } failure:^(NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
    }
    
    if (self.hasPostImage && self.postImage.imageData) {
        return [UIImage imageWithData:self.postImage.imageData];
    }
    else {
        return nil;
    }
}

- (BOOL)isPostInMyClass
{
    if (self.challengeClass.id == [MTUser currentUser].userClass.id) {
        return YES;
    }
    else {
        return NO;
    }
}


@end
