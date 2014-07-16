//
//  UIColor+Palette.h
//  moneythink-ios
//
//  Created by jdburgie on 7/16/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Palette)

//@property (nonatomic, strong) UIColor *primaryOrange;
//@property (nonatomic, strong) UIColor *mutedOrange;
//@property (nonatomic, strong) UIColor *primaryGreen;
//@property (nonatomic, strong) UIColor *mutedGreen;
//@property (nonatomic, strong) UIColor *DarkGrey;
//@property (nonatomic, strong) UIColor *Grey;
//@property (nonatomic, strong) UIColor *lightGrey;
//@property (nonatomic, strong) UIColor *lightTan;
//@property (nonatomic, strong) UIColor *white;
//@property (nonatomic, strong) UIColor *redOrange;

+ (UIColor *)primaryOrange;
+ (UIColor *)mutedOrange;
+ (UIColor *)primaryGreen;
+ (UIColor *)mutedGreen;
+ (UIColor *)darkGrey;
+ (UIColor *)grey;
+ (UIColor *)lightGrey;
+ (UIColor *)lightTan;
+ (UIColor *)white;
+ (UIColor *)redOrange;

+ (UIColor *) colorWithHexString: (NSString *) hexString;

@end
