//
//  MTActivationTableViewCell.h
//  moneythink-ios
//
//  Created by jdburgie on 8/7/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTActivationTableViewCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel *challengeNumber;
@property (strong, nonatomic) IBOutlet UILabel *challengeTitle;
@property (strong, nonatomic) IBOutlet UILabel *activationDate;

@end
