//
//  MTRefreshView.h
//  moneythink-ios
//
//  Created by Colin Young on 12/7/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JYRefreshView.h"

@interface MTRefreshView : UIView <JYRefreshView>

- (void)scrollView:(UIScrollView *)scrollView contentOffsetDidUpdate:(CGPoint)contentOffset;

- (void)start;
- (void)stop;

@end
