//
//  UIView+MTAdditions.h
//  moneythink-ios
//
//  Created by David Sica on 10/03/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIAlertView (MTAdditions)

+ (void)showNetworkAlertWithError:(NSError *)error;
+ (void)showNetworkAlertWithError:(NSError *)error completion:(void(^)(UIAlertView *alertView, NSInteger buttonIndex))completion;
+ (void)showNoInternetAlert;

@end
