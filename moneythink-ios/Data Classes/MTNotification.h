//
//  MTNotification.h
//  moneythink-ios
//
//  Created by David Sica on 9/2/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@interface MTNotification : RLMObject

@property NSInteger id;
@property NSString *notificationType;
@property NSString *message;
@property NSDate *createdAt;
@property NSDate *updatedAt;
@property BOOL read;
@property BOOL isDeleted;

@property MTChallenge *relatedChallenge;
@property MTUser *relatedUser;
@property MTChallengePost *relatedPost;
@property MTChallengePostComment *relatedComment;

@property RLMArray<MTUser> *recipients;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTNotification>
RLM_ARRAY_TYPE(MTNotification)
