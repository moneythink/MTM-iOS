//
//  NSDictionary+MTAdditions.m
//  moneythink-ios
//
//  Created by David Sica on 7/23/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "NSDictionary+MTAdditions.h"

@implementation NSDictionary (MTAdditions)

- (id)safeValueForKey:(NSString *)key
{
    id value = !IsEmpty([self valueForKey:key]) ? [self valueForKey:key] : @"";
    return value;
}

@end
