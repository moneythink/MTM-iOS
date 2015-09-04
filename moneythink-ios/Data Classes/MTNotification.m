//
//  MTNotification.m
//  moneythink-ios
//
//  Created by David Sica on 9/2/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTNotification.h"

@implementation MTNotification

+ (NSDictionary *)defaultPropertyValues {
    return @{@"notificationType" : @"",
             @"message": @"",
             @"read": @NO,
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
             @"read": @"read",
             @"message": @"message",
             @"createdAt": @"createdAt",
             @"updatedAt": @"updatedAt",
             @"_embedded.notificationType.code": @"notificationType",
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             };
}

@end
