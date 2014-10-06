//
//  UIView+MTAdditions.m
//  moneythink-ios
//
//  Created by David Sica on 10/03/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "UIAlertView+MTAdditions.h"

@implementation UIAlertView (MTAdditions)

+ (void)showNetworkAlertWithError:(NSError *)error
{
    UIAlertView *alert = [UIAlertView networkAlertViewWithError:error];
    [alert show];
}

+ (void)showNetworkAlertWithError:(NSError *)error completion:(void(^)(UIAlertView *alertView, NSInteger buttonIndex))completion
{
    UIAlertView *alert = [UIAlertView networkAlertViewWithError:error];
    [UIAlertView bk_showAlertViewWithTitle:alert.title message:alert.message cancelButtonTitle:@"OK" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (completion) {
            completion(alertView, buttonIndex);
        }
    }];
}

+ (UIAlertView *)networkAlertViewWithError:(NSError *)error
{
    NSString *title = @"Network Error";
    if (error != nil) {
        title = [title stringByAppendingFormat:@" (%lu)", error.code];
    }
    
    NSString *message = nil;
    if (![MTUtil internetReachable]) {
        message = @"The Internet connection appears to be offline.  Connect to the Internet to restore functionality.";
    }
    else {
        message = @"An error occurred connecting to MoneyThink.";
    }
    
    NSString *cancelButtonTitle = @"OK";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
    return alert;
}

+ (void)showNoInternetAlert
{
    NSString *title = @"Network Error";
    NSString *message = @"The Internet connection appears to be offline.  Connect to the Internet to restore functionality.";
    NSString *cancelButtonTitle = @"OK";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
    [alert show];
}

@end
