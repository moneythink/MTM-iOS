//
//  MTPostCommentItemsTableViewCell.h
//  moneythink-ios
//
//  Created by David Sica on 10/27/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTLabel.h"

@interface MTPostCommentItemsTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet MTLabel *commentLabel;
@property (nonatomic, weak) IBOutlet MTLabel *userLabel;
@property (nonatomic, weak) IBOutlet UIView *separatorView;
@property (nonatomic, strong) IBOutlet UIImageView *userAvatarImageView;
@property (nonatomic, strong) IBOutlet UIImageView *pickerImageView;

@property (nonatomic, strong) MTChallengePostComment *comment;

@end
