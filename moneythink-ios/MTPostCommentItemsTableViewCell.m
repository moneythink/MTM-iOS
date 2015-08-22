//
//  MTPostCommentItemsTableViewCell.m
//  moneythink-ios
//
//  Created by David Sica on 10/27/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTPostCommentItemsTableViewCell.h"

@implementation MTPostCommentItemsTableViewCell

- (void)awakeFromNib {
    self.userAvatarImageView.layer.cornerRadius = round(self.userAvatarImageView.frame.size.width / 2.0f);
    self.userAvatarImageView.layer.masksToBounds = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.userAvatarImageView.image = nil;
    self.separatorView.hidden = NO;
}


@end
