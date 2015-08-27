//
//  MTMyClassTableViewController.m
//  moneythink-ios
//
//  Created by dsica on 8/20/14.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTMyClassTableViewController.h"
#import "MTPostsTableViewCell.h"
#import "MTCommentViewController.h"
#import "MTEmojiPickerCollectionView.h"
#import "MTPostViewController.h"

NSString *const kWillSaveNewChallengePostNotification = @"kWillSaveNewChallengePostNotification";
NSString *const kDidDeleteChallengePostNotification = @"kDidDeleteChallengePostNotification";
NSString *const kDidTapChallengeButtonNotification = @"kDidTapChallengeButtonNotification";
NSString *const kSavedMyClassChallengePostNotification = @"kSavedMyClassChallengePostNotification";
NSString *const kFailedMyClassChallengePostNotification = @"kFailedMyClassChallengePostNotification";
NSString *const kFailedMyClassChallengePostCommentNotification = @"kFailedMyClassChallengePostCommentNotification";
NSString *const kFailedMyClassChallengePostCommentEditNotification = @"kFailedMyClassChallengePostCommentEditNotification";
NSString *const kWillSaveNewPostCommentNotification = @"kWillSaveNewPostCommentNotification";
NSString *const kWillSaveEditPostCommentNotification = @"kWillSaveEditPostCommentNotification";
NSString *const kDidSaveNewPostCommentNotification = @"kDidSaveNewPostCommentNotification";
NSString *const kWillSaveEditPostNotification = @"kWillSaveEditPostNotification";
NSString *const kDidSaveEditPostNotification = @"kDidSaveEditPostNotification";
NSString *const kFailedSaveEditPostNotification = @"kFailedSaveEditPostNotification";

@interface MTMyClassTableViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic) BOOL hasButtons;
@property (nonatomic) BOOL hasSecondaryButtons;
@property (nonatomic) BOOL hasTertiaryButtons;
@property (nonatomic) BOOL isMentor;
@property (nonatomic, strong) NSDictionary *buttonsTapped;
@property (nonatomic, strong) NSDictionary *secondaryButtonsTapped;
@property (nonatomic) BOOL iLike;
@property (nonatomic) BOOL deletingPost;
@property (nonatomic, strong) UIImage *postImage;
@property (nonatomic, strong) UIButton *secondaryButton1;
@property (nonatomic, strong) UIButton *secondaryButton2;
@property (nonatomic, strong) MTEmojiPickerCollectionView *emojiCollectionView;
@property (nonatomic, strong) UIView *emojiDimView;
@property (nonatomic, strong) UIView *emojiContainerView;
@property (nonatomic) BOOL displaySpentView;
@property (nonatomic, strong) RLMResults *challengePosts;
@property (nonatomic) BOOL savingNewEditPost;

@end

@implementation MTMyClassTableViewController

#pragma mark - Lifecycle -
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveNewChallengePost:) name:kWillSaveNewChallengePostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postSucceeded) name:kSavedMyClassChallengePostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postFailed) name:kFailedMyClassChallengePostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveNewPostComment:) name:kWillSaveNewPostCommentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveEditPostComment:) name:kWillSaveEditPostCommentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSaveNewPostComment:) name:kDidSaveNewPostCommentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentFailed) name:kFailedMyClassChallengePostCommentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentEditFailed) name:kFailedMyClassChallengePostCommentEditNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveEditPost:) name:kWillSaveEditPostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSaveEditPost:) name:kDidSaveEditPostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedSaveEditPost:) name:kFailedSaveEditPostNotification object:nil];

//    self.didUpdateLikedPosts = NO;
//    self.updatedButtonsAndLikes = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor whiteColor];
    self.refreshControl.tintColor = [UIColor primaryOrange];
    [self.refreshControl addTarget:self action:@selector(loadData) forControlEvents:UIControlEventValueChanged];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = @"My Class";
    self.isMentor = [MTUser isCurrentUserMentor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.postViewController = nil;
}

- (void)dealloc
{
    if ([self isViewLoaded]) {
        self.tableView.emptyDataSetSource = nil;
        self.tableView.emptyDataSetDelegate = nil;
    }
}


#pragma mark - Data Loading -
- (void)loadData
{
    [self refreshFromDatabase];
    
    // Don't GET from DB right away because there's a delay in processing updates.
    if (!self.savingNewEditPost && !self.deletingPost) {
        MTMakeWeakSelf();
        [[MTNetworkManager sharedMTNetworkManager] loadPostsForChallengeId:self.challenge.id success:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.refreshControl endRefreshing];
                [weakSelf refreshFromDatabase];
                
                [weakSelf updateComments];
                [weakSelf updateLikes];
            });
            
        } failure:^(NSError *error) {
            NSLog(@"Failed to load post data: %@", [error mtErrorDescription]);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.refreshControl endRefreshing];
                [weakSelf refreshFromDatabase];
            });
        }];
    }
}

- (void)refreshFromDatabase
{
    if (self.challenge) {
        self.challengePosts = [[MTChallengePost objectsWhere:@"challenge.id = %d  AND isDeleted = NO", self.challenge.id] sortedResultsUsingProperty:@"updatedAt" ascending:NO];
    }
    else {
        self.challengePosts = nil;
    }
    
    [self.tableView reloadData];
}

- (void)updateComments
{
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] loadCommentsForChallengeId:self.challenge.id success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            [weakSelf.tableView reloadData];
        });
        
    } failure:^(NSError *error) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
//        });
    }];
}

- (void)updateButtons
{
    //    NSPredicate *thisChallenge = [NSPredicate predicateWithFormat:@"objectId = %@", self.challenge.objectId];
    //    PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:thisChallenge];
    //    [challengeQuery includeKey:@"verified_by"];
    //    challengeQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
    //
    //    MTMakeWeakSelf();
    //    [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
    //        if (!error) {
    //            PFChallenges *challenge = (PFChallenges *)[objects firstObject];
    //            if (![[weakSelf.challenge objectId] isEqualToString:[challenge objectId]]) {
    //                weakSelf.challenge = challenge;
    //            }
    //
    //            NSArray *buttons = challenge[@"buttons"];
    //            NSArray *secondaryButtons = challenge[@"secondary_buttons"];
    //
    //            weakSelf.hasButtons = NO;
    //            weakSelf.hasSecondaryButtons = NO;
    //            weakSelf.hasTertiaryButtons = NO;
    //
    //            if (!IsEmpty(buttons) && [buttons firstObject] != [NSNull null]) {
    //                if ([buttons count] == 4) {
    //                    weakSelf.hasTertiaryButtons = YES;
    //                }
    //                else {
    //                    weakSelf.hasButtons = YES;
    //                }
    //
    //                [weakSelf userButtonsTapped];
    //            }
    //            else if (!IsEmpty(secondaryButtons) && ([secondaryButtons firstObject] != [NSNull null]) && !self.isMentor) {
    //                weakSelf.hasSecondaryButtons = YES;
    //                [weakSelf updateSecondaryButtonsTapped];
    //            }
    //        }
    //
    //        dispatch_async(dispatch_get_main_queue(), ^{
    //            [weakSelf updateLikes];
    //        });
    //    }];
}

- (void)updateLikes
{
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] loadLikesForChallengeId:self.challenge.id success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load/update likes: %@", [error mtErrorDescription]);
    }];
}


#pragma mark - Public -
- (void)setChallenge:(MTChallenge *)challenge
{
    if (_challenge != challenge) {
        BOOL refresh = (_challenge == nil || (_challenge != nil && (_challenge.id != challenge.id)));
        _challenge = challenge;
        
        if (refresh) {
            self.challengePosts = nil;
            self.displaySpentView = !IsEmpty(challenge.postExtraFields);
            self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            [self loadData];
        }
    }
}

- (void)didSelectLikeWithEmojiForPost:(MTChallengePost *)post
{
    CGRect keyWindowFrame = [UIApplication sharedApplication].keyWindow.frame;
    self.emojiDimView = [[UIView alloc] initWithFrame:keyWindowFrame];
    self.emojiDimView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.3f];
    self.emojiDimView.alpha = 0.0f;
    
    self.emojiContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 242.0f, 126.0f + 25.0f)];
    self.emojiContainerView.backgroundColor = [UIColor colorWithHexString:@"#fbfaf7"];
    self.emojiContainerView.layer.cornerRadius = 4.0f;
    self.emojiContainerView.clipsToBounds = YES;
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 5.0f, 222.0f, 20.0f)];
    title.backgroundColor = [UIColor clearColor];
    title.text = @"Like with Emoji";
    title.font = [UIFont mtFontOfSize:15.0f];
    title.textColor = [UIColor blackColor];
    title.textAlignment = NSTextAlignmentCenter;
    [self.emojiContainerView addSubview:title];
    
    self.emojiCollectionView = [self.storyboard instantiateViewControllerWithIdentifier:@"EmojiPickerCollectionView"];
    self.emojiCollectionView.collectionView.backgroundColor = [UIColor colorWithHexString:@"#fbfaf7"];
    self.emojiCollectionView.collectionView.frame = CGRectMake(0.0f, 25.0f, 242.0f, 126.0f);
        
    self.emojiCollectionView.emojiObjects = self.emojiObjects;
    self.emojiCollectionView.post = post;
    self.emojiCollectionView.delegate = self;
    
    self.emojiContainerView.frame = ({
        CGRect newFrame = self.emojiContainerView.frame;
        newFrame.size.height = 0.0f;
        newFrame.size.width = 0.0f;
        newFrame.origin.y = keyWindowFrame.size.height/2.0f;
        newFrame.origin.x = keyWindowFrame.size.width/2.0f;
        
        newFrame;
    });
    
    UIButton *dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissButton.frame = self.emojiDimView.frame;
    dismissButton.backgroundColor = [UIColor clearColor];
    [dismissButton addTarget:self action:@selector(cancelEmojiPrompt) forControlEvents:UIControlEventTouchUpInside];
    [self.emojiDimView addSubview:dismissButton];
    
    [self.emojiDimView addSubview:self.emojiContainerView];
    [[UIApplication sharedApplication].keyWindow addSubview:self.emojiDimView];
    
    self.emojiCollectionView.collectionView.alpha = 0.0f;
    title.alpha = 0.0f;
    
    // Animate In
    [UIView animateWithDuration:0.2f animations:^{
        self.emojiDimView.alpha = 1.0f;
        self.emojiContainerView.frame = ({
            CGRect newFrame = self.emojiContainerView.frame;
            newFrame.size.height = 151.0f;
            newFrame.size.width = 242.0f;
            newFrame.origin.y = (keyWindowFrame.size.height - 126.0f - 25.0f)/2.0f;
            newFrame.origin.x = (keyWindowFrame.size.width - 242.0f)/2.0f;
            
            newFrame;
        });
        
    } completion:^(BOOL finished) {
        [self addChildViewController:self.emojiCollectionView];
        [self.emojiContainerView addSubview:self.emojiCollectionView.collectionView];
        [self.emojiCollectionView didMoveToParentViewController:self];
        
        [UIView animateWithDuration:0.1f animations:^{
            title.alpha = 1.0f;
            self.emojiCollectionView.collectionView.alpha = 1.0f;
        } completion:^(BOOL finished) {
        }];
    }];
}


#pragma mark - Class Methods -
- (void)userButtonsTapped
{
//    PFQuery *buttonsTapped = [PFQuery queryWithClassName:[PFChallengePostButtonsClicked parseClassName]];
//    [buttonsTapped whereKey:@"user" equalTo:[PFUser currentUser]];
//    
//    MTMakeWeakSelf();
//    [buttonsTapped findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
//        });
//
//        if (!error) {
//            NSMutableDictionary *tappedButtonObjects = [NSMutableDictionary dictionary];
//            for (PFChallengePostButtonsClicked *clicks in objects) {
//                id button = clicks[@"button_clicked"];
//                id post = [(PFChallengePost *)clicks[@"post"] objectId];
//                [tappedButtonObjects setValue:button forKey:post];
//            }
//            weakSelf.buttonsTapped = tappedButtonObjects;
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [weakSelf loadObjects];
//            });
//
//        } else {
//            NSLog(@"Error - %@", error);
//        }
//    }];
}

- (void)updateSecondaryButtonsTapped
{
//    PFQuery *buttonsTapped = [PFQuery queryWithClassName:[PFChallengePostSecondaryButtonsClicked parseClassName]];
//    [buttonsTapped whereKey:@"user" equalTo:[PFUser currentUser]];
//    [buttonsTapped includeKey:@"post"];
//    
//    MTMakeWeakSelf();
//    [buttonsTapped findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//        if (!error) {
//            NSMutableDictionary *tappedButtonObjects = [NSMutableDictionary dictionary];
//            for (PFChallengePostSecondaryButtonsClicked *clicks in objects) {
//                PFChallengePost *post = (PFChallengePost *)clicks[@"post"];
//                PFChallenges *challenge = post[@"challenge"];
//                NSString *challengeObjectId = challenge.objectId;
//                
//                id postObjectId = [(PFChallengePost *)clicks[@"post"] objectId];
//                
//                if ([challengeObjectId isEqualToString:weakSelf.challenge.objectId]) {
//                    id button = clicks[@"button"];
//                    id count = clicks[@"count"];
//                    
//                    NSDictionary *buttonsDict;
//                    if ([tappedButtonObjects objectForKey:postObjectId]) {
//                        buttonsDict = [tappedButtonObjects objectForKey:postObjectId];
//                        NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:buttonsDict];
//                        [mutableDict setValue:count forKey:button];
//                        buttonsDict = [NSDictionary dictionaryWithDictionary:mutableDict];
//                    }
//                    else {
//                        buttonsDict = [NSDictionary dictionaryWithObjectsAndKeys:count, button, nil];
//                    }
//                    
//                    [tappedButtonObjects setValue:buttonsDict forKey:postObjectId];
//                }
//            }
//            weakSelf.secondaryButtonsTapped = tappedButtonObjects;
//
//            dispatch_async(dispatch_get_main_queue(), ^{
//                weakSelf.secondaryButton1.enabled = YES;
//                [weakSelf loadObjects];
//            });
//            
//        } else {
//            NSLog(@"Error - %@", error);
//            dispatch_async(dispatch_get_main_queue(), ^{
//                weakSelf.secondaryButton1.enabled = YES;
//                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
//            });
//        }
//    }];
}


#pragma mark - NSNotification Methods -
- (void)willSaveNewChallengePost:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.savingNewEditPost = YES;
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Saving New Post...";
        hud.dimBackground = NO;
    });
}

- (void)postSucceeded
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        [self refreshFromDatabase];
        self.savingNewEditPost = NO;
    });
}

- (void)postFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.savingNewEditPost = NO;

        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Your post failed to upload.";
        hud.dimBackground = NO;
        hud.mode = MBProgressHUDModeText;
        [hud hide:YES afterDelay:1.5f];
    });
}

- (void)willSaveNewPostComment:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Saving New Comment...";
        hud.dimBackground = NO;
    });
}

- (void)willSaveEditPostComment:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Saving Updated Comment...";
        hud.dimBackground = NO;
    });
}

- (void)didSaveNewPostComment:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        [self refreshFromDatabase];
    });
}

- (void)commentFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Your comment failed to post.";
        hud.dimBackground = NO;
        hud.mode = MBProgressHUDModeText;
        [hud hide:YES afterDelay:1.5f];
    });
}

- (void)commentEditFailed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Your comment failed to save.";
        hud.dimBackground = NO;
        hud.mode = MBProgressHUDModeText;
        [hud hide:YES afterDelay:1.5f];
    });
}

- (void)willSaveEditPost:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.savingNewEditPost = YES;
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Saving...";
        hud.dimBackground = NO;
    });
}

- (void)didSaveEditPost:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.savingNewEditPost = NO;
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        [self refreshFromDatabase];
    });
}

- (void)failedSaveEditPost:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.savingNewEditPost = NO;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Your edit post failed to save.";
        hud.dimBackground = NO;
        hud.mode = MBProgressHUDModeText;
        [hud hide:YES afterDelay:1.5f];
    });
}


#pragma mark - Private -
- (void)configureButtonsForCell:(MTPostsTableViewCell *)cell
{
//    id buttonID = [self.buttonsTapped valueForKey:[cell.post objectId]];
//    NSInteger button = 0;
//    if (buttonID) {
//        button = [buttonID intValue];
//    }
//    
//    [self resetButtonsForCell:cell];
//
//    [cell.button1 layer].masksToBounds = YES;
//    [cell.button2 layer].masksToBounds = YES;
//
//    if ((button == 0) && buttonID) {
//        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:cell.button1.frame.size] forState:UIControlStateNormal];
//        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
//
//        [cell.button1 setTintColor:[UIColor white]];
//        [cell.button1 setTitleColor:[UIColor white] forState:UIControlStateNormal];
//        [cell.button1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
//
//        [[cell.button2 layer] setBorderWidth:2.0f];
//        [[cell.button2 layer] setBorderColor:[UIColor redOrange].CGColor];
//        [cell.button2 setTintColor:[UIColor redOrange]];
//        [cell.button2 setTitleColor:[UIColor redOrange] forState:UIControlStateNormal];
//        [cell.button2 setTitleColor:[UIColor lightRedOrange] forState:UIControlStateHighlighted];
//        
//        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateNormal];
//        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
//    }
//    else if (button == 1) {
//        [[cell.button1 layer] setBorderWidth:2.0f];
//        [[cell.button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
//        [cell.button1 setTintColor:[UIColor primaryGreen]];
//        [cell.button1 setTitleColor:[UIColor primaryGreen] forState:UIControlStateNormal];
//        [cell.button1 setTitleColor:[UIColor lightGreen] forState:UIControlStateHighlighted];
//
//        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateNormal];
//        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
//        
//        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor redOrange] size:cell.button2.frame.size] forState:UIControlStateNormal];
//        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor redOrange] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
//
//        [cell.button2 setTintColor:[UIColor white]];
//        [cell.button2 setTitleColor:[UIColor white] forState:UIControlStateNormal];
//        [cell.button2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
//    }
//    else {
//        [[cell.button1 layer] setBorderWidth:2.0f];
//        [[cell.button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
//        [cell.button1 setTintColor:[UIColor primaryGreen]];
//        [cell.button1 setTitleColor:[UIColor primaryGreen] forState:UIControlStateNormal];
//        [cell.button1 setTitleColor:[UIColor lightGreen] forState:UIControlStateHighlighted];
//
//        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateNormal];
//        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
//
//        [[cell.button2 layer] setBorderWidth:2.0f];
//        [[cell.button2 layer] setBorderColor:[UIColor redOrange].CGColor];
//        [cell.button2 setTintColor:[UIColor redOrange]];
//        [cell.button2 setTitleColor:[UIColor redOrange] forState:UIControlStateNormal];
//        [cell.button2 setTitleColor:[UIColor lightRedOrange] forState:UIControlStateHighlighted];
//
//        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateNormal];
//        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
//    }
//    
//    [[cell.button1 layer] setCornerRadius:5.0f];
//    [[cell.button2 layer] setCornerRadius:5.0f];
//    
//    [cell.button1 addTarget:self action:@selector(button1Tapped:) forControlEvents:UIControlEventTouchUpInside];
//    [cell.button2 addTarget:self action:@selector(button2Tapped:) forControlEvents:UIControlEventTouchUpInside];
//    
//    NSArray *buttonTitles = self.challenge[@"buttons"];
//    NSArray *buttonsClicked = cell.post[@"buttons_clicked"];
//    
//    if (buttonTitles.count > 0) {
//        NSString *button1Title;
//        NSString *button2Title;
//        
//        if (buttonsClicked.count > 0) {
//            button1Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[0], buttonsClicked[0]];
//        }
//        else {
//            button1Title = [NSString stringWithFormat:@"%@ (0)", buttonTitles[0]];
//        }
//        
//        if (buttonsClicked.count > 1) {
//            button2Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[1], buttonsClicked[1]];
//        }
//        else {
//            button2Title = [NSString stringWithFormat:@"%@ (0)", buttonTitles[1]];
//        }
//        
//        [cell.button1 setTitle:button1Title forState:UIControlStateNormal];
//        [cell.button2 setTitle:button2Title forState:UIControlStateNormal];
//    }
}

- (void)configureSecondaryButtonsForCell:(MTPostsTableViewCell *)cell
{
    MTChallengePost *post = cell.post;
//    NSDictionary *buttonDict = [self.secondaryButtonsTapped objectForKey:post.objectId];
//    
//    NSInteger button1Count = [[buttonDict objectForKey:@0] integerValue];
//    NSInteger button2Count = [[buttonDict objectForKey:@1] integerValue];
//    
//    [self resetButtonsForCell:cell];
//    
//    // Configure Button 1
//    [[cell.button1 layer] setBackgroundColor:[UIColor whiteColor].CGColor];
//    [[cell.button1 layer] setBorderWidth:1.0f];
//    [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor] size:cell.button1.frame.size] forState:UIControlStateNormal];
//    [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
//    [[cell.button1 layer] setCornerRadius:5.0f];
//    [cell.button1 setImage:[UIImage imageNamed:@"icon_button_dollar_normal"] forState:UIControlStateNormal];
//    [cell.button1 setImage:[UIImage imageNamed:@"icon_button_dollar_pressed"] forState:UIControlStateHighlighted];
//    [cell.button1 setTitleColor:[UIColor white] forState:UIControlStateHighlighted];
//
//    cell.button1.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 0.0f);
//    [cell.button1 layer].masksToBounds = YES;
//    
//    if (button1Count > 0) {
//        [cell.button1 setTitle:[NSString stringWithFormat:@"%ld", (long)button1Count] forState:UIControlStateNormal];
//    }
//    else {
//        [cell.button1 setTitle:@"" forState:UIControlStateNormal];
//    }
//
//    [cell.button1 addTarget:self action:@selector(secondaryButton1Tapped:) forControlEvents:UIControlEventTouchUpInside];
//
//    // Configure Button 2
//    [[cell.button2 layer] setBorderColor:[UIColor darkGrayColor].CGColor];
//    [[cell.button2 layer] setBackgroundColor:[UIColor whiteColor].CGColor];
//    [[cell.button2 layer] setBorderWidth:1.0f];
//    [[cell.button2 layer] setCornerRadius:5.0f];
//    [cell.button2 setTitle:@"" forState:UIControlStateNormal];
//    [cell.button2 layer].masksToBounds = YES;
//
//    if (button2Count > 0) {
//        cell.button1.enabled = NO;
//        [[cell.button1 layer] setBorderColor:[UIColor lightGrayColor].CGColor];
//        [cell.button1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
//
//        [cell.button2 setImage:[UIImage imageNamed:@"icon_button_check_pressed"] forState:UIControlStateNormal];
//        [cell.button2 setImage:[UIImage imageNamed:@"icon_button_check_normal"] forState:UIControlStateHighlighted];
//
//        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:cell.button2.frame.size] forState:UIControlStateNormal];
//        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreenDark] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
//    }
//    else {
//        cell.button1.enabled = YES;
//        [[cell.button1 layer] setBorderColor:[UIColor darkGrayColor].CGColor];
//        [cell.button1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//        [cell.button1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
//
//        [cell.button2 setImage:[UIImage imageNamed:@"icon_button_check_normal"] forState:UIControlStateNormal];
//        [cell.button2 setImage:[UIImage imageNamed:@"icon_button_check_pressed"] forState:UIControlStateHighlighted];
//
//        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor] size:cell.button2.frame.size] forState:UIControlStateNormal];
//        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
//    }
//    
//    [cell.button2 addTarget:self action:@selector(secondaryButton2Tapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureTertiaryButtonsForCell:(MTPostsTableViewCell *)cell
{
//    id buttonID = [self.buttonsTapped valueForKey:[cell.post objectId]];
//    NSInteger button = 0;
//    if (buttonID) {
//        button = [buttonID intValue];
//    }
//    
//    [self resetButtonsForCell:cell];
//    
//    [cell.button1 layer].masksToBounds = YES;
//    [cell.button2 layer].masksToBounds = YES;
//    [cell.button3 layer].masksToBounds = YES;
//    [cell.button4 layer].masksToBounds = YES;
//
//    if (!buttonID) {
//        [[cell.button1 layer] setBorderWidth:2.0f];
//        [[cell.button1 layer] setBorderColor:[UIColor votingRed].CGColor];
//        [cell.button1 setTintColor:[UIColor votingRed]];
//        [cell.button1 setTitleColor:[UIColor votingRed] forState:UIControlStateNormal];
//        [cell.button1 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateNormal];
//        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
//        
//        [[cell.button2 layer] setBorderWidth:2.0f];
//        [[cell.button2 layer] setBorderColor:[UIColor votingPurple].CGColor];
//        [cell.button2 setTintColor:[UIColor votingPurple]];
//        [cell.button2 setTitleColor:[UIColor votingPurple] forState:UIControlStateNormal];
//        [cell.button2 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateNormal];
//        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
//        
//        [[cell.button3 layer] setBorderWidth:2.0f];
//        [[cell.button3 layer] setBorderColor:[UIColor votingBlue].CGColor];
//        [cell.button3 setTintColor:[UIColor votingBlue]];
//        [cell.button3 setTitleColor:[UIColor votingBlue] forState:UIControlStateNormal];
//        [cell.button3 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//        [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateNormal];
//        [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateHighlighted];
//        
//        [[cell.button4 layer] setBorderWidth:2.0f];
//        [[cell.button4 layer] setBorderColor:[UIColor votingGreen].CGColor];
//        [cell.button4 setTintColor:[UIColor votingGreen]];
//        [cell.button4 setTitleColor:[UIColor votingGreen] forState:UIControlStateNormal];
//        [cell.button4 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//        [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateNormal];
//        [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateHighlighted];
//    }
//    else {
//        if (button == 0) {
//            // Selected
//            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor votingRed] size:cell.button1.frame.size] forState:UIControlStateNormal];
//            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor votingRed] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
//            [cell.button1 setTintColor:[UIColor white]];
//            [cell.button1 setTitleColor:[UIColor white] forState:UIControlStateNormal];
//            [cell.button1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
//            
//            [[cell.button2 layer] setBorderWidth:2.0f];
//            [[cell.button2 layer] setBorderColor:[UIColor votingPurple].CGColor];
//            [cell.button2 setTintColor:[UIColor votingPurple]];
//            [cell.button2 setTitleColor:[UIColor votingPurple] forState:UIControlStateNormal];
//            [cell.button2 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateNormal];
//            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
//            
//            [[cell.button3 layer] setBorderWidth:2.0f];
//            [[cell.button3 layer] setBorderColor:[UIColor votingBlue].CGColor];
//            [cell.button3 setTintColor:[UIColor votingBlue]];
//            [cell.button3 setTitleColor:[UIColor votingBlue] forState:UIControlStateNormal];
//            [cell.button3 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateNormal];
//            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateHighlighted];
//            
//            [[cell.button4 layer] setBorderWidth:2.0f];
//            [[cell.button4 layer] setBorderColor:[UIColor votingGreen].CGColor];
//            [cell.button4 setTintColor:[UIColor votingGreen]];
//            [cell.button4 setTitleColor:[UIColor votingGreen] forState:UIControlStateNormal];
//            [cell.button4 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateNormal];
//            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateHighlighted];
//        }
//        else if (button == 1) {
//            [[cell.button1 layer] setBorderWidth:2.0f];
//            [[cell.button1 layer] setBorderColor:[UIColor votingRed].CGColor];
//            [cell.button1 setTintColor:[UIColor votingRed]];
//            [cell.button1 setTitleColor:[UIColor votingRed] forState:UIControlStateNormal];
//            [cell.button1 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateNormal];
//            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
//            
//            // Selected
//            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor votingPurple] size:cell.button2.frame.size] forState:UIControlStateNormal];
//            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor votingPurple] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
//            [cell.button2 setTintColor:[UIColor white]];
//            [cell.button2 setTitleColor:[UIColor white] forState:UIControlStateNormal];
//            [cell.button2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
//            
//            [[cell.button3 layer] setBorderWidth:2.0f];
//            [[cell.button3 layer] setBorderColor:[UIColor votingBlue].CGColor];
//            [cell.button3 setTintColor:[UIColor votingBlue]];
//            [cell.button3 setTitleColor:[UIColor votingBlue] forState:UIControlStateNormal];
//            [cell.button3 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateNormal];
//            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateHighlighted];
//            
//            [[cell.button4 layer] setBorderWidth:2.0f];
//            [[cell.button4 layer] setBorderColor:[UIColor votingGreen].CGColor];
//            [cell.button4 setTintColor:[UIColor votingGreen]];
//            [cell.button4 setTitleColor:[UIColor votingGreen] forState:UIControlStateNormal];
//            [cell.button4 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateNormal];
//            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateHighlighted];
//        }
//        else if (button == 2) {
//            [[cell.button1 layer] setBorderWidth:2.0f];
//            [[cell.button1 layer] setBorderColor:[UIColor votingRed].CGColor];
//            [cell.button1 setTintColor:[UIColor votingRed]];
//            [cell.button1 setTitleColor:[UIColor votingRed] forState:UIControlStateNormal];
//            [cell.button1 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateNormal];
//            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
//            
//            [[cell.button2 layer] setBorderWidth:2.0f];
//            [[cell.button2 layer] setBorderColor:[UIColor votingPurple].CGColor];
//            [cell.button2 setTintColor:[UIColor votingPurple]];
//            [cell.button2 setTitleColor:[UIColor votingPurple] forState:UIControlStateNormal];
//            [cell.button2 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateNormal];
//            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
//            
//            // Selected
//            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor votingBlue] size:cell.button3.frame.size] forState:UIControlStateNormal];
//            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor votingBlue] size:cell.button3.frame.size] forState:UIControlStateHighlighted];
//            [cell.button3 setTintColor:[UIColor white]];
//            [cell.button3 setTitleColor:[UIColor white] forState:UIControlStateNormal];
//            [cell.button3 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
//            
//            [[cell.button4 layer] setBorderWidth:2.0f];
//            [[cell.button4 layer] setBorderColor:[UIColor votingGreen].CGColor];
//            [cell.button4 setTintColor:[UIColor votingGreen]];
//            [cell.button4 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//            [cell.button4 setTitleColor:[UIColor votingGreen] forState:UIControlStateHighlighted];
//            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateNormal];
//            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateHighlighted];
//        }
//        else if (button == 3) {
//            [[cell.button1 layer] setBorderWidth:2.0f];
//            [[cell.button1 layer] setBorderColor:[UIColor votingRed].CGColor];
//            [cell.button1 setTintColor:[UIColor votingRed]];
//            [cell.button1 setTitleColor:[UIColor votingRed] forState:UIControlStateNormal];
//            [cell.button1 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateNormal];
//            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
//            
//            [[cell.button2 layer] setBorderWidth:2.0f];
//            [[cell.button2 layer] setBorderColor:[UIColor votingPurple].CGColor];
//            [cell.button2 setTintColor:[UIColor votingPurple]];
//            [cell.button2 setTitleColor:[UIColor votingPurple] forState:UIControlStateNormal];
//            [cell.button2 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateNormal];
//            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
//
//            [[cell.button3 layer] setBorderWidth:2.0f];
//            [[cell.button3 layer] setBorderColor:[UIColor votingBlue].CGColor];
//            [cell.button3 setTintColor:[UIColor votingBlue]];
//            [cell.button3 setTitleColor:[UIColor votingBlue] forState:UIControlStateNormal];
//            [cell.button3 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
//            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateNormal];
//            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateHighlighted];
//            
//            // Selected
//            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor votingGreen] size:cell.button4.frame.size] forState:UIControlStateNormal];
//            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor votingGreen] size:cell.button4.frame.size] forState:UIControlStateHighlighted];
//            [cell.button4 setTintColor:[UIColor white]];
//            [cell.button4 setTitleColor:[UIColor white] forState:UIControlStateNormal];
//            [cell.button4 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
//        }
//    }
//    
//    [[cell.button1 layer] setCornerRadius:5.0f];
//    [[cell.button2 layer] setCornerRadius:5.0f];
//    [[cell.button3 layer] setCornerRadius:5.0f];
//    [[cell.button4 layer] setCornerRadius:5.0f];
//    
//    [cell.button1 addTarget:self action:@selector(button1Tapped:) forControlEvents:UIControlEventTouchUpInside];
//    [cell.button2 addTarget:self action:@selector(button2Tapped:) forControlEvents:UIControlEventTouchUpInside];
//    [cell.button3 addTarget:self action:@selector(button3Tapped:) forControlEvents:UIControlEventTouchUpInside];
//    [cell.button4 addTarget:self action:@selector(button4Tapped:) forControlEvents:UIControlEventTouchUpInside];
//    
//    NSArray *buttonTitles = self.challenge[@"buttons"];
//    NSArray *buttonsClicked = cell.post[@"buttons_clicked"];
//    
//    if (buttonTitles.count == 4) {
//        NSString *button1Title;
//        NSString *button2Title;
//        NSString *button3Title;
//        NSString *button4Title;
//        
//        if (buttonsClicked.count > 0 && [buttonsClicked[0] intValue] > 0) {
//            button1Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[0], buttonsClicked[0]];
//        }
//        else {
//            button1Title = [NSString stringWithFormat:@"%@", buttonTitles[0]];
//        }
//        
//        if (buttonsClicked.count > 1 && [buttonsClicked[1] intValue] > 0) {
//            button2Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[1], buttonsClicked[1]];
//        }
//        else {
//            button2Title = [NSString stringWithFormat:@"%@", buttonTitles[1]];
//        }
//
//        if (buttonsClicked.count > 2 && [buttonsClicked[2] intValue] > 0) {
//            button3Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[2], buttonsClicked[2]];
//        }
//        else {
//            button3Title = [NSString stringWithFormat:@"%@", buttonTitles[2]];
//        }
//
//        if (buttonsClicked.count > 3 && [buttonsClicked[3] intValue] > 0) {
//            button4Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[3], buttonsClicked[3]];
//        }
//        else {
//            button4Title = [NSString stringWithFormat:@"%@", buttonTitles[3]];
//        }
//
//        [cell.button1 setTitle:button1Title forState:UIControlStateNormal];
//        [cell.button2 setTitle:button2Title forState:UIControlStateNormal];
//        [cell.button3 setTitle:button3Title forState:UIControlStateNormal];
//        [cell.button4 setTitle:button4Title forState:UIControlStateNormal];
//    }
//    
//    [cell.button1.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
//    [cell.button2.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
}

- (void)resetButtonsForCell:(MTPostsTableViewCell *)cell
{
    // Reset buttons
    cell.button1.enabled = YES;
    cell.button2.enabled = YES;
    cell.button3.enabled = YES;
    cell.button4.enabled = YES;

    [cell.button1.titleLabel setFont:[UIFont systemFontOfSize:18.0f]];
    [cell.button1 setImage:nil forState:UIControlStateNormal];
    [cell.button1 setImage:nil forState:UIControlStateHighlighted];
    [cell.button1 setBackgroundImage:nil forState:UIControlStateNormal];
    [cell.button1 setBackgroundImage:nil forState:UIControlStateHighlighted];
    [cell.button1.titleLabel setTextAlignment:NSTextAlignmentCenter];
    cell.button1.titleEdgeInsets = UIEdgeInsetsZero;
    [cell.button1 setTitle:@"" forState:UIControlStateNormal];

    [cell.button2.titleLabel setFont:[UIFont systemFontOfSize:18.0f]];
    [cell.button2 setImage:nil forState:UIControlStateNormal];
    [cell.button2 setImage:nil forState:UIControlStateHighlighted];
    [cell.button2 setBackgroundImage:nil forState:UIControlStateNormal];
    [cell.button2 setBackgroundImage:nil forState:UIControlStateHighlighted];
    [cell.button2.titleLabel setTextAlignment:NSTextAlignmentCenter];
    cell.button2.titleEdgeInsets = UIEdgeInsetsZero;
    [cell.button1 setTitle:@"" forState:UIControlStateNormal];

    [cell.button3.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [cell.button3 setImage:nil forState:UIControlStateNormal];
    [cell.button3 setImage:nil forState:UIControlStateHighlighted];
    [cell.button3 setBackgroundImage:nil forState:UIControlStateNormal];
    [cell.button3 setBackgroundImage:nil forState:UIControlStateHighlighted];
    [cell.button3.titleLabel setTextAlignment:NSTextAlignmentCenter];
    cell.button3.titleEdgeInsets = UIEdgeInsetsZero;
    [cell.button1 setTitle:@"" forState:UIControlStateNormal];

    [cell.button4.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [cell.button4 setImage:nil forState:UIControlStateNormal];
    [cell.button4 setImage:nil forState:UIControlStateHighlighted];
    [cell.button4 setBackgroundImage:nil forState:UIControlStateNormal];
    [cell.button4 setBackgroundImage:nil forState:UIControlStateHighlighted];
    [cell.button4.titleLabel setTextAlignment:NSTextAlignmentCenter];
    cell.button4.titleEdgeInsets = UIEdgeInsetsZero;
    [cell.button1 setTitle:@"" forState:UIControlStateNormal];

    [cell.button1 removeTarget:self action:@selector(button1Tapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button2 removeTarget:self action:@selector(button2Tapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button3 removeTarget:self action:@selector(button3Tapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button4 removeTarget:self action:@selector(button4Tapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button1 removeTarget:self action:@selector(secondaryButton1Tapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button2 removeTarget:self action:@selector(secondaryButton2Tapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)showFirstTimeToastNotification
{
    NSString *key = @"ShownToastForChallenge";
    NSArray *shownArray = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (![shownArray containsObject:[NSNumber numberWithInteger:self.challenge.id]]) {
        
        // If not added for this install but we have a title, no need to show this again
        if (!IsEmpty([self.secondaryButton1 titleForState:UIControlStateNormal])) {
            NSMutableArray *mutant = [NSMutableArray arrayWithArray:shownArray];
            [mutant addObject:[NSNumber numberWithInteger:self.challenge.id]];
            [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:mutant] forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];

            [self secondaryButton1AfterToastAction];
        }
        else {
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
            hud.labelText = @"";
            hud.detailsLabelText = @"Congratulations on taking a step towards your goal!";
            hud.dimBackground = NO;
            hud.mode = MBProgressHUDModeText;
            hud.delegate = self;
            [hud hide:YES afterDelay:1.0f];
            
            NSMutableArray *mutant = [NSMutableArray arrayWithArray:shownArray];
            [mutant addObject:[NSNumber numberWithInteger:self.challenge.id]];
            [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:mutant] forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    else {
        [self secondaryButton1AfterToastAction];
    }
}

- (void)likeWithEmojiPrompt:(id)sender
{
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[sender findSuperViewWithClass:[MTPostsTableViewCell class]];
    MTChallengePost *post = cell.post;
    
    [self didSelectLikeWithEmojiForPost:post];
}

- (void)cancelEmojiPrompt
{
    [self dismissEmojiPromptWithCompletion:NULL];
}

- (void)dismissEmojiPromptWithCompletion:(void (^)(BOOL finished))completion
{
    CGRect keyWindowFrame = [UIApplication sharedApplication].keyWindow.frame;
    
    [UIView animateWithDuration:0.1f animations:^{
        for (UIView *subview in [self.emojiContainerView subviews]) {
            subview.alpha = 0.0f;
        }
        
    } completion:^(BOOL finished) {
        
        [UIView animateWithDuration:0.3f animations:^{
            self.emojiDimView.alpha = 0.0f;
            self.emojiContainerView.frame = ({
                CGRect newFrame = self.emojiContainerView.frame;
                newFrame.size.height = 0.0f;
                newFrame.size.width = 0.0f;
                newFrame.origin.y = keyWindowFrame.size.height/2.0f;
                newFrame.origin.x = keyWindowFrame.size.width/2.0f;
                
                newFrame;
            });
            
            self.emojiContainerView.alpha = 0.0f;
            
        } completion:^(BOOL finished) {
            
            _emojiCollectionView.collectionView.dataSource = nil;
            _emojiCollectionView.collectionView.delegate = nil;

            [self.emojiCollectionView willMoveToParentViewController:nil];
            [self.emojiCollectionView.view removeFromSuperview];
            [self.emojiCollectionView.collectionView removeFromSuperview];
            [self.emojiCollectionView removeFromParentViewController];
            
            [self.emojiContainerView removeFromSuperview];
            [self.emojiDimView removeFromSuperview];
            
            _emojiCollectionView = nil;
            _emojiContainerView = nil;
            _emojiDimView = nil;
            
            if (completion) {
                completion(YES);
            }
        }];
    }];
}

- (void)parseAndPopulateSpentFieldsForCell:(MTPostsTableViewCell *)cell
{
    // Assume blank
    cell.spentView.hidden = YES;
    cell.spentLabel.text = @"";
    cell.savedLabel.text = @"";

    if (self.displaySpentView && !IsEmpty(cell.post.challengeData)) {
        NSData *data = [cell.post.challengeData dataUsingEncoding:NSUTF8StringEncoding];
        id jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        if ([jsonDict isKindOfClass:[NSDictionary class]]) {
            NSDictionary *savedSpentDict = (NSDictionary *)jsonDict;
            NSString *spentString = [savedSpentDict objectForKey:@"spent"];
            NSString *currencyString = [self currencyTextForString:spentString];
            if (!IsEmpty(currencyString)) {
                cell.spentLabel.text = [NSString stringWithFormat:@"Spent %@", currencyString];
                cell.spentView.hidden = NO;
            }
            
            NSString *savedString = [savedSpentDict objectForKey:@"saved"];
            currencyString = [self currencyTextForString:savedString];
            if (!IsEmpty(currencyString)) {
                cell.savedLabel.text = [NSString stringWithFormat:@"Saved %@", currencyString];
                cell.spentView.hidden = NO;
            }
        }
    }
}

- (BOOL)hasSpentContentForPost:(MTChallengePost *)post
{
    BOOL hasContent = NO;
    if (self.displaySpentView && !IsEmpty(post.challengeData)) {
        NSData *data = [post.challengeData dataUsingEncoding:NSUTF8StringEncoding];
        id jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        if ([jsonDict isKindOfClass:[NSDictionary class]]) {
            NSDictionary *savedSpentDict = (NSDictionary *)jsonDict;
            NSString *spentString = [savedSpentDict objectForKey:@"spent"];
            NSString *currencyString = [self currencyTextForString:spentString];
            if (!IsEmpty(currencyString)) {
                hasContent = YES;
            }
            
            NSString *savedString = [savedSpentDict objectForKey:@"saved"];
            currencyString = [self currencyTextForString:savedString];
            if (!IsEmpty(currencyString)) {
                hasContent = YES;
            }
        }
    }
    
    return hasContent;
}

- (NSString *)currencyTextForString:(NSString *)string
{
    NSString *currencyText = nil;
    
    NSNumberFormatter *decimalFormatter = [[NSNumberFormatter alloc] init];
    [decimalFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [decimalFormatter setUsesGroupingSeparator:NO];
    [decimalFormatter setMaximumFractionDigits:2];
    
    NSNumber *currentNumber = [decimalFormatter numberFromString:string];
    
    if ([currentNumber floatValue] >= 0.01f) {
        NSNumberFormatter *currencyformatter = [[NSNumberFormatter alloc] init];
        [currencyformatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        currencyText = [currencyformatter stringFromNumber:currentNumber];
    }
    else {
        currencyText = @"";
    }
    
    return currencyText;
}


#pragma mark - MBProgressHUDDelegate Methods -
- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self secondaryButton1AfterToastAction];
}


#pragma mark - UITableViewDataSource methods -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.challengePosts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block MTChallengePost *post = (MTChallengePost *)[self.challengePosts objectAtIndex:indexPath.row];

    MTUser *user = post.user;
    NSString *CellIdentifier = @"";
    
    BOOL hasImage = post.hasPostImage;
    
    BOOL myPost = [MTUser isUserMe:user];
    
    BOOL showButtons = NO;
    if (self.hasButtons || (self.hasSecondaryButtons && myPost) || self.hasTertiaryButtons) {
        showButtons = YES;
    }
    
    BOOL hasSpentContent = [self hasSpentContentForPost:post];
    
    if (showButtons && hasImage) {
        if (self.hasTertiaryButtons) {
            CellIdentifier = @"postCellWithQuadButtons";
        }
        else {
            CellIdentifier = @"postCellWithButtons";
        }
    } else if (showButtons) {
        if (self.hasTertiaryButtons) {
            if (hasSpentContent) {
                CellIdentifier = @"postCellNoImageWithQuadButtonsSpentView";
            }
            else {
                CellIdentifier = @"postCellNoImageWithQuadButtons";
            }
        }
        else {
            if (hasSpentContent) {
                CellIdentifier = @"postCellNoImageWithButtonsSpentView";
            }
            else {
                CellIdentifier = @"postCellNoImageWithButtons";
            }
        }
    } else if (hasImage) {
        CellIdentifier = @"postCell";
    } else {
        if (hasSpentContent) {
            CellIdentifier = @"postCellNoImageSpentView";
        }
        else {
            CellIdentifier = @"postCellNoImage";
        }
    }
    
    MTPostsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.post = post;
    
    [self parseAndPopulateSpentFieldsForCell:cell];
    
    // Setup Verify
    BOOL isMentor = [MTUser isCurrentUserMentor];
    BOOL autoVerify = self.challenge.autoVerify;
    BOOL hideVerifySwitch = !isMentor || autoVerify;

    cell.verifiedCheckBox.hidden = hideVerifySwitch;
    BOOL isChecked = post.isVerified;
    [cell.verifiedCheckBox setIsChecked:isChecked];
    
    cell.verfiedLabel.hidden = hideVerifySwitch;
    if (isChecked) {
        cell.verfiedLabel.text = @"Verified";
    }
    else {
        cell.verfiedLabel.text = @"Verify";
    }
    
    BOOL canDelete = NO;
    if (myPost) {
        canDelete = YES;
        [cell.deletePost removeTarget:self action:@selector(editDeletePostTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cell.deletePost addTarget:self action:@selector(editDeletePostTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (showButtons) {
        if (self.hasTertiaryButtons) {
            [self configureTertiaryButtonsForCell:cell];
        }
        else if (self.hasSecondaryButtons) {
            [self configureSecondaryButtonsForCell:cell];
        }
        else {
            [self configureButtonsForCell:cell];
        }
    }
    
    cell.userName.text = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
    
    __block MTPostsTableViewCell *weakCell = cell;
    cell.profileImage.image = [user loadAvatarImageWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakCell.profileImage.image = responseData;
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load user avatar");
    }];
    
    cell.postText.text = post.content;
    
    if (!IsEmpty(cell.postText.text)) {
        NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
        NSRange rangeAll = NSMakeRange(0, cell.postText.text.length);
        
        [hashtags enumerateMatchesInString:cell.postText.text options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSMutableAttributedString *hashtag = [[NSMutableAttributedString alloc]initWithString:cell.postText.text];
            [hashtag addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
            
            cell.postText.attributedText = hashtag;
        }];
    }
    
    if (hasImage) {
        cell.postImage.image = [post loadPostImageWithSuccess:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakCell.postImage.image = responseData;
            });
        } failure:^(NSError *error) {
            NSLog(@"Unable to load post image");
        }];
    }
    
    NSDate *dateObject = post.createdAt;
    
    if (dateObject) {
        cell.postedWhen.text = [dateObject niceRelativeTimeFromNow];
    }
    else {
        // New one
        cell.postedWhen.text = [[NSDate dateWithTimeIntervalSinceNow:0.1f] niceRelativeTimeFromNow];
    }
    
    // Likes Info
    RLMResults *likesForPost = [MTChallengePostLike objectsWhere:@"challengePost.id = %lu AND isDeleted = NO", post.id];
    NSMutableArray *emojiArray = [NSMutableArray array];
    for (MTChallengePostLike *thisLike in likesForPost) {
        MTEmoji *thisEmoji = thisLike.emoji;
        if (thisEmoji) {
            [emojiArray addObject:thisEmoji];
        }
    }
    
    cell.emojiArray = emojiArray;

    NSInteger likes = [likesForPost count];
    BOOL iLike = [MTChallengePostLike postLikesContainsMyLike:likesForPost];
    
    if (iLike) {
        [cell.likeButton setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
        [cell.likeButton setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateDisabled];
    }
    else {
        [cell.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
        [cell.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateDisabled];
    }
    
    // Set Likes Text
    NSString *likesString;
    if (likes > 0) {
        likesString = [NSString stringWithFormat:@"%ld", (long)likes];
    }
    else {
        likesString = @"0";
    }
    cell.likes.text = likesString;
    
    [cell.likeButton removeTarget:self action:@selector(likeWithEmojiPrompt:) forControlEvents:UIControlEventTouchUpInside];
    [cell.likeButton addTarget:self action:@selector(likeWithEmojiPrompt:) forControlEvents:UIControlEventTouchUpInside];
    
    // Default comment
    [cell.commentButton setImage:[UIImage imageNamed:@"comment_highlighted"] forState:UIControlStateHighlighted];
    [cell.commentButton setImage:[UIImage imageNamed:@"comment_normal"] forState:UIControlStateNormal];
    [cell.commentButton setImage:[UIImage imageNamed:@"comment_normal"] forState:UIControlStateDisabled];
    cell.comments.text = @"";
    
    RLMResults *comments = [MTChallengePostComment objectsWhere:@"challengePost.id = %lu AND isDeleted = NO", post.id];
    if ([MTChallengePostComment postCommentsContainsMyComment:comments]) {
        [cell.commentButton setImage:[UIImage imageNamed:@"comment_active"] forState:UIControlStateNormal];
        [cell.commentButton setImage:[UIImage imageNamed:@"comment_active"] forState:UIControlStateDisabled];
    } else {
        [cell.commentButton setImage:[UIImage imageNamed:@"comment_normal"] forState:UIControlStateNormal];
        [cell.commentButton setImage:[UIImage imageNamed:@"comment_normal"] forState:UIControlStateDisabled];
    }

    cell.comments.text = [NSString stringWithFormat:@"%ld", (long)[comments count]];

    cell.activityIndicator.hidden = YES;
    cell.deletePost.hidden = !canDelete;
    cell.loadingView.alpha = 0.0f;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    // TODO: Re-enable showing new post?
//    if (dateObject) {
//        cell.activityIndicator.hidden = YES;
//        cell.deletePost.hidden = !canDelete;
//        cell.loadingView.alpha = 0.0f;
//        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
//    }
//    else {
//        cell.comments.text = @"0";
//        cell.activityIndicator.hidden = NO;
//        [cell.activityIndicator startAnimating];
//        cell.deletePost.hidden = YES;
//        cell.loadingView.alpha = 0.3f;
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
//    }
    
    return cell;
}


#pragma mark - UITableViewDelegate Methods -
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (cell.loadingView.alpha != 0.0f) {
        return;
    }
    
    MTChallengePost *rowObject = self.challengePosts[indexPath.row];
//    self.postImage = rowObject[@"picture"];
    
    [self performSegueWithIdentifier:@"pushViewPost" sender:cell];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    CGFloat height = 0.0f;
    
    if (row < [self.challengePosts count]) {
        MTChallengePost *rowObject = self.challengePosts[row];
        BOOL hasPostImage = rowObject.hasPostImage;
        
        MTChallengePost *post = (MTChallengePost *)[self.challengePosts objectAtIndex:indexPath.row];
        MTUser *user = post.user;

        BOOL myPost = NO;
        if ([MTUser isUserMe:user]) {
            myPost = YES;
        }

        BOOL showButtons = NO;
        if (self.hasButtons || (self.hasSecondaryButtons && myPost) || self.hasTertiaryButtons) {
            showButtons = YES;
        }
        
        BOOL hasSpentContent = [self hasSpentContentForPost:post];

        if (showButtons && hasPostImage) {
            if (self.hasTertiaryButtons) {
                height = 500.0f;
            }
            else {
                height = 466.0f;
            }
        } else if (showButtons) {
            if (self.hasTertiaryButtons) {
                if (hasSpentContent) {
                    height = 258.0f;
                }
                else {
                    height = 224.0f;
                }
            }
            else {
                if (hasSpentContent) {
                    height = 224.0f;
                }
                else {
                    height = 190.0f;
                }
            }
        } else if (hasPostImage) {
            height = 436.0f;
        } else {
            if (hasSpentContent) {
                height = 184.0f;
            }
            else {
                height = 150.0f;
            }
        }
    }
    
    return height;
}

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize withImage:(UIImage *)image
{
    UIImage *newImage = nil;
    CGSize imageSize = image.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor; // scale to fit height
        }
        else {
            scaleFactor = heightFactor; // scale to fit width
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else {
            if (widthFactor < heightFactor) {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
        }
    }
    
    UIGraphicsBeginImageContext(targetSize); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [image drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil) {
        NSLog(@"could not scale image");
    }
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    return newImage;
}


#pragma mark - Segue -
- (void)prepareForSegue:(UIStoryboardSegue*)segue sender:(id)sender
{
    NSString *segueIdentifier = [segue identifier];
    if ([segueIdentifier isEqualToString:@"commentOnPost"]) {
        UIButton *button = sender;
        
        MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[button findSuperViewWithClass:[MTPostsTableViewCell class]];
        MTChallengePost *post = cell.post;
  
        MTCommentViewController *destinationViewController = (MTCommentViewController *)[segue destinationViewController];
        destinationViewController.post = post;
        [destinationViewController setDelegate:self];
    }
    else if ([segueIdentifier isEqualToString:@"editPostSegue"]) {
        UIButton *button = sender;
        
        MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[button findSuperViewWithClass:[MTPostsTableViewCell class]];
        MTChallengePost *post = cell.post;
        
        UINavigationController *destinationViewController = (UINavigationController *)[segue destinationViewController];
        
        MTPostViewController *postVC = (MTPostViewController *)[destinationViewController topViewController];
        postVC.post = post;
        postVC.challenge = self.challenge;
        postVC.editPost = YES;
    }
    else {
        MTPostsTableViewCell *cell = (MTPostsTableViewCell *)sender;
        MTChallengePost *post = cell.post;

        self.postViewController = (MTPostDetailViewController*)[segue destinationViewController];
        self.postViewController.challengePost = post;
        self.postViewController.challenge = self.challenge;
        self.postViewController.delegate = self;
//        self.postViewController.postsLiked = self.postsLiked;
//        self.postViewController.postsLikedFull = self.postsLikedFull;
        self.postViewController.emojiArray = cell.emojiArray;
        self.postViewController.myClassTableViewController = self;

        MTUser *user = post.user;

        BOOL myPost = NO;
        if ([MTUser isUserMe:user]) {
            myPost = YES;
        }
        
        BOOL showButtons = NO;
        if (self.hasButtons || (self.hasSecondaryButtons && myPost) || self.hasTertiaryButtons) {
            showButtons = YES;
        }
        
        if (showButtons) {
            self.postViewController.hasButtons = self.hasButtons;
            self.postViewController.hasSecondaryButtons = self.hasSecondaryButtons;
            self.postViewController.hasTertiaryButtons = self.hasTertiaryButtons;
            self.postViewController.buttonsTapped = self.buttonsTapped;
            self.postViewController.secondaryButtonsTapped = self.secondaryButtonsTapped;
        }

        if (showButtons && post.hasPostImage)
            self.postViewController.postType = MTPostTypeWithButtonsWithImage;
        else if (showButtons)
            self.postViewController.postType = MTPostTypeWithButtonsNoImage;
        else if (post.hasPostImage)
            self.postViewController.postType = MTPostTypeNoButtonsWithImage;
        else
            self.postViewController.postType = MTPostTypeNoButtonsNoImage;
    }
}


#pragma mark - MTCommentViewProtocol Methods -
- (void)dismissCommentView
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}


#pragma mark - MTPostViewControllerDelegate Methods -
- (void)didDeletePost:(MTChallengePost *)challengePost
{
    self.deletingPost = YES;
    self.tableView.userInteractionEnabled = NO;
    
    // Perform on delay after we get popped to here
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        NSUInteger row = [weakSelf.challengePosts indexOfObject:challengePost];
        if (row != NSNotFound) {
            MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[weakSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
            if (cell) {
                UIButton *button = cell.deletePost;
                [weakSelf bk_performBlock:^(id obj) {
                    weakSelf.tableView.userInteractionEnabled = YES;
                } afterDelay:0.3f];
                
                [weakSelf performDeletePostWithSender:button withConfirmation:NO];
            }
            else {
                weakSelf.tableView.userInteractionEnabled = YES;
            }
        }
        else {
            weakSelf.tableView.userInteractionEnabled = YES;
        }
        
        weakSelf.deletingPost = NO;
    } afterDelay:0.35f];
}

- (void)didUpdateLikes
{
    [self updateLikes];
}

- (void)didUpdateButtonsTapped:(NSDictionary *)buttonsTapped
{
    self.buttonsTapped = buttonsTapped;
    [self.tableView reloadData];
}

- (void)didUpdateSecondaryButtonsTapped:(NSDictionary *)secondaryButtonsTapped
{
    self.secondaryButtonsTapped = secondaryButtonsTapped;
    [self.tableView reloadData];
}


#pragma mark - Actions -
- (IBAction)unwindToMyClassTableView:(UIStoryboardSegue *)sender
{
}

- (IBAction)commentTapped:(id)sender
{
    if (![MTUtil internetReachable]) {
        [UIAlertView showNoInternetAlert];
        return;
    }

    [self performSegueWithIdentifier:@"commentOnPost" sender:sender];
}

- (void)editDeletePostTapped:(id)sender
{
    __block id weakSender = sender;

    // Prompt for Edit or Delete
    if ([UIAlertController class]) {
        UIAlertController *editDeletePostSheet = [UIAlertController alertControllerWithTitle:@"Edit or Delete this post?" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }];
        MTMakeWeakSelf();
        UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [weakSelf performDeletePostWithSender:weakSender withConfirmation:YES];
        }];
        UIAlertAction *edit = [UIAlertAction actionWithTitle:@"Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakSelf performEditPostWithSender:weakSender];
        }];
        
        [editDeletePostSheet addAction:cancel];
        [editDeletePostSheet addAction:edit];
        [editDeletePostSheet addAction:delete];

        [self presentViewController:editDeletePostSheet animated:YES completion:nil];
    }
    else {
        MTMakeWeakSelf();
        UIActionSheet *editDeleteAction = [UIActionSheet bk_actionSheetWithTitle:@"Delete this post?"];
        [editDeleteAction bk_addButtonWithTitle:@"Edit" handler:^{
            [weakSelf performEditPostWithSender:weakSender];
        }];
        [editDeleteAction bk_setDestructiveButtonWithTitle:@"Delete" handler:^{
            [weakSelf performDeletePostWithSender:weakSender withConfirmation:YES];
        }];
        [editDeleteAction bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
        [editDeleteAction showInView:[UIApplication sharedApplication].keyWindow];
    }
}

- (void)performEditPostWithSender:(id)sender
{
    [self performSegueWithIdentifier:@"editPostSegue" sender:sender];
}

- (void)performDeletePostWithSender:(id)sender withConfirmation:(BOOL)withConfirmation
{
    UIButton *button = sender;
    
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[button findSuperViewWithClass:[MTPostsTableViewCell class]];
    __block MTChallengePost *post = cell.post;
    __block NSInteger postID = post.id;
    
    if (withConfirmation) {
        if ([UIAlertController class]) {
            UIAlertController *deletePostSheet = [UIAlertController alertControllerWithTitle:@"Delete this post?" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                     }];
            MTMakeWeakSelf();
            UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {

                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                MTChallengePost *postToDelete = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postID]];
                postToDelete.isDeleted = YES;
                [realm commitWriteTransaction];
                [weakSelf refreshFromDatabase];

                [[MTNetworkManager sharedMTNetworkManager] deletePostId:postID success:^(AFOAuthCredential *credential) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf refreshFromDatabase];
                        [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:nil failure:nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kDidDeleteChallengePostNotification object:[NSNumber numberWithInteger:weakSelf.challenge.id]];
                    });
                } failure:^(NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"error - %@", [error mtErrorDescription]);

                        RLMRealm *realm = [RLMRealm defaultRealm];
                        [realm beginWriteTransaction];
                        MTChallengePost *postToDelete = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postID]];
                        postToDelete.isDeleted = NO;
                        [realm commitWriteTransaction];
                        [weakSelf refreshFromDatabase];

                        [UIAlertView bk_showAlertViewWithTitle:@"Unable to Delete" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                    });
                }];
            }];
                                     
            [deletePostSheet addAction:cancel];
            [deletePostSheet addAction:delete];
            
            [self presentViewController:deletePostSheet animated:YES completion:nil];
        }
        else {
            MTMakeWeakSelf();
            UIActionSheet *deleteAction = [UIActionSheet bk_actionSheetWithTitle:@"Delete this post?"];
            [deleteAction bk_setDestructiveButtonWithTitle:@"Delete" handler:^{
                
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                MTChallengePost *postToDelete = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postID]];
                postToDelete.isDeleted = YES;
                [realm commitWriteTransaction];
                [weakSelf refreshFromDatabase];

                [[MTNetworkManager sharedMTNetworkManager] deletePostId:postID success:^(AFOAuthCredential *credential) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf refreshFromDatabase];
                        [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:nil failure:nil];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kDidDeleteChallengePostNotification object:[NSNumber numberWithInteger:weakSelf.challenge.id]];
                    });
                } failure:^(NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"error - %@", [error mtErrorDescription]);
                        
                        RLMRealm *realm = [RLMRealm defaultRealm];
                        [realm beginWriteTransaction];
                        MTChallengePost *postToDelete = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postID]];
                        postToDelete.isDeleted = NO;
                        [realm commitWriteTransaction];
                        [weakSelf refreshFromDatabase];

                        [UIAlertView bk_showAlertViewWithTitle:@"Unable to Delete" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                    });
                }];
                
            }];
            [deleteAction bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
            [deleteAction showInView:[UIApplication sharedApplication].keyWindow];
        }
    }
    else {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        MTChallengePost *postToDelete = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postID]];
        postToDelete.isDeleted = YES;
        [realm commitWriteTransaction];
        [self refreshFromDatabase];

        MTMakeWeakSelf();
        [[MTNetworkManager sharedMTNetworkManager] deletePostId:postID success:^(AFOAuthCredential *credential) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf refreshFromDatabase];
                [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:nil failure:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:kDidDeleteChallengePostNotification object:[NSNumber numberWithInteger:weakSelf.challenge.id]];
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"error - %@", [error mtErrorDescription]);
                
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                MTChallengePost *postToDelete = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postID]];
                postToDelete.isDeleted = NO;
                [realm commitWriteTransaction];
                [weakSelf refreshFromDatabase];
                
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Delete" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            });
        }];
    }
}

- (void)button1Tapped:(id)sender
{
    [self submitPrimaryButtonTapped:sender withButtonNumber:0];
}

- (void)button2Tapped:(id)sender
{
    [self submitPrimaryButtonTapped:sender withButtonNumber:1];
}

- (void)button3Tapped:(id)sender
{
    [self submitPrimaryButtonTapped:sender withButtonNumber:2];
}

- (void)button4Tapped:(id)sender
{
    [self submitPrimaryButtonTapped:sender withButtonNumber:3];
}

- (void)submitPrimaryButtonTapped:(id)sender withButtonNumber:(NSInteger)buttonNumber
{
    UIButton *button = sender;
    button.enabled = NO;
    
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[button findSuperViewWithClass:[MTPostsTableViewCell class]];
    MTChallengePost *post = cell.post;
    
    MTUser *user = [MTUser currentUser];
    
//    NSString *userID = [user objectId];
//    NSString *postID = [post objectId];
//    
//    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInteger:buttonNumber]};
    
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
//    hud.labelText = @"Submitting...";
//    hud.dimBackground = YES;
//    
//    MTMakeWeakSelf();
//    [self bk_performBlock:^(id obj) {
//        [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
//            if (!error) {
//                [[PFUser currentUser] fetchInBackground];
////                [weakSelf.challenge fetchInBackground];
//                [post fetchInBackground];
//                [weakSelf userButtonsTapped];
////                [weakSelf loadObjects];
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidTapChallengeButtonNotification object:[NSNumber numberWithInteger:weakSelf.challenge.id]];
//                });
//            }
//            else {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
//                });
//                
//                NSLog(@"error - %@", error);
//                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
//            }
//            
//            button.enabled = YES;
//        }];
//    } afterDelay:0.35f];
}

- (IBAction)verifiedTapped:(id)sender
{
    __block MTPostsTableViewCell *postCell = (MTPostsTableViewCell *)[sender findSuperViewWithClass:[MTPostsTableViewCell class]];
    __block MTChallengePost *post = postCell.post;
    __block MTUser *currentUser = [MTUser currentUser];

//    NSString *postID = [post objectId];
//    NSString *verifiedBy = [currentUser objectId];
//
//    BOOL isChecked = (post[@"verified_by"] != nil);
//    
//    if (isChecked) {
//        verifiedBy = @"";
//    }
//    
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
//    if (isChecked) {
//        hud.labelText = @"Removing Verification...";
//    }
//    else {
//        hud.labelText = @"Verifying...";
//    }
//    hud.dimBackground = YES;
//    
//    postCell.verfiedLabel.text = @"Updating...";
//    
//    MTMakeWeakSelf();
//    [self bk_performBlock:^(id obj) {
//        [PFCloud callFunctionInBackground:@"updatePostVerification" withParameters:@{@"verified_by" : verifiedBy, @"post_id" : postID} block:^(id object, NSError *error) {
//            
//            if (error) {
//                NSLog(@"error - %@", error);
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
//                });
//                
//                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
//                [weakSelf.tableView reloadData];
//                
//            } else {
//                [currentUser fetchInBackground];
////                [weakSelf.challenge fetchInBackground];
//                
//                [post fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
//                        [weakSelf.tableView reloadData];
//                    });
//                }];
//            }
//        }];
//        
//    } afterDelay:0.35f];
}

- (void)secondaryButton1Tapped:(id)sender
{
    ((UIButton *)sender).enabled = NO;
    self.secondaryButton1 = (UIButton *)sender;
    [self showFirstTimeToastNotification];
}

- (void)secondaryButton1AfterToastAction
{
    if (IsEmpty([self.secondaryButton1 titleForState:UIControlStateNormal])) {
        [self secondaryButton1ActionWithIncrement:YES];
        return;
    }
    
    NSString *title = @"How do you want to change this?";
    
    MTMakeWeakSelf();
    if ([UIAlertController class]) {
        UIAlertController *changeSheet = [UIAlertController
                                          alertControllerWithTitle:title
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction *action) {
                                     weakSelf.secondaryButton1.enabled = YES;
                                 }];
        
        UIAlertAction *minus = [UIAlertAction
                                actionWithTitle:@"-1"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [weakSelf secondaryButton1ActionWithIncrement:NO];
                                    });
                                }];
        
        UIAlertAction *plus = [UIAlertAction
                               actionWithTitle:@"+1"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction *action) {
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       [weakSelf secondaryButton1ActionWithIncrement:YES];
                                   });
                               }];
        
        [changeSheet addAction:cancel];
        [changeSheet addAction:minus];
        [changeSheet addAction:plus];
        
        [weakSelf presentViewController:changeSheet animated:YES completion:nil];
    } else {
        
        MTMakeWeakSelf();
        UIActionSheet *changeSheet = [UIActionSheet bk_actionSheetWithTitle:title];
        [changeSheet bk_addButtonWithTitle:@"-1" handler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf secondaryButton1ActionWithIncrement:NO];
            });
        }];
        [changeSheet bk_addButtonWithTitle:@"+1" handler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf secondaryButton1ActionWithIncrement:YES];
            });
        }];
        [changeSheet bk_setCancelButtonWithTitle:@"Cancel" handler:^{
            weakSelf.secondaryButton1.enabled = YES;
        }];
        [changeSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
}

- (void)secondaryButton1ActionWithIncrement:(BOOL)increment
{
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[self.secondaryButton1 findSuperViewWithClass:[MTPostsTableViewCell class]];
    MTChallengePost *post = cell.post;
    
    MTUser *user = [MTUser currentUser];
    
//    NSString *userID = [user objectId];
//    NSString *postID = [post objectId];
//    NSNumber *increaseNumber = [NSNumber numberWithBool:(increment ? YES : NO)];
//    
//    NSDictionary *buttonTappedDict = @{@"user_id": userID, @"post_id": postID, @"button": [NSNumber numberWithInt:0], @"increase": increaseNumber};
//
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
//    hud.labelText = @"Processing Points...";
//    hud.dimBackground = YES;
//    
//    MTMakeWeakSelf();
//    [self bk_performBlock:^(id obj) {
//        [PFCloud callFunctionInBackground:@"challengePostSecondaryButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
//            if (!error) {
//                [[PFUser currentUser] fetchInBackground];
//                [weakSelf updateSecondaryButtonsTapped];
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidTapChallengeButtonNotification object:[NSNumber numberWithInteger:weakSelf.challenge.id]];
//                });
//            }
//            else {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
//                    weakSelf.secondaryButton1.enabled = YES;
//                });
//                
//                NSLog(@"error - %@", error);
//                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
//            }
//        }];
//    } afterDelay:0.35f];
}

- (void)secondaryButton2Tapped:(id)sender
{
    ((UIButton *)sender).enabled = NO;
    self.secondaryButton2 = (UIButton *)sender;
    
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[self.secondaryButton2 findSuperViewWithClass:[MTPostsTableViewCell class]];
    MTChallengePost *post = cell.post;
    
//    NSDictionary *buttonDict = [self.secondaryButtonsTapped objectForKey:post.objectId];
//    
//    NSInteger button2Count = [[buttonDict objectForKey:@1] integerValue];
//    BOOL markComplete = (button2Count > 0) ? NO : YES;
//    NSString *title = @"Mark this as complete?";
//
//    if (button2Count > 0) {
//        // Now complete, marking incomplete
//        title = @"Mark this as incomplete?";
//    }
//    
//    MTMakeWeakSelf();
//    if ([UIAlertController class]) {
//        UIAlertController *changeSheet = [UIAlertController
//                                          alertControllerWithTitle:title
//                                          message:nil
//                                          preferredStyle:UIAlertControllerStyleActionSheet];
//        
//        UIAlertAction *cancel = [UIAlertAction
//                                 actionWithTitle:@"No"
//                                 style:UIAlertActionStyleCancel
//                                 handler:^(UIAlertAction *action) {
//                                     weakSelf.secondaryButton2.enabled = YES;
//                                 }];
//        
//        UIAlertAction *complete = [UIAlertAction
//                                actionWithTitle:@"Yes"
//                                style:UIAlertActionStyleDestructive
//                                handler:^(UIAlertAction *action) {
//                                    dispatch_async(dispatch_get_main_queue(), ^{
//                                        [weakSelf secondaryButton2ActionWithMarkComplete:markComplete];
//                                    });
//                                }];
//        
//        [changeSheet addAction:cancel];
//        [changeSheet addAction:complete];
//        
//        [weakSelf presentViewController:changeSheet animated:YES completion:nil];
//    } else {
//        
//        UIActionSheet *changeSheet = [UIActionSheet bk_actionSheetWithTitle:title];
//        [changeSheet bk_setDestructiveButtonWithTitle:@"Yes" handler:^{
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [weakSelf secondaryButton2ActionWithMarkComplete:markComplete];
//            });
//        }];
//        [changeSheet bk_setCancelButtonWithTitle:@"No" handler:^{
//            weakSelf.secondaryButton2.enabled = YES;
//        }];
//        [changeSheet showInView:[UIApplication sharedApplication].keyWindow];
//    }
}

- (void)secondaryButton2ActionWithMarkComplete:(BOOL)markComplete
{
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[self.secondaryButton2 findSuperViewWithClass:[MTPostsTableViewCell class]];
    MTChallengePost *post = cell.post;
    
//    MTUser *user = [MTUser currentUser];
//    
//    NSString *userID = [user objectId];
//    NSString *postID = [post objectId];
//    NSNumber *completeNumber = [NSNumber numberWithBool:(markComplete ? YES : NO)];
//    
//    NSDictionary *buttonTappedDict = @{@"user_id": userID, @"post_id": postID, @"button": @1, @"increase": completeNumber};
//    
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
//    hud.labelText = markComplete ? @"Marking Complete..." : @"Marking Incomplete...";
//    hud.dimBackground = YES;
//    
//    MTMakeWeakSelf();
//    [self bk_performBlock:^(id obj) {
//        [PFCloud callFunctionInBackground:@"challengePostSecondaryButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
//            if (!error) {
//                [[PFUser currentUser] fetchInBackground];
//                [weakSelf updateSecondaryButtonsTapped];
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidTapChallengeButtonNotification object:[NSNumber numberWithInteger:weakSelf.challenge.id]];
//                });
//            }
//            else {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
//                });
//                
//                NSLog(@"error - %@", error);
//                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
//            }
//            
//            weakSelf.secondaryButton2.enabled = YES;
//        }];
//    } afterDelay:0.35f];
}

- (void)emojiLikedForPost:(MTChallengePost *)likedPost withEmoji:(MTEmoji *)emoji
{
    NSUInteger row = [self.challengePosts indexOfObject:likedPost];
    if (row == NSNotFound) {
        return;
    }
    
    NSString *emojiCode = emoji.code;
    
    __block MTChallengePost *post = likedPost;
    
    MTUser *user = [MTUser currentUser];
    RLMResults *likesForPost = [MTChallengePostLike objectsWhere:@"challengePost.id = %lu AND isDeleted = NO AND user.id = %lu", post.id, user.id];
    BOOL iLike = !IsEmpty(likesForPost);
    
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    if (iLike) {
        hud.detailsLabelText = @"Updating Emoji...";
    }
    else {
        hud.detailsLabelText = @"Sending Emoji...";
    }
    hud.dimBackground = YES;
    hud.color = [UIColor colorWithWhite:1.0f alpha:1.0f];
    hud.detailsLabelColor = [UIColor blackColor];
    hud.detailsLabelFont = [UIFont mtFontOfSize:13.0f];

    hud.mode = MBProgressHUDModeCustomView;
    
    UIImageView *emojiImageView = [[UIImageView alloc] initWithImage:[UIImage imageWithData:emoji.emojiImage.imageData]];
    emojiImageView.frame = ({
        CGRect newFrame = emojiImageView.frame;
        newFrame.size = CGSizeMake(120.0f, 120.0f);
        newFrame;
    });
    hud.customView = emojiImageView;

    MTMakeWeakSelf();
    if (iLike) {
        NSInteger likeId = ((MTChallengePostLike *)[likesForPost firstObject]).id;
        [[MTNetworkManager sharedMTNetworkManager] updateLikeId:likeId emojiCode:emojiCode success:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                [weakSelf.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            });
        }];
    }
    else {
        [[MTNetworkManager sharedMTNetworkManager] addLikeForPostId:post.id emojiCode:emojiCode success:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                [weakSelf.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            });
        }];
    }
}


#pragma mark - MTEmojiPickerCollectionViewDelegate Methods -
- (void)didSelectEmoji:(MTEmoji *)emoji withPost:(MTChallengePost *)post;
{
    __block MTEmoji *weakEmoji = emoji;
    __block MTChallengePost *weakPost = post;
    
    MTMakeWeakSelf();
    if (self.postViewController) {
        [self dismissEmojiPromptWithCompletion:^(BOOL finished) {
            [weakSelf.postViewController emojiLiked:weakEmoji];
        }];
    }
    else {
        [self dismissEmojiPromptWithCompletion:^(BOOL finished) {
            [weakSelf emojiLikedForPost:weakPost withEmoji:weakEmoji];
        }];

    }
}


#pragma mark - DZNEmptyDataSetDelegate/Datasource Methods -
- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"No Posts";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Be the first to post to this Challenge!";
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    if (IsEmpty(self.challengePosts)) {
        return YES;
    }
    else {
        return NO;
    }
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor whiteColor];
}

- (CGPoint)offsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return CGPointMake(0, -56.0f);
}


@end
