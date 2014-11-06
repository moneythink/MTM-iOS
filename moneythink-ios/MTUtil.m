//
//  MTUtil.m
//  moneythink-ios
//
//  Created by David Sica on 10/03/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTUtil.h"

@implementation MTUtil

+ (BOOL)internetReachable
{
    Reachability *internetReach = [Reachability reachabilityForInternetConnection];
	NetworkStatus netStatus = [internetReach currentReachabilityStatus];
	if (netStatus == NotReachable)
        return NO;
    return YES;
}

+ (id)getAppDelegate
{
    return [UIApplication sharedApplication].delegate;
}

+ (BOOL)displayingCustomPlaylist
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"DisplayingCustomPlaylist"];
}

+ (void)setDisplayingCustomPlaylist:(BOOL)diplayingCustomPlaylist
{
    [[NSUserDefaults standardUserDefaults] setBool:diplayingCustomPlaylist forKey:@"DisplayingCustomPlaylist"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSInteger)orderingForChallengeObjectId:(NSString *)objectId
{
    NSNumber *ordering = [[NSUserDefaults standardUserDefaults] objectForKey:objectId];
    if (ordering) {
        return [ordering integerValue];
    }
    else {
        return -1;
    }
}

+ (void)setOrdering:(NSInteger)ordering forChallengeObjectId:(NSString *)objectId
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:ordering] forKey:objectId];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
