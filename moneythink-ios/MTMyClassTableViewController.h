//
//  MTMyClassTableViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 8/4/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTCommentViewController.h"
#import "MTPostViewController.h"
#import "MTEmojiPickerCollectionView.h"

extern NSString *const kWillSaveNewChallengePostNotification;
extern NSString *const kSavingWithPhotoNewChallengePostNotification;
extern NSString *const kSavedMyClassChallengePostsdNotification;
extern NSString *const kFailedMyClassChallengePostsdNotification;
extern NSString *const kWillSaveNewPostCommentNotification;
extern NSString *const kWillSaveEditPostNotification;
extern NSString *const kDidSaveEditPostNotification;
extern NSString *const kFailedSaveEditPostNotification;

@interface MTMyClassTableViewController : PFQueryTableViewController <MTCommentViewProtocol, MTEmojiPickerCollectionViewDelegate, MTPostViewControllerDelegate, MBProgressHUDDelegate>

@property (nonatomic, strong) PFChallenges *challenge;
@property (nonatomic, strong) NSString *challengeNumber;
@property (nonatomic, strong) NSString *className;
@property (nonatomic, strong) NSString *schoolName;

@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) NSArray *emojiObjects;
@property (nonatomic, strong) MTPostViewController *postViewController;

- (void)didSelectLikeWithEmojiForPost:(PFChallengePost *)post;

@end

