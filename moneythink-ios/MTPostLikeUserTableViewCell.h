//
//  MTPostLikeUserTableViewCell.h
//  moneythink-ios
//
//  Created by David Sica on 4/30/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTPostLikeUserTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet PFImageView *userAvatarImageView;
@property (nonatomic, strong) IBOutlet UILabel *username;
@property (nonatomic, strong) IBOutlet PFImageView *emojiView;

@property (nonatomic, strong) UIImage *userAvatarImage;

@end
