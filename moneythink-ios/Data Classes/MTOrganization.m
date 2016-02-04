//
//  MTOrganization.m
//  moneythink-ios
//
//  Created by David Sica on 7/13/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTOrganization.h"

@implementation MTOrganization

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues {
    return @{@"name" : @"",
             @"mentorSignupCode": @"",
             @"isActive": @YES,
             @"isDeleted": @NO,
             @"subscriptionIncludesDirectMessaging": @NO
             };
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
             @"mentorSignupCode": @"mentorSignupCode",
             @"subscriptionIncludesDirectMessaging" : @"subscriptionIncludesDirectMessaging"
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"id": @"id",
             @"name": @"name",
             @"mentorSignupCode": @"mentorSignupCode",
             @"subscriptionIncludesDirectMessaging": @"subscriptionIncludesDirectMessaging"
             };
}


#pragma mark - Custom Methods -
+ (void)markAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *allObjects = [MTOrganization allObjects];
    NSInteger count = [allObjects count];
    for (MTOrganization *thisObject in allObjects) {
        thisObject.isDeleted = YES;
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Marked MTOrganization (%ld) deleted", (long)count);
}

+ (void)markAllDeletedExcept:(RLMObject *)object
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *allObjects = [MTOrganization allObjects];
    NSInteger count = [allObjects count];
    for (MTOrganization *thisObject in allObjects) {
        if ([object isEqual:thisObject]) {
            count--;
            continue;
        }
        thisObject.isDeleted = YES;
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Marked MTClass (%ld) deleted", (long)count);
}

+ (void)removeAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *deletedObjects = [MTOrganization objectsWhere:@"isDeleted = YES"];
    NSInteger count = [deletedObjects count];
    if (!IsEmpty(deletedObjects)) {
        [realm deleteObjects:deletedObjects];
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Removed deleted MTOrganization (%ld) objects", (long)count);
}


@end
