//
//  MTNotificationTableViewCell.h
//  moneythink-ios
//
//  Created by jdburgie on 8/13/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTNotificationTableViewCell : PFTableViewCell

@property (strong, nonatomic) IBOutlet UILabel *userName;
@property (strong, nonatomic) IBOutlet UILabel *message;
@property (strong, nonatomic) IBOutlet UILabel *agePosted;

@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@end
