//
//  MTUserAvatar.h
//  moneythink-ios
//
//  Created by David Sica on 8/11/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@interface MTUserAvatar : RLMObject

@property NSData *avatarData;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTUserAvatar>
RLM_ARRAY_TYPE(MTUserAvatar)
