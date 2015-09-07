//
//  MTChallengeButtonClick.h
//  moneythink-ios
//
//  Created by David Sica on 8/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@interface MTChallengeButtonClick : RLMObject

@property NSInteger id;
@property NSDate *assignedAt;
@property BOOL isDeleted;

@property MTChallengePost *challengePost;
@property MTChallengeButton *challengeButton;
@property MTUser *user;

+ (void)markAllDeleted;
+ (void)removeAllDeleted;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTChallengeButtonClick>
RLM_ARRAY_TYPE(MTChallengeButtonClick)
