//
//  MTPostCommentItemsTableViewCell.h
//  moneythink-ios
//
//  Created by David Sica on 10/27/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTLabel.h"

@interface MTPostCommentItemsTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet MTLabel *commentLabel;
@property (nonatomic, weak) IBOutlet MTLabel *userLabel;
@end
