//
//  MTPostImageTableViewCell.m
//  moneythink-ios
//
//  Created by David Sica on 10/24/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTPostImageTableViewCell.h"

@implementation MTPostImageTableViewCell

- (void)awakeFromNib {
    self.spentLabel.textColor = [UIColor votingRed];
    self.savedLabel.textColor = [UIColor votingBlue];
    self.postImage.contentMode = UIViewContentModeTop;
    self.postImage.clipsToBounds = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.spentView.hidden = YES;
    self.spentLabel.text = @"";
    self.savedLabel.text = @"";
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
