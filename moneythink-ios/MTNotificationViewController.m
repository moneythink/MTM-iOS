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

@interface MTNotificationViewController ()

@property (nonatomic, weak) IBOutlet UIBarButtonItem *revealButtonItem;

@property (nonatomic, strong) UIView *noNotificationsView;

@end

@implementation MTNotificationViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        PFUser *user = [PFUser currentUser];
        NSString *userID = [user objectId];
        NSString *className = user[@"class"];
        NSString *schoolName = user[@"school"];
        
        [PFCloud callFunctionInBackground:@"markAllNotificationsRead" withParameters:@{@"user_id": [user objectId]} block:^(id object, NSError *error) {
            if (!error) {
                PFQuery *queryMe = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
                [queryMe whereKey:@"recipient" equalTo:user];
                [queryMe whereKey:@"class" equalTo:className];
                [queryMe whereKey:@"school" equalTo:schoolName];
                [queryMe whereKey:@"read_by" notEqualTo:userID];
                
                PFQuery *queryNoOne = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
                [queryNoOne whereKeyDoesNotExist:@"recipient"];
                [queryNoOne whereKey:@"class" equalTo:className];
                [queryNoOne whereKey:@"school" equalTo:schoolName];
                [queryNoOne whereKey:@"read_by" notEqualTo:userID];
                
                PFQuery *query = [PFQuery orQueryWithSubqueries:@[queryMe, queryNoOne]];
                query.cachePolicy = kPFCachePolicyCacheThenNetwork;
                
                [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                    if (number > 0) {
                        NSString *badgeNumber = [NSString stringWithFormat:@"%d", number];
                        [self.navigationController.tabBarItem setBadgeValue:badgeNumber];
                    } else {
                        [self.navigationController.tabBarItem setBadgeValue:nil];
                    }
                }];
            } else {
                NSLog(@"error - %@", error);
            }
        }];
        
        // Custom the table
        
        // The className to query on
        self.parseClassName = [PFNotifications parseClassName];
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = @"challenge_started";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
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
    
    // Add a no notifications view
    self.noNotificationsView = [[UIView alloc] initWithFrame:self.tableView.frame];
    self.noNotificationsView.backgroundColor = [UIColor whiteColor];
    UILabel *noNotificationsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 20.0f, self.view.frame.size.width, 44.0f)];
    noNotificationsLabel.backgroundColor = [UIColor clearColor];
    noNotificationsLabel.text = @"No Notifications";
    noNotificationsLabel.font = [UIFont mtFontOfSize:18.0f];
    noNotificationsLabel.textAlignment = NSTextAlignmentCenter;
    [self.noNotificationsView addSubview:noNotificationsLabel];
    [self.view addSubview:self.noNotificationsView];
    
    SWRevealViewController *revealViewController = self.revealViewController;
    if (revealViewController) {
        [self.revealButtonItem setTarget: self.revealViewController];
        [self.revealButtonItem setAction: @selector(revealToggle:)];
        [self.navigationController.navigationBar addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    }
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_actionbar"]];
    
    // Set the gesture
    //  Add tag = 5000 so panGestureRecognizer can be re-added
    self.navigationController.navigationBar.tag = 5000;
    [self.navigationController.navigationBar addGestureRecognizer:self.revealViewController.panGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadObjects];
    
    if (self.actionableNotificationId) {
        [self handleActionableNotification];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
}


#pragma mark - Parse
- (void)objectsDidLoad:(NSError *)error
{
    [super objectsDidLoad:error];
    
    // This method is called every time objects are loaded from Parse via the PFQuery
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
    
    if (!IsEmpty(self.objects)) {
        self.noNotificationsView.alpha = 0.0f;
        [self.view bringSubviewToFront:self.tableView];
    }
    else {
        self.noNotificationsView.alpha = 1.0f;
        [self.view bringSubviewToFront:self.noNotificationsView];
    }
}

- (void)objectsWillLoad
{
    [super objectsWillLoad];
    
    // This method is called before a PFQuery is fired to get more objects
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    
    if ([self.objects count] == 0) {
        hud.labelText = @"Loading...";
    }
    else {
        hud.labelText = @"Refreshing...";
    }
    hud.dimBackground = YES;
}

- (PFQuery *)queryForTable
{
    PFUser *user = [PFUser currentUser];
    NSString *className = user[@"class"];
    NSString *schoolName = user[@"school"];

    PFQuery *queryMe = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryMe whereKey:@"recipient" equalTo:user];

    PFQuery *queryClass = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryClass whereKeyDoesNotExist:@"recipient"];
    [queryClass whereKey:@"class" equalTo:className];
    [queryClass whereKey:@"school" equalTo:schoolName];
    
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
        [cell.avatarImageView loadInBackground:^(UIImage *image, NSError *error) {
            if (!error) {
                if (image) {
                    cell.avatarImageView.image = image;
                    [cell setNeedsDisplay];
                }
                else {
                    cell.avatarImageView.image = nil;
                }
            } else {
                NSLog(@"error - %@", error);
            }
        }];
    }
    
    cell.agePosted.text = [[notification createdAt] niceRelativeTimeFromNow];
    cell.agePosted.textColor = [UIColor primaryGreen];
    
    NSString *notificationType = notification[@"notification_type"];
    
    // TODO, remove hard code, get actual values
    if (notification[@"comment"]) {
        notificationType = kNotificationPostComment;
    }
    else if (notification[@"challenge_activated_ref"]) {
        notificationType = kNotificationNewChallenge;
    }
    else if (notification[@"post_liked"]) {
        notificationType = kNotificationPostLiked;
    }
    else if (notification[@"leader_on"]) {
        notificationType = kNotificationLeaderOn;
    }
    else if (notification[@"leader_off"]) {
        notificationType = kNotificationLeaderOff;
    }
    else if (notification[@"inactivity"]) {
        notificationType = kNotificationInactivity;
    }
    else if (notification[@"verify_post"]) {
        notificationType = kNotificationVerifyPost;
    }
    
    cell.messageTextView.textContainerInset = UIEdgeInsetsZero;
    cell.messageTextView.textContainer.lineFragmentPadding = 0;

    if ([notificationType isEqualToString:kNotificationPostComment]) {
        PFChallengePostComment *post = notification[@"comment"];
        
        if (!IsEmpty(username)) {
            NSString *theMessage = [NSString stringWithFormat:@"%@ commented on your post: %@",username, post[@"comment_text"]];
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
        
        if (!IsEmpty(username)) {
            NSString *theMessage = [NSString stringWithFormat:@"%@ liked your post: %@", username, post[@"post_text"]];
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
            cell.messageTextView.text = [NSString stringWithFormat:@"Someone liked your post: %@", post[@"post_text"]];
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
        cell.messageTextView.text = @"Congrats, you're top of the leaderboard.";
    }
    else if ([notificationType isEqualToString:kNotificationLeaderOff]) {
        cell.messageTextView.text = @"Watch out - your classmate is now top of the leaderboard.";
    }
    else if ([notificationType isEqualToString:kNotificationInactivity]) {
        cell.messageTextView.text = @"Where’d you go? Check out what your friends are posting.";
    }
    else if ([notificationType isEqualToString:kNotificationVerifyPost]) {
        cell.messageTextView.text = @"Your class has posts that need verification!";
    }
    else {
        // Shouldn't get here but let's print out for debugging.
        NSLog(@"Notification: %@", notification);
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    PFNotifications *notification = (PFNotifications *)[self objectAtIndexPath:indexPath];
    [self actionForNotification:notification];
}


#pragma mark - Actionable Notification Methods -
- (void)handleActionableNotification
{
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
        if (!error && !IsEmpty(objects)) {
            PFNotifications *notification = [objects objectAtIndex:0];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf displayPostDetailForNotification:notification];
            });
            
        } else {
            NSLog(@"error - %@", error);
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        }
        
        weakSelf.actionableNotificationId = nil;
    }];
}

- (void)actionForNotification:(PFNotifications *)notification
{
    NSString *notificationType = notification[@"notification_type"];
    
    // TODO, remove hard code, get actual values
    if (notification[@"comment"]) {
        notificationType = kNotificationPostComment;
    }
    else if (notification[@"challenge_activated_ref"]) {
        notificationType = kNotificationNewChallenge;
    }
    else if (notification[@"post_liked"]) {
        notificationType = kNotificationPostLiked;
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
            [self displayChallengesViewForChallenge:challengeActivated];
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
        if (notification[@"verify_post"]) {
            [self displayPostDetailForNotification:notification];
        }
    }

    // Inactivity
    //  Students and Mentors have unique messages
    //
    //  Action: Take user to current open challenge
    else if ([notificationType isEqualToString:kNotificationInactivity]) {
        if (notification[@"challenge_open"]) {
            PFChallenges *challengeOpen = notification[@"challenge_open"];
            [self displayChallengesViewForChallenge:challengeOpen];
        }
    }
}

- (void)displayPostDetailForNotification:(PFNotifications *)notification
{
    MTPostViewController *postVC = (MTPostViewController *)[self.storyboard instantiateViewControllerWithIdentifier:@"challengePost"];
    postVC.notification = notification;
    
    __block UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:postVC];
    [self.revealViewController presentViewController:nav animated:YES completion:nil];
}

- (void)displayChallengesViewForChallenge:(PFChallenges *)challenge
{
    MTMenuViewController *menuVC = (MTMenuViewController *)self.revealViewController.rearViewController;
    [menuVC openChallengesForChallenge:challenge];
}


@end
