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
@property (strong, nonatomic) IBOutlet UITextField *userName;
@property (strong, nonatomic) IBOutlet UITextField *postedWhen;

@property (strong, nonatomic) IBOutlet PFImageView *postImage;
@property (strong, nonatomic) IBOutlet UITextField *postText;

@property (strong, nonatomic) IBOutlet UITextField *likes;
@property (strong, nonatomic) IBOutlet UITextField *comments;


@property (strong, nonatomic) IBOutlet UIButton *likeButton;
@property (strong, nonatomic) IBOutlet UIButton *commentBUtton;

@end
