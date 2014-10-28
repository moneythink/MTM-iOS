//
//  MTLabel.m
//  moneythink-ios
//
//  Created by David Sica on 10/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTLabel.h"

@implementation MTLabel

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.numberOfLines == 0) {
        
        // If this is a multiline label, need to make sure
        // preferredMaxLayoutWidth always matches the frame width
        // (i.e. orientation change can mess this up)
        
        if (self.preferredMaxLayoutWidth != self.frame.size.width) {
            self.preferredMaxLayoutWidth = self.frame.size.width;
            [self setNeedsUpdateConstraints];
        }
    }
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    
    if (self.numberOfLines == 0) {
        
        // There's a bug where intrinsic content size
        // may be 1 point too short
        
        size.height += 1;
    }
    
    return size;
}

@end
