//
//  MTChallengePost.h
//  moneythink-ios
//
//  Created by Colin Young on 2/9/16.
//  Copyright (c) 2016 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@class MTOptionalImage;

@interface MTExplorePost : RLMObject

@property NSNumber<RLMInt> *postId;
@property NSNumber<RLMInt> *challengeId;
@property NSNumber<RLMInt> *userId;
@property MTOptionalImage *postPicture;
@property NSDate *createdAt;
@property NSString *userName;
@property MTOptionalImage *userAvatar;
@property NSString *postContent;

- (UIImage *)loadPostImageWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (UIImage *)loadUserAvatarWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

+ (void)deleteAll;
- (NSNumber<RLMInt> *)id;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTChallengePost>
RLM_ARRAY_TYPE(MTExplorePost)
