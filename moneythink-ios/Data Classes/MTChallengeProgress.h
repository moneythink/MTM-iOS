//
//  MTChallengeProgress.h
//  moneythink-ios
//
//  Created by David Sica on 9/1/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@interface MTChallengeProgress : RLMObject

@property NSInteger id;
@property CGFloat progress;
@property BOOL isDeleted;

@property MTUser *user;
@property MTChallenge *challenge;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTChallengeProgress>
RLM_ARRAY_TYPE(MTChallengeProgress)
