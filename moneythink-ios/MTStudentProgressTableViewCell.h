//
//  MTStudentProgressTableViewCell.h
//  moneythink-ios
//
//  Created by jdburgie on 8/3/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MICheckBox.h"

@interface MTStudentProgressTableViewCell : UITableViewCell

@property (strong, nonatomic) MTUser *user;

@property (strong, nonatomic) IBOutlet UILabel *userFullName;
@property (strong, nonatomic) IBOutlet UIImageView *userProfileImage;
@property (strong, nonatomic) IBOutlet MICheckBox *bankCheckbox;
@property (strong, nonatomic) IBOutlet MICheckBox *resumeCheckbox;

@end
