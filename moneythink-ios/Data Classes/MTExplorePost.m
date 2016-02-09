//
//  MTChallengePost.m
//  moneythink-ios
//
//  Created by Colin Young on 2/9/16.
//  Copyright (c) 2016 Moneythink. All rights reserved.
//

#import "MTExplorePost.h"

@implementation MTExplorePost

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

+ (NSDictionary *)JSONInboundMappingDictionary {
    return @{
             @"post_id" : @"postId",
             @"post_content" : @"postContent",
             @"challenge_id" : @"challengeId",
             @"post_created_at": @"createdAt",
             @"user_id" : @"userId",
             @"user_name" : @"userName"
             };
}

+ (NSString *)primaryKey {
    return @"postId";
}

#pragma mark - Custom Methods -
+ (void)deleteAll
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *deletedObjects = [MTExplorePost allObjects];
    if (!IsEmpty(deletedObjects)) {
        [realm deleteObjects:deletedObjects];
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Removed all MTExplorePost objects");
}

- (UIImage *)loadPostImageWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    if (self.postPicture == nil) {
        [[MTNetworkManager sharedMTNetworkManager] getImageForExplorePostId:[self.postId integerValue] success:^(id responseData) {
            if (success) {
                success(responseData);
            }
        } failure:^(NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
    }
    
    if (self.postPicture && self.postPicture.imageData) {
        return [UIImage imageWithData:self.postPicture.imageData];
    }
    else {
        return nil;
    }
}

- (UIImage *)loadUserAvatarWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    if (self.userAvatar == nil) {
        [[MTNetworkManager sharedMTNetworkManager] getUserAvatarForExplorePost:self success:^(id responseData) {
            if (success) {
                success(responseData);
            }
        } failure:^(NSError *error) {
            if (failure) {
                failure(error);
            }
        }];
    }
    
    if (self.userAvatar && self.userAvatar.imageData) {
        return [UIImage imageWithData:self.userAvatar.imageData];
    }
    else {
        return [UIImage imageNamed:@"profile_image"];
    }
}

#pragma mark - other methods
- (NSNumber<RLMInt> *)id {
    return [self postId];
}

@end
