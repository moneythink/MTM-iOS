//
//  MTUtil.h
//  moneythink-ios
//
//  Created by David Sica on 10/03/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

@interface MTUtil : NSObject

+ (BOOL)internetReachable;
+ (id)getAppDelegate;

+ (BOOL)displayingCustomPlaylist;
+ (void)setDisplayingCustomPlaylist:(BOOL)diplayingCustomPlaylist;

+ (NSInteger)orderingForChallengeObjectId:(NSString *)objectId;
+ (void)setOrdering:(NSInteger)ordering forChallengeObjectId:(NSString *)objectId;
+ (void)logout;

@end
