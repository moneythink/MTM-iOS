//
//  MTPostImageTableViewCell.h
//  moneythink-ios
//
//  Created by David Sica on 10/24/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTPostImageTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UIImageView *postImage;
@property (nonatomic, strong) IBOutlet UIView *spentView;
@property (nonatomic, strong) IBOutlet UILabel *spentLabel;
@property (nonatomic, strong) IBOutlet UILabel *savedLabel;

@end
