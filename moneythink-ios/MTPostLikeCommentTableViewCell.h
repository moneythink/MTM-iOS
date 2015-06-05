//
//  MTPostLikeCommentTableViewCell.h
//  moneythink-ios
//
//  Created by David Sica on 10/24/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MICheckBox.h"

@interface MTPostLikeCommentTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIButton *likePost;
@property (nonatomic, strong) IBOutlet UILabel *postLikes;
@property (nonatomic, strong) IBOutlet UIButton *comment;
@property (nonatomic, strong) IBOutlet UILabel *commentCount;
@property (nonatomic, strong) IBOutlet MICheckBox *verifiedCheckBox;
@property (nonatomic, strong) IBOutlet UILabel *verfiedLabel;
@property (nonatomic, strong) IBOutlet UIButton *commentPost;
@property (nonatomic, strong) IBOutlet UIView *emojiContainerView;

@end
