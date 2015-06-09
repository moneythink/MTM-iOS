//
//  MTNotificationTableViewCell.h
//  moneythink-ios
//
//  Created by dsica on 6/9/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTNotificationTableViewCell : PFTableViewCell

@property (strong, nonatomic) IBOutlet UITextView *messageTextView;
@property (strong, nonatomic) IBOutlet UILabel *agePosted;
@property (nonatomic, strong) IBOutlet PFImageView *avatarImageView;

@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@end
