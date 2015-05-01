//
//  MTPostLikeUserTableViewCell.m
//  moneythink-ios
//
//  Created by David Sica on 4/30/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTPostLikeUserTableViewCell.h"

@interface MTPostLikeUserTableViewCell ()

@end

@implementation MTPostLikeUserTableViewCell


- (void)awakeFromNib {
    self.userAvatarImageView.layer.cornerRadius = round(self.userAvatarImageView.frame.size.width / 2.0f);
    self.userAvatarImageView.layer.masksToBounds = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.userAvatarImageView.image = nil;
    self.userAvatarImage = nil;
}


@end
