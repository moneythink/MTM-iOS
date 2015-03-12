//
//  MTNotificationTableViewCell.m
//  moneythink-ios
//
//  Created by jdburgie on 8/13/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTNotificationTableViewCell.h"

@implementation MTNotificationTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.userName.text = nil;
    self.message.text = nil;
    self.agePosted.text = nil;
    self.currentIndexPath = nil;
}

-(UIEdgeInsets)layoutMargins
{
    return UIEdgeInsetsZero;
}


@end
