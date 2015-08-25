//
//  MTChallengePostComment.m
//  moneythink-ios
//
//  Created by David Sica on 8/24/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTChallengePostComment.h"

@implementation MTChallengePostComment

+ (NSDictionary *)defaultPropertyValues {
    return @{@"content": @"",
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
             @"content": @"content",
             @"updatedAt": @"updatedAt",
             @"createdAt": @"createdAt"
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"id": @"id",
             @"content": @"content",
             @"updatedAt": @"updatedAt",
             @"createdAt": @"createdAt"
             };
}


#pragma mark - Custom Methods -
+ (BOOL)postCommentsContainsMyComment:(RLMResults *)commentArray;
{
    BOOL containsMe = NO;
    for (MTChallengePostComment *thisComment in commentArray) {
        if ([MTUser isUserMe:thisComment.user]) {
            containsMe = YES;
            break;
        }
    }
    
    return containsMe;
}


@end
