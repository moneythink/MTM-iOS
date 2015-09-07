//
//  MTChallengePostLike.h
//  moneythink-ios
//
//  Created by David Sica on 8/26/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@interface MTChallengePostLike : RLMObject

@property NSInteger id;
@property BOOL isDeleted;

@property MTEmoji *emoji;
@property MTChallengePost *challengePost;
@property MTUser *user;

+ (BOOL)postLikesContainsMyLike:(RLMResults *)likeArray;

+ (void)markAllDeleted;
+ (void)removeAllDeleted;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTChallengePostLike>
RLM_ARRAY_TYPE(MTChallengePostLike)
