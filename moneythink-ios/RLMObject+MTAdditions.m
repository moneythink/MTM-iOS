//
//  UIView+MTAdditions.m
//  moneythink-ios
//
//  Created by David Sica on 10/03/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "RLMObject+MTAdditions.h"

@implementation RLMObject (MTAdditions)


// withJSONDictionary does not seem to work with new, Realm 0.92 "nullable" columns
- (void)setValue:(id)value forNullableDateKey:(NSString *)key {
    if (![value isKindOfClass:[NSNull class]]) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];

        [formatter setLocale:enUSPOSIXLocale];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
        [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

        NSDate *date = [formatter dateFromString:(NSString *)value];
        [self setValue:date forKey:key];
    } else {
        [self setValue:nil forKey:key];
    }
}

@end
