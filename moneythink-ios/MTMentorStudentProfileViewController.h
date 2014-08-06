//
//  MTMentorStudentProfileViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTMentorStudentProfileViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) PFUser *student;
@property (strong, nonatomic) IBOutlet PFImageView *profileImage;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end
