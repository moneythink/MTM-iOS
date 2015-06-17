//
//  MTPostsTableViewCell.h
//  moneythink-ios
//
//  Created by jdburgie on 7/31/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <Parse/Parse.h>
#import "MICheckBox.h"

@interface MTPostsTableViewCell : PFTableViewCell

@property (nonatomic, strong) PFChallengePost *post;
@property (nonatomic, strong) IBOutlet PFImageView *profileImage;
@property (nonatomic, strong) IBOutlet UILabel *userName;
@property (nonatomic, strong) IBOutlet UILabel *postedWhen;
@property (nonatomic, strong) IBOutlet PFImageView *postImage;
@property (nonatomic, strong) IBOutlet UILabel *postText;
@property (nonatomic, strong) IBOutlet UILabel *likes;
@property (nonatomic, strong) IBOutlet UILabel *comments;
@property (nonatomic, strong) IBOutlet UIButton *likeButton;
@property (nonatomic, strong) IBOutlet UIButton *commentButton;
@property (nonatomic, strong) IBOutlet UIButton *button1;
@property (nonatomic, strong) IBOutlet UIButton *button2;
@property (nonatomic, strong) IBOutlet UIButton *deletePost;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UIView *loadingView;
@property (nonatomic, strong) IBOutlet MICheckBox *verifiedCheckBox;
@property (nonatomic, strong) IBOutlet UILabel *verfiedLabel;
@property (nonatomic, strong) IBOutlet UIView *emojiContainerView;

@property (nonatomic, strong) NSArray *postsLiked;
@property (assign, nonatomic) NSInteger postLikesCount;
@property (assign, nonatomic) BOOL iLike;

@property (nonatomic, strong) NSArray *emojiArray;

+ (void)layoutEmojiForContainerView:(UIView *)containerView withEmojiArray:(NSArray *)emojiArray;

@end
