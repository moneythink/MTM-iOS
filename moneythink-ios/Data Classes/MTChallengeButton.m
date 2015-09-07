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

#pragma mark - Custom Methods -
+ (void)markAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *allObjects = [MTChallengeButton allObjects];
    NSInteger count = [allObjects count];
    for (MTChallengeButton *thisObject in allObjects) {
        thisObject.isDeleted = YES;
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Marked MTChallengeButton (%ld) deleted", (long)count);
}

+ (void)removeAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *deletedObjects = [MTChallengeButton objectsWhere:@"isDeleted = YES"];
    NSInteger count = [deletedObjects count];
    if (!IsEmpty(deletedObjects)) {
        [realm deleteObjects:deletedObjects];
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Removed deleted MTChallengeButton (%ld) objects", (long)count);
}


@end
