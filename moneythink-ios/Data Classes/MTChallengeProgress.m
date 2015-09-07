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

#pragma mark - Custom Methods -
+ (void)markAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *allObjects = [MTChallengeProgress allObjects];
    NSInteger count = [allObjects count];
    for (MTChallengeProgress *thisObject in allObjects) {
        thisObject.isDeleted = YES;
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Marked MTChallengeProgress (%ld) deleted", (long)count);
}

+ (void)removeAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *deletedObjects = [MTChallengeProgress objectsWhere:@"isDeleted = YES"];
    NSInteger count = [deletedObjects count];
    if (!IsEmpty(deletedObjects)) {
        [realm deleteObjects:deletedObjects];
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Removed deleted MTChallengeProgress (%ld) objects", (long)count);
}

@end
