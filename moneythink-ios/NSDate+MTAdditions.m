//
//  NSDate+MTAdditions.m
//  moneythink-ios
//
//  Created by David Sica on 10/13/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "NSDate+MTAdditions.h"

@implementation NSDate (MTAdditions)

- (NSString *)niceRelativeTimeFromNow
{
    NSTimeInterval secSinceModified = MTMax(1, [[NSDate date] timeIntervalSinceDate: self]);
    if (secSinceModified < 30)
        return @"just now";
    return [NSString stringWithFormat: @"%@ ago", [NSDate secondsToString:secSinceModified abbreviate:YES]];
}

+ (NSString *)secondsToString:(NSUInteger)seconds abbreviate:(BOOL)abbreviate
{
    NSUInteger minutes = seconds / 60;
    NSUInteger hours = minutes / 60;
    NSUInteger days = hours / 24;
    NSUInteger months = days / 30;
    NSUInteger years = months / 12;
    
    if (years)
        return [NSString stringWithFormat: @"%ju%@%@%@", (uintmax_t)years, (abbreviate ? @"" : @" "), (abbreviate ? @"yr" : @"year"), (!abbreviate && years > 1 ? @"s" : @"")];
    
    else if (months)
        return [NSString stringWithFormat: @"%ju%@%@%@", (uintmax_t)months, (abbreviate ? @"" : @" "), (abbreviate ? @"mo" : @"month"), (!abbreviate && months > 1 ? @"s" : @"")];
    
    else if (days)
        return [NSString stringWithFormat: @"%ju%@%@%@", (uintmax_t)days, (abbreviate ? @"" : @" "), (abbreviate ? @"d" : @"day"), (!abbreviate && days > 1 ? @"s" : @"")];
    
    else if (hours)
        return [NSString stringWithFormat: @"%ju%@%@%@", (uintmax_t)hours, (abbreviate ? @"" : @" "), (abbreviate ? @"hr" : @"hour"), (!abbreviate && hours > 1 ? @"s" : @"")];
    
    else if (minutes)
        return [NSString stringWithFormat: @"%ju%@%@%@", (uintmax_t)minutes, (abbreviate ? @"" : @" "), (abbreviate ? @"m" : @"minute"), (!abbreviate && minutes > 1 ? @"s" : @"")];
    
    else
        return [NSString stringWithFormat: @"%ju%@%@%@", (uintmax_t)seconds, (abbreviate ? @"" : @" "), (abbreviate ? @"s" : @"second"), (!abbreviate && seconds > 1 ? @"s" : @"")];
}

@end
