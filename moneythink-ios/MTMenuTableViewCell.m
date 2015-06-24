//
//  MTMenuTableViewCell.m
//  moneythink-ios
//
//  Created by David Sica on 5/26/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTMenuTableViewCell.h"

@interface MTMenuTableViewCell ()

@end

@implementation MTMenuTableViewCell

- (void)awakeFromNib {
    // Initialization code
    
    self.unreadCountView.layer.cornerRadius = self.unreadCountView.frame.size.height/2.0f;
    self.unreadCountView.backgroundColor = [UIColor redColor];
    self.unreadCountView.layer.masksToBounds = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    if (selected) {
        self.contentView.backgroundColor = [UIColor menuDarkGreen];
    }
    else {
        self.contentView.backgroundColor = [UIColor menuLightGreen];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        self.contentView.backgroundColor = [UIColor menuHightlightGreen];
    }
    else {
        if (self.selected) {
            self.contentView.backgroundColor = [UIColor menuDarkGreen];
        }
        else {
            self.contentView.backgroundColor = [UIColor menuLightGreen];
        }
    }
}

@end
