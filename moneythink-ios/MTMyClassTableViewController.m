//
//  MTMyClassTableViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 8/4/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMyClassTableViewController.h"
#import "MTPostsTableViewCell.h"
#import "MTCommentViewController.h"
#import "MTEmojiPickerCollectionView.h"

NSString *const kWillSaveNewChallengePostNotification = @"kWillSaveNewChallengePostNotification";
NSString *const kSavingWithPhotoNewChallengePostNotification = @"kSavingWithPhotoNewChallengePostNotification";
NSString *const kSavedMyClassChallengePostsdNotification = @"kSavedMyClassChallengePostsdNotification";
NSString *const kFailedMyClassChallengePostsdNotification = @"kFailedMyClassChallengePostsdNotification";
NSString *const kWillSaveNewPostCommentNotification = @"kWillSaveNewPostCommentNotification";
NSString *const kDidSaveNewPostCommentNotification = @"kDidSaveNewPostCommentNotification";
NSString *const kWillSaveEditPostNotification = @"kWillSaveEditPostNotification";
NSString *const kDidSaveEditPostNotification = @"kDidSaveEditPostNotification";
NSString *const kFailedSaveEditPostNotification = @"kFailedSaveEditPostNotification";

@interface MTMyClassTableViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic) BOOL hasButtons;
@property (nonatomic) BOOL hasSecondaryButtons;
@property (nonatomic) BOOL hasTertiaryButtons;
@property (nonatomic) BOOL isMentor;
@property (nonatomic, strong) NSArray *postsLiked;
@property (nonatomic, strong) NSArray *postsLikedFull;
@property (nonatomic, strong) NSDictionary *buttonsTapped;
@property (nonatomic, strong) NSDictionary *secondaryButtonsTapped;
@property (nonatomic) BOOL iLike;
@property (nonatomic, strong) NSMutableArray *myObjects;
@property (nonatomic) BOOL deletingPost;
@property (nonatomic, strong) UIImage *postImage;
@property (nonatomic, strong) UIButton *secondaryButton1;
@property (nonatomic, strong) UIButton *secondaryButton2;
@property (nonatomic) BOOL didUpdateLikedPosts;
@property (nonatomic) BOOL updatedButtonsAndLikes;
@property (nonatomic, strong) MTEmojiPickerCollectionView *emojiCollectionView;
@property (nonatomic, strong) UIView *emojiDimView;
@property (nonatomic, strong) UIView *emojiContainerView;

@end

@implementation MTMyClassTableViewController

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // The className to query on
        self.parseClassName = [PFChallengePost parseClassName];
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = @"post_text";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
    }
    
    return self;
}


#pragma mark - Lifecycle -
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveNewChallengePost:) name:kWillSaveNewChallengePostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(savingWithPhoto:) name:kSavingWithPhotoNewChallengePostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postSucceeded) name:kSavedMyClassChallengePostsdNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postFailed) name:kFailedMyClassChallengePostsdNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveNewPostComment:) name:kWillSaveNewPostCommentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSaveNewPostComment:) name:kDidSaveNewPostCommentNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willSaveEditPost:) name:kWillSaveEditPostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSaveEditPost:) name:kDidSaveEditPostNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedSaveEditPost:) name:kFailedSaveEditPostNotification object:nil];

    self.didUpdateLikedPosts = NO;
    self.updatedButtonsAndLikes = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = @"My Class";
    self.isMentor = [[PFUser currentUser][@"type"] isEqualToString:@"mentor"];
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


#pragma mark - Parse -
- (void)objectsDidLoad:(NSError *)error
{
    [super objectsDidLoad:error];
    
    if (self.updatedButtonsAndLikes) {
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
    }
    
    self.myObjects = [NSMutableArray arrayWithArray:self.objects];
    [self.tableView reloadData];
}

// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable
{
    self.className = [PFUser currentUser][@"class"];
    
    NSPredicate *challengePostQuery = [NSPredicate predicateWithFormat:@"challenge = %@ AND class = %@",
                                    self.challenge, self.className];
    
    if (self.challengeNumber) {
        NSInteger challengeNumberInt = [self.challengeNumber intValue];
        challengePostQuery = [NSPredicate predicateWithFormat:@"(challenge = %@ OR challenge_number = %d) AND class = %@",
                                        self.challenge, challengeNumberInt, self.className];
    }
    
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName predicate:challengePostQuery];
    [query orderByDescending:@"createdAt"];
    
    [query includeKey:@"user"];
    [query includeKey:@"reference_post"];

    query.cachePolicy = kPFCachePolicyNetworkElseCache;

    return query;
}


#pragma mark - Public -
- (void)setChallenge:(PFChallenges *)challenge
{
    if (_challenge != challenge) {
        _challenge = challenge;
        
        self.myObjects = nil;
        self.didUpdateLikedPosts = NO;
        self.updatedButtonsAndLikes = NO;

        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        [self.tableView reloadData];
        
        [self updateButtonsAndLikes];
    }
}

- (void)didSelectLikeWithEmojiForPost:(PFChallengePost *)post
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
    
    // Sort by name, so consistent in presentation
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"emoji_order" ascending:YES];
    NSArray *sortedEmojiArray = [self.emojiObjects sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    self.emojiCollectionView.emojiObjects = sortedEmojiArray;
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
    [dismissButton addTarget:self action:@selector(dismissEmojiPrompt) forControlEvents:UIControlEventTouchUpInside];
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf loadObjects];
            });

        } else {
            NSLog(@"Error - %@", error);
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
                weakSelf.secondaryButton1.enabled = YES;
                [weakSelf loadObjects];
            });
            
        } else {
            NSLog(@"Error - %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.secondaryButton1.enabled = YES;
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            });
        }
    }];
}


#pragma mark - NSNotification Methods -
- (void)willSaveNewChallengePost:(NSNotification *)notif
{
    PFChallengePost *newPost = notif.object;
    [self.myObjects insertObject:newPost atIndex:0];
    
    [self.tableView reloadData];
}

- (void)savingWithPhoto:(NSNotificationCenter *)notif
{
    [self.tableView reloadData];
}

- (void)postSucceeded
{
    [self loadObjects];
}

- (void)postFailed
{
    [self loadObjects];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Your post failed to upload.";
    hud.dimBackground = NO;
    hud.mode = MBProgressHUDModeText;
    [hud hide:YES afterDelay:1.5f];
}

- (void)willSaveNewPostComment:(NSNotification *)notif
{
    [self.tableView reloadData];
}

- (void)didSaveNewPostComment:(NSNotification *)notif
{
    [self.tableView reloadData];
}

- (void)willSaveEditPost:(NSNotification *)notif
{
    [self.tableView reloadData];
}

- (void)didSaveEditPost:(NSNotification *)notif
{
    [self loadObjects];
}

- (void)failedSaveEditPost:(NSNotification *)notif
{
    [self loadObjects];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Your edit post failed to save.";
    hud.dimBackground = NO;
    hud.mode = MBProgressHUDModeText;
    [hud hide:YES afterDelay:1.5f];
}


#pragma mark - Private -
- (void)configureButtonsForCell:(MTPostsTableViewCell *)cell
{
    id buttonID = [self.buttonsTapped valueForKey:[cell.post objectId]];
    NSInteger button = 0;
    if (buttonID) {
        button = [buttonID intValue];
    }
    
    [self resetButtonsForCell:cell];

    [cell.button1 layer].masksToBounds = YES;
    [cell.button2 layer].masksToBounds = YES;

    if ((button == 0) && buttonID) {
        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:cell.button1.frame.size] forState:UIControlStateNormal];
        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:cell.button1.frame.size] forState:UIControlStateHighlighted];

        [cell.button1 setTintColor:[UIColor white]];
        [cell.button1 setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [cell.button1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];

        [[cell.button2 layer] setBorderWidth:2.0f];
        [[cell.button2 layer] setBorderColor:[UIColor redOrange].CGColor];
        [cell.button2 setTintColor:[UIColor redOrange]];
        [cell.button2 setTitleColor:[UIColor redOrange] forState:UIControlStateNormal];
        [cell.button2 setTitleColor:[UIColor lightRedOrange] forState:UIControlStateHighlighted];
        
        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateNormal];
        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
    }
    else if (button == 1) {
        [[cell.button1 layer] setBorderWidth:2.0f];
        [[cell.button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
        [cell.button1 setTintColor:[UIColor primaryGreen]];
        [cell.button1 setTitleColor:[UIColor primaryGreen] forState:UIControlStateNormal];
        [cell.button1 setTitleColor:[UIColor lightGreen] forState:UIControlStateHighlighted];

        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateNormal];
        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
        
        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor redOrange] size:cell.button2.frame.size] forState:UIControlStateNormal];
        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor redOrange] size:cell.button2.frame.size] forState:UIControlStateHighlighted];

        [cell.button2 setTintColor:[UIColor white]];
        [cell.button2 setTitleColor:[UIColor white] forState:UIControlStateNormal];
        [cell.button2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    }
    else {
        [[cell.button1 layer] setBorderWidth:2.0f];
        [[cell.button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
        [cell.button1 setTintColor:[UIColor primaryGreen]];
        [cell.button1 setTitleColor:[UIColor primaryGreen] forState:UIControlStateNormal];
        [cell.button1 setTitleColor:[UIColor lightGreen] forState:UIControlStateHighlighted];

        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateNormal];
        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateHighlighted];

        [[cell.button2 layer] setBorderWidth:2.0f];
        [[cell.button2 layer] setBorderColor:[UIColor redOrange].CGColor];
        [cell.button2 setTintColor:[UIColor redOrange]];
        [cell.button2 setTitleColor:[UIColor redOrange] forState:UIControlStateNormal];
        [cell.button2 setTitleColor:[UIColor lightRedOrange] forState:UIControlStateHighlighted];

        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateNormal];
        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
    }
    
    [[cell.button1 layer] setCornerRadius:5.0f];
    [[cell.button2 layer] setCornerRadius:5.0f];
    
    [cell.button1 addTarget:self action:@selector(button1Tapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button2 addTarget:self action:@selector(button2Tapped:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray *buttonTitles = self.challenge[@"buttons"];
    NSArray *buttonsClicked = cell.post[@"buttons_clicked"];
    
    if (buttonTitles.count > 0) {
        NSString *button1Title;
        NSString *button2Title;
        
        if (buttonsClicked.count > 0) {
            button1Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[0], buttonsClicked[0]];
        }
        else {
            button1Title = [NSString stringWithFormat:@"%@ (0)", buttonTitles[0]];
        }
        
        if (buttonsClicked.count > 1) {
            button2Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[1], buttonsClicked[1]];
        }
        else {
            button2Title = [NSString stringWithFormat:@"%@ (0)", buttonTitles[1]];
        }
        
        [cell.button1 setTitle:button1Title forState:UIControlStateNormal];
        [cell.button2 setTitle:button2Title forState:UIControlStateNormal];
    }
}

- (void)configureSecondaryButtonsForCell:(MTPostsTableViewCell *)cell
{
    PFChallengePost *post = cell.post;
    NSDictionary *buttonDict = [self.secondaryButtonsTapped objectForKey:post.objectId];
    
    NSInteger button1Count = [[buttonDict objectForKey:@0] integerValue];
    NSInteger button2Count = [[buttonDict objectForKey:@1] integerValue];
    
    [self resetButtonsForCell:cell];
    
    // Configure Button 1
    [[cell.button1 layer] setBackgroundColor:[UIColor whiteColor].CGColor];
    [[cell.button1 layer] setBorderWidth:1.0f];
    [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor] size:cell.button1.frame.size] forState:UIControlStateNormal];
    [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
    [[cell.button1 layer] setCornerRadius:5.0f];
    [cell.button1 setImage:[UIImage imageNamed:@"icon_button_dollar_normal"] forState:UIControlStateNormal];
    [cell.button1 setImage:[UIImage imageNamed:@"icon_button_dollar_pressed"] forState:UIControlStateHighlighted];
    [cell.button1 setTitleColor:[UIColor white] forState:UIControlStateHighlighted];

    cell.button1.titleEdgeInsets = UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 0.0f);
    [cell.button1 layer].masksToBounds = YES;
    
    if (button1Count > 0) {
        [cell.button1 setTitle:[NSString stringWithFormat:@"%ld", (long)button1Count] forState:UIControlStateNormal];
    }
    else {
        [cell.button1 setTitle:@"" forState:UIControlStateNormal];
    }

    [cell.button1 addTarget:self action:@selector(secondaryButton1Tapped:) forControlEvents:UIControlEventTouchUpInside];

    // Configure Button 2
    [[cell.button2 layer] setBorderColor:[UIColor darkGrayColor].CGColor];
    [[cell.button2 layer] setBackgroundColor:[UIColor whiteColor].CGColor];
    [[cell.button2 layer] setBorderWidth:1.0f];
    [[cell.button2 layer] setCornerRadius:5.0f];
    [cell.button2 setTitle:@"" forState:UIControlStateNormal];
    [cell.button2 layer].masksToBounds = YES;

    if (button2Count > 0) {
        cell.button1.enabled = NO;
        [[cell.button1 layer] setBorderColor:[UIColor lightGrayColor].CGColor];
        [cell.button1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];

        [cell.button2 setImage:[UIImage imageNamed:@"icon_button_check_pressed"] forState:UIControlStateNormal];
        [cell.button2 setImage:[UIImage imageNamed:@"icon_button_check_normal"] forState:UIControlStateHighlighted];

        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:cell.button2.frame.size] forState:UIControlStateNormal];
        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreenDark] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
    }
    else {
        cell.button1.enabled = YES;
        [[cell.button1 layer] setBorderColor:[UIColor darkGrayColor].CGColor];
        [cell.button1 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [cell.button1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];

        [cell.button2 setImage:[UIImage imageNamed:@"icon_button_check_normal"] forState:UIControlStateNormal];
        [cell.button2 setImage:[UIImage imageNamed:@"icon_button_check_pressed"] forState:UIControlStateHighlighted];

        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor] size:cell.button2.frame.size] forState:UIControlStateNormal];
        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
    }
    
    [cell.button2 addTarget:self action:@selector(secondaryButton2Tapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)configureTertiaryButtonsForCell:(MTPostsTableViewCell *)cell
{
    id buttonID = [self.buttonsTapped valueForKey:[cell.post objectId]];
    NSInteger button = 0;
    if (buttonID) {
        button = [buttonID intValue];
    }
    
    [self resetButtonsForCell:cell];
    
    [cell.button1 layer].masksToBounds = YES;
    [cell.button2 layer].masksToBounds = YES;
    [cell.button3 layer].masksToBounds = YES;
    [cell.button4 layer].masksToBounds = YES;

    if (!buttonID) {
        [[cell.button1 layer] setBorderWidth:2.0f];
        [[cell.button1 layer] setBorderColor:[UIColor votingRed].CGColor];
        [cell.button1 setTintColor:[UIColor votingRed]];
        [cell.button1 setTitleColor:[UIColor votingRed] forState:UIControlStateNormal];
        [cell.button1 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateNormal];
        [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
        
        [[cell.button2 layer] setBorderWidth:2.0f];
        [[cell.button2 layer] setBorderColor:[UIColor votingPurple].CGColor];
        [cell.button2 setTintColor:[UIColor votingPurple]];
        [cell.button2 setTitleColor:[UIColor votingPurple] forState:UIControlStateNormal];
        [cell.button2 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateNormal];
        [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
        
        [[cell.button3 layer] setBorderWidth:2.0f];
        [[cell.button3 layer] setBorderColor:[UIColor votingBlue].CGColor];
        [cell.button3 setTintColor:[UIColor votingBlue]];
        [cell.button3 setTitleColor:[UIColor votingBlue] forState:UIControlStateNormal];
        [cell.button3 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateNormal];
        [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateHighlighted];
        
        [[cell.button4 layer] setBorderWidth:2.0f];
        [[cell.button4 layer] setBorderColor:[UIColor votingGreen].CGColor];
        [cell.button4 setTintColor:[UIColor votingGreen]];
        [cell.button4 setTitleColor:[UIColor votingGreen] forState:UIControlStateNormal];
        [cell.button4 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateNormal];
        [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateHighlighted];
    }
    else {
        if (button == 0) {
            // Selected
            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor votingRed] size:cell.button1.frame.size] forState:UIControlStateNormal];
            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor votingRed] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
            [cell.button1 setTintColor:[UIColor white]];
            [cell.button1 setTitleColor:[UIColor white] forState:UIControlStateNormal];
            [cell.button1 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
            
            [[cell.button2 layer] setBorderWidth:2.0f];
            [[cell.button2 layer] setBorderColor:[UIColor votingPurple].CGColor];
            [cell.button2 setTintColor:[UIColor votingPurple]];
            [cell.button2 setTitleColor:[UIColor votingPurple] forState:UIControlStateNormal];
            [cell.button2 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateNormal];
            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
            
            [[cell.button3 layer] setBorderWidth:2.0f];
            [[cell.button3 layer] setBorderColor:[UIColor votingBlue].CGColor];
            [cell.button3 setTintColor:[UIColor votingBlue]];
            [cell.button3 setTitleColor:[UIColor votingBlue] forState:UIControlStateNormal];
            [cell.button3 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateNormal];
            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateHighlighted];
            
            [[cell.button4 layer] setBorderWidth:2.0f];
            [[cell.button4 layer] setBorderColor:[UIColor votingGreen].CGColor];
            [cell.button4 setTintColor:[UIColor votingGreen]];
            [cell.button4 setTitleColor:[UIColor votingGreen] forState:UIControlStateNormal];
            [cell.button4 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateNormal];
            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateHighlighted];
        }
        else if (button == 1) {
            [[cell.button1 layer] setBorderWidth:2.0f];
            [[cell.button1 layer] setBorderColor:[UIColor votingRed].CGColor];
            [cell.button1 setTintColor:[UIColor votingRed]];
            [cell.button1 setTitleColor:[UIColor votingRed] forState:UIControlStateNormal];
            [cell.button1 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateNormal];
            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
            
            // Selected
            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor votingPurple] size:cell.button2.frame.size] forState:UIControlStateNormal];
            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor votingPurple] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
            [cell.button2 setTintColor:[UIColor white]];
            [cell.button2 setTitleColor:[UIColor white] forState:UIControlStateNormal];
            [cell.button2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
            
            [[cell.button3 layer] setBorderWidth:2.0f];
            [[cell.button3 layer] setBorderColor:[UIColor votingBlue].CGColor];
            [cell.button3 setTintColor:[UIColor votingBlue]];
            [cell.button3 setTitleColor:[UIColor votingBlue] forState:UIControlStateNormal];
            [cell.button3 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateNormal];
            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateHighlighted];
            
            [[cell.button4 layer] setBorderWidth:2.0f];
            [[cell.button4 layer] setBorderColor:[UIColor votingGreen].CGColor];
            [cell.button4 setTintColor:[UIColor votingGreen]];
            [cell.button4 setTitleColor:[UIColor votingGreen] forState:UIControlStateNormal];
            [cell.button4 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateNormal];
            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateHighlighted];
        }
        else if (button == 2) {
            [[cell.button1 layer] setBorderWidth:2.0f];
            [[cell.button1 layer] setBorderColor:[UIColor votingRed].CGColor];
            [cell.button1 setTintColor:[UIColor votingRed]];
            [cell.button1 setTitleColor:[UIColor votingRed] forState:UIControlStateNormal];
            [cell.button1 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateNormal];
            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
            
            [[cell.button2 layer] setBorderWidth:2.0f];
            [[cell.button2 layer] setBorderColor:[UIColor votingPurple].CGColor];
            [cell.button2 setTintColor:[UIColor votingPurple]];
            [cell.button2 setTitleColor:[UIColor votingPurple] forState:UIControlStateNormal];
            [cell.button2 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateNormal];
            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateHighlighted];
            
            // Selected
            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor votingBlue] size:cell.button3.frame.size] forState:UIControlStateNormal];
            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor votingBlue] size:cell.button3.frame.size] forState:UIControlStateHighlighted];
            [cell.button3 setTintColor:[UIColor white]];
            [cell.button3 setTitleColor:[UIColor white] forState:UIControlStateNormal];
            [cell.button3 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
            
            [[cell.button4 layer] setBorderWidth:2.0f];
            [[cell.button4 layer] setBorderColor:[UIColor votingGreen].CGColor];
            [cell.button4 setTintColor:[UIColor votingGreen]];
            [cell.button4 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
            [cell.button4 setTitleColor:[UIColor votingGreen] forState:UIControlStateHighlighted];
            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateNormal];
            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button4.frame.size] forState:UIControlStateHighlighted];
        }
        else if (button == 3) {
            [[cell.button1 layer] setBorderWidth:2.0f];
            [[cell.button1 layer] setBorderColor:[UIColor votingRed].CGColor];
            [cell.button1 setTintColor:[UIColor votingRed]];
            [cell.button1 setTitleColor:[UIColor votingRed] forState:UIControlStateNormal];
            [cell.button1 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateNormal];
            [cell.button1 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button1.frame.size] forState:UIControlStateHighlighted];
            
            [[cell.button2 layer] setBorderWidth:2.0f];
            [[cell.button2 layer] setBorderColor:[UIColor votingPurple].CGColor];
            [cell.button2 setTintColor:[UIColor votingPurple]];
            [cell.button2 setTitleColor:[UIColor votingPurple] forState:UIControlStateNormal];
            [cell.button2 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateNormal];
            [cell.button2 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button2.frame.size] forState:UIControlStateHighlighted];

            [[cell.button3 layer] setBorderWidth:2.0f];
            [[cell.button3 layer] setBorderColor:[UIColor votingBlue].CGColor];
            [cell.button3 setTintColor:[UIColor votingBlue]];
            [cell.button3 setTitleColor:[UIColor votingBlue] forState:UIControlStateNormal];
            [cell.button3 setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateNormal];
            [cell.button3 setBackgroundImage:[UIImage imageWithColor:[UIColor white] size:cell.button3.frame.size] forState:UIControlStateHighlighted];
            
            // Selected
            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor votingGreen] size:cell.button4.frame.size] forState:UIControlStateNormal];
            [cell.button4 setBackgroundImage:[UIImage imageWithColor:[UIColor votingGreen] size:cell.button4.frame.size] forState:UIControlStateHighlighted];
            [cell.button4 setTintColor:[UIColor white]];
            [cell.button4 setTitleColor:[UIColor white] forState:UIControlStateNormal];
            [cell.button4 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        }
    }
    
    [[cell.button1 layer] setCornerRadius:5.0f];
    [[cell.button2 layer] setCornerRadius:5.0f];
    [[cell.button3 layer] setCornerRadius:5.0f];
    [[cell.button4 layer] setCornerRadius:5.0f];
    
    [cell.button1 addTarget:self action:@selector(button1Tapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button2 addTarget:self action:@selector(button2Tapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button3 addTarget:self action:@selector(button3Tapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button4 addTarget:self action:@selector(button4Tapped:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray *buttonTitles = self.challenge[@"buttons"];
    NSArray *buttonsClicked = cell.post[@"buttons_clicked"];
    
    if (buttonTitles.count == 4) {
        NSString *button1Title;
        NSString *button2Title;
        NSString *button3Title;
        NSString *button4Title;
        
        if (buttonsClicked.count > 0 && [buttonsClicked[0] intValue] > 0) {
            button1Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[0], buttonsClicked[0]];
        }
        else {
            button1Title = [NSString stringWithFormat:@"%@", buttonTitles[0]];
        }
        
        if (buttonsClicked.count > 1 && [buttonsClicked[1] intValue] > 0) {
            button2Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[1], buttonsClicked[1]];
        }
        else {
            button2Title = [NSString stringWithFormat:@"%@", buttonTitles[1]];
        }

        if (buttonsClicked.count > 2 && [buttonsClicked[2] intValue] > 0) {
            button3Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[2], buttonsClicked[2]];
        }
        else {
            button3Title = [NSString stringWithFormat:@"%@", buttonTitles[2]];
        }

        if (buttonsClicked.count > 3 && [buttonsClicked[3] intValue] > 0) {
            button4Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[3], buttonsClicked[3]];
        }
        else {
            button4Title = [NSString stringWithFormat:@"%@", buttonTitles[3]];
        }

        [cell.button1 setTitle:button1Title forState:UIControlStateNormal];
        [cell.button2 setTitle:button2Title forState:UIControlStateNormal];
        [cell.button3 setTitle:button3Title forState:UIControlStateNormal];
        [cell.button4 setTitle:button4Title forState:UIControlStateNormal];
    }
    
    [cell.button1.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [cell.button2.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
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

    [cell.button2.titleLabel setFont:[UIFont systemFontOfSize:18.0f]];
    [cell.button2 setImage:nil forState:UIControlStateNormal];
    [cell.button2 setImage:nil forState:UIControlStateHighlighted];
    [cell.button2 setBackgroundImage:nil forState:UIControlStateNormal];
    [cell.button2 setBackgroundImage:nil forState:UIControlStateHighlighted];
    
    [cell.button3.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [cell.button3 setImage:nil forState:UIControlStateNormal];
    [cell.button3 setImage:nil forState:UIControlStateHighlighted];
    [cell.button3 setBackgroundImage:nil forState:UIControlStateNormal];
    [cell.button3 setBackgroundImage:nil forState:UIControlStateHighlighted];

    [cell.button4.titleLabel setFont:[UIFont systemFontOfSize:14.0f]];
    [cell.button4 setImage:nil forState:UIControlStateNormal];
    [cell.button4 setImage:nil forState:UIControlStateHighlighted];
    [cell.button4 setBackgroundImage:nil forState:UIControlStateNormal];
    [cell.button4 setBackgroundImage:nil forState:UIControlStateHighlighted];

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
    if (![shownArray containsObject:self.challenge.objectId]) {
        
        // If not added for this install but we have a title, no need to show this again
        if (!IsEmpty([self.secondaryButton1 titleForState:UIControlStateNormal])) {
            NSMutableArray *mutant = [NSMutableArray arrayWithArray:shownArray];
            [mutant addObject:self.challenge.objectId];
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
            [mutant addObject:self.challenge.objectId];
            [[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithArray:mutant] forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    else {
        [self secondaryButton1AfterToastAction];
    }
}

- (void)updateButtonsAndLikes
{
    NSInteger hiddenCount = [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
    BOOL animated = hiddenCount > 0 ? NO : YES;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:animated];
    hud.labelText = @"Loading Challenge Data...";
    hud.dimBackground = YES;

    // Call updateButtons first which will then call updateLikes when done
    [self performSelector:@selector(updateButtons) withObject:nil afterDelay:0.3f];
}

- (void)updateButtons
{
    NSPredicate *thisChallenge = [NSPredicate predicateWithFormat:@"objectId = %@", self.challenge.objectId];
    PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:thisChallenge];
    [challengeQuery includeKey:@"verified_by"];
    challengeQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    MTMakeWeakSelf();
    [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            PFChallenges *challenge = (PFChallenges *)[objects firstObject];
            if (![[weakSelf.challenge objectId] isEqualToString:[challenge objectId]]) {
                weakSelf.challenge = challenge;
            }
            
            NSArray *buttons = challenge[@"buttons"];
            NSArray *secondaryButtons = challenge[@"secondary_buttons"];
            
            weakSelf.hasButtons = NO;
            weakSelf.hasSecondaryButtons = NO;
            weakSelf.hasTertiaryButtons = NO;
            
            if (!IsEmpty(buttons) && [buttons firstObject] != [NSNull null]) {
                if ([buttons count] == 4) {
                    weakSelf.hasTertiaryButtons = YES;
                }
                else {
                    weakSelf.hasButtons = YES;
                }
                
                [weakSelf userButtonsTapped];
            }
            else if (!IsEmpty(secondaryButtons) && ([secondaryButtons firstObject] != [NSNull null]) && !self.isMentor) {
                weakSelf.hasSecondaryButtons = YES;
                [weakSelf updateSecondaryButtonsTapped];
            }
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf updateLikes];
        });
    }];
}

- (void)updateLikes
{
    MTMakeWeakSelf();
    NSPredicate *myLikesPredicate = [NSPredicate predicateWithFormat:@"user = %@", [PFUser currentUser]];
    PFQuery *myLikesQuery = [PFQuery queryWithClassName:[PFChallengePostsLiked parseClassName] predicate:myLikesPredicate];
    [myLikesQuery selectKeys:[NSArray arrayWithObjects:@"post", @"emoji", nil]];
    
    if (self.didUpdateLikedPosts) {
        myLikesQuery.cachePolicy = kPFCachePolicyNetworkOnly;
        self.didUpdateLikedPosts = NO;
        [self.tableView reloadData];
    }
    else {
        myLikesQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
    }
    
    [myLikesQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableArray *mutableLiked = [NSMutableArray array];
            NSMutableArray *mutableLikedFull = [NSMutableArray array];

            for (PFChallengePostsLiked *thisPostLiked in objects) {
                PFChallengePost *post = thisPostLiked[@"post"];
                if (!IsEmpty(post.objectId)) {
                    [mutableLiked addObject:post.objectId];
                    [mutableLikedFull addObject:thisPostLiked];
                }
            }
            
            weakSelf.postsLiked = [NSArray arrayWithArray:mutableLiked];
            weakSelf.postsLikedFull = [NSArray arrayWithArray:mutableLikedFull];
        }
        
        weakSelf.updatedButtonsAndLikes = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf loadObjects];
        });
    }];
}

- (void)likeWithEmojiPrompt:(id)sender
{
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[sender findSuperViewWithClass:[MTPostsTableViewCell class]];
    PFChallengePost *post = cell.post;
    
    [self didSelectLikeWithEmojiForPost:post];
}

- (void)loadLikesForPost:(PFChallengePost *)post withCell:(MTPostsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (![cell.post.objectId isEqualToString:post.objectId]) {
        return;
    }
    
    PFQuery *queryPostEmojis = [PFQuery queryWithClassName:[PFChallengePostsLiked parseClassName]];
    [queryPostEmojis whereKey:@"post" equalTo:post];
    [queryPostEmojis includeKey:@"emoji"];
    queryPostEmojis.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    [queryPostEmojis findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            NSMutableArray *emojiArray = [NSMutableArray array];
            for (PFChallengePostsLiked *thisLike in objects) {
                PFEmoji *thisEmoji = thisLike[@"emoji"];
                if (thisEmoji) {
                    [emojiArray addObject:thisEmoji];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                cell.emojiArray = emojiArray;
            });
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (void)dismissEmojiPrompt
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
        }];
    }];
}


#pragma mark - MBProgressHUDDelegate Methods -
- (void)hudWasHidden:(MBProgressHUD *)hud
{
    [self secondaryButton1AfterToastAction];
}


#pragma mark - UITableViewDataSource methods -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.myObjects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Override to use self.myObjects in below method.  Otherwise, crashes because
    //  the PFQueryTableViewController gets called and can't find the object when
    //  adding a new item.
    return [self tableView:tableView cellForRowAtIndexPath:indexPath object:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object
{
    __block PFChallengePost *post = (PFChallengePost *)[self.myObjects objectAtIndex:indexPath.row];

    PFUser *user = post[@"user"];
    NSString *CellIdentifier = @"";
    PFFile *postImage = post[@"picture"];
    
    BOOL myPost = [MTUtil isUserMe:user];
    
    BOOL showButtons = NO;
    if (self.hasButtons || (self.hasSecondaryButtons && myPost) || self.hasTertiaryButtons) {
        showButtons = YES;
    }
    
    if (showButtons && postImage) {
        if (self.hasTertiaryButtons) {
            CellIdentifier = @"postCellWithQuadButtons";
        }
        else {
            CellIdentifier = @"postCellWithButtons";
        }
    } else if (showButtons) {
        if (self.hasTertiaryButtons) {
            CellIdentifier = @"postCellNoImageWithQuadButtons";
        }
        else {
            CellIdentifier = @"postCellNoImageWithButtons";
        }
    } else if (postImage) {
        CellIdentifier = @"postCell";
    } else {
        CellIdentifier = @"postCellNoImage";
    }
    
    MTPostsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.post = post;
    
    [self loadLikesForPost:post withCell:cell atIndexPath:indexPath];
    
    // Setup Verify
    PFUser *currentUser = [PFUser currentUser];
    BOOL isMentor = [currentUser[@"type"] isEqualToString:@"mentor"];
    BOOL autoVerify = [self.challenge[@"auto_verify"] boolValue];
    BOOL hideVerifySwitch = !isMentor || autoVerify;

    cell.verifiedCheckBox.hidden = hideVerifySwitch;
    BOOL isChecked = (post[@"verified_by"] != nil);
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
    
    cell.userName.text = [NSString stringWithFormat:@"%@ %@", user[@"first_name"], user[@"last_name"]];
    
    cell.profileImage.image = [UIImage imageNamed:@"profile_image"];
    cell.profileImage.file = user[@"profile_picture"];
    cell.profileImage.layer.cornerRadius = round(cell.profileImage.frame.size.width / 2.0f);
    cell.profileImage.layer.masksToBounds = YES;

    [cell.profileImage loadInBackground:^(UIImage *image, NSError *error) {
        if (!error) {
            if (image) {
                cell.profileImage.image = image;
                [cell setNeedsDisplay];
            }
            else {
                image = nil;
            }
        } else {
            NSLog(@"error - %@", error);
        }
    }];
    
    cell.postText.text = post[@"post_text"];
    NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange rangeAll = NSMakeRange(0, cell.postText.text.length);
    
    [hashtags enumerateMatchesInString:cell.postText.text options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSMutableAttributedString *hashtag = [[NSMutableAttributedString alloc]initWithString:cell.postText.text];
        [hashtag addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
        
        cell.postText.attributedText = hashtag;
    }];
    
    if (postImage) {
        cell.postImage.image = nil;
        cell.postImage.file = postImage;
        [cell.postImage loadInBackground:^(UIImage *image, NSError *error) {
            if (!error) {
                if (image) {
                    CGRect frame = cell.postImage.frame;
                    cell.postImage.image = [self imageByScalingAndCroppingForSize:frame.size withImage:image];
                    [cell setNeedsDisplay];
                } else {
                    cell.postImage.image = nil;
                }
            } else {
                NSLog(@"error - %@", error);
            }
        }];
    }
    
    NSDate *dateObject = [post createdAt];
    
    if (dateObject) {
        cell.postedWhen.text = [dateObject niceRelativeTimeFromNow];
    }
    else {
        // New one
        cell.postedWhen.text = [[NSDate dateWithTimeIntervalSinceNow:0.1f] niceRelativeTimeFromNow];
    }
    
    NSInteger likes = 0;
    if (post[@"likes"]) {
        likes = [post[@"likes"] intValue];
    }
    
    // Set Like
    NSString *postID = [post objectId];
    BOOL like = [self.postsLiked containsObject:postID];
    
    if (like) {
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

    if (dateObject) {
        // Don't retrieve comment count on newly created objects
        PFQuery *commentQuery = [PFQuery queryWithClassName:[PFChallengePostComment parseClassName]];
        [commentQuery whereKey:@"challenge_post" equalTo:post];
        [commentQuery includeKey:@"user"];

        commentQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        
        __block MTPostsTableViewCell *weakCell = cell;
        [commentQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                BOOL containsMe = NO;
                for (PFChallengePostComment *thisPostComment in objects) {
                    PFUser *thisUser = thisPostComment[@"user"];
                    if ([MTUtil isUserMe:thisUser]) {
                        containsMe = YES;
                        break;
                    }
                }

                dispatch_async(dispatch_get_main_queue(), ^{
                    if (containsMe) {
                        [weakCell.commentButton setImage:[UIImage imageNamed:@"comment_active"] forState:UIControlStateNormal];
                        [weakCell.commentButton setImage:[UIImage imageNamed:@"comment_active"] forState:UIControlStateDisabled];
                    } else {
                        [weakCell.commentButton setImage:[UIImage imageNamed:@"comment_normal"] forState:UIControlStateNormal];
                        [weakCell.commentButton setImage:[UIImage imageNamed:@"comment_normal"] forState:UIControlStateDisabled];
                    }
                    
                    weakCell.comments.text = [NSString stringWithFormat:@"%ld", (long)[objects count]];
                });

            } else {
                NSLog(@"error - %@", error);
            }
        }];
        
        cell.activityIndicator.hidden = YES;
        cell.deletePost.hidden = !canDelete;
        cell.loadingView.alpha = 0.0f;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else {
        cell.comments.text = @"0";
        cell.activityIndicator.hidden = NO;
        [cell.activityIndicator startAnimating];
        cell.deletePost.hidden = YES;
        cell.loadingView.alpha = 0.3f;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
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
    
    PFChallengePost *rowObject = self.myObjects[indexPath.row];
    self.postImage = rowObject[@"picture"];
    
    [self performSegueWithIdentifier:@"pushViewPost" sender:cell];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    CGFloat height = 0.0f;
    
    if (row < [self.myObjects count]) {
        PFChallengePost *rowObject = self.myObjects[row];
        UIImage *postImage = rowObject[@"picture"];
        
        PFChallengePost *post = (PFChallengePost *)[self.myObjects objectAtIndex:indexPath.row];
        PFUser *user = post[@"user"];

        BOOL myPost = NO;
        if ([[user username] isEqualToString:[[PFUser currentUser] username]]) {
            myPost = YES;
        }

        BOOL showButtons = NO;
        if (self.hasButtons || (self.hasSecondaryButtons && myPost) || self.hasTertiaryButtons) {
            showButtons = YES;
        }

        if (showButtons && postImage) {
            if (self.hasTertiaryButtons) {
                height = 500.0f;
            }
            else {
                height = 466.0f;
            }
        } else if (showButtons) {
            if (self.hasTertiaryButtons) {
                height = 224.0f;
            }
            else {
                height = 190.0f;
            }
        } else if (postImage) {
            height = 436.0f;
        } else {
            height = 150.0f;
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
        PFChallengePost *post = cell.post;
  
        MTCommentViewController *destinationViewController = (MTCommentViewController *)[segue destinationViewController];
        destinationViewController.post = post;
        destinationViewController.challenge = self.challenge;
        [destinationViewController setDelegate:self];
    }
    else if ([segueIdentifier isEqualToString:@"editPostSegue"]) {
        UIButton *button = sender;
        
        MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[button findSuperViewWithClass:[MTPostsTableViewCell class]];
        PFChallengePost *post = cell.post;
        
        UINavigationController *destinationViewController = (UINavigationController *)[segue destinationViewController];
        
        MTCommentViewController *commentVC = (MTCommentViewController *)[destinationViewController topViewController];
        commentVC.post = post;
        commentVC.challenge = self.challenge;
        commentVC.editPost = YES;
        [commentVC setDelegate:self];
    }
    else {
        MTPostsTableViewCell *cell = (MTPostsTableViewCell *)sender;
        PFChallengePost *post = cell.post;

        self.postViewController = (MTPostViewController*)[segue destinationViewController];
        self.postViewController.challengePost = post;
        self.postViewController.challenge = self.challenge;
        self.postViewController.delegate = self;
        self.postViewController.postsLiked = self.postsLiked;
        self.postViewController.postsLikedFull = self.postsLikedFull;
        self.postViewController.emojiArray = cell.emojiArray;
        self.postViewController.myClassTableViewController = self;

        PFUser *user = post[@"user"];

        BOOL myPost = NO;
        if ([[user username] isEqualToString:[[PFUser currentUser] username]]) {
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

        if (showButtons && self.postImage)
            self.postViewController.postType = MTPostTypeWithButtonsWithImage;
        else if (showButtons)
            self.postViewController.postType = MTPostTypeWithButtonsNoImage;
        else if (self.postImage)
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
- (void)didDeletePost:(PFChallengePost *)challengePost
{
    self.deletingPost = YES;
    self.tableView.userInteractionEnabled = NO;
    
    // Perform on delay after we get popped to here
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        NSUInteger row = [weakSelf.myObjects indexOfObject:challengePost];
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

- (void)willUpdatePostsLiked:(NSArray *)postsLiked withPostLikedFull:(NSArray *)postsLikedFull;
{
    self.postsLiked = postsLiked;
    self.postsLikedFull = postsLikedFull;
    [self.tableView reloadData];
}

- (void)didUpdatePostsLiked:(NSArray *)postsLiked withPostLikedFull:(NSArray *)postsLikedFull
{
    self.didUpdateLikedPosts = YES;
    self.postsLiked = postsLiked;
    self.postsLikedFull = postsLikedFull;
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
    PFUser *user = [PFUser currentUser];
    
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[button findSuperViewWithClass:[MTPostsTableViewCell class]];
    __block PFChallengePost *post = cell.post;
    __block NSString *userID = [user objectId];
    __block NSString *postID = [post objectId];
    
    if (withConfirmation)
    {
        if ([UIAlertController class])
        {
            UIAlertController *deletePostSheet = [UIAlertController alertControllerWithTitle:@"Delete this post?" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                                     }];
            MTMakeWeakSelf();
            UIAlertAction *delete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                                         NSInteger index = [weakSelf.myObjects indexOfObject:post];
                                         [weakSelf.myObjects removeObject:post];
                                         NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                                         [weakSelf.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

                                         [PFCloud callFunctionInBackground:@"deletePost" withParameters:@{@"user_id": userID, @"post_id": postID} block:^(id object, NSError *error) {
                                             if (error) {
                                                 [UIAlertView bk_showAlertViewWithTitle:@"Unable to Delete" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                                                 NSLog(@"error - %@", error);
                                             }
                                             else {
                                                 [[PFUser currentUser] fetchInBackground];
                                             }
                                             
                                             dispatch_async(dispatch_get_main_queue(), ^{
                                                 [weakSelf loadObjects];
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
                NSInteger index = [weakSelf.myObjects indexOfObject:post];
                [weakSelf.myObjects removeObject:post];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [weakSelf.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];\
                
                [PFCloud callFunctionInBackground:@"deletePost" withParameters:@{@"user_id": userID, @"post_id": postID} block:^(id object, NSError *error) {
                    if (error) {
                        [UIAlertView bk_showAlertViewWithTitle:@"Unable to Delete" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                        NSLog(@"error - %@", error);
                    }
                    else {
                        [[PFUser currentUser] fetchInBackground];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [weakSelf loadObjects];
                    });
                }];
                
            }];
            [deleteAction bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
            [deleteAction showInView:[UIApplication sharedApplication].keyWindow];
        }
    }
    else {
        MTMakeWeakSelf();
        NSInteger index = [self.myObjects indexOfObject:post];
        [self.myObjects removeObject:post];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        [PFCloud callFunctionInBackground:@"deletePost" withParameters:@{@"user_id": userID, @"post_id": postID} block:^(id object, NSError *error) {
            if (error) {
                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Delete" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf loadObjects];
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
    PFChallengePost *post = cell.post;
    
    PFUser *user = [PFUser currentUser];
    
    NSString *userID = [user objectId];
    NSString *postID = [post objectId];
    
    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInteger:buttonNumber]};
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Submitting...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
            if (!error) {
                [[PFUser currentUser] fetchInBackground];
                [weakSelf.challenge fetchInBackground];
                [post fetchInBackground];
                [weakSelf userButtonsTapped];
                [weakSelf loadObjects];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
                
                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
            
            button.enabled = YES;
        }];
    } afterDelay:0.35f];
}

- (IBAction)verifiedTapped:(id)sender
{
    __block MTPostsTableViewCell *postCell = (MTPostsTableViewCell *)[sender findSuperViewWithClass:[MTPostsTableViewCell class]];
    __block PFChallengePost *post = postCell.post;
    __block PFUser *currentUser = [PFUser currentUser];

    NSString *postID = [post objectId];
    NSString *verifiedBy = [currentUser objectId];

    BOOL isChecked = (post[@"verified_by"] != nil);
    
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
    
    postCell.verfiedLabel.text = @"Updating...";
    
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
                [currentUser fetchInBackground];
                [weakSelf.challenge fetchInBackground];
                
                [post fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                        [weakSelf.tableView reloadData];
                    });
                }];
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
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[self.secondaryButton1 findSuperViewWithClass:[MTPostsTableViewCell class]];
    PFChallengePost *post = cell.post;
    
    PFUser *user = [PFUser currentUser];
    
    NSString *userID = [user objectId];
    NSString *postID = [post objectId];
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
                    weakSelf.secondaryButton1.enabled = YES;
                });
                
                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
        }];
    } afterDelay:0.35f];
}

- (void)secondaryButton2Tapped:(id)sender
{
    ((UIButton *)sender).enabled = NO;
    self.secondaryButton2 = (UIButton *)sender;
    
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[self.secondaryButton2 findSuperViewWithClass:[MTPostsTableViewCell class]];
    PFChallengePost *post = cell.post;
    NSDictionary *buttonDict = [self.secondaryButtonsTapped objectForKey:post.objectId];
    
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
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[self.secondaryButton2 findSuperViewWithClass:[MTPostsTableViewCell class]];
    PFChallengePost *post = cell.post;
    
    PFUser *user = [PFUser currentUser];
    
    NSString *userID = [user objectId];
    NSString *postID = [post objectId];
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

- (void)emojiLikedForPost:(PFChallengePost *)likedPost withEmoji:(PFEmoji *)emoji
{
    NSUInteger row = [self.myObjects indexOfObject:likedPost];
    if (row == NSNotFound) {
        return;
    }
    
    NSString *emojiName = emoji[@"name"];
    
    __block MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
    __block PFChallengePost *post = likedPost;
    
    PFUser *user = [PFUser currentUser];
    
    NSString *userID = [user objectId];
    NSString *postID = [post objectId];
    
    BOOL like = [self.postsLiked containsObject:postID];
    
    __block NSMutableArray *oldLikePosts = [NSMutableArray arrayWithArray:self.postsLiked];
    NSInteger oldLikesCount = [post[@"likes"] intValue];
    
    NSMutableArray *likes = [NSMutableArray arrayWithArray:self.postsLiked];
    NSInteger likesCount = [post[@"likes"] intValue];
    NSMutableArray *newEmojiArray = [NSMutableArray arrayWithArray:cell.emojiArray];
    
    if (!like) {
        likesCount += 1;
        [likes addObject:postID];
    }
    else {
        // We're replacing existing emoji like
        BOOL foundMatch = NO;
        for (PFChallengePostsLiked *thisPostLiked in self.postsLikedFull) {
            PFChallengePost *post = thisPostLiked[@"post"];
            if ([post.objectId isEqualToString:cell.post.objectId]) {
                PFEmoji *originalMatchedEmoji = thisPostLiked[@"emoji"];
                thisPostLiked[@"emoji"] = emoji;
                
                for (PFEmoji *thisEmoji in cell.emojiArray) {
                    if ([thisEmoji.objectId isEqualToString:originalMatchedEmoji.objectId]) {
                        [newEmojiArray removeObject:thisEmoji];
                        foundMatch = YES;
                        break;
                    }
                }
            }
            
            if (foundMatch) {
                break;
            }
        }
    }
    
    post[@"likes"] = [NSNumber numberWithInteger:likesCount];
    self.postsLiked = likes;
    
    // Optimistically update view (can roll back on error below)
    cell.likes.text = [NSString stringWithFormat:@"%ld", (long)likesCount];
    
    // Optimistically update the emoji likes
    __block NSMutableArray *oldEmojiArray = [NSMutableArray arrayWithArray:cell.emojiArray];
    [newEmojiArray insertObject:emoji atIndex:0];
    cell.emojiArray = [NSArray arrayWithArray:newEmojiArray];
    
    // First, like, animate
    if (!like) {
        [cell.likeButton setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
        [cell.likeButton setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateDisabled];
        
        // Animations are borked on < iOS 8.0 because of autolayout?
        // http://stackoverflow.com/questions/25286022/animation-of-cgaffinetransform-in-ios8-looks-different-than-in-ios7?rq=1
        if(NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
            // no animation
        } else {
            [UIView animateWithDuration:0.2f animations:^{
                cell.likeButton.transform = CGAffineTransformMakeScale(1.5, 1.5);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2f animations:^{
                    cell.likeButton.transform = CGAffineTransformMakeScale(1, 1);
                } completion:NULL];
            }];
        }
        
    }
    
    MTMakeWeakSelf();
    [PFCloud callFunctionInBackground:@"toggleLikePost" withParameters:@{@"user_id": userID, @"post_id" : postID, @"like" : @"1", @"emoji_name" : emojiName} block:^(id object, NSError *error) {
        
        if (!error) {
            [weakSelf updateLikes];
            
            [post fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                // Load/update the objects but don't clear the table
                [weakSelf loadObjects];
            }];
        }
        else {
            NSLog(@"error - %@", error);
            weakSelf.postsLiked = oldLikePosts;
            post[@"likes"] = [NSNumber numberWithInteger:oldLikesCount];
            
            cell.emojiArray = oldEmojiArray;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                
                // Revert locally if network down
                [weakSelf.tableView reloadData];
                
                // Then, sync with server
                if ([MTUtil internetReachable]) {
                    [weakSelf updateLikes];
                    [post fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                        // Load/update the objects but don't clear the table
                        [weakSelf loadObjects];
                    }];
                }
            });
        }
    }];
}


#pragma mark - MTEmojiPickerCollectionViewDelegate Methods -
- (void)didSelectEmoji:(PFEmoji *)emoji withPost:(PFChallengePost *)post;
{
    if (self.postViewController) {
        [self.postViewController emojiLiked:emoji];
    }
    else {
        [self emojiLikedForPost:post withEmoji:emoji];
    }
    
    [self dismissEmojiPrompt];
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
    if (IsEmpty(self.myObjects) && self.updatedButtonsAndLikes) {
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
