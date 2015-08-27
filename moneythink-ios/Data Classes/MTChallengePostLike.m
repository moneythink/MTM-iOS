//
//  MTChallengePostLike.m
//  moneythink-ios
//
//  Created by David Sica on 8/26/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTChallengePostLike.h"

@implementation MTChallengePostLike

+ (NSDictionary *)defaultPropertyValues {
    return @{@"isDeleted": @NO};
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
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"id": @"id",
             };
}


#pragma mark - Custom Methods -
+ (BOOL)postLikesContainsMyLike:(RLMResults *)likeArray;
{
    BOOL containsMe = NO;
    for (MTChallengePostLike *thisLike in likeArray) {
        if ([MTUser isUserMe:thisLike.user]) {
            containsMe = YES;
            break;
        }
    }
    
    return containsMe;
}


@end
