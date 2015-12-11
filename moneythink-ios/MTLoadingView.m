//
//  MTLoadingView.m
//  moneythink-ios
//
//  Created by Colin Young on 12/2/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import "MTLoadingView.h"

@implementation MTLoadingView

- (void)setMessage:(NSString *)message {
    self.textLabel.text = message;
}

- (void)setIsLoading:(BOOL)isLoading {
    [self.activityIndicator setHidden:!isLoading];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"MTLoadingView" owner:self options:nil];
        self.view.frame = CGRectMakeCenteredInScreen(self.frame.size.width, self.frame.size.height);
        [self addSubview:self.view];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self)
    {
        [[NSBundle mainBundle] loadNibNamed:@"MTLoadingView" owner:self options:nil];
        self.view.frame = CGRectMakeCenteredInScreen(self.frame.size.width, self.frame.size.height);
        [self addSubview:self.view];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self.activityIndicator startAnimating];
}

- (void)startLoading {
    [self setIsLoading:YES];
    [self setHidden:NO];
    [self.activityIndicator startAnimating];
}

- (void)stopLoadingSuccessfully:(BOOL)success {
    [self setIsLoading:NO];
    [self.activityIndicator stopAnimating];
    [self setHidden:success];
    if (!success) {
        [self setMessage:@"No results found."];
    }
}

@end