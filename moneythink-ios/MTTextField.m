//
//  MTTextField.m
//  moneythink-ios
//
//  Created by David Sica on 7/20/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTTextField.h"

IB_DESIGNABLE
@implementation MTTextField

@synthesize xPadding;
@synthesize yPadding;

-(CGRect)textRectForBounds:(CGRect)bounds{
    return CGRectInset(bounds, xPadding, yPadding);
}

-(CGRect)editingRectForBounds:(CGRect)bounds{
    return [self textRectForBounds:bounds];
}

@end

