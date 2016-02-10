//
//  MTUserAvatar.m
//  moneythink-ios
//
//  Created by David Sica on 8/11/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTOptionalImage.h"

@implementation MTOptionalImage

+ (NSDictionary *)defaultPropertyValues {
    return @{
             @"isDeleted": @NO,
             @"isThumbnail": @NO
             };
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}


#pragma mark - Custom Methods -
+ (void)markAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *allObjects = [MTOptionalImage allObjects];
    NSInteger count = [allObjects count];
    for (MTOptionalImage *thisObject in allObjects) {
        thisObject.isDeleted = YES;
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Marked MTOptionalImage (%ld) deleted", (long)count);
}

+ (void)removeAllDeleted
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    RLMResults *deletedObjects = [MTOptionalImage objectsWhere:@"isDeleted = YES"];
    NSInteger count = [deletedObjects count];
    if (!IsEmpty(deletedObjects)) {
        [realm deleteObjects:deletedObjects];
    }
    [realm commitWriteTransaction];
    
    NSLog(@"Removed deleted MTOptionalImage (%ld) objects", (long)count);
}


@end
