//
//  MTNotificationTableViewCell.h
//  moneythink-ios
//
//  Created by dsica on 6/9/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTNotificationTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UITextView *messageTextView;
@property (nonatomic, strong) IBOutlet UILabel *agePosted;
@property (nonatomic, strong) IBOutlet UIImageView *avatarImageView;

@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@end
