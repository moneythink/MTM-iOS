//
//  MTUserPostPropertyCount.h
//  moneythink-ios
//
//  Created by David Sica on 9/3/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@interface MTUserPostPropertyCount : RLMObject

@property NSString *complexId;
@property MTUser *user;
@property MTChallengePost *post;
@property NSInteger likeCount;
@property NSInteger commentCount;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTUserPostPropertyCount>
RLM_ARRAY_TYPE(MTUserPostPropertyCount)
