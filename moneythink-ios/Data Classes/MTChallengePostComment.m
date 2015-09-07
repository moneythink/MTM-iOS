//
//  MTChallengePostComment.m
//  moneythink-ios
//
//  Created by David Sica on 8/24/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTChallengePostComment.h"

@implementation MTChallengePostComment

+ (NSDictionary *)defaultPropertyValues {
    return @{@"content": @"",
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
             @"content": @"content",
             @"updatedAt": @"updatedAt",
             @"createdAt": @"createdAt"
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"id": @"id",
             @"content": @"content",
             @"updatedAt": @"updatedAt",
             @"createdAt": @"createdAt"
             };
}


#pragma mark - Custom Methods -
+ (void)markAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *allObjects = [MTChallengePostComment allObjects];
    NSInteger count = [allObjects count];
    for (MTChallengePostComment *thisObject in allObjects) {
        thisObject.isDeleted = YES;
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Marked MTChallengePostComment (%ld) deleted", (long)count);
}

+ (void)removeAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *deletedObjects = [MTChallengePostComment objectsWhere:@"isDeleted = YES"];
    NSInteger count = [deletedObjects count];
    if (!IsEmpty(deletedObjects)) {
        [realm deleteObjects:deletedObjects];
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Removed deleted MTChallengePostComment (%ld) objects", (long)count);
}

+ (BOOL)postCommentsContainsMyComment:(RLMResults *)commentArray;
{
    BOOL containsMe = NO;
    for (MTChallengePostComment *thisComment in commentArray) {
        if ([MTUser isUserMe:thisComment.user]) {
            containsMe = YES;
            break;
        }
    }
    
    return containsMe;
}


@end
