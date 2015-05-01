//
//  MTPostViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTPostViewController.h"
#import "MTMentorStudentProfileViewController.h"
#import "MTPostUserInfoTableViewCell.h"
#import "MTPostImageTableViewCell.h"
#import "MTPostCommentTableViewCell.h"
#import "MTPostLikeCommentTableViewCell.h"
#import "MTPostCommentItemsTableViewCell.h"
#import "MTPostLikeUserTableViewCell.h"

typedef enum {
    MTPostTableCellTypeUserInfo = 0,
    MTPostTableCellTypeImage,
    MTPostTableCellTypeCommentText,
    MTPostTableCellTypeButtons,
    MTPostTableCellTypeLikeComment,
    MTPostTableCellTypePostComments,
    MTPostTableCellTypeLikeUsers
} MTPostTableCellType;

@interface MTPostViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) PFUser *currentUser;
@property (nonatomic, strong) PFUser *postUser;
@property (assign, nonatomic) NSInteger postLikesCount;
@property (assign, nonatomic) BOOL iLike;
@property (assign, nonatomic) BOOL isMyClass;
@property (nonatomic, strong) NSArray *comments;
@property (nonatomic, strong) NSArray *challengePostsLikedUsers;
@property (nonatomic) NSInteger likeActionCount;
@property (nonatomic, strong) UIImage *userAvatarImage;
@property (nonatomic, strong) UIImage *postImage;
@property (nonatomic, strong) NSMutableAttributedString *postText;
@property (nonatomic) CGFloat postTextHeight;
@property (nonatomic) BOOL isMentor;
@property (nonatomic) BOOL autoVerify;
@property (nonatomic) BOOL hideVerifySwitch;
@property (nonatomic, strong) UIButton *secondaryButton1;
@property (nonatomic, strong) UIButton *secondaryButton2;

@end

@implementation MTPostViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *postID = [self.challengePost objectId];
    self.iLike = [self.postsLiked containsObject:postID];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = self.challenge[@"title"];
    self.postUser = self.challengePost[@"user"];
    self.currentUser = [PFUser currentUser];
    self.postLikesCount = 0;
    if (self.challengePost[@"likes"]) {
        self.postLikesCount = [self.challengePost[@"likes"] intValue];
    }
    
    NSPredicate *posterWithID = [NSPredicate predicateWithFormat:@"objectId = %@", [self.postUser objectId]];
    PFQuery *findPoster = [PFQuery queryWithClassName:[PFUser parseClassName] predicate:posterWithID];
    
    findPoster.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    MTMakeWeakSelf();
    [findPoster findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            weakSelf.postUser = [objects firstObject];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }
    }];
    
    if (self.hasButtons && IsEmpty(self.buttonsTapped)) {
        [self updateButtonsTapped];
    }
    if (self.hasSecondaryButtons && IsEmpty(self.secondaryButtonsTapped)) {
        [self updateSecondaryButtonsTapped];
    }
    
    [self loadComments];
    [self loadPostText];
    [self loadLikesWithCache:YES];
    [self loadChallengePost];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Private Methods -
- (void)loadComments
{
    MTMakeWeakSelf();
    PFQuery *queryPostComments = [PFQuery queryWithClassName:[PFChallengePostComment parseClassName]];
    [queryPostComments whereKey:@"challenge_post" equalTo:self.challengePost];
    [queryPostComments includeKey:@"user"];
    
    queryPostComments.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    [queryPostComments findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            weakSelf.comments = objects;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (void)loadLikesWithCache:(BOOL)withCache
{
    MTMakeWeakSelf();
    PFQuery *queryPostLikes = [PFQuery queryWithClassName:[PFChallengePostsLiked parseClassName]];
    [queryPostLikes whereKey:@"post" equalTo:self.challengePost];
    [queryPostLikes includeKey:@"user"];
    
    if (withCache) {
        queryPostLikes.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    else {
        queryPostLikes.cachePolicy = kPFCachePolicyNetworkOnly;
    }
    
    [queryPostLikes findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableArray *users = [NSMutableArray array];
            for (PFChallengePostsLiked *thisLike in objects) {
                PFUser *thisUser = thisLike[@"user"];
                [users addObject:thisUser];
            }
            weakSelf.challengePostsLikedUsers = [NSArray arrayWithArray:users];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (void)loadPostText
{
    NSString *textString = self.challengePost[@"post_text"];
    self.postText = [[NSMutableAttributedString alloc] initWithString:textString];
    
    NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange rangeAll = NSMakeRange(0, textString.length);
    
    [hashtags enumerateMatchesInString:textString options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        
        NSMutableAttributedString *hashtag = [[NSMutableAttributedString alloc] initWithString:textString];
        [hashtag addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
        
        self.postText = hashtag;
    }];
}

- (void)updateButtonsTapped
{
    PFQuery *buttonsTapped = [PFQuery queryWithClassName:[PFChallengePostButtonsClicked parseClassName]];
    [buttonsTapped whereKey:@"user" equalTo:[PFUser currentUser]];
    
    MTMakeWeakSelf();
    [buttonsTapped findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        });

        if (!error) {
            NSMutableDictionary *tappedButtonObjects = [NSMutableDictionary dictionary];
            for (PFChallengePostButtonsClicked *clicks in objects) {
                id button = clicks[@"button_clicked"];
                id post = [(PFChallengePost *)clicks[@"post"] objectId];
                [tappedButtonObjects setValue:button forKey:post];
            }
            weakSelf.buttonsTapped = tappedButtonObjects;
            [weakSelf.tableView reloadData];
        }
        else {
            NSLog(@"Error - %@", error);
            [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
        }
    }];
}

- (void)updateSecondaryButtonsTapped
{
    PFQuery *buttonsTapped = [PFQuery queryWithClassName:[PFChallengePostSecondaryButtonsClicked parseClassName]];
    [buttonsTapped whereKey:@"user" equalTo:[PFUser currentUser]];
    [buttonsTapped includeKey:@"post"];
    
    MTMakeWeakSelf();
    [buttonsTapped findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        });
        
        if (!error) {
            NSMutableDictionary *tappedButtonObjects = [NSMutableDictionary dictionary];
            for (PFChallengePostSecondaryButtonsClicked *clicks in objects) {
                PFChallengePost *post = (PFChallengePost *)clicks[@"post"];
                PFChallenges *challenge = post[@"challenge"];
                NSString *challengeObjectId = challenge.objectId;
                
                id postObjectId = [(PFChallengePost *)clicks[@"post"] objectId];
                
                if ([challengeObjectId isEqualToString:weakSelf.challenge.objectId]) {
                    id button = clicks[@"button"];
                    id count = clicks[@"count"];
                    
                    NSDictionary *buttonsDict;
                    if ([tappedButtonObjects objectForKey:postObjectId]) {
                        buttonsDict = [tappedButtonObjects objectForKey:postObjectId];
                        NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:buttonsDict];
                        [mutableDict setValue:count forKey:button];
                        buttonsDict = [NSDictionary dictionaryWithDictionary:mutableDict];
                    }
                    else {
                        buttonsDict = [NSDictionary dictionaryWithObjectsAndKeys:count, button, nil];
                    }
                    
                    [tappedButtonObjects setValue:buttonsDict forKey:postObjectId];
                }

            }
            weakSelf.secondaryButtonsTapped = tappedButtonObjects;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
            
        } else {
            NSLog(@"Error - %@", error);
        }
    }];
}

- (void)loadChallengePost
{
    self.isMentor = [self.currentUser[@"type"] isEqualToString:@"mentor"];
    self.autoVerify = [self.challenge[@"auto_verify"] boolValue];
    self.hideVerifySwitch = !self.isMentor || self.autoVerify;
}

- (void)setupButtonsForCell:(UITableViewCell *)cell
{
    UIButton *button1 = (UIButton *)[cell.contentView viewWithTag:1];
    UIButton *button2 = (UIButton *)[cell.contentView viewWithTag:2];
    
    id buttonID = [self.buttonsTapped valueForKey:[self.challengePost objectId]];
    NSInteger button = 0;
    if (buttonID) {
        button = [buttonID intValue];
    }
    
    [button1 layer].masksToBounds = YES;
    [button2 layer].masksToBounds = YES;

    if ((button == 0) && buttonID) {
        [button1 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:button1.frame.size] forState:UIControlStateNormal];
        [button1 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:button1.frame.size] forState:UIControlStateHighlighted];

        [button1 setTintColor:[UIColor white]];
        [button1 setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [button1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];

        [[button2 layer] setBorderWidth:2.0f];
        [[button2 layer] setBorderColor:[UIColor redOrange].CGColor];
        [button2 setTintColor:[UIColor redOrange]];
        [button2 setTitleColor:[UIColor redOrange] forState:UIControlStateNormal];
        [button2 setTitleColor:[UIColor lightRedOrange] forState:UIControlStateHighlighted];

        [button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:button2.frame.size] forState:UIControlStateNormal];
        [button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:button2.frame.size] forState:UIControlStateHighlighted];
    }
    else if (button == 1) {
        [[button1 layer] setBorderWidth:2.0f];
        [[button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
        [button1 setTintColor:[UIColor primaryGreen]];
        [button1 setTitleColor:[UIColor primaryGreen] forState:UIControlStateNormal];
        [button1 setTitleColor:[UIColor lightGreen] forState:UIControlStateHighlighted];

        [button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:button1.frame.size] forState:UIControlStateNormal];
        [button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:button1.frame.size] forState:UIControlStateHighlighted];
        
        [button2 setBackgroundImage:[UIImage imageWithColor:[UIColor redOrange] size:button2.frame.size] forState:UIControlStateNormal];
        [button2 setBackgroundImage:[UIImage imageWithColor:[UIColor redOrange] size:button2.frame.size] forState:UIControlStateHighlighted];

        [button2 setTintColor:[UIColor white]];
        [button2 setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [button2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    }
    else {
        [[button1 layer] setBorderWidth:2.0f];
        [[button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
        [button1 setTintColor:[UIColor primaryGreen]];
        [button1 setTitleColor:[UIColor primaryGreen] forState:UIControlStateNormal];
        [button1 setTitleColor:[UIColor lightGreen] forState:UIControlStateHighlighted];

        [button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:button1.frame.size] forState:UIControlStateNormal];
        [button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:button1.frame.size] forState:UIControlStateHighlighted];

        [[button2 layer] setBorderWidth:2.0f];
        [[button2 layer] setBorderColor:[UIColor redOrange].CGColor];
        [button2 setTintColor:[UIColor redOrange]];
        [button2 setTitleColor:[UIColor redOrange] forState:UIControlStateNormal];
        [button2 setTitleColor:[UIColor lightRedOrange] forState:UIControlStateHighlighted];

        [button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:button2.frame.size] forState:UIControlStateNormal];
        [button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:button2.frame.size] forState:UIControlStateHighlighted];
    }

    [[button1 layer] setCornerRadius:5.0f];
    [[button2 layer] setCornerRadius:5.0f];

    NSArray *buttonTitles = self.challenge[@"buttons"];
    NSArray *buttonsClicked = self.challengePost [@"buttons_clicked"];

    if (buttonTitles.count > 0) {
        NSString *button1Title;
        NSString *button2Title;

        if (buttonsClicked.count > 0) {
            button1Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[0], buttonsClicked[0]];
        } else {
            button1Title = [NSString stringWithFormat:@"%@ (0)", buttonTitles[0]];
        }

        if (buttonsClicked.count > 1) {
            button2Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[1], buttonsClicked[1]];
        } else {
            button2Title = [NSString stringWithFormat:@"%@ (0)", buttonTitles[1]];
        }
        
        [button1 setTitle:button1Title forState:UIControlStateNormal];
        [button2 setTitle:button2Title forState:UIControlStateNormal];
    }
}

- (void)setupSecondaryButtonsForCell:(UITableViewCell *)cell
{
    NSDictionary *buttonDict = [self.secondaryButtonsTapped objectForKey:self.challengePost.objectId];
    
    NSInteger button1Count = [[buttonDict objectForKey:@0] integerValue];
    NSInteger button2Count = [[buttonDict objectForKey:@1] integerValue];
    
    UIButton *button1 = (UIButton *)[cell.contentView viewWithTag:1];
    UIButton *button2 = (UIButton *)[cell.contentView viewWithTag:2];
    
    // Configure Button 1
    [[button1 layer] setBackgroundColor:[UIColor whiteColor].CGColor];
    [[button1 layer] setBorderWidth:1.0f];
    [button1 setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor] size:button1.frame.size] forState:UIControlStateNormal];
    [button1 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:button1.frame.size] forState:UIControlStateHighlighted];
    [[button1 layer] setCornerRadius:5.0f];
    [button1 setImage:[UIImage imageNamed:@"icon_button_dollar_normal"] forState:UIControlStateNormal];
    [button1 setImage:[UIImage imageNamed:@"icon_button_dollar_pressed"] forState:UIControlStateHighlighted];
    [button1 setTitleColor:[UIColor white] forState:UIControlStateHighlighted];
    
    button1.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 0.0f);
    [button1 layer].masksToBounds = YES;
    
    if (button1Count > 0) {
        [button1 setTitle:[NSString stringWithFormat:@"%ld", (long)button1Count] forState:UIControlStateNormal];
    }
    else {
        [button1 setTitle:@"" forState:UIControlStateNormal];
    }
    
    [button1 removeTarget:self action:@selector(secondaryButton1Tapped:) forControlEvents:UIControlEventTouchUpInside];
    [button1 addTarget:self action:@selector(secondaryButton1Tapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // Configure Button 2
    [[button2 layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    [[button2 layer] setBackgroundColor:[UIColor whiteColor].CGColor];
    [[button2 layer] setBorderWidth:1.0f];
    [[button2 layer] setCornerRadius:5.0f];
    [button2 setTitle:@"" forState:UIControlStateNormal];
    [button2 layer].masksToBounds = YES;
    
    if (button2Count > 0) {
        button1.enabled = NO;
        [[button1 layer] setBorderColor:[UIColor lightGrayColor].CGColor];
        [button1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        
        [button2 setImage:[UIImage imageNamed:@"icon_button_check_pressed"] forState:UIControlStateNormal];
        [button2 setImage:[UIImage imageNamed:@"icon_button_check_normal"] forState:UIControlStateHighlighted];
        
        [button2 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:button2.frame.size] forState:UIControlStateNormal];
        [button2 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreenDark] size:button2.frame.size] forState:UIControlStateHighlighted];
    }
    else {
        button1.enabled = YES;
        [[button1 layer] setBorderColor:[UIColor darkGrayColor].CGColor];
        [button1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

        [button2 setImage:[UIImage imageNamed:@"icon_button_check_normal"] forState:UIControlStateNormal];
        [button2 setImage:[UIImage imageNamed:@"icon_button_check_pressed"] forState:UIControlStateHighlighted];
        
        [button2 setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor] size:button2.frame.size] forState:UIControlStateNormal];
        [button2 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:button2.frame.size] forState:UIControlStateHighlighted];
    }
    
    [button2 removeTarget:self action:@selector(secondaryButton2Tapped:) forControlEvents:UIControlEventTouchUpInside];
    [button2 addTarget:self action:@selector(secondaryButton2Tapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)showFirstTimeToastNotification
{
    NSString *key = @"ShownToastForChallenge";
    NSArray *shownArray = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (![shownArray containsObject:self.challenge.objectId]) {
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"";
        hud.detailsLabelText = @"Congratulations on taking a step towards your goal!";
        hud.dimBackground = NO;
        hud.mode = MBProgressHUDModeText;
        hud.delegate = self;
        [hud hide:YES afterDelay:1.0f];
        
        NSMutableArray *mutant = [NSMutableArray arrayWithArray:shownArray];
        [mutant addObject:self.challenge.objectId];
        [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:mutant] forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    else {
        [self secondaryButton1AfterToastAction];
    }
}


#pragma mark - Variable Cell Height calculations -
- (CGFloat)heightForPostTextCellAtIndexPath:(NSIndexPath *)indexPath {
    static MTPostCommentTableViewCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommentTextCell"];
    });
    
    [self configurePostTextCell:sizingCell atIndexPath:indexPath];
    return [self calculateHeightForConfiguredSizingCell:sizingCell];
}

- (CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell {
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
}

- (void)configurePostTextCell:(MTPostCommentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    cell.postText.attributedText = self.postText;
}

- (CGFloat)heightForPostCommentsCellAtIndexPath:(NSIndexPath *)indexPath {
    static MTPostCommentItemsTableViewCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:@"PostCommentItemsCell"];
    });
    
    [self configurePostCommentsCell:sizingCell atIndexPath:indexPath];
    return [self calculateHeightForCommentsConfiguredSizingCell:sizingCell];
}

- (CGFloat)calculateHeightForCommentsConfiguredSizingCell:(UITableViewCell *)sizingCell {
    sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.bounds), 0.0f);

    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
}

- (void)configurePostCommentsCell:(MTPostCommentItemsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    PFChallengePostComment *comment = self.comments[indexPath.row];
    cell.commentLabel.text = comment[@"comment_text"];
    [cell.commentLabel setFont:[UIFont mtLightFontOfSize:13.0f]];
    
    PFUser *commentPoster = comment[@"user"];
    NSString *detailString = [NSString stringWithFormat:@"%@ %@", commentPoster[@"first_name"], commentPoster[@"last_name"]];
    cell.userLabel.text = detailString;
    [cell.userLabel setFont:[UIFont mtLightFontOfSize:11.0f]];
}


#pragma mark - Actions -
- (IBAction)likeButtonTapped:(id)sender
{
    __block MTPostLikeCommentTableViewCell *likeCommentCell = (MTPostLikeCommentTableViewCell *)[sender findSuperViewWithClass:[MTPostLikeCommentTableViewCell class]];
    
    self.likeActionCount++;
    
    __block NSString *postID = [self.challengePost objectId];
    NSString *userID = [self.currentUser objectId];
    
    self.iLike = !self.iLike;
    
    NSInteger oldPostLikesCount = self.postLikesCount;
    NSMutableArray *oldLikePosts = [NSMutableArray arrayWithArray:self.postsLiked];
    NSMutableArray *likePosts = [NSMutableArray arrayWithArray:self.postsLiked];
    
    if (self.iLike) {
        [likePosts addObject:postID];
        
        [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
        [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateDisabled];
        self.postLikesCount += 1;
        
        // Animations are borked on < iOS 8.0 because of autolayout?
        // http://stackoverflow.com/questions/25286022/animation-of-cgaffinetransform-in-ios8-looks-different-than-in-ios7?rq=1
        if(NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
            // no animation
        } else {
            [UIView animateWithDuration:0.2f animations:^{
                likeCommentCell.likePost.transform = CGAffineTransformMakeScale(1.5, 1.5);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2f animations:^{
                    likeCommentCell.likePost.transform = CGAffineTransformMakeScale(1, 1);
                } completion:NULL];
            }];
        }

    }
    else {
        [likePosts removeObject:postID];
        [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
        [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateDisabled];
        if (self.postLikesCount > 0) {
            self.postLikesCount -= 1;
        }
    }
    
    self.postsLiked = likePosts;
    self.challengePost[@"likes"] = [NSNumber numberWithInteger:self.postLikesCount];
    likeCommentCell.postLikes.text = [NSString stringWithFormat:@"%ld", (long)self.postLikesCount];
    
    NSString *likeString = [NSString stringWithFormat:@"%d", self.iLike];
    
    // Optimistically, add/remove myself from like users
    NSMutableArray *newMutableArray = [NSMutableArray arrayWithArray:self.challengePostsLikedUsers];
    if (self.iLike) {
        if (IsEmpty(newMutableArray)) {
            [newMutableArray addObject:self.currentUser];
        }
        else {
            BOOL hasUser = NO;
            for (PFUser *thisUser in self.challengePostsLikedUsers) {
                if ([thisUser.objectId isEqualToString:self.currentUser.objectId]) {
                    hasUser = YES;
                    break;
                }
                if (!hasUser) {
                    [newMutableArray addObject:self.currentUser];
                }
            }
        }
    }
    else {
        for (PFUser *thisUser in self.challengePostsLikedUsers) {
            if ([thisUser.objectId isEqualToString:self.currentUser.objectId]) {
                [newMutableArray removeObject:thisUser];
                break;
            }
        }
    }
    self.challengePostsLikedUsers = [NSArray arrayWithArray:newMutableArray];
    [self.tableView reloadData];
    
    MTMakeWeakSelf();
    [PFCloud callFunctionInBackground:@"toggleLikePost" withParameters:@{@"user_id": userID, @"post_id" : postID, @"like" : likeString} block:^(id object, NSError *error) {
        
        weakSelf.likeActionCount--;
        if (weakSelf.likeActionCount > 0) {
            return;
        }

        if (!error) {
            [weakSelf.challengePost fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.tableView reloadData];
                });
            }];
            
            if ([weakSelf.delegate respondsToSelector:@selector(didUpdatePostsLiked:)]) {
                [weakSelf.delegate didUpdatePostsLiked:weakSelf.postsLiked];
            }
            
            [weakSelf loadLikesWithCache:NO];

        } else {
            NSLog(@"Error updating: %@", [error localizedDescription]);
            
            // Rollback
            weakSelf.iLike = !weakSelf.iLike;
            weakSelf.postsLiked = oldLikePosts;
            weakSelf.postLikesCount = oldPostLikesCount;
            weakSelf.challengePost[@"likes"] = [NSNumber numberWithInteger:oldPostLikesCount];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                likeCommentCell.postLikes.text = [NSString stringWithFormat:@"%ld", (long)oldPostLikesCount];
                [weakSelf.tableView reloadData];
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            });
            
            [weakSelf loadLikesWithCache:YES];
        }
        
    }];
}

- (IBAction)commentTapped:(id)sender
{
    [self performSegueWithIdentifier:@"commentOnPost" sender:sender];
}

- (void)dismissCommentView
{
    [self loadComments];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)deletePostTapped:(id)sender
{
    if ([UIAlertController class]) {
        UIAlertController *deletePostSheet = [UIAlertController
                                              alertControllerWithTitle:@"Delete this post?"
                                              message:nil
                                              preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction *action) {
                                 }];
        
        MTMakeWeakSelf();
        UIAlertAction *delete = [UIAlertAction
                                 actionWithTitle:@"Delete"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction *action) {
                                     [weakSelf performDeletePost];
                                 }];
        
        [deletePostSheet addAction:cancel];
        [deletePostSheet addAction:delete];
        
        [self presentViewController:deletePostSheet animated:YES completion:nil];
    } else {
        
        MTMakeWeakSelf();
        UIActionSheet *deleteAction = [UIActionSheet bk_actionSheetWithTitle:@"Delete this post?"];
        [deleteAction bk_setDestructiveButtonWithTitle:@"Delete" handler:^{
            [weakSelf performDeletePost];
        }];
        [deleteAction bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
        [deleteAction showInView:[UIApplication sharedApplication].keyWindow];
    }
}

- (void)performDeletePost
{
    if ([self.delegate respondsToSelector:@selector(didDeletePost:)]) {
        [self.delegate didDeletePost:self.challengePost];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        NSString *userID = [self.postUser objectId];
        NSString *postID = [self.challengePost objectId];
        
        MTMakeWeakSelf();
        [PFCloud callFunctionInBackground:@"deletePost" withParameters:@{@"user_id": userID, @"post_id": postID} block:^(id object, NSError *error) {
            if (!error) {
                [weakSelf.currentUser fetchInBackground];
                [self.navigationController popViewControllerAnimated:NO];
            } else {
                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Delete" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
        }];
    }
}

- (IBAction)verifiedTapped:(id)sender
{
    __block MTPostLikeCommentTableViewCell *likeCommentCell = (MTPostLikeCommentTableViewCell *)[sender findSuperViewWithClass:[MTPostLikeCommentTableViewCell class]];

    NSString *postID = [self.challengePost objectId];
    NSString *verifiedBy = [self.currentUser objectId];
    
    BOOL isChecked = (self.challengePost[@"verified_by"] != nil);

    if (isChecked) {
        verifiedBy = @"";
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    if (isChecked) {
        hud.labelText = @"Removing Verification...";
    }
    else {
        hud.labelText = @"Verifying...";
    }
    hud.dimBackground = YES;
    
    likeCommentCell.verfiedLabel.text = @"Updating...";
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [PFCloud callFunctionInBackground:@"updatePostVerification" withParameters:@{@"verified_by" : verifiedBy, @"post_id" : postID} block:^(id object, NSError *error) {
            
            if (error) {
                NSLog(@"error - %@", error);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });

                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                [weakSelf.tableView reloadData];

            } else {
                [weakSelf.currentUser fetchInBackground];
                [weakSelf.challenge fetchInBackground];
                
                [weakSelf.challengePost fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                        [weakSelf.tableView reloadData];
                    });
                }];
            }
        }];
        
    } afterDelay:0.35f];
}

- (IBAction)button1Tapped:(id)sender
{
    __block id weakSender = sender;
    ((UIButton *)sender).enabled = NO;
    
    PFChallengePost *post = self.challengePost;
    
    NSString *userID = [self.currentUser objectId];
    NSString *postID = [post objectId];
    
    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:0]};
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Submitting...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
            if (!error) {
                [weakSelf.currentUser fetch];
                [weakSelf.challenge fetch];
                [weakSelf.challengePost fetch];
                ((UIButton *)weakSender).enabled = YES;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf updateButtonsTapped];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
                
                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
        }];
    } afterDelay:0.35f];
    
}

- (IBAction)button2Tapped:(id)sender
{
    __block id weakSender = sender;
    ((UIButton *)sender).enabled = NO;

    PFChallengePost *post = self.challengePost;
    
    NSString *userID = [self.currentUser objectId];
    NSString *postID = [post objectId];
    
    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:1]};
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Submitting...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
            if (!error) {
                [weakSelf.currentUser fetchInBackground];
                [weakSelf.challenge fetchInBackground];
                [weakSelf.challengePost fetchInBackground];
                ((UIButton *)weakSender).enabled = YES;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf updateButtonsTapped];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });

                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
        }];
    } afterDelay:0.35f];
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
    PFUser *user = [PFUser currentUser];
    
    NSString *userID = [user objectId];
    NSString *postID = [self.challengePost objectId];
    NSNumber *increaseNumber = [NSNumber numberWithBool:(increment ? YES : NO)];
    
    NSDictionary *buttonTappedDict = @{@"user_id": userID, @"post_id": postID, @"button": [NSNumber numberWithInt:0], @"increase": increaseNumber};
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Processing Points...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [PFCloud callFunctionInBackground:@"challengePostSecondaryButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
            if (!error) {
                [[PFUser currentUser] fetchInBackground];
                [weakSelf updateSecondaryButtonsTapped];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
                
                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
            
            weakSelf.secondaryButton1.enabled = YES;
        }];
    } afterDelay:0.35f];
}

- (void)secondaryButton2Tapped:(id)sender
{
    ((UIButton *)sender).enabled = NO;
    self.secondaryButton2 = (UIButton *)sender;
    NSDictionary *buttonDict = [self.secondaryButtonsTapped objectForKey:self.challengePost.objectId];
    NSInteger button2Count = [[buttonDict objectForKey:@1] integerValue];

    BOOL markComplete = (button2Count > 0) ? NO : YES;
    NSString *title = @"Mark this as complete?";
    
    if (button2Count > 0) {
        // Now complete, marking incomplete
        title = @"Mark this as incomplete?";
    }
    
    MTMakeWeakSelf();
    if ([UIAlertController class]) {
        UIAlertController *changeSheet = [UIAlertController
                                          alertControllerWithTitle:title
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:@"No"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction *action) {
                                     weakSelf.secondaryButton2.enabled = YES;
                                 }];
        
        UIAlertAction *complete = [UIAlertAction
                                   actionWithTitle:@"Yes"
                                   style:UIAlertActionStyleDestructive
                                   handler:^(UIAlertAction *action) {
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [weakSelf secondaryButton2ActionWithMarkComplete:markComplete];
                                       });
                                   }];
        
        [changeSheet addAction:cancel];
        [changeSheet addAction:complete];
        
        [weakSelf presentViewController:changeSheet animated:YES completion:nil];
    } else {
        
        UIActionSheet *changeSheet = [UIActionSheet bk_actionSheetWithTitle:title];
        [changeSheet bk_setDestructiveButtonWithTitle:@"Yes" handler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf secondaryButton2ActionWithMarkComplete:markComplete];
            });
        }];
        [changeSheet bk_setCancelButtonWithTitle:@"No" handler:^{
            weakSelf.secondaryButton2.enabled = YES;
        }];
        [changeSheet showInView:[UIApplication sharedApplication].keyWindow];
    }
}

- (void)secondaryButton2ActionWithMarkComplete:(BOOL)markComplete
{
    PFUser *user = [PFUser currentUser];
    
    NSString *userID = [user objectId];
    NSString *postID = [self.challengePost objectId];
    NSNumber *completeNumber = [NSNumber numberWithBool:(markComplete ? YES : NO)];
    
    NSDictionary *buttonTappedDict = @{@"user_id": userID, @"post_id": postID, @"button": @1, @"increase": completeNumber};
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = markComplete ? @"Marking Complete..." : @"Marking Incomplete...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [PFCloud callFunctionInBackground:@"challengePostSecondaryButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
            if (!error) {
                [[PFUser currentUser] fetchInBackground];
                [weakSelf updateSecondaryButtonsTapped];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
                
                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
            
            weakSelf.secondaryButton2.enabled = YES;
        }];
    } afterDelay:0.35f];
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


#pragma mark - Navigation -
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueIdentifier = [segue identifier];
    if ([segueIdentifier isEqualToString:@"commentOnPost"]) {
        MTCommentViewController *destinationViewController = (MTCommentViewController *)[segue destinationViewController];
        destinationViewController.post = self.challengePost;
        destinationViewController.challenge = self.challenge;
        [destinationViewController setDelegate:self];
    }
    else if ([segueIdentifier isEqualToString:@"pushStudentProfileFromPost"]) {
        MTMentorStudentProfileViewController *destinationVC = (MTMentorStudentProfileViewController *)[segue destinationViewController];
        destinationVC.student = self.challengePost[@"user"];
    }
    else if ([segueIdentifier isEqualToString:@"postDetailStudentProfileView"]) {
        MTMentorStudentProfileViewController *destinationVC = (MTMentorStudentProfileViewController *)[segue destinationViewController];
        PFUser *student = sender;
        destinationVC.student = student;
    }
}


#pragma mark - UITableViewDataSource & Delegate Methods -
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.0f;
    NSInteger section = indexPath.section;
    
    switch (self.postType) {
        case MTPostTypeWithButtonsWithImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    height = 57.0f;
                    break;
                case MTPostTableCellTypeImage:
                    height = 320.0f;
                    break;
                case MTPostTableCellTypeCommentText:
                    height = [self heightForPostTextCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeButtons:
                    height = 44.0f;
                    break;
                case MTPostTableCellTypeLikeComment:
                    height = 46.0f;
                    break;
                case MTPostTableCellTypePostComments:
                    height = [self heightForPostCommentsCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeLikeUsers:
                    height = 44.0f;
                    break;
                    
                default:
                    break;
            }
            break;
        }
            
        case MTPostTypeWithButtonsNoImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    height = 57.0f;
                    break;
                case MTPostTableCellTypeImage:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeCommentText:
                    height = [self heightForPostTextCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeButtons:
                    height = 44.0f;
                    break;
                case MTPostTableCellTypeLikeComment:
                    height = 46.0f;
                    break;
                case MTPostTableCellTypePostComments:
                    height = [self heightForPostCommentsCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeLikeUsers:
                    height = 44.0f;
                    break;
                    
                default:
                    break;
            }
            break;
        }
        case MTPostTypeNoButtonsWithImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    height = 57.0f;
                    break;
                case MTPostTableCellTypeImage:
                    height = 320.0f;
                    break;
                case MTPostTableCellTypeCommentText:
                    height = [self heightForPostTextCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeButtons:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeLikeComment:
                    height = 46.0f;
                    break;
                case MTPostTableCellTypePostComments:
                    height = [self heightForPostCommentsCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeLikeUsers:
                    height = 44.0f;
                    break;
                    
                default:
                    break;
            }
            break;
        }
        case MTPostTypeNoButtonsNoImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    height = 57.0f;
                    break;
                case MTPostTableCellTypeImage:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeCommentText:
                    height = [self heightForPostTextCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeButtons:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeLikeComment:
                    height = 46.0f;
                    break;
                case MTPostTableCellTypePostComments:
                    height = [self heightForPostCommentsCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeLikeUsers:
                    height = 44.0f;
                    break;
                    
                default:
                    break;
            }
            break;
        }
            
        default:
            break;
    }
    
    return height;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;    // fixed font style. use custom view (UILabel) if you want something different
{
    
    switch (section) {
        case MTPostTableCellTypeUserInfo:
            return @"";
            break;
        case MTPostTableCellTypeImage:
            return @"";
            break;
        case MTPostTableCellTypeCommentText:
            return @"";
            break;
        case MTPostTableCellTypeButtons:
            return @"";
            break;
        case MTPostTableCellTypeLikeComment:
            return @"";
            break;
        case MTPostTableCellTypePostComments:
            return [self.comments count] > 0 ? @"Comments" : @"";
            break;
        case MTPostTableCellTypeLikeUsers:
            return [self.challengePostsLikedUsers count] > 0 ? @"Likes" : @"";
            break;
            
        default:
            return @"";
            break;
    }

}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = 0.0f;
    
    switch (section) {
        case MTPostTableCellTypeUserInfo:
            break;
        case MTPostTableCellTypeImage:
            break;
        case MTPostTableCellTypeCommentText:
            break;
        case MTPostTableCellTypeButtons:
            break;
        case MTPostTableCellTypeLikeComment:
            break;
        case MTPostTableCellTypePostComments:
            height = [self.comments count] > 0 ? 30.0f : 0.0f;
            break;
        case MTPostTableCellTypeLikeUsers:
            height = [self.challengePostsLikedUsers count] > 0 ? 30.0f : 0.0f;
            break;
            
        default:
            break;
    }
    
    return height;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;

    switch (self.postType) {
        case MTPostTypeWithButtonsWithImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    rows = 1;
                    break;
                case MTPostTableCellTypeImage:
                    rows = 1;
                    break;
                case MTPostTableCellTypeCommentText:
                    rows = 1;
                    break;
                case MTPostTableCellTypeButtons:
                    rows = 1;
                    break;
                case MTPostTableCellTypeLikeComment:
                    rows = 1;
                    break;
                case MTPostTableCellTypePostComments:
                    rows = self.comments.count;
                    break;
                case MTPostTableCellTypeLikeUsers:
                    rows = self.challengePostsLikedUsers.count;
                    break;
   
                default:
                    break;
            }
            break;
        }
         
        case MTPostTypeWithButtonsNoImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    rows = 1;
                    break;
                case MTPostTableCellTypeImage:
                    rows = 0;
                    break;
                case MTPostTableCellTypeCommentText:
                    rows = 1;
                    break;
                case MTPostTableCellTypeButtons:
                    rows = 1;
                    break;
                case MTPostTableCellTypeLikeComment:
                    rows = 1;
                    break;
                case MTPostTableCellTypePostComments:
                    rows = self.comments.count;
                    break;
                case MTPostTableCellTypeLikeUsers:
                    rows = self.challengePostsLikedUsers.count;
                    break;
                    
                default:
                    break;
            }
            break;
        }
        case MTPostTypeNoButtonsWithImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    rows = 1;
                    break;
                case MTPostTableCellTypeImage:
                    rows = 1;
                    break;
                case MTPostTableCellTypeCommentText:
                    rows = 1;
                    break;
                case MTPostTableCellTypeButtons:
                    rows = 0;
                    break;
                case MTPostTableCellTypeLikeComment:
                    rows = 1;
                    break;
                case MTPostTableCellTypePostComments:
                    rows = self.comments.count;
                    break;
                case MTPostTableCellTypeLikeUsers:
                    rows = self.challengePostsLikedUsers.count;
                    break;
                    
                default:
                    break;
            }
            break;
        }
        case MTPostTypeNoButtonsNoImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    rows = 1;
                    break;
                case MTPostTableCellTypeImage:
                    rows = 0;
                    break;
                case MTPostTableCellTypeCommentText:
                    rows = 1;
                    break;
                case MTPostTableCellTypeButtons:
                    rows = 0;
                    break;
                case MTPostTableCellTypeLikeComment:
                    rows = 1;
                    break;
                case MTPostTableCellTypePostComments:
                    rows = self.comments.count;
                    break;
                case MTPostTableCellTypeLikeUsers:
                    rows = self.challengePostsLikedUsers.count;
                    break;
                    
                default:
                    break;
            }
            break;
        }

        default:
            break;
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id cell = nil;
    
    switch (indexPath.section) {
        case MTPostTableCellTypeUserInfo:
        {
            __block MTPostUserInfoTableViewCell *userInfoCell = [tableView dequeueReusableCellWithIdentifier:@"PostUserInfoCell" forIndexPath:indexPath];
            userInfoCell.selectionStyle = UITableViewCellSelectionStyleNone;

            NSString *firstName = self.postUser[@"first_name"];
            NSString *lastName = self.postUser[@"last_name"];
            userInfoCell.postUsername.text = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            
            userInfoCell.whenPosted.text = [[self.challengePost createdAt] niceRelativeTimeFromNow];
            userInfoCell.postUserImageView.contentMode = UIViewContentModeScaleAspectFill;

            if (self.userAvatarImage) {
                [userInfoCell.postUserImageView setImage:self.userAvatarImage];
            }
            else {
                userInfoCell.postImage.file = self.postUser[@"profile_picture"];
                
                MTMakeWeakSelf();
                [userInfoCell.postImage loadInBackground:^(UIImage *image, NSError *error) {
                    weakSelf.userAvatarImage = image;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (weakSelf.userAvatarImage) {
                            [userInfoCell.postUserImageView setImage:weakSelf.userAvatarImage];
                        }
                    });
                }];
            }
            
            if ([[self.postUser username] isEqualToString:[self.currentUser username]]) {
                userInfoCell.deletePost.hidden = NO;
                userInfoCell.deletePost.enabled = YES;
            }
            else {
                userInfoCell.deletePost.hidden = YES;
                userInfoCell.deletePost.enabled = NO;
            }
            
            cell = userInfoCell;
            
            break;
        }
        case MTPostTableCellTypeImage:
        {
            __block MTPostImageTableViewCell *imageCell = [tableView dequeueReusableCellWithIdentifier:@"PostImageCell" forIndexPath:indexPath];
            imageCell.selectionStyle = UITableViewCellSelectionStyleNone;
            imageCell.postImage.file = self.challengePost[@"picture"];
            
            MTMakeWeakSelf();
            [imageCell.postImage loadInBackground:^(UIImage *image, NSError *error) {
                if (!error) {
                    if (image) {
                        CGRect frame = imageCell.postImage.frame;
                        imageCell.postImage.image = [weakSelf imageByScalingAndCroppingForSize:frame.size withImage:image];
                    }
                    else {
                        imageCell.postImage.image = nil;
                    }
                }
                else {
                    NSLog(@"error - %@", error);
                }
            }];

            cell = imageCell;

            break;
        }
        case MTPostTableCellTypeCommentText:
        {
            MTPostCommentTableViewCell *commentTextCell = [tableView dequeueReusableCellWithIdentifier:@"CommentTextCell" forIndexPath:indexPath];
            commentTextCell.postText.attributedText = self.postText;
            commentTextCell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell = commentTextCell;
            
            break;
        }
        case MTPostTableCellTypeButtons:
        {
            UITableViewCell *buttonsCell = [tableView dequeueReusableCellWithIdentifier:@"ButtonsCell" forIndexPath:indexPath];
            buttonsCell.selectionStyle = UITableViewCellSelectionStyleNone;

            if (self.hasSecondaryButtons) {
                [self setupSecondaryButtonsForCell:buttonsCell];
            }
            else {
                [self setupButtonsForCell:buttonsCell];
            }
            cell = buttonsCell;

            break;
        }
        case MTPostTableCellTypeLikeComment:
        {
            MTPostLikeCommentTableViewCell *likeCommentCell = [tableView dequeueReusableCellWithIdentifier:@"LikeCommentCell" forIndexPath:indexPath];
            likeCommentCell.selectionStyle = UITableViewCellSelectionStyleNone;

            NSString *likesString;
        
            if (self.postLikesCount > 0) {
                likesString = [NSString stringWithFormat:@"%ld", (long)self.postLikesCount];
            }
            else {
                likesString = @"0";
            }
        
            likeCommentCell.postLikes.text = likesString;
        
            if (self.iLike) {
                [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
                [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateDisabled];
            }
            else {
                [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
                [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateDisabled];
            }
            
            if (self.comments) {
                likeCommentCell.commentCount.text = [NSString stringWithFormat:@"%ld", (unsigned long)[self.comments count]];
            }
            else {
                likeCommentCell.commentCount.text = @"0";
            }
            
            likeCommentCell.verifiedCheckBox.hidden = self.hideVerifySwitch;
            BOOL isChecked = (self.challengePost[@"verified_by"] != nil);
            [likeCommentCell.verifiedCheckBox setIsChecked:isChecked];
            
            likeCommentCell.verfiedLabel.hidden = self.hideVerifySwitch;
            if (isChecked) {
                likeCommentCell.verfiedLabel.text = @"Verified";
            }
            else {
                likeCommentCell.verfiedLabel.text = @"Verify";
            }

            [likeCommentCell.commentPost setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
            [likeCommentCell.commentPost setTitleColor:[UIColor primaryOrangeDark] forState:UIControlStateHighlighted];

            cell = likeCommentCell;
            
            break;
        }
        case MTPostTableCellTypePostComments:
        {
            MTPostCommentItemsTableViewCell *defaultCell = [tableView dequeueReusableCellWithIdentifier:@"PostCommentItemsCell" forIndexPath:indexPath];
            defaultCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            PFChallengePostComment *comment = self.comments[indexPath.row];
            defaultCell.commentLabel.text = comment[@"comment_text"];
            [defaultCell.commentLabel setFont:[UIFont mtLightFontOfSize:13.0f]];
            defaultCell.commentLabel.textColor = [UIColor darkGrey];
            
            PFUser *commentPoster = comment[@"user"];
            
            NSString *detailString = [NSString stringWithFormat:@"%@ %@", commentPoster[@"first_name"], commentPoster[@"last_name"]];
            defaultCell.userLabel.text = detailString;
            [defaultCell.userLabel setFont:[UIFont mtLightFontOfSize:11.0f]];
            defaultCell.userLabel.textColor = [UIColor darkGrey];
            
            [defaultCell setAccessoryType:UITableViewCellAccessoryNone];
            
            // If last row and has likes, don't show separator
            if ((indexPath.row == [self.comments count]-1) && !IsEmpty(self.challengePostsLikedUsers)) {
                defaultCell.separatorView.hidden = YES;
            }
            else {
                defaultCell.separatorView.hidden = NO;
            }
            
            cell = defaultCell;
            
            break;
        }
        case MTPostTableCellTypeLikeUsers:
        {
            __block MTPostLikeUserTableViewCell *likeUserCell = [tableView dequeueReusableCellWithIdentifier:@"LikeUserCell" forIndexPath:indexPath];
            likeUserCell.selectionStyle = UITableViewCellSelectionStyleGray;
            
            PFUser *likeUser = self.challengePostsLikedUsers[indexPath.row];
            
            [likeUserCell setAccessoryType:UITableViewCellAccessoryNone];
            
            NSString *firstName = likeUser[@"first_name"];
            NSString *lastName = likeUser[@"last_name"];
            likeUserCell.username.text = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            likeUserCell.userAvatarImageView.contentMode = UIViewContentModeScaleAspectFill;
            
            if (likeUserCell.userAvatarImage) {
                [likeUserCell.userAvatarImageView setImage:likeUserCell.userAvatarImage];
            }
            else {
                if (!likeUser[@"profile_picture"]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [likeUserCell.userAvatarImageView setImage:[UIImage imageNamed:@"profile_image"]];
                    });
                }
                else {
                    likeUserCell.userAvatarImageView.file = likeUser[@"profile_picture"];
                    
                    [likeUserCell.userAvatarImageView loadInBackground:^(UIImage *image, NSError *error) {
                        likeUserCell.userAvatarImage = image;
                        
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (likeUserCell.userAvatarImage) {
                                [likeUserCell.userAvatarImageView setImage:likeUserCell.userAvatarImage];
                            }
                        });
                    }];
                }
            }
            
            cell = likeUserCell;

            break;
        }
            
        default:
            break;
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != MTPostTableCellTypeLikeUsers) {
        return;
    }
    
    PFUser *likeUser = self.challengePostsLikedUsers[indexPath.row];
    
    [self performSegueWithIdentifier:@"postDetailStudentProfileView" sender:likeUser];
}

- (IBAction)unwindToPostView:(UIStoryboardSegue *)sender
{
}


#pragma mark - MBProgressHUDDelegate Methods -
- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self secondaryButton1AfterToastAction];
}


@end
