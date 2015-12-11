//
//  MTLoadingView.h
//  moneythink-ios
//
//  Created by Colin Young on 12/2/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTLoadingView : UIView

@property (nonatomic, retain) IBOutlet UIView *view;

@property (nonatomic, retain) IBOutlet UILabel *textLabel;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *activityIndicator;

- (void)setMessage:(NSString *)message;

- (void)startLoading;
- (void)stopLoadingSuccessfully:(BOOL)success;

@end
