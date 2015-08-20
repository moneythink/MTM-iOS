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

@end
