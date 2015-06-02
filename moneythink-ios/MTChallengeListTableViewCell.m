//
//  MTChallengeListTableViewCell.m
//  moneythink-ios
//
//  Created by David Sica on 5/30/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTChallengeListTableViewCell.h"

@implementation MTChallengeListTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted) {
        self.centerView.backgroundColor = [UIColor primaryGreen];
        self.challengeTitle.textColor = [UIColor whiteColor];
        self.leftView.backgroundColor = [UIColor clearColor];
    }
    else {
        self.centerView.backgroundColor = [UIColor whiteColor];
        self.challengeTitle.textColor = [UIColor blackColor];
        self.leftView.backgroundColor = [UIColor primaryOrange];
    }
}

@end
