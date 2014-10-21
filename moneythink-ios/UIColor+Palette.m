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

+ (UIColor *)mutedGreen;
{
    return [UIColor colorWithHexString:@"#a1d4b0"];
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

@end
