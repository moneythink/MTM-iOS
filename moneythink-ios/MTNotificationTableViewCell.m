//
//  MTNotificationTableViewCell.m
//  moneythink-ios
//
//  Created by dsica on 6/9/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTNotificationTableViewCell.h"

@implementation MTNotificationTableViewCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.messageTextView.text = nil;
    self.messageTextView.attributedText = nil;
    self.agePosted.text = nil;
    self.currentIndexPath = nil;
}

-(UIEdgeInsets)layoutMargins
{
    return UIEdgeInsetsZero;
}


@end
