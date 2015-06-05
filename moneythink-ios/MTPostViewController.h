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

- (void)didDeletePost:(PFChallengePost *)challengePost;
- (void)didUpdatePostsLiked:(NSArray *)postsLiked withPostLikedFull:(NSArray *)postsLikedFull;

@end

@interface MTPostViewController : UIViewController <MTCommentViewProtocol, UITableViewDataSource, UITableViewDelegate, MBProgressHUDDelegate>

@property (nonatomic, weak) id<MTPostViewControllerDelegate> delegate;

@property (nonatomic, strong) MTMyClassTableViewController *myClassTableViewController;
@property (strong, nonatomic) PFChallenges *challenge;
@property (strong, nonatomic) PFChallengePost *challengePost;
@property (nonatomic) MTPostType postType;
@property (nonatomic) BOOL hasButtons;
@property (nonatomic) BOOL hasSecondaryButtons;
@property (nonatomic, strong) NSDictionary *buttonsTapped;
@property (nonatomic, strong) NSDictionary *secondaryButtonsTapped;
@property (nonatomic, strong) NSArray *postsLiked;
@property (nonatomic, strong) NSArray *postsLikedFull;
@property (nonatomic, strong) NSArray *emojiArray;

- (void)emojiLiked:(PFEmoji *)emoji;

@end
