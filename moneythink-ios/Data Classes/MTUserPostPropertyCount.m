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
             @"commentCount": @0,
             @"isDeleted": @NO};
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


#pragma mark - Custom Methods -
+ (void)markAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *allObjects = [MTUserPostPropertyCount allObjects];
    NSInteger count = [allObjects count];
    for (MTUserPostPropertyCount *thisObject in allObjects) {
        thisObject.isDeleted = YES;
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Marked MTUserPostPropertyCount (%ld) deleted", (long)count);
}

+ (void)removeAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *deletedObjects = [MTUserPostPropertyCount objectsWhere:@"isDeleted = YES"];
    NSInteger count = [deletedObjects count];
    if (!IsEmpty(deletedObjects)) {
        [realm deleteObjects:deletedObjects];
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Removed deleted MTUserPostPropertyCount (%ld) objects", (long)count);
}


@end
