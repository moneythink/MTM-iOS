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


#pragma mark - Custom Methods -
+ (void)markAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *allObjects = [MTNotification allObjects];
    NSInteger count = [allObjects count];
    for (MTNotification *thisObject in allObjects) {
        thisObject.isDeleted = YES;
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Marked MTNotification (%ld) deleted", (long)count);
}

+ (void)removeAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *deletedObjects = [MTNotification objectsWhere:@"isDeleted = YES"];
    NSInteger count = [deletedObjects count];
    if (!IsEmpty(deletedObjects)) {
        [realm deleteObjects:deletedObjects];
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Removed deleted MTNotification (%ld) objects", (long)count);
}


@end
