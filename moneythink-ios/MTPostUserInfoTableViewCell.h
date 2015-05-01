//
//  MTPostUserInfoTableViewCell.h
//  moneythink-ios
//
//  Created by David Sica on 10/24/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTPostUserInfoTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *postUserImageView;
@property (weak, nonatomic) IBOutlet UILabel *postUsername;
@property (weak, nonatomic) IBOutlet UIButton *deletePost;
@property (weak, nonatomic) IBOutlet UILabel *whenPosted;
@property (strong, nonatomic) PFImageView *postImage;

@end
