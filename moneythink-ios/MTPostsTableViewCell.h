//
//  MTPostsTableViewCell.h
//  moneythink-ios
//
//  Created by jdburgie on 7/31/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <Parse/Parse.h>

@interface MTPostsTableViewCell : PFTableViewCell

@property (strong, nonatomic) IBOutlet PFImageView *profileImage;
@property (strong, nonatomic) IBOutlet UILabel *userName;
@property (strong, nonatomic) IBOutlet UILabel *postedWhen;

@property (strong, nonatomic) IBOutlet PFImageView *postImage;
@property (strong, nonatomic) IBOutlet UILabel *postText;

@property (strong, nonatomic) IBOutlet UILabel *likes;
@property (strong, nonatomic) IBOutlet UILabel *comments;

@property (strong, nonatomic) IBOutlet UIButton *likeButton;
@property (strong, nonatomic) IBOutlet UIButton *commentBUtton;

@property (strong, nonatomic) IBOutlet UIButton *button1;
@property (strong, nonatomic) IBOutlet UIButton *button2;

@property (strong, nonatomic) IBOutlet UIButton *deletePost;

@end
