//
//  MTChallengePostComment.h
//  moneythink-ios
//
//  Created by David Sica on 8/24/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@interface MTChallengePostComment : RLMObject

@property NSInteger id;
@property NSString *content;
@property NSDate *createdAt;
@property NSDate *updatedAt;
@property BOOL isDeleted;

@property MTUser *user;
@property MTChallengePost *challengePost;

+ (BOOL)postCommentsContainsMyComment:(RLMResults *)commentArray;

@end


// This protocol enables typed collections. i.e.:
// RLMArray<MTChallengePostComment>
RLM_ARRAY_TYPE(MTChallengePostComment)
