//
//  MTUserPostPropertyCount.m
//  moneythink-ios
//
//  Created by David Sica on 9/3/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTUserPostPropertyCount.h"

@implementation MTUserPostPropertyCount

// Specify default values for properties
+ (NSDictionary *)defaultPropertyValues {
    return @{@"likeCount" : @0,
             @"commentCount": @0};
}

// Specify properties to ignore (Realm won't persist these)
//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}
//

+ (NSString *)primaryKey {
    return @"complexId";
}


#pragma mark - Realm+JSON Methods -
+ (NSDictionary *)JSONInboundMappingDictionary {
    return @{
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             };
}

@end
