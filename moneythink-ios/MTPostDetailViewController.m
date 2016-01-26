//
//  MTPostViewController.m
//  moneythink-ios
//
//  Created by dsica on 6/4/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTPostDetailViewController.h"
#import "MTMentorStudentProfileViewController.h"
#import "MTPostUserInfoTableViewCell.h"
#import "MTPostImageTableViewCell.h"
#import "MTPostCommentTableViewCell.h"
#import "MTPostLikeCommentTableViewCell.h"
#import "MTPostCommentItemsTableViewCell.h"
#import "MTPostLikeUserTableViewCell.h"
#import "MTMyClassTableViewController.h"
#import "MTPostsTableViewCell.h"
#import "MTPostViewController.h"

typedef enum {
    MTPostTableCellTypeUserInfo = 0,
    MTPostTableCellTypeImage,
    MTPostTableCellTypeSpentSaved,
    MTPostTableCellTypeCommentText,
    MTPostTableCellTypeButtons,
    MTPostTableCellTypeQuadButtons,
    MTPostTableCellTypeLikeComment,
    MTPostTableCellTypePostComments,
    MTPostTableCellTypeLikeUsers
} MTPostTableCellType;

@interface MTPostDetailViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) MTChallengePost *challengePost;

@property (nonatomic, strong) MTUser *currentUser;
@property (nonatomic, strong) MTUser *postUser;
@property (nonatomic) BOOL isMyClass;
@property (nonatomic, strong) RLMResults *comments;
@property (nonatomic, strong) RLMResults *likes;

@property (nonatomic, strong) NSMutableAttributedString *postText;
@property (nonatomic) CGFloat postTextHeight;
@property (nonatomic) BOOL isMentor;
@property (nonatomic) BOOL hideVerifySwitch;
@property (nonatomic, strong) UIButton *secondaryButton1;
@property (nonatomic, strong) UIButton *secondaryButton2;
@property (nonatomic, strong) RLMResults *emojiObjects;
@property (nonatomic, strong) NSString *spentAmount;
@property (nonatomic, strong) NSString *savedAmount;
@property (nonatomic) BOOL displaySpentView;
@property (nonatomic) BOOL hasSpentSavedContent;
@property (nonatomic, strong) RLMResults *buttons;
@property (nonatomic) BOOL loadedComments;
@property (nonatomic) BOOL loadedLikes;
@property (nonatomic, strong) UIImage *postImage;
@property (nonatomic) BOOL savingEdit;

@property (nonatomic, strong) UITapGestureRecognizer *verifiedTapGestureRecognizer;

- (void)attachTapGestureRecognizerToCell:(MTPostLikeCommentTableViewCell *)cell;

@end

@implementation MTPostDetailViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.challengePost = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:self.challengePostId]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveEditPost:) name:kWillSaveEditPostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSaveEditPost:) name:kDidSaveEditPostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedSaveEditPost:) name:kFailedSaveEditPostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveNewPostComment:) name:kWillSaveNewPostCommentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSaveNewPostComment:) name:kDidSaveNewPostCommentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDeletePostComment:) name:kDidDeletePostCommentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveEditPostComment:) name:kWillSaveEditPostCommentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentEditFailed) name:kFailedChallengePostCommentEditNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = @"Post Detail";
    
    if (IsEmpty(self.emojiObjects)) {
        [self loadEmoji];
    }

    if (self.notification) {
        self.postType = MTPostTypeNoButtonsNoImage;
        self.isMentor = NO;
        self.hideVerifySwitch = YES;
        [self.tableView reloadData];
        [self loadFromNotification];
    }
    else if (!self.savingEdit) {
        self.displaySpentView = !IsEmpty(self.challenge.postExtraFields);
        if (self.displaySpentView) {
            [self parseSpentFields];
        }
        
        self.postUser = self.challengePost.user;
        self.currentUser = [MTUser currentUser];
        
        [self loadCommentsOnlyDatabase:NO];
        [self loadPostText];
        [self loadPostImage];
        [self loadLikesOnlyDatabase:NO];
        [self loadButtonsOnlyDatabase:YES];
        [self configureChallengePermissions];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Private Methods -
- (void)loadFromNotification
{
    if (!self.notification || !self.notification.relatedPost) {
        return;
    }
    
    MTChallengePost *thisPost = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:self.notification.relatedPost.id]];
    if (thisPost) {
        [[RLMRealm defaultRealm] beginWriteTransaction];
        thisPost.isDeleted = NO;
        [[RLMRealm defaultRealm] commitWriteTransaction];
        
        self.challengePostId = self.notification.relatedPost.id;
        self.challengePost = thisPost;
        self.challenge = thisPost.challenge;
        
        self.displaySpentView = !IsEmpty(self.challenge.postExtraFields);
        if (self.displaySpentView) {
            [self parseSpentFields];
        }
        
        self.postUser = self.challengePost.user;
        self.currentUser = [MTUser currentUser];
        
        [self.tableView reloadData];
        
        [self loadCommentsOnlyDatabase:YES];
        [self loadPostText];
        [self loadPostImage];
        [self loadLikesOnlyDatabase:YES];
        [self loadButtonsOnlyDatabase:YES];
        [self configureChallengePermissions];
        
        if (IsEmpty(self.likes) && IsEmpty(self.comments)) {
            // We probably haven't loaded the data yet so display overlay, otherwise update in the background
            MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
            hud.labelText = @"Loading Post Data...";
            hud.dimBackground = YES;
        }

    }
    else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Loading Post...";
        hud.dimBackground = YES;
    }

    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] loadPostId:self.notification.relatedPost.id success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MTChallengePost *thisPost = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:weakSelf.notification.relatedPost.id]];
            
            if (!thisPost) {
                NSLog(@"Unable to find this post");
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                return;
            }
            
            weakSelf.challengePostId = weakSelf.notification.relatedPost.id;
            weakSelf.challengePost = thisPost;
            weakSelf.challenge = thisPost.challenge;
            
            weakSelf.displaySpentView = !IsEmpty(weakSelf.challenge.postExtraFields);
            if (weakSelf.displaySpentView) {
                [weakSelf parseSpentFields];
            }
            
            weakSelf.postUser = weakSelf.challengePost.user;
            weakSelf.currentUser = [MTUser currentUser];
            
            [weakSelf.tableView reloadData];
            
            [weakSelf loadCommentsOnlyDatabase:NO];
            [weakSelf loadPostText];
            [weakSelf loadLikesOnlyDatabase:NO];
            [weakSelf loadButtonsOnlyDatabase:NO];
            [weakSelf configureChallengePermissions];
        });

    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            NSLog(@"Unable to load post: %@", [error mtErrorDescription]);
        });
    }];
}

- (void)loadCommentsOnlyDatabase:(BOOL)onlyDatabase
{
    self.comments = [[MTChallengePostComment objectsWhere:@"challengePost.id = %lu AND isDeleted = NO", self.challengePostId] sortedResultsUsingProperty:@"createdAt" ascending:NO];
    [self.tableView reloadData];
    
    if (onlyDatabase) {
        return;
    }
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] loadCommentsForPostId:self.challengePostId success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.loadedComments = YES;
            
            weakSelf.comments = [[MTChallengePostComment objectsWhere:@"challengePost.id = %lu AND isDeleted = NO", weakSelf.challengePostId] sortedResultsUsingProperty:@"createdAt" ascending:NO];
            [weakSelf.tableView reloadData];
            
            if (weakSelf.loadedLikes) {
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            }
        });

    } failure:^(NSError *error) {
        NSLog(@"Unable to load comment for post: %@", [error mtErrorDescription]);
    }];
}

- (void)loadLikesOnlyDatabase:(BOOL)onlyDatabase;
{
    self.likes = [MTChallengePostLike objectsWhere:@"challengePost.id = %lu AND isDeleted = NO", self.challengePostId];
    
    NSMutableArray *emojiArray = [NSMutableArray array];
    for (MTChallengePostLike *thisLike in self.likes) {
        MTEmoji *thisEmoji = thisLike.emoji;
        if (thisEmoji) {
            [emojiArray addObject:thisEmoji];
        }
    }

    self.emojiArray = emojiArray;
    [self.tableView reloadData];

    if (onlyDatabase) {
        return;
    }
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] loadLikesForPostId:self.challengePostId success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.loadedLikes = YES;
            
            weakSelf.likes = [MTChallengePostLike objectsWhere:@"challengePost.id = %lu AND isDeleted = NO", weakSelf.challengePostId];
            
            NSMutableArray *emojiArray = [NSMutableArray array];
            for (MTChallengePostLike *thisLike in weakSelf.likes) {
                MTEmoji *thisEmoji = thisLike.emoji;
                if (thisEmoji) {
                    [emojiArray addObject:thisEmoji];
                }
            }
            
            weakSelf.emojiArray = emojiArray;
            [weakSelf.tableView reloadData];
            
            if (weakSelf.loadedComments) {
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            }
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load/update likes: %@", [error mtErrorDescription]);
    }];
}

- (void)loadPostText
{
    NSString *textString = self.challengePost.content;
    if (IsEmpty(textString)) {
        return;
    }
    
    self.postText = [[NSMutableAttributedString alloc] initWithString:textString];
    
    NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange rangeAll = NSMakeRange(0, textString.length);
    
    [hashtags enumerateMatchesInString:textString options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        
        NSMutableAttributedString *hashtag = [[NSMutableAttributedString alloc] initWithString:textString];
        [hashtag addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
        
        self.postText = hashtag;
    }];
    
    [self.tableView reloadData];
}

- (void)loadPostImage
{
    if (self.challengePost.hasPostImage) {
        MTMakeWeakSelf();
        self.postImage = [self.challengePost loadPostImageWithSuccess:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.postImage = responseData;
                [weakSelf.tableView reloadData];
            });
        } failure:^(NSError *error) {
            NSLog(@"Unable to load post image");
        }];
        
        [self.tableView reloadData];
    }
}

- (void)loadButtonsOnlyDatabase:(BOOL)onlyDatabase
{
    self.buttons = [[MTChallengeButton objectsWhere:@"isDeleted = NO AND challenge.id = %lu", self.challenge.id] sortedResultsUsingProperty:@"ranking" ascending:YES];
    
    self.hasButtons = NO;
    self.hasSecondaryButtons = NO;
    self.hasTertiaryButtons = NO;
    
    if (!IsEmpty(self.buttons)) {
        if ([[((MTChallengeButton *)[self.buttons firstObject]).buttonTypeCode uppercaseString] isEqualToString:@"VOTE"]) {
            // Voting buttons (primary or tertiary)
            if ([self.buttons count] == 4) {
                // Tertiary
                self.hasTertiaryButtons = YES;
            }
            else {
                // Primary
                self.hasButtons = YES;
            }
        }
        else if (!self.isMentor) {
            // Secondary
            self.hasSecondaryButtons = YES;
        }
        
        MTUser *user = self.challengePost.user;
        BOOL myPost = NO;
        if ([MTUser isUserMe:user]) {
            myPost = YES;
        }

        BOOL showButtons = NO;
        if (self.hasButtons || (self.hasSecondaryButtons && myPost) || self.hasTertiaryButtons) {
            showButtons = YES;
        }

        if (showButtons && self.challengePost.hasPostImage)
            self.postType = MTPostTypeWithButtonsWithImage;
        else if (showButtons)
            self.postType = MTPostTypeWithButtonsNoImage;
        else if (self.challengePost.hasPostImage)
            self.postType = MTPostTypeNoButtonsWithImage;
        else
            self.postType = MTPostTypeNoButtonsNoImage;

        [self.tableView reloadData];
        
        // We already have buttons, just update clicks
        [self updateButtonClicks];
        return;
    }
    else {
        if (self.challengePost.hasPostImage)
            self.postType = MTPostTypeNoButtonsWithImage;
        else
            self.postType = MTPostTypeNoButtonsNoImage;
    }
    
    if (onlyDatabase) {
        return;
    }
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] loadButtonsWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf loadButtonsOnlyDatabase:YES];
            if (weakSelf.hasButtons || weakSelf.hasSecondaryButtons || weakSelf.hasTertiaryButtons) {
                [weakSelf updateButtonClicks];
            }
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to updateButtons: %@", [error mtErrorDescription]);
    }];
}

- (void)updateButtonClicks
{
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] loadButtonClicksForChallengeId:self.challenge.id success:^(id responseData) {
        [weakSelf.tableView reloadData];
    } failure:^(NSError *error) {
        NSLog(@"Unable to updateButtonsClicks: %@", [error mtErrorDescription]);
    }];
}

- (void)configureChallengePermissions
{
    self.isMentor = [MTUser isCurrentUserMentor];
    BOOL autoVerify = self.challenge.autoVerify;
    self.hideVerifySwitch = !self.isMentor || autoVerify;
}

- (void)showFirstTimeToastNotification
{
    NSString *key = @"ShownToastForChallenge";
    NSArray *shownArray = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (![shownArray containsObject:[NSNumber numberWithInteger:self.challenge.id]]) {
        
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
    else {
        [self secondaryButton1AfterToastAction];
    }
}

- (void)closeTouched:(id)sender
{
    self.myClassTableViewController = nil;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadEmoji
{
    RLMResults *emojis = [[MTEmoji objectsWhere:@"isDeleted = NO"] sortedResultsUsingProperty:@"ranking" ascending:YES];
    if (!IsEmpty(emojis)) {
        self.emojiObjects = emojis;
        [self.tableView reloadData];
    }
    else {
        MTMakeWeakSelf();
        [[MTNetworkManager sharedMTNetworkManager] loadEmojiWithSuccess:^(id responseData) {
            RLMResults *emojis = [[MTEmoji objectsWhere:@"isDeleted = NO"] sortedResultsUsingProperty:@"ranking" ascending:YES];
            weakSelf.emojiObjects = emojis;
            [weakSelf.tableView reloadData];
        } failure:^(NSError *error) {
            NSLog(@"Unable to fetch emojis: %@", [error mtErrorDescription]);
        }];
    }
}

- (void)showNoDataAlertAndPopView:(BOOL)popView
{
    NSString *title = @"Unable to load Notification";
    NSString *messageToDisplay = @"Post may have been previously deleted.";
    
    if ([UIAlertController class]) {
        UIAlertController *changeSheet = [UIAlertController
                                          alertControllerWithTitle:title
                                          message:messageToDisplay
                                          preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *close = [UIAlertAction
                                actionWithTitle:@"Close"
                                style:UIAlertActionStyleCancel
                                handler:^(UIAlertAction *action) {
                                    if (popView) {
                                        [self.navigationController popViewControllerAnimated:YES];
                                    }
                                }];
        
        [changeSheet addAction:close];
        
        [self presentViewController:changeSheet animated:YES completion:nil];
    } else {
        MTMakeWeakSelf();
        [UIAlertView bk_showAlertViewWithTitle:title message:messageToDisplay cancelButtonTitle:@"Close" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (popView) {
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }
        }];
    }
}

- (void)parseSpentFields
{
    // Assume blank
    self.hasSpentSavedContent = NO;
    self.savedAmount = @"";
    self.spentAmount = @"";
    
    if (!IsEmpty(self.challengePost.extraFields)) {
        NSData *data = [self.challengePost.extraFields dataUsingEncoding:NSUTF8StringEncoding];
        id jsonDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        
        if ([jsonDict isKindOfClass:[NSDictionary class]]) {
            NSDictionary *savedSpentDict = (NSDictionary *)jsonDict;
            NSString *spentString = [savedSpentDict objectForKey:@"spent"];
            NSString *currencyString = [self currencyTextForString:spentString];
            if (!IsEmpty(currencyString)) {
                self.spentAmount = currencyString;
            }
            
            NSString *savedString = [savedSpentDict objectForKey:@"saved"];
            currencyString = [self currencyTextForString:savedString];
            if (!IsEmpty(currencyString)) {
                self.savedAmount = currencyString;
            }
        }
    }
    
    if ((!IsEmpty(self.savedAmount) || !IsEmpty(self.spentAmount))) {
        self.hasSpentSavedContent = YES;
    }
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


#pragma mark - Button Methods -
- (void)setupButtonsForCell:(UITableViewCell *)cell
{
    UIButton *button1 = (UIButton *)[cell.contentView viewWithTag:1];
    UIButton *button2 = (UIButton *)[cell.contentView viewWithTag:2];
    
    [button1 removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [button1 addTarget:self action:@selector(button1Tapped:) forControlEvents:UIControlEventTouchUpInside];

    [button2 removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [button2 addTarget:self action:@selector(button2Tapped:) forControlEvents:UIControlEventTouchUpInside];
    
    MTChallengeButton *challengeButton1 = [self.buttons objectAtIndex:0];
    MTChallengeButton *challengeButton2 = [self.buttons objectAtIndex:1];
    
    RLMResults *myButton1Clicks = [MTChallengeButtonClick objectsWhere:@"user.id = %lu AND challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                   [MTUser currentUser].id, self.challengePost.id, challengeButton1.id];
    
    RLMResults *myButton2Clicks = [MTChallengeButtonClick objectsWhere:@"user.id = %lu AND challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                   [MTUser currentUser].id, self.challengePost.id, challengeButton2.id];
    
    RLMResults *allButton1Clicks = [MTChallengeButtonClick objectsWhere:@"challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                    self.challengePost.id, challengeButton1.id];
    
    RLMResults *allButton2Clicks = [MTChallengeButtonClick objectsWhere:@"challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                    self.challengePost.id, challengeButton2.id];
    
    [button1 layer].masksToBounds = YES;
    [button2 layer].masksToBounds = YES;
    
    if (!IsEmpty(myButton1Clicks)) {
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
    else if (!IsEmpty(myButton2Clicks)) {
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
    
    if (self.buttons.count > 1) {
        NSString *button1Title;
        NSString *button2Title;
        
        if ([allButton1Clicks count] > 0) {
            button1Title = [NSString stringWithFormat:@"%@ (%lu)", challengeButton1.label, (unsigned long)[allButton1Clicks count]];
        }
        else {
            button1Title = [NSString stringWithFormat:@"%@ (0)", challengeButton1.label];
        }
        
        if (allButton2Clicks.count > 1) {
            button2Title = [NSString stringWithFormat:@"%@ (%lu)", challengeButton2.label, (unsigned long)[allButton2Clicks count]];
        }
        else {
            button2Title = [NSString stringWithFormat:@"%@ (0)", challengeButton2.label];
        }
        
        [button1 setTitle:button1Title forState:UIControlStateNormal];
        [button2 setTitle:button2Title forState:UIControlStateNormal];
    }
}

- (void)setupSecondaryButtonsForCell:(UITableViewCell *)cell
{
    UIButton *button1 = (UIButton *)[cell.contentView viewWithTag:1];
    UIButton *button2 = (UIButton *)[cell.contentView viewWithTag:2];
    
    [button1 removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [button1 addTarget:self action:@selector(secondaryButton1Tapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [button2 removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [button2 addTarget:self action:@selector(secondaryButton2Tapped:) forControlEvents:UIControlEventTouchUpInside];

    MTChallengeButton *challengeButton1 = [self.buttons objectAtIndex:0];
    MTChallengeButton *challengeButton2 = [self.buttons objectAtIndex:1];
    
    RLMResults *myButton1Clicks = [MTChallengeButtonClick objectsWhere:@"user.id = %lu AND challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                   [MTUser currentUser].id, self.challengePost.id, challengeButton1.id];
    
    RLMResults *myButton2Clicks = [MTChallengeButtonClick objectsWhere:@"user.id = %lu AND challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                   [MTUser currentUser].id, self.challengePost.id, challengeButton2.id];
    
    NSInteger button1Count = [myButton1Clicks count];
    NSInteger button2Count = [myButton2Clicks count];
    
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
}

- (void)setupTertiaryButtonsForCell:(UITableViewCell *)cell
{
    MTChallengeButton *challengeButton1 = [self.buttons objectAtIndex:0];
    MTChallengeButton *challengeButton2 = [self.buttons objectAtIndex:1];
    MTChallengeButton *challengeButton3 = [self.buttons objectAtIndex:2];
    MTChallengeButton *challengeButton4 = [self.buttons objectAtIndex:3];
    
    RLMResults *myButton1Clicks = [MTChallengeButtonClick objectsWhere:@"user.id = %lu AND challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                   [MTUser currentUser].id, self.challengePost.id, challengeButton1.id];
    
    RLMResults *myButton2Clicks = [MTChallengeButtonClick objectsWhere:@"user.id = %lu AND challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                   [MTUser currentUser].id, self.challengePost.id, challengeButton2.id];
    
    RLMResults *myButton3Clicks = [MTChallengeButtonClick objectsWhere:@"user.id = %lu AND challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                   [MTUser currentUser].id, self.challengePost.id, challengeButton3.id];
    
    RLMResults *myButton4Clicks = [MTChallengeButtonClick objectsWhere:@"user.id = %lu AND challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                   [MTUser currentUser].id, self.challengePost.id, challengeButton4.id];
    
    RLMResults *allButton1Clicks = [MTChallengeButtonClick objectsWhere:@"challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                    self.challengePost.id, challengeButton1.id];
    
    RLMResults *allButton2Clicks = [MTChallengeButtonClick objectsWhere:@"challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                    self.challengePost.id, challengeButton2.id];
    
    RLMResults *allButton3Clicks = [MTChallengeButtonClick objectsWhere:@"challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                    self.challengePost.id, challengeButton3.id];
    
    RLMResults *allButton4Clicks = [MTChallengeButtonClick objectsWhere:@"challengePost.id = %lu AND challengeButton.id = %lu AND isDeleted = NO",
                                    self.challengePost.id, challengeButton4.id];

    BOOL tertiaryRow = NO;
    UIButton *button1 = (UIButton *)[cell.contentView viewWithTag:1];
    if (!button1) {
        button1 = (UIButton *)[cell.contentView viewWithTag:3];
        tertiaryRow = YES;
    }
    else {
        [button1 removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [button1 addTarget:self action:@selector(button1Tapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    UIButton *button2 = (UIButton *)[cell.contentView viewWithTag:2];
    if (!button2) {
        button2 = (UIButton *)[cell.contentView viewWithTag:4];
    }
    else {
        [button2 removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
        [button2 addTarget:self action:@selector(button2Tapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [button1 layer].masksToBounds = YES;
    [button2 layer].masksToBounds = YES;
    [[button1 layer] setCornerRadius:5.0f];
    [[button2 layer] setCornerRadius:5.0f];

    UIColor *button1Color;
    UIColor *button2Color;
    
    if (tertiaryRow) {
        button1Color = [UIColor votingBlue];
        button2Color = [UIColor votingGreen];
    }
    else {
        button1Color = [UIColor votingRed];
        button2Color = [UIColor votingPurple];
    }
    
    // Reset to default
    [[button1 layer] setBorderWidth:2.0f];
    [[button1 layer] setBorderColor:button1Color.CGColor];
    [button1 setTintColor:button1Color];
    [button1 setTitleColor:button1Color forState:UIControlStateNormal];
    [button1 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:button1.frame.size] forState:UIControlStateNormal];
    [button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:button1.frame.size] forState:UIControlStateHighlighted];
    
    [[button2 layer] setBorderWidth:2.0f];
    [[button2 layer] setBorderColor:button2Color.CGColor];
    [button2 setTintColor:button2Color];
    [button2 setTitleColor:button2Color forState:UIControlStateNormal];
    [button2 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    [button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:button2.frame.size] forState:UIControlStateNormal];
    [button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:button2.frame.size] forState:UIControlStateHighlighted];
    
    if ((!IsEmpty(myButton1Clicks) && !tertiaryRow) || (!IsEmpty(myButton3Clicks) && tertiaryRow)) {
        [button1 setBackgroundImage:[UIImage imageWithColor:button1Color size:button1.frame.size] forState:UIControlStateNormal];
        [button1 setBackgroundImage:[UIImage imageWithColor:button1Color size:button1.frame.size] forState:UIControlStateHighlighted];
        [button1 setTintColor:[UIColor white]];
        [button1 setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [button1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    }
    else if ((!IsEmpty(myButton2Clicks) && !tertiaryRow) || (!IsEmpty(myButton4Clicks) && tertiaryRow)) {
        [button2 setBackgroundImage:[UIImage imageWithColor:button2Color size:button2.frame.size] forState:UIControlStateNormal];
        [button2 setBackgroundImage:[UIImage imageWithColor:button2Color size:button2.frame.size] forState:UIControlStateHighlighted];
        [button2 setTintColor:[UIColor white]];
        [button2 setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [button2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    }
    
    if (self.buttons.count == 4) {
        NSString *button1Title;
        NSString *button2Title;
        
        if (!tertiaryRow) {
            if ([allButton1Clicks count] > 0) {
                button1Title = [NSString stringWithFormat:@"%@ (%lu)", challengeButton1.label, (unsigned long)[allButton1Clicks count]];
            }
            else {
                button1Title = [NSString stringWithFormat:@"%@", challengeButton1.label];
            }
            
            if ([allButton2Clicks count] > 0 ) {
                button2Title = [NSString stringWithFormat:@"%@ (%lu)", challengeButton2.label, (unsigned long)[allButton2Clicks count]];
            }
            else {
                button2Title = [NSString stringWithFormat:@"%@", challengeButton2.label];
            }

        }
        else {
            if ([allButton3Clicks count] > 0) {
                button1Title = [NSString stringWithFormat:@"%@ (%lu)", challengeButton3.label, (unsigned long)[allButton3Clicks count]];
            }
            else {
                button1Title = [NSString stringWithFormat:@"%@", challengeButton3.label];
            }
            
            if ([allButton4Clicks count] > 0) {
                button2Title = [NSString stringWithFormat:@"%@ (%lu)", challengeButton4.label, (unsigned long)[allButton4Clicks count]];
            }
            else {
                button2Title = [NSString stringWithFormat:@"%@", challengeButton4.label];
            }

        }
        
        [button1 setTitle:button1Title forState:UIControlStateNormal];
        [button2 setTitle:button2Title forState:UIControlStateNormal];
    }
    
    [button1.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [button2.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
}


#pragma mark - Public Methods -
- (void)emojiLiked:(MTEmoji *)emoji
{
    NSString *emojiCode = emoji.code;
    
    __block MTChallengePost *post = self.challengePost;
    
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
                [weakSelf loadLikesOnlyDatabase:YES];
                if ([weakSelf.delegate respondsToSelector:@selector(didUpdateLikes)]) {
                    [weakSelf.delegate didUpdateLikes];
                }
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
                [weakSelf loadLikesOnlyDatabase:YES];
                if ([weakSelf.delegate respondsToSelector:@selector(didUpdateLikes)]) {
                    [weakSelf.delegate didUpdateLikes];
                }
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            });
        }];
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
    MTChallengePostComment *comment = nil;
    if ([self.comments count] > indexPath.row) {
        comment = [self.comments objectAtIndex:indexPath.row];
    }
    
    if (!comment || IsEmpty(comment.content)) {
        return 0.0f;
    }
    
    static MTPostCommentItemsTableViewCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:@"PostCommentItemsCell"];
    });
    
    [self configurePostCommentsCell:sizingCell atIndexPath:indexPath comment:comment];
    return [self calculateHeightForCommentsConfiguredSizingCell:sizingCell];
}

- (CGFloat)calculateHeightForCommentsConfiguredSizingCell:(UITableViewCell *)sizingCell {
    sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.bounds), 0.0f);

    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
}

- (void)configurePostCommentsCell:(MTPostCommentItemsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath comment:(MTChallengePostComment *)comment {
    cell.commentLabel.text = comment.content;
    [cell.commentLabel setFont:[UIFont mtFontOfSize:13.0f]];
    
    MTUser *commentPoster = comment.user;
    NSString *detailString = [NSString stringWithFormat:@"%@ %@:", commentPoster.firstName, commentPoster.lastName];
    cell.userLabel.text = detailString;
    [cell.userLabel setFont:[UIFont mtBoldFontOfSize:11.0f]];
}


#pragma mark - Actions -
- (IBAction)likeButtonTapped:(id)sender
{
    // Load for Notification-loaded case
    if (!self.myClassTableViewController) {
        self.myClassTableViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"myClassChallengePostsTableView"];
        self.myClassTableViewController.emojiObjects = self.emojiObjects;
        self.myClassTableViewController.postViewController = self;
    }
    
    [self.myClassTableViewController didSelectLikeWithEmojiForPost:self.challengePost];
}

- (IBAction)commentTapped:(id)sender
{
    [self performSegueWithIdentifier:@"commentOnPost" sender:sender];
}

- (void)dismissCommentView
{
    [self loadCommentsOnlyDatabase:YES];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)editDeletePostTapped:(id)sender
{
    __block id weakSender = sender;
    
    // Prompt for Edit or Delete
    if ([UIAlertController class]) {
        UIAlertController *editDeletePostSheet = [UIAlertController alertControllerWithTitle:@"Edit or Delete this post?" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }];
        MTMakeWeakSelf();
        UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [weakSelf promptForDelete];
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
        UIActionSheet *editDeleteAction = [UIActionSheet bk_actionSheetWithTitle:@"Edit or Delete this post?"];
        [editDeleteAction bk_addButtonWithTitle:@"Edit" handler:^{
            [weakSelf performEditPostWithSender:weakSender];
        }];
        [editDeleteAction bk_setDestructiveButtonWithTitle:@"Delete" handler:^{
            [weakSelf promptForDelete];
        }];
        [editDeleteAction bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
        [editDeleteAction showInView:[UIApplication sharedApplication].keyWindow];
    }
}

- (void)performEditPostWithSender:(id)sender
{
    [self performSegueWithIdentifier:@"editPostSegue" sender:sender];
}

- (void)promptForDelete
{
    if ([UIAlertController class]) {
        UIAlertController *deletePostSheet = [UIAlertController alertControllerWithTitle:@"Delete this post?" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }];
        MTMakeWeakSelf();
        UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [weakSelf performDeletePost];
        }];
        
        [deletePostSheet addAction:cancel];
        [deletePostSheet addAction:delete];
        
        [self presentViewController:deletePostSheet animated:YES completion:nil];
    }
    else {
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
        [[MTNetworkManager sharedMTNetworkManager] deletePostId:self.challengePost.id success:^(AFOAuthCredential *credential) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (![MTUser isCurrentUserMentor]) {
                    // Update current user (to get current point total)
                    [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
                        [MTUtil setRefreshedForKey:kRefreshForMeUser];
                    } failure:nil];
                }
                [self.navigationController popViewControllerAnimated:YES];
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"error deleting post - %@", [error mtErrorDescription]);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Delete" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            });
        }];
    }
}

- (void)editDeleteCommentTapped:(id)sender
{
    __block id weakSender = sender;
    
    // Prompt for Edit or Delete
    NSString *title = @"Edit or Delete this comment?";
    if ([UIAlertController class]) {
        UIAlertController *editDeleteCommentSheet = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }];
        MTMakeWeakSelf();
        UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [weakSelf promptForDeleteCommentWithSender:sender];
        }];
        UIAlertAction *edit = [UIAlertAction actionWithTitle:@"Edit" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakSelf performEditCommentWithSender:weakSender];
        }];
        
        [editDeleteCommentSheet addAction:cancel];
        [editDeleteCommentSheet addAction:edit];
        [editDeleteCommentSheet addAction:delete];
        
        [self presentViewController:editDeleteCommentSheet animated:YES completion:nil];
    }
    else {
        MTMakeWeakSelf();
        UIActionSheet *editDeleteAction = [UIActionSheet bk_actionSheetWithTitle:title];
        [editDeleteAction bk_addButtonWithTitle:@"Edit" handler:^{
            [weakSelf performEditCommentWithSender:weakSender];
        }];
        [editDeleteAction bk_setDestructiveButtonWithTitle:@"Delete" handler:^{
            [weakSelf promptForDeleteCommentWithSender:sender];
        }];
        [editDeleteAction bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
        [editDeleteAction showInView:[UIApplication sharedApplication].keyWindow];
    }
}

- (void)performEditCommentWithSender:(id)sender
{
    [self performSegueWithIdentifier:@"editCommentSegue" sender:sender];
}

- (void)promptForDeleteCommentWithSender:(id)sender
{
    NSString *title = @"Delete this comment?";
    if ([UIAlertController class]) {
        UIAlertController *deletePostSheet = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        }];
        MTMakeWeakSelf();
        UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [weakSelf performDeleteCommentWithSender:sender];
        }];
        
        [deletePostSheet addAction:cancel];
        [deletePostSheet addAction:delete];
        
        [self presentViewController:deletePostSheet animated:YES completion:nil];
    }
    else {
        MTMakeWeakSelf();
        UIActionSheet *deleteAction = [UIActionSheet bk_actionSheetWithTitle:title];
        [deleteAction bk_setDestructiveButtonWithTitle:@"Delete" handler:^{
            [weakSelf performDeleteCommentWithSender:sender];
        }];
        [deleteAction bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
        [deleteAction showInView:[UIApplication sharedApplication].keyWindow];
    }
}

- (void)performDeleteCommentWithSender:(id)sender
{
    MTPostCommentItemsTableViewCell *cell = (MTPostCommentItemsTableViewCell *)sender;
    MTChallengePostComment *comment = cell.comment;
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Deleting Comment...";
    hud.dimBackground = YES;

    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] deleteCommentId:comment.id success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf loadCommentsOnlyDatabase:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:kDidDeletePostCommentNotification object:nil];
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            [UIAlertView bk_showAlertViewWithTitle:@"Unable to Delete Comment" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
        });
    }];
}

- (IBAction)verifiedTapped:(id)sender
{
    UIView *subview = sender;
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tapGestureRecognizer = (UITapGestureRecognizer *)sender;
        subview = tapGestureRecognizer.view;
    }
    
    MTPostLikeCommentTableViewCell *likeCommentCell;
    likeCommentCell = (MTPostLikeCommentTableViewCell *)[subview findSuperViewWithClass:[MTPostLikeCommentTableViewCell class]];
    
    BOOL isVerified = self.challengePost.isVerified;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    if (isVerified) {
        hud.labelText = @"Removing Verification...";
    }
    else {
        hud.labelText = @"Verifying...";
    }
    hud.dimBackground = YES;
    
    likeCommentCell.verfiedLabel.text = @"Updating...";
    
    MTMakeWeakSelf();
    if (isVerified) {
        [[MTNetworkManager sharedMTNetworkManager] unVerifyPostId:self.challengePost.id success:^(AFOAuthCredential *credential) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                [weakSelf.tableView reloadData];
                
                if ([weakSelf.delegate respondsToSelector:@selector(didUpdateVerification)]) {
                    [weakSelf.delegate didUpdateVerification];
                }
            });
            
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                [weakSelf.tableView reloadData];
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            });
        }];
    }
    else {
        [[MTNetworkManager sharedMTNetworkManager] verifyPostId:self.challengePost.id success:^(AFOAuthCredential *credential) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                [weakSelf.tableView reloadData];
                
                if ([weakSelf.delegate respondsToSelector:@selector(didUpdateVerification)]) {
                    [weakSelf.delegate didUpdateVerification];
                }
            });
            
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                [weakSelf.tableView reloadData];
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
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

- (IBAction)button3Tapped:(id)sender
{
    [self submitPrimaryButtonTapped:sender withButtonNumber:2];
}

- (IBAction)button4Tapped:(id)sender
{
    [self submitPrimaryButtonTapped:sender withButtonNumber:3];
}

- (void)submitPrimaryButtonTapped:(id)sender withButtonNumber:(NSInteger)buttonNumber
{
    UIButton *button = sender;
    button.enabled = NO;
    
    MTChallengeButton *challengeButton = [self.buttons objectAtIndex:buttonNumber];
    
    RLMResults *existingClick = [MTChallengeButtonClick objectsWhere:@"isDeleted = NO AND user.id = %lu AND challengePost.id = %lu",
                                 [MTUser currentUser].id, self.challengePost.id];
    
    MTChallengeButtonClick *thisClick = [existingClick firstObject];
    if (thisClick.challengeButton.id == challengeButton.id) {
        button.enabled = YES;
        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Submitting...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    if (thisClick) {
        // Delete old one first, then add
        [[MTNetworkManager sharedMTNetworkManager] deleteButtonClickId:thisClick.id success:^(id responseData) {
            
            [[MTNetworkManager sharedMTNetworkManager] addButtonClickForPostId:weakSelf.challengePost.id buttonId:challengeButton.id success:^(id responseData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                    button.enabled = YES;
                    [weakSelf.tableView reloadData];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidTapChallengeButtonNotification object:[NSNumber numberWithInteger:weakSelf.challenge.id]];
                    if ([weakSelf.delegate respondsToSelector:@selector(didUpdateButtons)]) {
                        [weakSelf.delegate didUpdateButtons];
                    }
                    // Update current user (to get current point total)
                    [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
                        [MTUtil setRefreshedForKey:kRefreshForMeUser];
                    } failure:nil];
                });
            } failure:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                    button.enabled = YES;
                    [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                });
            }];
            
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                button.enabled = YES;
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            });
        }];
    }
    else {
        [[MTNetworkManager sharedMTNetworkManager] addButtonClickForPostId:self.challengePost.id buttonId:challengeButton.id success:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                button.enabled = YES;
                [weakSelf.tableView reloadData];
                [[NSNotificationCenter defaultCenter] postNotificationName:kDidTapChallengeButtonNotification object:[NSNumber numberWithInteger:weakSelf.challenge.id]];
                if ([weakSelf.delegate respondsToSelector:@selector(didUpdateButtons)]) {
                    [weakSelf.delegate didUpdateButtons];
                }
                // Update current user (to get current point total)
                [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
                    [MTUtil setRefreshedForKey:kRefreshForMeUser];
                } failure:nil];
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                button.enabled = YES;
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            });
        }];
    }
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
    MTChallengeButton *button1 = [self.buttons objectAtIndex:0];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Processing Points...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    if (increment) {
        // Create new buttonClick
        [[MTNetworkManager sharedMTNetworkManager] addButtonClickForPostId:self.challengePost.id buttonId:button1.id success:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                weakSelf.secondaryButton1.enabled = YES;
                [weakSelf.tableView reloadData];
                [[NSNotificationCenter defaultCenter] postNotificationName:kDidTapChallengeButtonNotification object:[NSNumber numberWithInteger:weakSelf.challenge.id]];
                if ([weakSelf.delegate respondsToSelector:@selector(didUpdateButtons)]) {
                    [weakSelf.delegate didUpdateButtons];
                }
                // Update current user (to get current point total)
                [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
                    [MTUtil setRefreshedForKey:kRefreshForMeUser];
                } failure:nil];
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                weakSelf.secondaryButton1.enabled = YES;
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            });
        }];
    }
    else {
        // Delete existing buttonClick
        MTChallengeButtonClick *oneClick = [[MTChallengeButtonClick objectsWhere:@"isDeleted = NO AND user.id = %lu AND challengePost.id = %lu AND challengeButton.id = %lu",
                                             [MTUser currentUser].id, self.challengePost.id, button1.id] firstObject];
        
        if (oneClick) {
            [[MTNetworkManager sharedMTNetworkManager] deleteButtonClickId:oneClick.id success:^(id responseData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                    weakSelf.secondaryButton1.enabled = YES;
                    [weakSelf.tableView reloadData];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidTapChallengeButtonNotification object:[NSNumber numberWithInteger:weakSelf.challenge.id]];
                    if ([weakSelf.delegate respondsToSelector:@selector(didUpdateButtons)]) {
                        [weakSelf.delegate didUpdateButtons];
                    }
                    // Update current user (to get current point total)
                    [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
                        [MTUtil setRefreshedForKey:kRefreshForMeUser];
                    } failure:nil];
                });
            } failure:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                    weakSelf.secondaryButton1.enabled = YES;
                    [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                });
            }];
        }
        else {
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            weakSelf.secondaryButton1.enabled = YES;
        }
    }
}

- (void)secondaryButton2Tapped:(id)sender
{
    ((UIButton *)sender).enabled = NO;
    self.secondaryButton2 = (UIButton *)sender;
    MTChallengeButton *button2 = [self.buttons objectAtIndex:1];
    
    RLMResults *clickResults = [MTChallengeButtonClick objectsWhere:@"isDeleted = NO AND user.id = %lu AND challengePost.id = %lu AND challengeButton.id = %lu",
                                [MTUser currentUser].id, self.challengePost.id, button2.id];
    
    BOOL markComplete = ([clickResults count] > 0) ? NO : YES;
    NSString *title = @"Mark this as complete?";
    if (!markComplete) {
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
    MTChallengeButton *button2 = [self.buttons objectAtIndex:1];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = markComplete ? @"Marking Complete..." : @"Marking Incomplete...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    if (markComplete) {
        // Add click
        [[MTNetworkManager sharedMTNetworkManager] addButtonClickForPostId:self.challengePost.id buttonId:button2.id success:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                weakSelf.secondaryButton2.enabled = YES;
                [weakSelf.tableView reloadData];
                [[NSNotificationCenter defaultCenter] postNotificationName:kDidTapChallengeButtonNotification object:[NSNumber numberWithInteger:weakSelf.challenge.id]];
                if ([weakSelf.delegate respondsToSelector:@selector(didUpdateButtons)]) {
                    [weakSelf.delegate didUpdateButtons];
                }
                // Update current user (to get current point total)
                [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
                    [MTUtil setRefreshedForKey:kRefreshForMeUser];
                } failure:nil];
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                weakSelf.secondaryButton2.enabled = YES;
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            });
        }];
    }
    else {
        // Delete existing buttonClick
        MTChallengeButtonClick *oneClick = [[MTChallengeButtonClick objectsWhere:@"isDeleted = NO AND user.id = %lu AND challengePost.id = %lu AND challengeButton.id = %lu",
                                             [MTUser currentUser].id, self.challengePost.id, button2.id] firstObject];
        
        if (oneClick) {
            [[MTNetworkManager sharedMTNetworkManager] deleteButtonClickId:oneClick.id success:^(id responseData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                    weakSelf.secondaryButton2.enabled = YES;
                    [weakSelf.tableView reloadData];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidTapChallengeButtonNotification object:[NSNumber numberWithInteger:weakSelf.challenge.id]];
                    if ([weakSelf.delegate respondsToSelector:@selector(didUpdateButtons)]) {
                        [weakSelf.delegate didUpdateButtons];
                    }
                    // Update current user (to get current point total)
                    [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
                        [MTUtil setRefreshedForKey:kRefreshForMeUser];
                    } failure:nil];
                });
            } failure:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                    weakSelf.secondaryButton2.enabled = YES;
                    [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                });
            }];
        }
        else {
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            weakSelf.secondaryButton2.enabled = YES;
        }
    }
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
        [destinationViewController setDelegate:self];
    }
    else if ([segueIdentifier isEqualToString:@"editPostSegue"]) {
        UINavigationController *destinationViewController = (UINavigationController *)[segue destinationViewController];
        MTPostViewController *postVC = (MTPostViewController *)[destinationViewController topViewController];
        postVC.post = self.challengePost;
        postVC.challenge = self.challenge;
        postVC.editPost = YES;
    }
    else if ([segueIdentifier isEqualToString:@"editCommentSegue"]) {
        MTPostCommentItemsTableViewCell *cell = (MTPostCommentItemsTableViewCell *)sender;
        
        MTCommentViewController *destinationViewController = (MTCommentViewController *)[segue destinationViewController];
        destinationViewController.post = self.challengePost;
        destinationViewController.challengePostComment = cell.comment;
        destinationViewController.editComment = YES;
        [destinationViewController setDelegate:self];
    }
    else if ([segueIdentifier isEqualToString:@"pushStudentProfileFromPost"]) {
        MTMentorStudentProfileViewController *destinationVC = (MTMentorStudentProfileViewController *)[segue destinationViewController];
        destinationVC.studentUser = self.challengePost[@"user"];
    }
    else if ([segueIdentifier isEqualToString:@"postDetailStudentProfileView"]) {
        MTMentorStudentProfileViewController *destinationVC = (MTMentorStudentProfileViewController *)[segue destinationViewController];
        MTUser *studentUser = sender;
        destinationVC.studentUser = studentUser;
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
                {
                    if (self.postImage) {
                        CGFloat ratio = self.postImage.size.height/self.postImage.size.width;
                        height = self.tableView.frame.size.width * ratio;
                    }
                    else {
                        height = 320.0f;
                    }
                    break;
                }
                case MTPostTableCellTypeSpentSaved:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeCommentText:
                    height = [self heightForPostTextCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeButtons:
                    height = 44.0f;
                    break;
                case MTPostTableCellTypeQuadButtons:
                    height = 44.0f;
                    if (!self.hasTertiaryButtons) {
                        height = 0.0f;
                    }
                    break;
                case MTPostTableCellTypeLikeComment:
                    height = 92.0f;
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
                case MTPostTableCellTypeSpentSaved:
                    height = 0.0f;
                    if (self.displaySpentView && self.hasSpentSavedContent) {
                        height = 34.0f;
                    }
                    break;
                case MTPostTableCellTypeCommentText:
                    height = [self heightForPostTextCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeButtons:
                    height = 44.0f;
                    break;
                case MTPostTableCellTypeQuadButtons:
                    height = 44.0f;
                    if (!self.hasTertiaryButtons) {
                        height = 0.0f;
                    }
                    break;
                case MTPostTableCellTypeLikeComment:
                    height = 92.0f;
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
                {
                    if (self.postImage) {
                        CGFloat ratio = self.postImage.size.height/self.postImage.size.width;
                        height = self.tableView.frame.size.width * ratio;
                    }
                    else {
                        height = 320.0f;
                    }
                    break;
                }
                case MTPostTableCellTypeSpentSaved:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeCommentText:
                    height = [self heightForPostTextCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeButtons:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeQuadButtons:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeLikeComment:
                    height = 92.0f;
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
                case MTPostTableCellTypeSpentSaved:
                    height = 0.0f;
                    if (self.displaySpentView && self.hasSpentSavedContent) {
                        height = 34.0f;
                    }
                    break;
                case MTPostTableCellTypeCommentText:
                    height = [self heightForPostTextCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeButtons:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeQuadButtons:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeLikeComment:
                    height = 92.0f;
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
        case MTPostTableCellTypeSpentSaved:
            return @"";
            break;
        case MTPostTableCellTypeCommentText:
            return @"";
            break;
        case MTPostTableCellTypeButtons:
            return @"";
            break;
        case MTPostTableCellTypeQuadButtons:
            return @"";
            break;
        case MTPostTableCellTypeLikeComment:
            return @"";
            break;
        case MTPostTableCellTypePostComments:
            return [self.comments count] > 0 ? @"Comments" : @"";
            break;
        case MTPostTableCellTypeLikeUsers:
            return [self.likes count] > 0 ? @"Likes" : @"";
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
        case MTPostTableCellTypeSpentSaved:
            break;
        case MTPostTableCellTypeCommentText:
            break;
        case MTPostTableCellTypeButtons:
            break;
        case MTPostTableCellTypeQuadButtons:
            break;
        case MTPostTableCellTypeLikeComment:
            break;
        case MTPostTableCellTypePostComments:
            height = [self.comments count] > 0 ? 30.0f : 0.0f;
            break;
        case MTPostTableCellTypeLikeUsers:
            height = [self.likes count] > 0 ? 30.0f : 0.0f;
            break;
            
        default:
            break;
    }
    
    return height;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 9;
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
                case MTPostTableCellTypeSpentSaved:
                    rows = 0;
                    break;
                case MTPostTableCellTypeCommentText:
                    rows = 1;
                    break;
                case MTPostTableCellTypeButtons:
                    rows = 1;
                    break;
                case MTPostTableCellTypeQuadButtons:
                    rows = 1;
                    if (!self.hasTertiaryButtons) {
                        rows = 0;
                    }
                    break;
                case MTPostTableCellTypeLikeComment:
                    rows = 1;
                    break;
                case MTPostTableCellTypePostComments:
                    rows = [self.comments count];
                    break;
                case MTPostTableCellTypeLikeUsers:
                    rows = [self.likes count];
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
                case MTPostTableCellTypeSpentSaved:
                    rows = 0;
                    if (self.displaySpentView && self.hasSpentSavedContent) {
                        rows = 1;
                    }
                    break;
                case MTPostTableCellTypeCommentText:
                    rows = 1;
                    break;
                case MTPostTableCellTypeButtons:
                    rows = 1;
                    break;
                case MTPostTableCellTypeQuadButtons:
                    rows = 1;
                    if (!self.hasTertiaryButtons) {
                        rows = 0;
                    }
                    break;
                case MTPostTableCellTypeLikeComment:
                    rows = 1;
                    break;
                case MTPostTableCellTypePostComments:
                    rows = [self.comments count];
                    break;
                case MTPostTableCellTypeLikeUsers:
                    rows = [self.likes count];
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
                case MTPostTableCellTypeSpentSaved:
                    rows = 0;
                    break;
                case MTPostTableCellTypeCommentText:
                    rows = 1;
                    break;
                case MTPostTableCellTypeButtons:
                    rows = 0;
                    break;
                case MTPostTableCellTypeQuadButtons:
                    rows = 0;
                    break;
                case MTPostTableCellTypeLikeComment:
                    rows = 1;
                    break;
                case MTPostTableCellTypePostComments:
                    rows = [self.comments count];
                    break;
                case MTPostTableCellTypeLikeUsers:
                    rows = [self.likes count];
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
                case MTPostTableCellTypeSpentSaved:
                    rows = 0;
                    if (self.displaySpentView && self.hasSpentSavedContent) {
                        rows = 1;
                    }
                    break;
                case MTPostTableCellTypeCommentText:
                    rows = 1;
                    break;
                case MTPostTableCellTypeButtons:
                    rows = 0;
                    break;
                case MTPostTableCellTypeQuadButtons:
                    rows = 0;
                    break;
                case MTPostTableCellTypeLikeComment:
                    rows = 1;
                    break;
                case MTPostTableCellTypePostComments:
                    rows = [self.comments count];
                    break;
                case MTPostTableCellTypeLikeUsers:
                    rows = [self.likes count];
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

            if (self.postUser) {
                NSString *firstName = self.postUser.firstName ? self.postUser.firstName: @"";
                NSString *lastName = self.postUser.lastName ? self.postUser.lastName : @"";
                
                userInfoCell.postUsername.text = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
                
                __block MTPostUserInfoTableViewCell *weakCell = userInfoCell;
                weakCell.postUserImageView.image = [self.postUser loadAvatarImageWithSuccess:^(id responseData) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        weakCell.postUserImageView.image = responseData;
                    });
                } failure:^(NSError *error) {
                    NSLog(@"Unable to load user avatar");
                }];
            }
            else {
                userInfoCell.postUsername.text = @"";
            }
            
            userInfoCell.whenPosted.text = [self.challengePost.createdAt niceRelativeTimeFromNow];
            userInfoCell.postUserImageView.contentMode = UIViewContentModeScaleAspectFill;
            
            if ([MTUser isUserMe:self.postUser]) {
                userInfoCell.deletePost.hidden = NO;
                userInfoCell.deletePost.enabled = YES;
            }
            else {
                userInfoCell.deletePost.hidden = YES;
                userInfoCell.deletePost.enabled = NO;
            }
            
            if (self.notification) {
                userInfoCell.deletePost.hidden = YES;
                userInfoCell.deletePost.enabled = NO;
            }
            
            cell = userInfoCell;
            
            break;
        }
        case MTPostTableCellTypeImage:
        {
            MTPostImageTableViewCell *imageCell = [tableView dequeueReusableCellWithIdentifier:@"PostImageCell" forIndexPath:indexPath];
            imageCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (self.postImage) {
                CGFloat ratio = self.postImage.size.height/self.postImage.size.width;
                CGFloat height = self.tableView.frame.size.width * ratio;

                CGSize photoSize = CGSizeMake(self.tableView.frame.size.width, height);
                imageCell.postImage.image = [self imageByScalingAndCroppingForSize:photoSize withImage:self.postImage];
            }
            
            if (self.displaySpentView && self.hasSpentSavedContent) {
                imageCell.spentView.hidden = NO;
                imageCell.savedLabel.text = @"";
                imageCell.spentLabel.text = @"";

                if (!IsEmpty(self.savedAmount)) {
                    imageCell.savedLabel.text = [NSString stringWithFormat:@"Saved %@", self.savedAmount];
                }
                if (!IsEmpty(self.spentAmount)) {
                    imageCell.spentLabel.text = [NSString stringWithFormat:@"Spent %@", self.spentAmount];
                }
            }
            else {
                imageCell.spentView.hidden = YES;
            }

            cell = imageCell;

            break;
        }
        case MTPostTableCellTypeSpentSaved:
        {
            __block MTPostImageTableViewCell *imageCell = [tableView dequeueReusableCellWithIdentifier:@"SpentSavedCell" forIndexPath:indexPath];
            imageCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (self.displaySpentView && self.hasSpentSavedContent) {
                imageCell.spentView.hidden = NO;
                imageCell.savedLabel.text = @"";
                imageCell.spentLabel.text = @"";

                if (!IsEmpty(self.savedAmount)) {
                    imageCell.savedLabel.text = [NSString stringWithFormat:@"Saved %@", self.savedAmount];
                }
                if (!IsEmpty(self.spentAmount)) {
                    imageCell.spentLabel.text = [NSString stringWithFormat:@"Spent %@", self.spentAmount];
                }
            }
            else {
                imageCell.spentView.hidden = YES;
            }
            
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

            if (self.hasTertiaryButtons) {
                [self setupTertiaryButtonsForCell:buttonsCell];
            }
            else if (self.hasSecondaryButtons) {
                [self setupSecondaryButtonsForCell:buttonsCell];
            }
            else {
                [self setupButtonsForCell:buttonsCell];
            }
            cell = buttonsCell;

            break;
        }
        case MTPostTableCellTypeQuadButtons:
        {
            UITableViewCell *buttonsCell = [tableView dequeueReusableCellWithIdentifier:@"QuadButtonsCell" forIndexPath:indexPath];
            buttonsCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (self.hasTertiaryButtons) {
                [self setupTertiaryButtonsForCell:buttonsCell];
            }
            else if (self.hasSecondaryButtons) {
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
        
            if ([self.likes count] > 0) {
                likesString = [NSString stringWithFormat:@"%ld", (long)[self.likes count]];
            }
            else {
                likesString = @"0";
            }
        
            likeCommentCell.postLikes.text = likesString;
            
            likeCommentCell.likePost.enabled = YES;
            likeCommentCell.comment.enabled = YES;
        
            BOOL iLike = [MTChallengePostLike postLikesContainsMyLike:self.likes];
            if (iLike) {
                [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
                [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateDisabled];
            }
            else {
                [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
                [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateDisabled];
            }
            
            if ([MTChallengePostComment postCommentsContainsMyComment:self.comments]) {
                [likeCommentCell.comment setImage:[UIImage imageNamed:@"comment_active"] forState:UIControlStateNormal];
                [likeCommentCell.comment setImage:[UIImage imageNamed:@"comment_active"] forState:UIControlStateDisabled];
            }
            else {
                [likeCommentCell.comment setImage:[UIImage imageNamed:@"comment_normal"] forState:UIControlStateNormal];
                [likeCommentCell.comment setImage:[UIImage imageNamed:@"comment_normal"] forState:UIControlStateDisabled];
            }
            likeCommentCell.commentCount.text = [NSString stringWithFormat:@"%ld", (unsigned long)[self.comments count]];
            
            likeCommentCell.verifiedCheckBox.hidden = self.hideVerifySwitch;
            
            BOOL isChecked = self.challengePost.isVerified;
            [likeCommentCell.verifiedCheckBox setIsChecked:isChecked];

            likeCommentCell.verfiedLabel.hidden = self.hideVerifySwitch;
            if (isChecked) {
                likeCommentCell.verfiedLabel.text = @"Verified";
            }
            else {
                likeCommentCell.verfiedLabel.text = @"Verify";
            }
            
            likeCommentCell.commentPost.enabled = YES;

            [likeCommentCell.commentPost setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
            [likeCommentCell.commentPost setTitleColor:[UIColor primaryOrangeDark] forState:UIControlStateHighlighted];
            
            [MTPostsTableViewCell layoutEmojiForContainerView:likeCommentCell.emojiContainerView withEmojiArray:self.emojiArray];
            
            [self attachTapGestureRecognizerToCell:likeCommentCell];

            cell = likeCommentCell;
            
            break;
        }
        case MTPostTableCellTypePostComments:
        {
            MTPostCommentItemsTableViewCell *defaultCell = [tableView dequeueReusableCellWithIdentifier:@"PostCommentItemsCell" forIndexPath:indexPath];
            defaultCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            MTChallengePostComment *comment = self.comments[indexPath.row];
            defaultCell.comment = comment;
            
            defaultCell.commentLabel.text = comment.content;
            [defaultCell.commentLabel setFont:[UIFont mtFontOfSize:13.0f]];
            defaultCell.commentLabel.textColor = [UIColor darkGrey];
            
            MTUser *commentPoster = comment.user;
            NSString *detailString = [NSString stringWithFormat:@"%@ %@:", commentPoster.firstName, commentPoster.lastName];
            defaultCell.userLabel.text = detailString;
            [defaultCell.userLabel setFont:[UIFont mtBoldFontOfSize:11.0f]];
            defaultCell.userLabel.textColor = [UIColor darkGrey];
            
            [defaultCell setAccessoryType:UITableViewCellAccessoryNone];
            defaultCell.pickerImageView.hidden = ![MTUser isUserMe:commentPoster];
            
            // If last row and has likes, don't show separator
            if ((indexPath.row == [self.comments count]-1) && !IsEmpty(self.likes)) {
                defaultCell.separatorView.hidden = YES;
            }
            else {
                defaultCell.separatorView.hidden = NO;
            }
            
            defaultCell.userAvatarImageView.contentMode = UIViewContentModeScaleAspectFill;
            
            __block MTPostCommentItemsTableViewCell *weakCell = defaultCell;
            weakCell.userAvatarImageView.image = [commentPoster loadAvatarImageWithSuccess:^(id responseData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakCell.userAvatarImageView.image = responseData;
                });
            } failure:^(NSError *error) {
                NSLog(@"Unable to load user avatar");
            }];
            
            cell = defaultCell;
            
            break;
        }
        case MTPostTableCellTypeLikeUsers:
        {
            __block MTPostLikeUserTableViewCell *likeUserCell = [tableView dequeueReusableCellWithIdentifier:@"LikeUserCell" forIndexPath:indexPath];
            likeUserCell.selectionStyle = UITableViewCellSelectionStyleGray;
            
            MTChallengePostLike *like = self.likes[indexPath.row];
            MTUser *likeUser = like.user;
            
            [likeUserCell setAccessoryType:UITableViewCellAccessoryNone];
            
            NSString *firstName = likeUser.firstName;
            NSString *lastName = likeUser.lastName;
            
            likeUserCell.username.text = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            likeUserCell.userAvatarImageView.contentMode = UIViewContentModeScaleAspectFill;
            
            __block MTPostLikeUserTableViewCell *weakCell = likeUserCell;
            weakCell.userAvatarImageView.image = [likeUser loadAvatarImageWithSuccess:^(id responseData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakCell.userAvatarImageView.image = responseData;
                });
            } failure:^(NSError *error) {
                NSLog(@"Unable to load user avatar");
            }];
            
            // Load Emoji like for this user
            if ([self.likes count] > indexPath.row) {
                MTChallengePostLike *thisLiked = [self.likes objectAtIndex:indexPath.row];
                MTEmoji *thisEmoji = thisLiked.emoji;
                
                if (thisEmoji && thisEmoji.emojiImage.imageData) {
                    likeUserCell.emojiView.image = [UIImage imageWithData:thisEmoji.emojiImage.imageData];
                }
                else {
                    likeUserCell.emojiView.image = nil;
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
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == MTPostTableCellTypeLikeUsers) {
        MTChallengePostLike *like = self.likes[indexPath.row];
        MTUser *likeUser = like.user;
        [self performSegueWithIdentifier:@"postDetailStudentProfileView" sender:likeUser];
    }
    else if (indexPath.section == MTPostTableCellTypePostComments) {
        MTPostCommentItemsTableViewCell *cell = (MTPostCommentItemsTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
        if ([MTUser isUserMe:cell.comment.user]) {
            [self editDeleteCommentTapped:cell];
        }
    }
}

- (IBAction)unwindToPostView:(UIStoryboardSegue *)sender
{
}


#pragma mark - MBProgressHUDDelegate Methods -
- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self secondaryButton1AfterToastAction];
}


#pragma mark - NSNotification Methods -
- (void)willSaveNewPostComment:(NSNotification *)notif
{
}

- (void)didSaveNewPostComment:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.savingEdit = NO;
        [self loadCommentsOnlyDatabase:YES];
        [self.tableView reloadData];
    });
}

- (void)didDeletePostComment:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        [self loadCommentsOnlyDatabase:YES];
        [self.tableView reloadData];
    });
}

- (void)willSaveEditPost:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.savingEdit = YES;
        [self updateViewForEditedPost];
    });
}

- (void)didSaveEditPost:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.savingEdit = NO;
        [self updateViewForEditedPost];
    });
}

- (void)updateViewForEditedPost
{
    NSNumber *postId = [NSNumber numberWithInteger:self.challengePostId];
    MTChallengePost *editedPost = [MTChallengePost objectForPrimaryKey:postId];
    
    if (editedPost) {
        self.challengePost = editedPost;
        if (self.displaySpentView) {
            [self parseSpentFields];
        }
        [self loadPostText];
        [self loadPostImage];
    }
    
    BOOL myPost = NO;
    if ([MTUser isUserMe:self.postUser]) {
        myPost = YES;
    }
    
    BOOL showButtons = NO;
    if (self.hasButtons || (self.hasSecondaryButtons && myPost) || self.hasTertiaryButtons) {
        showButtons = YES;
    }
    
    if (showButtons && self.challengePost.hasPostImage)
        self.postType = MTPostTypeWithButtonsWithImage;
    else if (showButtons)
        self.postType = MTPostTypeWithButtonsNoImage;
    else if (self.challengePost.hasPostImage)
        self.postType = MTPostTypeNoButtonsWithImage;
    else
        self.postType = MTPostTypeNoButtonsNoImage;
    
    [self.tableView reloadData];
}

- (void)failedSaveEditPost:(NSNotification *)notif
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.savingEdit = NO;

        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Your edit post failed to save.";
        hud.dimBackground = NO;
        hud.mode = MBProgressHUDModeText;
        [hud hide:YES afterDelay:1.5f];
        
        [self updateViewForEditedPost];
    });
}

- (void)willSaveEditPostComment:(NSNotification *)notif
{
    MTMakeWeakSelf();
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.savingEdit = YES;
        [weakSelf loadCommentsOnlyDatabase:YES];
        [weakSelf updateViewForEditedPost];
    });
}

- (void)commentEditFailed
{
    MTMakeWeakSelf();
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.savingEdit = NO;
        [weakSelf loadCommentsOnlyDatabase:YES];
        [weakSelf updateViewForEditedPost];
    });
}

- (void)attachTapGestureRecognizerToCell:(MTPostsTableViewCell *)cell
{
    if (self.verifiedTapGestureRecognizer && self.verifiedTapGestureRecognizer.view) {
        [self.verifiedTapGestureRecognizer.view removeGestureRecognizer:self.verifiedTapGestureRecognizer];
        self.verifiedTapGestureRecognizer = nil;
    }
    
    UITapGestureRecognizer *recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(verifiedTapped:)];
    recognizer.numberOfTapsRequired = 1;
    recognizer.numberOfTouchesRequired = 1;
    cell.verfiedLabel.userInteractionEnabled = YES;
    [cell.verfiedLabel addGestureRecognizer:recognizer];
    [recognizer setCancelsTouchesInView:YES];
    self.verifiedTapGestureRecognizer = recognizer;
}

@end
