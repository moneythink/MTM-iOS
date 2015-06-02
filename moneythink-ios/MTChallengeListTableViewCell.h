//
//  MTChallengeListTableViewCell.h
//  moneythink-ios
//
//  Created by David Sica on 5/30/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTChallengeListTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *challengeNumber;
@property (nonatomic, strong) IBOutlet UILabel *challengeTitle;
@property (nonatomic, strong) IBOutlet UIView *leftView;
@property (nonatomic, strong) IBOutlet UIView *centerView;

@end
