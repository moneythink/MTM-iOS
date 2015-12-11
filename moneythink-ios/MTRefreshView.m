//
//  MTRefreshView.m
//  moneythink-ios
//
//  Created by Colin Young on 12/7/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import "MTRefreshView.h"

@interface MTRefreshView ()

@property (nonatomic, retain) UIActivityIndicatorView *activityIndicatorView;

- (UIActivityIndicatorView *)setupActivityIndicatorView;

@end

@implementation MTRefreshView

- (UIActivityIndicatorView *)setupActivityIndicatorView {
    if (!_activityIndicatorView) {
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [activityIndicatorView setColor:[UIColor primaryOrange]];
        [activityIndicatorView setHidesWhenStopped:NO];
        [self addSubview:activityIndicatorView];
        _activityIndicatorView = activityIndicatorView;
    }
    return _activityIndicatorView;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!_activityIndicatorView) {
        [self setupActivityIndicatorView];
    }

    CGPoint boundsCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    [self.activityIndicatorView setCenter:boundsCenter];
}

// MARK: Delegate methods
- (void)pullToLoadMoreController:(JYPullToLoadMoreController *)loadMoreController
                didChangeToState:(JYLoadMoreState)loadMoreState {
    if (loadMoreState == JYLoadMoreStateLoading) {
        [self start];
    } else if (loadMoreState == JYLoadMoreStateStop) {
        [self stop];
    } else {
        [self stop];
    }
    
}

- (void)pullToRefreshController:(JYPullToRefreshController *)refreshController didChangeToState:(JYRefreshState)refreshState {
    if (refreshState == JYRefreshStateLoading) {
        [self start];
    } else if (refreshState == JYRefreshStateStop) {
        [self stop];
    } else {
        [self stop];
    }
}

// MARK: Animations
- (void)start {
    [self.activityIndicatorView startAnimating];
}

- (void)stop {
    [self.activityIndicatorView stopAnimating];
}

// MARK: Instance methods
- (void)scrollView:(UIScrollView *)scrollView contentOffsetDidUpdate:(CGPoint)contentOffset {
    CGFloat ratio = 0.0;
    CGFloat scrollViewContentHeight = scrollView.contentSize.height;
    CGFloat contentOffsetBottom = contentOffset.y + scrollView.bounds.size.height;
    
    if (contentOffset.y < 0) {
        // This is a refresh controller
        ratio = abs((int) contentOffset.y) / 44.0f;
    } else if (contentOffsetBottom > scrollViewContentHeight) {
        CGFloat base = contentOffsetBottom - scrollViewContentHeight;
        ratio = base / 44.0f;
    }
    
    ratio = fmin(ratio, 1.50f); // Max it out at 1.5x
    CGFloat degOffset = 20; // To compensate for the fact that the rotation isn't really visible until the indicator is more scrolled.
    CGFloat angleDeg = 180 + degOffset - (90 * fmin(1.50f, ratio)); /* max is a bit larger so that the indicator can appear to 'coil up' */
    CGFloat angleRad = deg2rad(angleDeg);
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformScale(transform, ratio, ratio);
    transform = CGAffineTransformRotate(transform, angleRad);
    self.activityIndicatorView.transform = transform;
}

float deg2rad(float degree)
{
    return ((degree / 180.0f) * M_PI);
}

@end
