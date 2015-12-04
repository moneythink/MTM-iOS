//
//  MTMentorStudentProfileViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTLoadingView.h"

@class MTStudentProfileTableViewCell;

@interface MTMentorStudentProfileViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) MTUser *student;
@property (strong, nonatomic) IBOutlet UIImageView *profileImage;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet MTLoadingView *loadingView;

- (IBAction)refreshAction:(id)sender;

@end
