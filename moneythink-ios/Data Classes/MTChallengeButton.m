//
//  MTChallengeButton.m
//  moneythink-ios
//
//  Created by David Sica on 8/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTChallengeButton.h"

@implementation MTChallengeButton

+ (NSDictionary *)defaultPropertyValues {
    return @{@"label" : @"",
             @"ranking": @0,
             @"points": @0,
             @"buttonTypeCode": @"",
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
             @"label": @"label",
             @"points": @"points",
             @"ranking": @"ranking",
             @"button_type_code": @"buttonTypeCode",
             @"createdAt": @"createdAt",
             @"updatedAt": @"updatedAt",
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"id": @"id",
             @"label": @"label",
             @"points": @"points",
             @"ranking": @"ranking",
             @"button_type_code": @"buttonTypeCode",
             @"createdAt": @"createdAt",
             @"updatedAt": @"updatedAt",
             };
}

@end
