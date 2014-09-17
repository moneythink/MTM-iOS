//
//  MTCommentViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol mtCommentViewProtocol <NSObject>

- (void)dismissCommentView;

@end

@interface MTCommentViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) id <mtCommentViewProtocol> delegate;
@property (strong, nonatomic) PFChallenges *challenge;
@property (strong, nonatomic) PFChallengePost *post;
@property (strong, nonatomic) PFChallengePostComment *challengePostComment;

@end
