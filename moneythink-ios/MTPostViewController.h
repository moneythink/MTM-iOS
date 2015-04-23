//
//  MTPostViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MICheckBox.h"
#import "MTCommentViewController.h"

typedef enum {
    MTPostTypeWithButtonsWithImage,
    MTPostTypeWithButtonsNoImage,
    MTPostTypeNoButtonsWithImage,
    MTPostTypeNoButtonsNoImage,
} MTPostType;


@protocol MTPostViewControllerDelegate <NSObject>

- (void)didDeletePost:(PFChallengePost *)challengePost;
- (void)didUpdatePostsLiked:(NSArray *)postsLiked;

@end

@interface MTPostViewController : UIViewController <MTCommentViewProtocol, UITableViewDataSource, UITableViewDelegate, MBProgressHUDDelegate>

@property (nonatomic, weak) id<MTPostViewControllerDelegate> delegate;

@property (strong, nonatomic) PFChallenges *challenge;
@property (strong, nonatomic) PFChallengePost *challengePost;
@property (nonatomic) MTPostType postType;
@property (nonatomic) BOOL hasButtons;
@property (nonatomic) BOOL hasSecondaryButtons;
@property (nonatomic, strong) NSDictionary *buttonsTapped;
@property (nonatomic, strong) NSDictionary *secondaryButtonsTapped;
@property (nonatomic, strong) NSArray *postsLiked;

@end
