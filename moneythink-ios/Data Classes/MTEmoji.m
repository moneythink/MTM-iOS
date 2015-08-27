//
//  MTEmoji.m
//  moneythink-ios
//
//  Created by David Sica on 8/26/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTEmoji.h"

@implementation MTEmoji

+ (NSDictionary *)defaultPropertyValues {
    return @{@"code" : @"",
             @"ranking": @0,
             @"isDeleted": @NO};
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

+ (NSString *)primaryKey {
    return @"code";
}


#pragma mark - Realm+JSON Methods -
+ (NSDictionary *)JSONInboundMappingDictionary {
    return @{
             @"code": @"code",
             @"ranking": @"ranking",
             @"createdAt": @"createdAt",
             @"updatedAt": @"updatedAt",
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"code": @"code",
             @"ranking": @"ranking",
             @"createdAt": @"createdAt",
             @"updatedAt": @"updatedAt",
             };
}


@end
