//
//  MTStudentProfileViewController.h
//  moneythink-ios
//
//  Created by colinyoung on 2/4/16.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTIncrementalLoadingTableViewController.h"

@class MTStudentProfileTableViewCell;

@interface MTStudentProfileViewController : UIViewController

@property (strong, nonatomic) MTUser *studentUser;

@end
