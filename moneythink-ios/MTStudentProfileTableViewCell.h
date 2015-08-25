//
//  MTStudentProfileTableViewCell.h
//  moneythink-ios
//
//  Created by jdburgie on 8/5/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MICheckBox.h"

@interface MTStudentProfileTableViewCell : PFTableViewCell

@property (strong, nonatomic) MTChallengePost *rowPost;

@property (strong, nonatomic) IBOutlet PFImageView *postProfileImage;
@property (strong, nonatomic) IBOutlet UILabel *timeSince;
@property (strong, nonatomic) IBOutlet UITextField *postText;

@property (strong, nonatomic) IBOutlet MICheckBox *verifiedCheckbox;
@property (strong, nonatomic) IBOutlet UISwitch *verified;
@property (strong, nonatomic) IBOutlet UILabel *verifiedLabel;

@property (strong, nonatomic) IBOutlet UIImageView *likes;
@property (strong, nonatomic) IBOutlet UILabel *likeCount;

@end
