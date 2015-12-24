//
//  MTClass.m
//  moneythink-ios
//
//  Created by David Sica on 7/13/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTClass.h"

@implementation MTClass

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues {
    return @{@"name" : @"",
             @"studentSignupCode": @"",
             @"isDeleted": @NO,
             @"isArchived": @NO};
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
             @"name": @"name",
             @"studentSignupCode": @"studentSignupCode",
             @"isArchived" : @"isArchived"
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"id": @"id",
             @"name": @"name",
             @"studentSignupCode": @"studentSignupCode",
             };
}


#pragma mark - Custom Methods -
+ (void)markAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *allObjects = [MTClass allObjects];
    NSInteger count = [allObjects count];
    for (MTClass *thisObject in allObjects) {
        thisObject.isDeleted = YES;
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Marked MTClass (%ld) deleted", (long)count);
}

+ (void)removeAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *deletedObjects = [MTClass objectsWhere:@"isDeleted = YES"];
    NSInteger count = [deletedObjects count];
    if (!IsEmpty(deletedObjects)) {
        [realm deleteObjects:deletedObjects];
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Removed deleted MTClass (%ld) objects", (long)count);
}


@end
