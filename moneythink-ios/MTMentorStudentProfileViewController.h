//
//  MTMentorStudentProfileViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTIncrementalLoadingTableViewController.h"

@class MTStudentProfileTableViewCell;

@interface MTMentorStudentProfileViewController : MTIncrementalLoadingTableViewController

@property (strong, nonatomic) MTUser *studentUser;
@property (strong, nonatomic) IBOutlet UIImageView *profileImage;

@end
