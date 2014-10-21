//
//  UIView+MTAdditions.h
//  moneythink-ios
//
//  Created by David Sica on 10/18/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "UIImage+MTAdditions.h"

@implementation UIImage (MTAdditions)

+ (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
