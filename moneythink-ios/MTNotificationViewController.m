//
//  MTNotificationViewController.m
//  moneythink-ios
//
//  Created by dsica on 6/9/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTNotificationViewController.h"
#import "MTMentorStudentProfileViewController.h"
#import "MTMentorDashboardViewController.h"
#import "MTNotificationTableViewCell.h"
#import "MTPostDetailViewController.h"
#import "MTMenuViewController.h"

@interface MTNotificationViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *markAllReadButtonItem;

@property (nonatomic, strong) RLMResults *notifications;

@property (nonatomic) BOOL showingAlert;

@end

@implementation MTNotificationViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor whiteColor];
    self.refreshControl.tintColor = [UIColor primaryOrange];
    [self.refreshControl addTarget:self action:@selector(loadData) forControlEvents:UIControlEventValueChanged];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController) {
        UIButton *customButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        [customButton addTarget:self.revealViewController action:@selector(revealToggle:) forControlEvents:UIControlEventTouchUpInside];
        [customButton setImage:[UIImage imageNamed:@"icon_main_nav.png"] forState:UIControlStateNormal];
        BBBadgeBarButtonItem *barButton = [[BBBadgeBarButtonItem alloc] initWithCustomUIButton:customButton];
        barButton.badgeOriginX = 13;
        barButton.badgeOriginY = -9;
        barButton.badgeValue = [NSString stringWithFormat:@"%ld", (long)((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount];
        self.navigationItem.leftBarButtonItem = barButton;
    }
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_actionbar"]];
    
    // Set the gesture
    //  Add tag = 5000 so panGestureRecognizer can be re-added
    self.navigationController.navigationBar.tag = 5000;

    [self.markAllReadButtonItem setTarget:self];
    [self.markAllReadButtonItem setAction:@selector(markAllRead)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [MTUtil GATrackScreen:@"Notifications"];
    
    if (self.actionableNotificationId > 0) {
        [self handleActionableNotification];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unreadCountUpdate:) name:kUnreadNotificationCountNotification object:nil];
    [self.navigationController.navigationBar addGestureRecognizer:self.revealViewController.panGestureRecognizer];
    
    [self loadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    for (UIGestureRecognizer *thisGesture in [self.navigationController.navigationBar gestureRecognizers]) {
        [self.navigationController.navigationBar removeGestureRecognizer:thisGesture];
    }
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
    self.notifications = [[MTNotification objectsWhere:@"isDeleted = NO"] sortedResultsUsingProperty:@"createdAt" ascending:NO];
    [self.tableView reloadData];
    
    __block MBProgressHUD *thisHUD = nil;
    if (!self.showingAlert && IsEmpty(self.notifications) && self.actionableNotificationId == 0) {
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
        thisHUD = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        thisHUD.labelText = @"Loading...";
        thisHUD.dimBackground = YES;
    }
    
    BOOL includeRead = NO;
    NSDate *lastFetchDate = [MTUtil lastNotificationFetchDate];
    if (!lastFetchDate || IsEmpty(self.notifications)) {
        includeRead = YES;
        lastFetchDate = [[NSDate date] dateByAddingTimeInterval:-60*60*24*7];
    }
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] loadNotificationsWithSinceDate:lastFetchDate includeRead:includeRead success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.refreshControl endRefreshing];
            [thisHUD hide:YES];
            weakSelf.notifications = [[MTNotification objectsWhere:@"isDeleted = NO"] sortedResultsUsingProperty:@"createdAt" ascending:NO];
            RLMResults *myUnReadNotifs = [MTNotification objectsWhere:@"isDeleted = NO AND read = NO"];
            ((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount = [myUnReadNotifs count];
            [[NSNotificationCenter defaultCenter] postNotificationName:kUnreadNotificationCountNotification object:[NSNumber numberWithInteger:[myUnReadNotifs count]]];

            [weakSelf.tableView reloadData];
            [MTUtil setLastNotificationFetchDate:[NSDate date]];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.refreshControl endRefreshing];
            [thisHUD hide:YES];
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        });
    }];
}


#pragma mark - UITableView -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.notifications count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableView.frame.size.width, 20.0f)];
    headerView.backgroundColor = [UIColor colorWithHexString:@"#f5f5f5"];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 0.0f, 300.0f, 20.0f)];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [UIColor colorWithHexString:@"#1a1a1a"];
    headerLabel.font = [UIFont boldSystemFontOfSize:13.0f];
    headerLabel.text = @"NOTIFICATIONS";
    [headerView addSubview:headerLabel];
    
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuserIdentifier = @"notificationCellView";
    
    MTNotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuserIdentifier];
    if (cell == nil) {
        cell = [[MTNotificationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuserIdentifier];
    }
    
    cell.currentIndexPath = indexPath;
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    MTNotification *notification = [self.notifications objectAtIndex:indexPath.row];
    
    MTUser *user = nil;
    NSString *username = nil;
    if (notification.relatedUser) {
        user = notification.relatedUser;
        if ([MTUser isUserMe:user]) {
            username = @"You";
        }
        else {
            username = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
        }
    }
    
    cell.avatarImageView.layer.cornerRadius = round(cell.avatarImageView.frame.size.width / 2.0f);
    cell.avatarImageView.layer.masksToBounds = YES;
    cell.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;

    __block MTNotificationTableViewCell *weakCell = cell;
    cell.avatarImageView.image = [user loadAvatarImageWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakCell.avatarImageView.image = responseData;
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load user avatar");
    }];
    
    cell.agePosted.text = [notification.createdAt niceRelativeTimeFromNow];
    cell.agePosted.textColor = [UIColor primaryGreen];
    
    NSString *notificationType = notification.notificationType;
    NSString *notificationMessage = notification.message;
    
    cell.messageTextView.textContainerInset = UIEdgeInsetsZero;
    cell.messageTextView.textContainer.lineFragmentPadding = 0;

    if ([notificationType isEqualToString:kNotificationPostComment]) {
        MTChallengePostComment *comment = notification.relatedComment;
        
        if (!IsEmpty(username)) {
            NSString *postMessage = IsEmpty(comment.content) ? @"" : comment.content;
            NSString *theMessage = [NSString stringWithFormat:@"%@ commented on your post: %@",username, postMessage];
            
            if (IsEmpty(postMessage)) {
                theMessage = [NSString stringWithFormat:@"%@ commented on your post.",username];
            }
            NSMutableAttributedString *theAttributedTitle = [[NSMutableAttributedString alloc] initWithString:theMessage];
            [theAttributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:[theMessage rangeOfString:theMessage]];
            
            [theAttributedTitle addAttribute:NSFontAttributeName value:[UIFont mtFontOfSize:12.0f] range:[theMessage rangeOfString:theMessage]];
            [theAttributedTitle addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:12.0f] range:[theMessage rangeOfString:username]];
            
            NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
            NSRange rangeAll = NSMakeRange(0, theMessage.length);
            [hashtags enumerateMatchesInString:theMessage options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                [theAttributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
            }];

            cell.messageTextView.attributedText = theAttributedTitle;
        }
        else {
            cell.messageTextView.text = [NSString stringWithFormat:@"Someone commented on your post: %@", comment.content];
        }
        
    }
    else if ([notificationType isEqualToString:kNotificationPostLiked]) {
        MTChallengePost *post = notification.relatedPost;
        NSString *postMessage = post.content;
        
        if (!IsEmpty(username)) {
            NSString *theMessage = [NSString stringWithFormat:@"%@ liked your post: %@", username, postMessage];
            if (IsEmpty(postMessage)) {
                theMessage = [NSString stringWithFormat:@"%@ liked your post.", username];
            }
            NSMutableAttributedString *theAttributedTitle = [[NSMutableAttributedString alloc] initWithString:theMessage];
            [theAttributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:[theMessage rangeOfString:theMessage]];
            
            [theAttributedTitle addAttribute:NSFontAttributeName value:[UIFont mtFontOfSize:12.0f] range:[theMessage rangeOfString:theMessage]];
            [theAttributedTitle addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:12.0f] range:[theMessage rangeOfString:username]];
            
            NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
            NSRange rangeAll = NSMakeRange(0, theMessage.length);
            [hashtags enumerateMatchesInString:theMessage options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                [theAttributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
            }];

            cell.messageTextView.attributedText = theAttributedTitle;
        }
        else {
            if (!IsEmpty(postMessage)) {
                cell.messageTextView.text = [NSString stringWithFormat:@"Someone liked your post: %@", postMessage];
            }
            else {
                cell.messageTextView.text = @"Someone liked your post.";
            }
        }
        
    }
    else if ([notificationType isEqualToString:kNotificationChallengeActivated]) {
        
        MTChallenge *challenge = notification.relatedChallenge;
        if (!IsEmpty(challenge.title)) {
            cell.messageTextView.text = [NSString stringWithFormat:@"Heads up!  New challenge unlocked: %@", challenge.title];
        }
        else {
            cell.messageTextView.text = [NSString stringWithFormat:@"Heads up!  New challenge unlocked"];
        }

    }
    else if ([notificationType isEqualToString:kNotificationLeaderOn]) {
        if (!IsEmpty(notificationMessage)) {
            cell.messageTextView.text = notificationMessage;
        }
        else {
            cell.messageTextView.text = @"Congrats, you're top of the leaderboard.";
        }
        
        if (!user.hasAvatar) {
            cell.avatarImageView.image = [UIImage imageNamed:@"mt_avatar"];
        }

    }
    else if ([notificationType isEqualToString:kNotificationLeaderOff]) {
        if (!IsEmpty(notificationMessage)) {
            cell.messageTextView.text = notificationMessage;
        }
        else {
            cell.messageTextView.text = @"Watch out - your classmate is now top of the leaderboard.";
        }
        
        if (!user.hasAvatar) {
            cell.avatarImageView.image = [UIImage imageNamed:@"mt_avatar"];
        }

    }
    else if ([notificationType isEqualToString:kNotificationStudentInactivity] || [notificationType isEqualToString:kNotificationMentorInactivity]) {
        if (!IsEmpty(notificationMessage)) {
            cell.messageTextView.text = notificationMessage;
        }
        else {
            cell.messageTextView.text = @"Where’d you go? Check out what your friends are posting.";
        }
        
        if (!user.hasAvatar) {
            cell.avatarImageView.image = [UIImage imageNamed:@"mt_avatar"];
        }
        
    }
    else if ([notificationType isEqualToString:kNotificationVerifyPost]) {
        if (!IsEmpty(notificationMessage)) {
            cell.messageTextView.text = notificationMessage;
        }
        else {
            cell.messageTextView.text = @"Your class has posts that need verification!";
        }

    }
    else {
        // Shouldn't get here but let's print out for debugging.
        NSLog(@"Notification: %@", notification);
    }
    
    cell.avatarImageView.layer.borderColor = [UIColor primaryGreen].CGColor;

    if (!notification.read) {
        cell.avatarImageView.layer.borderWidth = 2.0f;
    }
    else {
        cell.avatarImageView.layer.borderWidth = 0.0f;
    }
    
    cell.messageTextView.userInteractionEnabled = NO;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    MTNotification *notification = [self.notifications objectAtIndex:indexPath.row];
    [self actionForNotification:notification];
}


#pragma mark - Actionable Notification Methods -
- (void)handleActionableNotification
{
    MTNotification *thisNotification = [MTNotification objectForPrimaryKey:[NSNumber numberWithInteger:self.actionableNotificationId]];
    
    if (thisNotification) {
        [[RLMRealm defaultRealm] beginWriteTransaction];
        thisNotification.isDeleted = NO;
        [[RLMRealm defaultRealm] commitWriteTransaction];

        self.actionableNotificationId = 0;
        [self actionForNotification:thisNotification];
    }
    else {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Loading Notification...";
        hud.dimBackground = YES;
        
        MTMakeWeakSelf();
        [[MTNetworkManager sharedMTNetworkManager] loadNotificationId:self.actionableNotificationId success:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                MTNotification *thisNotification = [MTNotification objectForPrimaryKey:[NSNumber numberWithInteger:weakSelf.actionableNotificationId]];
                weakSelf.actionableNotificationId = 0;
                
                if (thisNotification) {
                    [weakSelf actionForNotification:thisNotification];
                }
            });
            
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                
                weakSelf.actionableNotificationId = 0;
                weakSelf.showingAlert = YES;
                NSString *title = @"Unable to load Notification";
                NSString *messageToDisplay = @"";
                
                if ([UIAlertController class]) {
                    UIAlertController *changeSheet = [UIAlertController
                                                      alertControllerWithTitle:title
                                                      message:messageToDisplay
                                                      preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction *close = [UIAlertAction
                                            actionWithTitle:@"Close"
                                            style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
                                                weakSelf.showingAlert = NO;
                                            }];
                    
                    [changeSheet addAction:close];
                    
                    [self presentViewController:changeSheet animated:YES completion:nil];
                } else {
                    MTMakeWeakSelf();
                    [UIAlertView bk_showAlertViewWithTitle:title message:messageToDisplay cancelButtonTitle:@"Close" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                        weakSelf.showingAlert = NO;
                    }];
                }
            });
        }];
    }
}

- (void)actionForNotification:(MTNotification *)notification
{
    [MTNotificationViewController markReadForNotification:notification];
    
    NSString *notificationType = notification.notificationType;
    if (IsEmpty(notificationType)) {
        return;
    }
    
    // Someone commented on your post (mentor/student)
    //
    //  Action: Bring user to post with new comment
    if ([notificationType isEqualToString:kNotificationPostComment]) {
        [self displayPostDetailForNotification:notification];
    }
    
    // Someone liked your post (mentor/student)
    //
    //  Action: Bring user to liked post
    else if ([notificationType isEqualToString:kNotificationPostLiked]) {
        [self displayPostDetailForNotification:notification];
    }
    
    // New challenge unlocked (student)
    //
    //  Action: Take user to new challenge
    else if ([notificationType isEqualToString:kNotificationChallengeActivated]) {
        
        if (notification.relatedChallenge) {
            MTChallenge *challengeActivated = notification.relatedChallenge;
            [self displayChallengesViewForChallengeId:challengeActivated.id];
        }
    }
    
    // Leaderboard (student)
    //  You're on top of leaderboard or your classmate is now at top
    //
    //  Action: Take user to leaderboard
    else if ([notificationType isEqualToString:kNotificationLeaderOn] ||
             [notificationType isEqualToString:kNotificationLeaderOff]) {
        
        MTMenuViewController *menuVC = (MTMenuViewController *)self.revealViewController.rearViewController;
        [menuVC openLeaderboard];
    }
    
    // Posts need verification (mentor)
    //
    //  Action: Take user to relevant challenge
    else if ([notificationType isEqualToString:kNotificationVerifyPost]) {
        if (notification.relatedPost) {
            [self displayPostDetailForNotification:notification];
        }
    }

    // Inactivity
    //  Students and Mentors have unique messages
    //
    //  Action: Take user to last open challenge
    else if ([notificationType isEqualToString:kNotificationStudentInactivity] || [notificationType isEqualToString:kNotificationMentorInactivity]) {
        [self displayChallengesViewForChallengeId:[[MTUtil lastViewedChallengeId] integerValue]];
    }
}

- (void)displayPostDetailForNotification:(MTNotification *)notification
{
    MTPostDetailViewController *postVC = (MTPostDetailViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"challengePost"];
    postVC.notification = notification;
    
    if (notification.relatedPost) {
        [self.navigationController pushViewController:postVC animated:YES];
    }
    else {
        self.showingAlert = YES;
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
                                        self.showingAlert = NO;
                                    }];
            
            [changeSheet addAction:close];
            
            [self presentViewController:changeSheet animated:YES completion:nil];
        } else {
            MTMakeWeakSelf();
            [UIAlertView bk_showAlertViewWithTitle:title message:messageToDisplay cancelButtonTitle:@"Close" otherButtonTitles:nil handler:^(UIAlertView *alertView, NSInteger buttonIndex) {
                weakSelf.showingAlert = NO;
            }];
        }
    }
}

- (void)displayChallengesViewForChallengeId:(NSInteger)challengeId
{
    MTMenuViewController *menuVC = (MTMenuViewController *)self.revealViewController.rearViewController;
    [menuVC openChallengesForChallengeId:challengeId];
}


#pragma mark - Actions -
- (void)markAllRead
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Marking All Read...";
    hud.dimBackground = YES;
    
    [[MTNetworkManager sharedMTNetworkManager] markAllNotificationsReadWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
            [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
        });

        NSLog(@"Unable to mark ALL read: %@", [error mtErrorDescription]);
    }];
}


#pragma mark - Public Methods -
+ (void)markReadForNotificationId:(NSInteger)notificationId
{
    [[MTNetworkManager sharedMTNetworkManager] markReadForNotificationId:notificationId success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to mark read: %@", [error mtErrorDescription]);
    }];
}

+ (void)markReadForNotification:(MTNotification *)notification
{
    if (notification.read) {
        return;
    }
    
    // Proactively, decrement notification count
    NSInteger currentCount = ((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount;
    if (currentCount > 0) {
        currentCount--;
    }
    
    ((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount = currentCount;
    
    [[MTNetworkManager sharedMTNetworkManager] markReadForNotificationId:notification.id success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to mark read: %@", [error mtErrorDescription]);
    }];
}

+ (void)requestNotificationUnreadCountUpdateUsingCache:(BOOL)useCache
{
    if (![MTUser currentUser]) {
        return;
    }
    
    if (useCache) {
        RLMResults *myUnReadNotifs = [MTNotification objectsWhere:@"isDeleted = NO AND read = NO"];
        ((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount = [myUnReadNotifs count];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kUnreadNotificationCountNotification object:[NSNumber numberWithInteger:[myUnReadNotifs count]]];
        });
    }
    else {
        [[MTNetworkManager sharedMTNetworkManager] loadNotificationsWithSinceDate:[MTUtil lastNotificationFetchDate] includeRead:NO success:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                RLMResults *myUnReadNotifs = [MTNotification objectsWhere:@"isDeleted = NO AND read = NO"];
                ((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount = [myUnReadNotifs count];
                [[NSNotificationCenter defaultCenter] postNotificationName:kUnreadNotificationCountNotification object:[NSNumber numberWithInteger:[myUnReadNotifs count]]];
                [MTUtil setLastNotificationFetchDate:[NSDate date]];
            });
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
            });
        }];
    }
}


#pragma mark - Notifications -
- (void)unreadCountUpdate:(NSNotification *)note
{
    NSNumber *count = note.object;
    
    BBBadgeBarButtonItem *barButton = (BBBadgeBarButtonItem *)self.navigationItem.leftBarButtonItem;
    barButton.badgeValue = [NSString stringWithFormat:@"%ld", (long)[count integerValue]];
    [self.tableView reloadData];
}


#pragma mark - DZNEmptyDataSetDelegate/Datasource Methods -
- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"No Notifications";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    if (IsEmpty(self.notifications)) {
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

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return -78.0f;
}


@end
