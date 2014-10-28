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

@property (strong, nonatomic) IBOutlet UIButton *likePost;
@property (strong, nonatomic) IBOutlet UILabel *postLikes;
@property (strong, nonatomic) IBOutlet UIButton *comment;
@property (strong, nonatomic) IBOutlet UILabel *commentCount;
@property (strong, nonatomic) IBOutlet MICheckBox *verifiedCheckBox;
@property (strong, nonatomic) IBOutlet UILabel *verfiedLabel;
@property (strong, nonatomic) IBOutlet UIButton *commentPost;

@end
