//
//  MTEmoji.h
//  moneythink-ios
//
//  Created by David Sica on 8/26/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@interface MTEmoji : RLMObject

@property NSString *code;
@property NSDate *createdAt;
@property NSDate *updatedAt;
@property MTOptionalImage *emojiImage;
@property NSInteger ranking;
@property BOOL isDeleted;

+ (void)markAllDeleted;
+ (void)removeAllDeleted;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTEmoji>
RLM_ARRAY_TYPE(MTEmoji)
