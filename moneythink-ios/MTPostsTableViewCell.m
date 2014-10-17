//
//  MTPostsTableViewCell.m
//  moneythink-ios
//
//  Created by jdburgie on 7/31/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTPostsTableViewCell.h"

@implementation MTPostsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.activityIndicator.hidden = YES;
    self.loadingView.alpha = 0.0f;
    [self.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
    [self.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateDisabled];
}


@end
