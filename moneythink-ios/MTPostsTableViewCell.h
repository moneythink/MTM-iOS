//
//  MTPostsTableViewCell.h
//  moneythink-ios
//
//  Created by jdburgie on 7/31/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <Parse/Parse.h>

@interface MTPostsTableViewCell : PFTableViewCell

@property (strong, nonatomic) IBOutlet PFImageView *postImage;

@property (strong, nonatomic) IBOutlet UITextField *postText;

@property (strong, nonatomic) IBOutlet PFImageView *profileImage;
@property (strong, nonatomic) IBOutlet UITextField *userName;

@end