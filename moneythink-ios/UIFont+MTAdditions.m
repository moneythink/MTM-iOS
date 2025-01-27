//
//  UIVFont+MTAdditions.h
//  moneythink-ios
//
//  Created by David Sica on 10/21/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "UIFont+MTAdditions.h"

@implementation UIFont (MTAdditions)


#pragma mark - Fonts
+ (UIFont *)mtFontOfSize:(CGFloat)fontSize {
	NSString *fontName = @"HelveticaNeue";
	return [self fontWithName:fontName size:fontSize];
}

+ (UIFont *)mtLightFontOfSize:(CGFloat)fontSize {
    NSString *fontName = @"HelveticaNeue-Light";
    return [self fontWithName:fontName size:fontSize];
}

+ (UIFont *)mtBoldFontOfSize:(CGFloat)fontSize {
    NSString *fontName = @"HelveticaNeue-Bold";
    return [self fontWithName:fontName size:fontSize];
}

@end
