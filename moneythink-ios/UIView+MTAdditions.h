//
//  UIView+MTAdditions.h
//  moneythink-ios
//
//  Created by David Sica on 10/03/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (MTAdditions)

+ (UIView *)viewFromNib:(NSString *)nibName bundle:(NSBundle *)bundle;
- (UIView *)findSuperViewWithClass:(Class)superViewClass;
- (UIView *)findViewThatIsFirstResponder;

@end
