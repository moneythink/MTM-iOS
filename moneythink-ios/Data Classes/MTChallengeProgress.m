//
//  MTChallengeProgress.m
//  moneythink-ios
//
//  Created by David Sica on 9/1/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTChallengeProgress.h"

@implementation MTChallengeProgress

+ (NSDictionary *)defaultPropertyValues {
    return @{@"progress" : @0,
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
             @"progress": @"progress",
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"id": @"id",
             @"progress": @"progress",
             };
}

@end
