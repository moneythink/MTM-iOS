//
//  MTMenuTableViewCell.h
//  moneythink-ios
//
//  Created by David Sica on 5/26/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTMenuTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *signupLabel;
@property (nonatomic, weak) IBOutlet UILabel *signupCode;
@property (nonatomic, weak) IBOutlet UIView *unreadCountView;
@property (nonatomic, weak) IBOutlet UILabel *unreadCountLabel;

@end
