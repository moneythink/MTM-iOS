//
//  UIView+MTAdditions.m
//  moneythink-ios
//
//  Created by David Sica on 10/03/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "UIView+MTAdditions.h"

@implementation UIView (MTAdditions)

+ (UIView *)viewFromNib:(NSString *)nibName bundle:(NSBundle *)bundle
{
    if (!nibName || [nibName length] == 0) {
        return nil;
    }
    
    UIView *view = nil;
    
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }
    
    // I assume, that there is only one root view in interface file
    NSArray *loadedObjects = [bundle loadNibNamed:nibName owner:nil options:nil];
    view = [loadedObjects lastObject];
    
    return view;
}

- (UIView *)findSuperViewWithClass:(Class)superViewClass
{
    UIView *superView = self.superview;
    UIView *foundSuperView = nil;
    
    while (nil != superView && nil == foundSuperView) {
        if ([superView isKindOfClass:superViewClass]) {
            foundSuperView = superView;
            break;
        } else {
            superView = superView.superview;
        }
    }
    return foundSuperView;
}

- (UIView *)findViewThatIsFirstResponder
{
    if (self.isFirstResponder) {
        return self;
    }
    
    for (UIView *subView in self.subviews) {
        UIView *firstResponder = [subView findViewThatIsFirstResponder];
        if (firstResponder != nil) {
            return firstResponder;
        }
    }
    
    return nil;
}


@end
