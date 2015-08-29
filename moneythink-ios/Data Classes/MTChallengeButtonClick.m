//
//  MTChallengeButtonClick.m
//  moneythink-ios
//
//  Created by David Sica on 8/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTChallengeButtonClick.h"

@implementation MTChallengeButtonClick

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
             @"assignedAt": @"assignedAt",
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"id": @"id",
             @"assignedAt": @"assignedAt",
             };
}

@end
