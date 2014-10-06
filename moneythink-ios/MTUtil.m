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


@end
