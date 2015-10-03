//
//  MTChallenge.h
//  moneythink-ios
//
//  Created by David Sica on 8/17/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@interface MTChallenge : RLMObject

@property NSInteger id;
@property BOOL autoVerify;
@property MTOptionalImage *banner;
@property NSDate *createdAt;
@property NSString *challengeDescription;
@property NSInteger difficulty;
@property NSString *goal;
@property BOOL isActive;
@property BOOL isPrivate;
@property NSInteger maxPoints;
@property NSString *mentorInstructions;
@property NSString *outcome;
@property NSInteger pointsPerPost;
@property NSInteger ranking;
@property NSString *studentInstructions;
@property NSString *tagline;
@property NSString *title;
@property NSDate *updatedAt;
@property NSString *postExtraFields;
@property NSString *rewardsInfo;
@property BOOL isPlaylistChallenge;
@property BOOL isDeleted;

+ (void)markAllDeleted;
+ (void)removeAllDeleted;

- (UIImage *)loadBannerImageWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTChallenge>
RLM_ARRAY_TYPE(MTChallenge)
