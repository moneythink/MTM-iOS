//
//  MTMentorChallengeRoomViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTMentorChallengeRoomViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutlet UIImageView *anyImage;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@end
