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
#import "MTPostViewController.h"
#import "MTMenuViewController.h"

@interface MTNotificationViewController () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, weak) IBOutlet UIBarButtonItem *revealButtonItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *markAllReadButtonItem;

@property (nonatomic) BOOL showingAlert;
@property (nonatomic) BOOL updatedObjects;

@end

@implementation MTNotificationViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // The className to query on
        self.parseClassName = [PFNotifications parseClassName];
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = @"challenge_started";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = NO;
        self.loadingViewEnabled = NO;
        
        self.paginationEnabled = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    self.tableView.separatorInset = UIEdgeInsetsZero;
    
    self.tableView.emptyDataSetSource = self;
    self.tableView.emptyDataSetDelegate = self;
    
    // A little trick for removing the cell separators
    self.tableView.tableFooterView = [UIView new];
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController) {
        [self.revealButtonItem setTarget: self.revealViewController];
        [self.revealButtonItem setAction: @selector(revealToggle:)];
        self.revealButtonItem.badgeValue = [NSString stringWithFormat:@"%ld", (long)((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount];
        [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];
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
    self.updatedObjects = NO;
    
    if (self.actionableNotificationId) {
        [self handleActionableNotification];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unreadCountUpdate:) name:kUnreadNotificationCountNotification object:nil];
    [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
    if ([self isViewLoaded]) {
        self.tableView.emptyDataSetSource = nil;
        self.tableView.emptyDataSetDelegate = nil;
    }
}


#pragma mark - Parse
- (void)objectsDidLoad:(NSError *)error
{
    [super objectsDidLoad:error];
    
    // This method is called every time objects are loaded from Parse via the PFQuery
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
    
    self.updatedObjects = YES;
    [self.tableView reloadData];
}

- (void)objectsWillLoad
{
    [super objectsWillLoad];
    
    // This method is called before a PFQuery is fired to get more objects
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
    
    if (!self.showingAlert) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        if ([self.objects count] == 0) {
            hud.labelText = @"Loading...";
        }
        else {
            hud.labelText = @"Refreshing...";
        }
        hud.dimBackground = YES;
    }
}

- (PFQuery *)queryForTable
{
    PFUser *user = [PFUser currentUser];
    NSString *className = user[@"class"];
    NSString *schoolName = user[@"school"];

    PFQuery *queryMe = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryMe whereKey:@"recipient" equalTo:user];
    [queryMe whereKeyExists:@"notificationType"];

    PFQuery *queryClass = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryClass whereKeyDoesNotExist:@"recipient"];
    [queryClass whereKey:@"class" equalTo:className];
    [queryClass whereKey:@"school" equalTo:schoolName];
    [queryClass whereKeyExists:@"notificationType"];

    PFQuery *query = [PFQuery orQueryWithSubqueries:@[queryMe, queryClass]];
    // Always pull latest from Network if available
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    [query orderByDescending:@"createdAt"];
    
    [query includeKey:@"comment.challenge_post.challenge"];
    [query includeKey:@"comment.challenge_post.user"];
    [query includeKey:@"post_liked.user"];
    [query includeKey:@"post_verified.user"];
    [query includeKey:@"user"];
    [query includeKey:@"recipient"];
    [query includeKey:@"challenge_activated_ref"];

    return query;
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

// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *reuserIdentifier = @"notificationCellView";
    
    MTNotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuserIdentifier];
    if (cell == nil) {
        cell = [[MTNotificationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuserIdentifier];
    }
    
    cell.currentIndexPath = indexPath;
    [cell setSelectionStyle:UITableViewCellSelectionStyleGray];
    
    PFNotifications *notification = (PFNotifications *)object;
    
    PFUser *user = nil;
    NSString *username = nil;
    if (notification[@"user"]) {
        user = notification[@"user"];
        if ([MTUtil isUserMe:user]) {
            username = @"You";
        }
        else {
            username = [NSString stringWithFormat:@"%@ %@", user[@"first_name"], user[@"last_name"]];
        }
    }
    
    cell.avatarImageView.image = [UIImage imageNamed:@"profile_image"];
    cell.avatarImageView.layer.cornerRadius = round(cell.avatarImageView.frame.size.width / 2.0f);
    cell.avatarImageView.layer.masksToBounds = YES;
    
    if (user[@"profile_picture"]) {
        cell.avatarImageView.file = user[@"profile_picture"];
        __block MTNotificationTableViewCell *weakCell = cell;
        __block NSIndexPath *oldIndexPath = indexPath;
        [cell.avatarImageView loadInBackground:^(UIImage *image, NSError *error) {
            if (oldIndexPath.row != weakCell.currentIndexPath.row) {
                return;
            }
            if (!error) {
                if (image) {
                    weakCell.avatarImageView.image = image;
                    [weakCell setNeedsDisplay];
                }
                else {
                    weakCell.avatarImageView.image = nil;
                }
            } else {
                NSLog(@"error - %@", error);
            }
        }];
    }
    
    cell.agePosted.text = [[notification createdAt] niceRelativeTimeFromNow];
    cell.agePosted.textColor = [UIColor primaryGreen];
    
    NSString *notificationType = notification[@"notificationType"];
    NSString *notificationMessage = notification[@"notificationMessage"];

    if (IsEmpty(notificationType)) {
        // Support legacy notifications
        if (notification[@"comment"]) {
            notificationType = kNotificationPostComment;
        }
        else if (notification[@"challenge_activated_ref"]) {
            notificationType = kNotificationNewChallenge;
        }
        else if (notification[@"post_liked"]) {
            notificationType = kNotificationPostLiked;
        }
        else if (notification[@"post_verified"]) {
            notificationType = kNotificationPostVerified;
        }
    }
    
    cell.messageTextView.textContainerInset = UIEdgeInsetsZero;
    cell.messageTextView.textContainer.lineFragmentPadding = 0;

    if ([notificationType isEqualToString:kNotificationPostComment]) {
        PFChallengePostComment *post = notification[@"comment"];
        
        if (!IsEmpty(username)) {
            NSString *postMessage = IsEmpty(post[@"comment_text"]) ? @"" : post[@"comment_text"];
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
            cell.messageTextView.text = [NSString stringWithFormat:@"Someone commented on your post: %@", post[@"comment_text"]];
        }
        
    }
    else if ([notificationType isEqualToString:kNotificationPostLiked]) {
        PFChallengePost *post = notification[@"post_liked"];
        NSString *postMessage = post[@"post_text"];
        
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
    else if ([notificationType isEqualToString:kNotificationNewChallenge]) {
        
        PFChallenges *challenge = notification[@"challenge_activated_ref"];
        if (!IsEmpty(challenge[@"title"])) {
            cell.messageTextView.text = [NSString stringWithFormat:@"Heads up!  New challenge unlocked: %@", challenge[@"title"]];
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
        
        if (!user[@"profile_picture"]) {
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
        
        if (!user[@"profile_picture"]) {
            cell.avatarImageView.image = [UIImage imageNamed:@"mt_avatar"];
        }

    }
    else if ([notificationType hasPrefix:kNotificationInactivity]) {
        
        if (!IsEmpty(notificationMessage)) {
            cell.messageTextView.text = notificationMessage;
        }
        else {
            cell.messageTextView.text = @"Where’d you go? Check out what your friends are posting.";
        }
        
        if (!user[@"profile_picture"]) {
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
    else if ([notificationType isEqualToString:kNotificationPostVerified]) {
        PFChallengePostComment *post = notification[@"post_verified"];
        NSString *postMessage = IsEmpty(post[@"post_text"]) ? @"" : post[@"post_text"];

        if (!IsEmpty(username)) {
            NSString *theMessage = [NSString stringWithFormat:@"%@ verified your post: %@",username, postMessage];
            if (IsEmpty(postMessage)) {
                theMessage = [NSString stringWithFormat:@"%@ verified your post.",username];
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
            NSString *theMessage = [NSString stringWithFormat:@"Someone verified your post: %@", postMessage];
            if (IsEmpty(postMessage)) {
                theMessage = @"Someone verified your post.";
            }

            cell.messageTextView.text = theMessage;
        }
        
    }
    else {
        // Shouldn't get here but let's print out for debugging.
        NSLog(@"Notification: %@", notification);
    }
    
    NSArray *readByArray = notification[@"read_by"];
    PFUser *meUser = [PFUser currentUser];
    cell.avatarImageView.layer.borderColor = [UIColor primaryGreen].CGColor;

    if (![readByArray containsObject:[meUser objectId]]) {
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
    
    PFNotifications *notification = (PFNotifications *)[self objectAtIndexPath:indexPath];
    [MTNotificationViewController markReadForNotification:notification];
    [self actionForNotification:notification];
}


#pragma mark - Actionable Notification Methods -
- (void)handleActionableNotification
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Loading...";
    hud.dimBackground = YES;

    // Load Notification Object
    PFQuery *queryNotification = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryNotification whereKey:@"objectId" equalTo:self.actionableNotificationId];
    [queryNotification includeKey:@"comment.challenge_post.challenge"];
    [queryNotification includeKey:@"comment.challenge_post.user"];
    [queryNotification includeKey:@"post_liked.user"];
    [queryNotification includeKey:@"post_verified.user"];
    [queryNotification includeKey:@"user"];
    [queryNotification includeKey:@"challenge_activated_ref"];

    queryNotification.cachePolicy = kPFCachePolicyNetworkOnly;
    
    MTMakeWeakSelf();
    [queryNotification findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];

        if (!error && !IsEmpty(objects)) {
            PFNotifications *notification = [objects objectAtIndex:0];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (notification) {
                    [weakSelf actionForNotification:notification];
                }
            });
            
        } else {
            NSLog(@"error - %@", error);
        }
        
        weakSelf.actionableNotificationId = nil;
    }];
}

- (void)actionForNotification:(PFNotifications *)notification
{
    NSString *notificationType = notification[@"notificationType"];
    
    if (IsEmpty(notificationType)) {
        
        // Handle some legacy notifications without type
        if (notification[@"comment"]) {
            notificationType = kNotificationPostComment;
        }
        else if (notification[@"challenge_activated_ref"]) {
            notificationType = kNotificationNewChallenge;
        }
        else if (notification[@"post_liked"]) {
            notificationType = kNotificationPostLiked;
        }
        else if (notification[@"post_verified"]) {
            notificationType = kNotificationPostVerified;
        }
    }
    
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
    else if ([notificationType isEqualToString:kNotificationNewChallenge]) {
        
        if (notification[@"challenge_activated_ref"]) {
            PFChallenges *challengeActivated = notification[@"challenge_activated_ref"];
            [self displayChallengesViewForChallengeId:challengeActivated.objectId];
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
        if (notification[@"post_to_verify"]) {
            [self displayPostDetailForNotification:notification];
        }
    }

    // Inactivity
    //  Students and Mentors have unique messages
    //
    //  Action: Take user to last open challenge
    else if ([notificationType hasPrefix:kNotificationInactivity]) {
        [self displayChallengesViewForChallengeId:[MTUtil lastViewedChallengeId]];
    }
    
    // Post Verified (unsupported)
    //
    //  Action: Take user to the post
    else if ([notificationType hasPrefix:kNotificationPostVerified]) {
        if (notification[@"post_verified"]) {
            [self displayPostDetailForNotification:notification];
        }
    }

}

- (void)displayPostDetailForNotification:(PFNotifications *)notification
{
    MTPostViewController *postVC = (MTPostViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"challengePost"];
    postVC.notification = notification;
    
    if ([postVC canPopulateForNotification:notification populate:NO]) {
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

- (void)displayChallengesViewForChallengeId:(NSString *)challengeId
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

    PFUser *user = [PFUser currentUser];
    
    [PFCloud callFunctionInBackground:@"markAllNotificationsRead" withParameters:@{@"user_id": [user objectId]} block:^(id object, NSError *error) {
        if (error) {
            NSLog(@"markAllRead, error:%@", [error localizedDescription]);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
        });
    }];
}


#pragma mark - Public Methods -
+ (void)markReadForNotificationId:(NSString *)notificationId
{
    PFUser *user = [PFUser currentUser];
    [PFCloud callFunctionInBackground:@"markNotificationRead" withParameters:@{@"user_id": [user objectId], @"notification_id": notificationId} block:^(id object, NSError *error) {
        if (error) {
            NSLog(@"markReadForNotification, error:%@", [error localizedDescription]);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
        });
    }];
}

+ (void)markReadForNotification:(PFNotifications *)notification
{
    PFUser *user = [PFUser currentUser];
    
    // Proactively, decrement notification count
    NSInteger currentCount = ((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount;
    if (currentCount > 0) {
        currentCount--;
    }
    
    if (notification[@"read_by"]) {
        NSArray *currentReadByArray = notification[@"read_by"];
        NSMutableArray *newReadByArray = [NSMutableArray arrayWithArray:currentReadByArray];
        [newReadByArray addObject:[user objectId]];
        notification[@"read_by"] = [NSArray arrayWithArray:newReadByArray];
    }
    
    ((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount = currentCount;
//    [[NSNotificationCenter defaultCenter] postNotificationName:kUnreadNotificationCountNotification object:[NSNumber numberWithInteger:currentCount]];
    
    [PFCloud callFunctionInBackground:@"markNotificationRead" withParameters:@{@"user_id": [user objectId], @"notification_id": [notification objectId]} block:^(id object, NSError *error) {
        if (error) {
            NSLog(@"markReadForNotification, error:%@", [error localizedDescription]);
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [MTNotificationViewController requestNotificationUnreadCountUpdateUsingCache:NO];
        });
    }];
}

+ (void)requestNotificationUnreadCountUpdateUsingCache:(BOOL)useCache
{
    PFUser *user = [PFUser currentUser];
    if (!user) {
        return;
    }
    
    NSString *className = user[@"class"];
    NSString *schoolName = user[@"school"];
    
    PFQuery *queryMe = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryMe whereKey:@"recipient" equalTo:user];
    
    PFQuery *queryClass = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryClass whereKeyDoesNotExist:@"recipient"];
    [queryClass whereKey:@"class" equalTo:className];
    [queryClass whereKey:@"school" equalTo:schoolName];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[queryMe, queryClass]];
    
    if (useCache) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    else {
        query.cachePolicy = kPFCachePolicyNetworkOnly;
    }
    
    [query includeKey:@"read_by"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        NSInteger count = 0;
        PFUser *meUser = [PFUser currentUser];
        for (PFNotifications *thisNotif in objects) {
            if (thisNotif[@"read_by"]) {
                NSArray *readByArray = thisNotif[@"read_by"];
                if (![readByArray containsObject:[meUser objectId]]) {
                    count++;
                }
            }
            else {
                count++;
            }
        }
        
        ((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount = count;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kUnreadNotificationCountNotification object:[NSNumber numberWithInteger:count]];
        });
    }];
}


#pragma mark - Notifications -
- (void)unreadCountUpdate:(NSNotification *)note
{
    NSNumber *count = note.object;
    self.revealButtonItem.badgeValue = [NSString stringWithFormat:@"%ld", [count integerValue]];
    [self loadObjects];
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
    if (IsEmpty(self.objects) && self.updatedObjects) {
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
