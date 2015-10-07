//
//  MTMyClassTableViewController.h
//  moneythink-ios
//
//  Created by dsica on 8/20/14.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTCommentViewController.h"
#import "MTPostDetailViewController.h"
#import "MTEmojiPickerCollectionView.h"

extern NSString *const kWillSaveNewChallengePostNotification;
extern NSString *const kDidDeleteChallengePostNotification;
extern NSString *const kDidTapChallengeButtonNotification;
extern NSString *const kSavedMyClassChallengePostNotification;
extern NSString *const kFailedMyClassChallengePostNotification;
extern NSString *const kFailedMyClassChallengePostCommentNotification;
extern NSString *const kFailedChallengePostCommentEditNotification;
extern NSString *const kWillSaveNewPostCommentNotification;
extern NSString *const kWillSaveEditPostCommentNotification;
extern NSString *const kDidSaveNewPostCommentNotification;
extern NSString *const kDidDeletePostCommentNotification;
extern NSString *const kWillSaveEditPostNotification;
extern NSString *const kDidSaveEditPostNotification;
extern NSString *const kFailedSaveEditPostNotification;

@interface MTMyClassTableViewController : UITableViewController <MTCommentViewProtocol, MTEmojiPickerCollectionViewDelegate, MTPostViewControllerDelegate, MBProgressHUDDelegate>

@property (nonatomic, strong) MTChallenge *challenge;
@property (nonatomic, strong) NSString *challengeNumber;
@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) NSString *schoolName;

@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) RLMResults *emojiObjects;
@property (nonatomic, strong) MTPostDetailViewController *postViewController;

- (void)didSelectLikeWithEmojiForPost:(MTChallengePost *)post;

@end

