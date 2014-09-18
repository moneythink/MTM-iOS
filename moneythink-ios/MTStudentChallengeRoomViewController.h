//
//  MTStudentChallengeRoomViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MTStudentChallengeRoomContentViewController.h"
#import "MTCommentViewController.h"

@interface MTStudentChallengeRoomViewController : UIViewController <MTCommentViewProtocol>

@property (nonatomic, strong) PFChallenges *challenge;
@property (nonatomic, strong) NSString *challengeNumber;

@property (strong, nonatomic) MTStudentChallengeRoomContentViewController *destinationVC;

@end
