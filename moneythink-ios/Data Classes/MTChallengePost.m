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
             @"content": @""};
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
- (UIImage *)loadPostImageWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    BOOL shouldFetchImage = NO;
    
    if (self.hasPostImage && !self.postImage) {
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


@end
