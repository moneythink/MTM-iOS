//
//  MTClass.h
//  moneythink-ios
//
//  Created by David Sica on 7/13/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@class MTOrganization;

@interface MTClass : RLMObject

@property NSInteger id;
@property NSString *name;
@property NSString *studentSignupCode;
@property BOOL isDeleted;
@property NSDate *archivedAt;

@property MTOrganization *organization;

+ (void)markAllDeleted;
+ (void)markAllDeletedExcept:(RLMObject *)object;
+ (void)removeAllDeleted;

- (BOOL)isArchived;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTClass>
RLM_ARRAY_TYPE(MTClass)
