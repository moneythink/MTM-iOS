//
//  NSDictionary+MTAdditions.h
//  moneythink-ios
//
//  Created by David Sica on 7/23/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (MTAdditions)

- (id)safeValueForKey:(NSString *)key;

@end
