//
//  MTCommentViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@protocol MTCommentViewProtocol <NSObject>

- (void)dismissCommentView;
- (void)dismissPostView;

@end

@interface MTCommentViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) id <MTCommentViewProtocol> delegate;
@property (strong, nonatomic) PFChallenges *challenge;
@property (strong, nonatomic) PFChallengePost *post;
@property (strong, nonatomic) PFChallengePostComment *challengePostComment;

@end
