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

#pragma mark - Custom Methods -
+ (void)markAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *allObjects = [MTChallengeButtonClick allObjects];
    NSInteger count = [allObjects count];
    for (MTChallengeButtonClick *thisObject in allObjects) {
        thisObject.isDeleted = YES;
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Marked MTChallengeButtonClick (%ld) deleted", (long)count);
}

+ (void)removeAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *deletedObjects = [MTChallengeButtonClick objectsWhere:@"isDeleted = YES"];
    NSInteger count = [deletedObjects count];
    if (!IsEmpty(deletedObjects)) {
        [realm deleteObjects:deletedObjects];
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Removed deleted MTChallengeButtonClick (%ld) objects", (long)count);
}


@end
