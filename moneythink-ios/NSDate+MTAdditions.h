//
//  NSDate+MTAdditions.h
//  moneythink-ios
//
//  Created by David Sica on 10/13/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#define MTMax(a, b)           \
({                            \
__typeof__(a) __a = (a);      \
__typeof__(b) __b = (b);      \
__a < __b ? __b : __a;        \
})

#import <Foundation/Foundation.h>

@interface NSDate (MTAdditions)

- (NSString *)niceRelativeTimeFromNow;

+ (NSString *)secondsToString:(NSUInteger)seconds abbreviate:(BOOL)abbreviate;

@end
