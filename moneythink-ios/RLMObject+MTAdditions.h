//
//  UIView+MTAdditions.h
//  moneythink-ios
//
//  Created by David Sica on 10/03/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RLMObject (MTAdditions)

- (void)setValue:(id)value forNullableDateKey:(NSString *)key;

@end
