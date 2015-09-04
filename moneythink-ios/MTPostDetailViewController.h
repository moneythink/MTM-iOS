//
//  MTPostViewController.h
//  moneythink-ios
//
//  Created by dsica on 6/4/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MICheckBox.h"
#import "MTCommentViewController.h"

@class MTMyClassTableViewController;

typedef enum {
    MTPostTypeWithButtonsWithImage,
    MTPostTypeWithButtonsNoImage,
    MTPostTypeNoButtonsWithImage,
    MTPostTypeNoButtonsNoImage,
} MTPostType;


@protocol MTPostViewControllerDelegate <NSObject>

- (void)didDeletePost:(MTChallengePost *)challengePost;
- (void)didUpdateLikes;
- (void)didUpdateButtons;
- (void)didUpdateVerification;

@end

@interface MTPostDetailViewController : UIViewController <MTCommentViewProtocol, UITableViewDataSource, UITableViewDelegate, MBProgressHUDDelegate>

@property (nonatomic, weak) id<MTPostViewControllerDelegate> delegate;

@property (nonatomic, strong) MTMyClassTableViewController *myClassTableViewController;
@property (nonatomic, strong) MTChallenge *challenge;
@property (nonatomic, strong) MTChallengePost *challengePost;
@property (nonatomic) MTPostType postType;
@property (nonatomic) BOOL hasButtons;
@property (nonatomic) BOOL hasSecondaryButtons;
@property (nonatomic) BOOL hasTertiaryButtons;
@property (nonatomic, strong) NSArray *emojiArray;
@property (nonatomic, strong) MTNotification *notification;

- (void)emojiLiked:(MTEmoji *)emoji;

@end
