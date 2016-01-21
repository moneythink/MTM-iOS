//
//  MTOrganization.h
//  moneythink-ios
//
//  Created by David Sica on 7/13/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@interface MTOrganization : RLMObject

@property NSInteger id;
@property NSString *name;
@property NSString *mentorSignupCode;
@property BOOL isActive;
@property BOOL isDeleted;

+ (void)markAllDeleted;
+ (void)markAllDeletedExcept:(RLMObject *)object;
+ (void)removeAllDeleted;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTOrganization>
RLM_ARRAY_TYPE(MTOrganization)
