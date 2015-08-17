//
//  MTPostViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface MTPostViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) MTChallenge *challenge;
@property (nonatomic, strong) PFChallengePost *post;
@property (nonatomic) BOOL editPost;

@end
