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

- (void) dismissCommentView;

@end

@interface MTCommentViewController : UIViewController

@property (nonatomic, weak) id <MTCommentViewProtocol> delegate;

@property (nonatomic, strong) MTChallengePost *post;
@property (nonatomic, strong) PFChallengePostComment *challengePostComment;
@property (nonatomic) BOOL editPost;

@end
