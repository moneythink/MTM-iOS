//
//  MTPostUserInfoTableViewCell.h
//  moneythink-ios
//
//  Created by David Sica on 10/24/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTPostUserInfoTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *postUserImageView;
@property (nonatomic, weak) IBOutlet UILabel *postUsername;
@property (nonatomic, weak) IBOutlet UIButton *deletePost;
@property (nonatomic, weak) IBOutlet UILabel *whenPosted;
@property (nonatomic, strong) UIImageView *postImage;

@end
