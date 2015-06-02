//
//  UIColor+Palette.h
//  moneythink-ios
//
//  Created by jdburgie on 7/16/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Palette)

+ (UIColor *)primaryOrange;
+ (UIColor *)primaryOrangeDark;
+ (UIColor *)mutedOrange;
+ (UIColor *)primaryGreen;
+ (UIColor *)primaryGreenDark;
+ (UIColor *)mutedGreen;
+ (UIColor *)lightGreen;
+ (UIColor *)menuLightGreen;
+ (UIColor *)menuDarkGreen;
+ (UIColor *)menuHightlightGreen;
+ (UIColor *)darkGrey;
+ (UIColor *)grey;
+ (UIColor *)lightGrey;
+ (UIColor *)navbarGrey;
+ (UIColor *)lightTan;
+ (UIColor *)white;
+ (UIColor *)redOrange;
+ (UIColor *)lightRedOrange;

+ (UIColor *)challengeViewToggleButtonBackgroundNormal;
+ (UIColor *)challengeViewToggleButtonBackgroundHighlighted;
+ (UIColor *)challengeViewToggleButtonBackgroundSelected;

+ (UIColor *)challengeViewToggleButtonTitleNormal;
+ (UIColor *)challengeViewToggleButtonTitleHighlighted;
+ (UIColor *)challengeViewToggleButtonTitleSelected;

+ (UIColor *)challengeViewToggleHighlightNormal;

+ (UIColor *) colorWithHexString: (NSString *) hexString;

@end
