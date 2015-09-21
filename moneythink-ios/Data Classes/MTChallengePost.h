//
//  MTChallengePost.h
//  moneythink-ios
//
//  Created by David Sica on 8/19/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@interface MTChallengePost : RLMObject

@property NSInteger id;
@property NSString *content;
@property BOOL isVerified;
@property NSDate *createdAt;
@property NSDate *updatedAt;
@property MTOptionalImage *postImage;
@property BOOL hasPostImage;
@property NSString *extraFields;
@property BOOL isDeleted;

@property MTUser *user;
@property MTChallenge *challenge;
@property MTClass *challengeClass;

- (UIImage *)loadPostImageWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (BOOL)isPostInMyClass;

+ (void)markAllDeleted;
+ (void)removeAllDeleted;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTChallengePost>
RLM_ARRAY_TYPE(MTChallengePost)
