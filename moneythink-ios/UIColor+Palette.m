    //
    //  UIColor+Palette.m
    //  moneythink-ios
    //
    //  Created by jdburgie on 7/16/14.
    //  Copyright (c) 2014 Moneythink. All rights reserved.
    //

#import "UIColor+Palette.h"

@implementation UIColor (Palette)

+ (UIColor *)primaryOrange
{
    return [UIColor colorWithHexString:@"#f7a341"];
}

+ (UIColor *)primaryOrangeDark
{
    return [UIColor colorWithHexString:@"#BB6705"];
}

+ (UIColor *)mutedOrange
{
    return [UIColor colorWithHexString:@"#fdefd2"];
}

+ (UIColor *)primaryGreen;
{
    return [UIColor colorWithHexString:@"#1abf97"];
}

+ (UIColor *)primaryGreenDark;
{
    return [UIColor colorWithHexString:@"#00976F"];
}

+ (UIColor *)menuLightGreen;
{
    return [UIColor colorWithHexString:@"#23a275"];
}

+ (UIColor *)menuDarkGreen;
{
    return [UIColor colorWithHexString:@"#2b906a"];
}

+ (UIColor *)menuHightlightGreen
{
    return [UIColor colorWithHexString:@"#79c09f"];
}

+ (UIColor *)mutedGreen;
{
    return [UIColor colorWithHexString:@"#a1d4b0"];
}

+ (UIColor *)lightGreen;
{
    return [UIColor colorWithHexString:@"#c6f0e5"];
}

+ (UIColor *)darkGrey;
{
    return [UIColor colorWithHexString:@"#58595b"];
}

+ (UIColor *)grey;
{
    return [UIColor colorWithHexString:@"#bdc0c7"];
}

+ (UIColor *)lightGrey;
{
    return [UIColor colorWithHexString:@"#ecedef"];
}

+ (UIColor *)navbarGrey
{
    return [UIColor colorWithHexString:@"#677377"];
}

+ (UIColor *)lightTan;
{
    return [UIColor colorWithHexString:@"#f7f6f3"];
}

+ (UIColor *)white;
{
    return [UIColor colorWithHexString:@"#ffffff"];
}

+ (UIColor *)redOrange;
{
    return [UIColor colorWithHexString:@"#fe4e00"];
}

+ (UIColor *)lightRedOrange
{
    return [UIColor colorWithHexString:@"#ffd2c0"];
}

+ (UIColor *)challengeViewToggleButtonBackgroundNormal;
{
    return [UIColor colorWithHexString:@"#f4f5f4"];
}

+ (UIColor *)challengeViewToggleButtonBackgroundHighlighted;
{
    return [UIColor colorWithHexString:@"#e7ebe8"];
}

+ (UIColor *)challengeViewToggleButtonBackgroundSelected;
{
    return [UIColor colorWithHexString:@"#e7ebe8"];
}

+ (UIColor *)challengeViewToggleButtonTitleNormal;
{
    return [UIColor colorWithHexString:@"#687377"];
}

+ (UIColor *)challengeViewToggleButtonTitleHighlighted;
{
    return [UIColor colorWithHexString:@"#687377"];
}

+ (UIColor *)challengeViewToggleButtonTitleSelected;
{
    return [UIColor colorWithHexString:@"#292c2d"];
}

+ (UIColor *)challengeViewToggleHighlightNormal;
{
    return [UIColor colorWithHexString:@"#bbbebd"];
}

+ (UIColor *)votingRed
{
    return [UIColor colorWithHexString:@"#7f2a27"];
}

+ (UIColor *)votingPurple
{
    return [UIColor colorWithHexString:@"#55406c"];
}

+ (UIColor *)votingBlue
{
    return [UIColor colorWithHexString:@"#5284cd"];
}

+ (UIColor *)votingGreen
{
    return [UIColor colorWithHexString:@"#668338"];
}

+ (UIColor *) colorWithHexString: (NSString *) hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            [NSException raise:@"Invalid color value" format: @"Color value %@ is invalid.  It should be a hex value of the form #RBG, #ARGB, #RRGGBB, or #AARRGGBB", hexString];
            break;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

+ (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

+ (UIColor *)lighterColorForColor:(UIColor *)c
{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MIN(r + 0.2, 1.0)
                               green:MIN(g + 0.2, 1.0)
                                blue:MIN(b + 0.2, 1.0)
                               alpha:a];
    return nil;
}

+ (UIColor *)darkerColorForColor:(UIColor *)c
{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MAX(r - 0.2, 0.0)
                               green:MAX(g - 0.2, 0.0)
                                blue:MAX(b - 0.2, 0.0)
                               alpha:a];
    return nil;
}

@end
