//
//  MTUserAvatar.h
//  moneythink-ios
//
//  Created by David Sica on 8/11/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@interface MTOptionalImage : RLMObject

@property NSData *imageData;
@property NSDate *updatedAt;
@property BOOL isDeleted;
@property BOOL isThumbnail;

+ (void)markAllDeleted;
+ (void)removeAllDeleted;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTOptionalImage>
RLM_ARRAY_TYPE(MTOptionalImage)
