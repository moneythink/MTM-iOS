//
//  MTStudentMainViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTUserInformationViewController.h"

@interface MTStudentMainViewController : UIViewController <MTUserInfoDelegate>

@property (strong, nonatomic) IBOutlet UIButton *buttonUserProfile;

@property (strong, nonatomic) IBOutlet UIButton *buttonMoneyMaker;
@property (strong, nonatomic) IBOutlet UIButton *buttonMoneyManager;

@end
