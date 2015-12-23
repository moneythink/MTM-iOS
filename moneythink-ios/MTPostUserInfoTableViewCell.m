//
//  MTPostUserInfoTableViewCell.m
//  moneythink-ios
//
//  Created by David Sica on 10/24/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTPostUserInfoTableViewCell.h"

@interface MTPostUserInfoTableViewCell ()

@end

@implementation MTPostUserInfoTableViewCell


- (void)awakeFromNib {
    self.postImage = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.postUserImageView.frame.size.width, self.postUserImageView.frame.size.height)];
    self.postUserImageView.layer.cornerRadius = round(self.postUserImageView.frame.size.width / 2.0f);
    self.postUserImageView.layer.masksToBounds = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.postImage.image = nil;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
