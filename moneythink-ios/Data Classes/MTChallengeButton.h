//
//  MTChallengeButton.h
//  moneythink-ios
//
//  Created by David Sica on 8/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@interface MTChallengeButton : RLMObject

@property NSInteger id;
@property NSString *label;
@property NSInteger ranking;
@property NSInteger points;
@property NSDate *createdAt;
@property NSDate *updatedAt;
@property NSString *buttonTypeCode;
@property BOOL isDeleted;

@property MTChallenge *challenge;

+ (void)markAllDeleted;
+ (void)removeAllDeleted;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTChallengeButton>
RLM_ARRAY_TYPE(MTChallengeButton)
