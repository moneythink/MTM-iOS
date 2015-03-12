//
//  MTMentorNotificationViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMentorNotificationViewController.h"
#import "MTMentorStudentProfileViewController.h"
#import "MTMentorStudentProgressViewController.h"
#import "MTStudentProgressTabBarViewController.h"
#import "MTNotificationTableViewCell.h"
#import "MTPostsTabBarViewController.h"

@interface MTMentorNotificationViewController ()

@property (nonatomic, strong) UIView *noNotificationsView;

@end

@implementation MTMentorNotificationViewController

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
        
        // The title for this table in the Navigation Controller.
        self.title = @"Notifications";
        
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
    
    self.navigationItem.title = self.title;
    
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.parentViewController.navigationItem.title = @"Notifications";
    [self loadObjects];
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
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
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
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
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

    PFQuery *queryNoOne = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryNoOne whereKeyDoesNotExist:@"recipient"];
    [queryNoOne whereKey:@"class" equalTo:className];
    [queryNoOne whereKey:@"school" equalTo:schoolName];
    
    PFQuery *queryActivated = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryActivated whereKeyExists:@"challenge_activated"];
    [queryActivated whereKey:@"class" equalTo:className];
    [queryActivated whereKey:@"school" equalTo:schoolName];
    
    PFQuery *queryClosed = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryClosed whereKeyExists:@"challenge_closed"];
    [queryClosed whereKey:@"class" equalTo:className];
    [queryClosed whereKey:@"school" equalTo:schoolName];

    PFQuery *queryCompleted = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryCompleted whereKeyExists:@"challenge_completed"];
    [queryCompleted whereKey:@"class" equalTo:className];
    [queryCompleted whereKey:@"school" equalTo:schoolName];

    PFQuery *queryStarted = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryStarted whereKeyExists:@"challenge_started"];
    [queryStarted whereKey:@"class" equalTo:className];
    [queryStarted whereKey:@"school" equalTo:schoolName];

    PFQuery *query = [PFQuery orQueryWithSubqueries:@[queryMe, queryNoOne, queryActivated,
                                                      queryClosed, queryCompleted, queryStarted]];
    // Always pull latest from Network if available
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    [query orderByDescending:@"createdAt"];
    
    [query includeKey:@"comment"];
    [query includeKey:@"post_liked"];
    [query includeKey:@"post_verified"];
    [query includeKey:@"recipient"];
    [query includeKey:@"user"];
    
    return query;
}

// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *reuserIdentifier = @"notificationCellView";
    
    MTNotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuserIdentifier];
    if (cell == nil) {
        cell = [[MTNotificationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuserIdentifier];
    }
    
    __block NSIndexPath *weakIndexPath = indexPath;
    cell.currentIndexPath = indexPath;
    
    __block MTNotificationTableViewCell *weakCell = cell;
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    PFNotifications *notification = (PFNotifications *)object;
    
    if (notification[@"user"]) {
        PFUser *user = notification[@"user"];
        cell.userName.text = [NSString stringWithFormat:@"%@ %@", user[@"first_name"], user[@"last_name"]];
    }
    else {
        cell.userName.text = @"";
    }
    
    cell.agePosted.text = [[notification createdAt] niceRelativeTimeFromNow];
    cell.message.text = @"";
    
    //<><><><><><><><><><> - Challenge
    // ****************** - Post
    
    if (notification[@"comment"]) { // ******************
        PFChallengePostComment *post = notification[@"comment"];
        cell.message.text = [NSString stringWithFormat:@"Comment: %@", post[@"comment_text"]];
        
    }
    else if (notification[@"post_liked"]) { // ******************
        PFChallengePost *post = notification[@"post_liked"];
        cell.message.text = [NSString stringWithFormat:@"Liked: %@", post[@"post_text"]];
        
    }
    else if (notification[@"post_verified"]) { // ******************
        PFChallengePost *post = notification[@"post_verified"];
        cell.message.text = [NSString stringWithFormat:@"Verified: %@", post[@"post_text"]];
        
    }
    else if (notification[@"challenge_activated"]) { //<><><><><><><><><><>
        NSPredicate *predChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %@", notification[@"challenge_activated"]];
        PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:predChallenge];
        [challengeQuery whereKeyDoesNotExist:@"school"];
        [challengeQuery whereKeyDoesNotExist:@"class"];
        challengeQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        weakCell.message.text = @"Activated: loading...";

        [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                if (!weakCell.currentIndexPath || (weakIndexPath.row != weakCell.currentIndexPath.row)) {
                    return;
                }
                
                PFChallenges *challenge = [objects firstObject];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!IsEmpty(challenge[@"title"])) {
                        weakCell.message.text = [NSString stringWithFormat:@"Activated: %@", challenge[@"title"]];
                    }
                    else {
                        weakCell.message.text = [NSString stringWithFormat:@"Activated"];
                    }
                });
            }
            else {
                weakCell.message.text = [NSString stringWithFormat:@"Activated"];
            }
        }];
    } else if (notification[@"challenge_closed"]) { //<><><><><><><><><><>
        NSPredicate *predChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %@", notification[@"challenge_closed"]];
        PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:predChallenge];
        [challengeQuery whereKeyDoesNotExist:@"school"];
        [challengeQuery whereKeyDoesNotExist:@"class"];
        challengeQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        weakCell.message.text = @"Closed: loading...";

        [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                if (!weakCell.currentIndexPath || (weakIndexPath.row != weakCell.currentIndexPath.row)) {
                    return;
                }

                PFChallenges *challenge = [objects firstObject];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!IsEmpty(challenge[@"title"])) {
                        weakCell.message.text = [NSString stringWithFormat:@"Closed: %@", challenge[@"title"]];
                    }
                    else {
                        weakCell.message.text = [NSString stringWithFormat:@"Closed"];
                    }
                });
            }
            else {
                weakCell.message.text = [NSString stringWithFormat:@"Closed"];
            }
        }];
    } else if (notification[@"challenge_completed"]) { //<><><><><><><><><><>
        NSPredicate *predChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %@", notification[@"challenge_completed"]];
        PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:predChallenge];
        [challengeQuery whereKeyDoesNotExist:@"school"];
        [challengeQuery whereKeyDoesNotExist:@"class"];
        challengeQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        weakCell.message.text = @"Completed: loading...";

        [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                if (!weakCell.currentIndexPath || (weakIndexPath.row != weakCell.currentIndexPath.row)) {
                    return;
                }

                PFChallenges *challenge = [objects firstObject];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!IsEmpty(challenge[@"title"])) {
                        weakCell.message.text = [NSString stringWithFormat:@"Completed: %@", challenge[@"title"]];
                    }
                    else {
                        weakCell.message.text = [NSString stringWithFormat:@"Completed"];
                    }
                });
            }
            else {
                weakCell.message.text = [NSString stringWithFormat:@"Completed"];
            }

        }];
    } else if (notification[@"challenge_started"]) { //<><><><><><><><><><>
        NSPredicate *predChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %@", notification[@"challenge_started"]];
        PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:predChallenge];
        [challengeQuery whereKeyDoesNotExist:@"school"];
        [challengeQuery whereKeyDoesNotExist:@"class"];
        challengeQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        weakCell.message.text = @"Started: loading...";

        [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                if (!weakCell.currentIndexPath || (weakIndexPath.row != weakCell.currentIndexPath.row)) {
                    return;
                }

                PFChallenges *challenge = [objects firstObject];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!IsEmpty(challenge[@"title"])) {
                        weakCell.message.text = [NSString stringWithFormat:@"Started: %@", challenge[@"title"]];
                    }
                    else {
                        weakCell.message.text = [NSString stringWithFormat:@"Started"];
                    }
                });
            }
            else {
                weakCell.message.text = [NSString stringWithFormat:@"Started"];
            }
        }];
    }
    else {
        // Shouldn't get here but let's print out for debugging.
        NSLog(@"Notification: %@", notification);
    }
    
    
    return cell;
}

-(void)exploreChallenge:(PFChallenges *)challenge
{
    NSPredicate *challengePredicate = [NSPredicate predicateWithFormat:@"challenge_number = %@", challenge[@"challenge_number"]];
    PFQuery *queryActivated = [PFQuery queryWithClassName:[PFChallengesActivated parseClassName] predicate:challengePredicate];
    
    __block NSInteger count;
    
    queryActivated.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [queryActivated countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            count = number;
            
            NSString *type = [PFUser currentUser][@"type"];
            switch (count) {
                case 0: // not activated
                    if ([type isEqualToString:@"mentor"]) {
                        [self performSegueWithIdentifier:@"exploreChallenge" sender:self];
                    }
                    break;
                    
                default: {
                    [self performSegueWithIdentifier:@"exploreChallenge" sender:self];
                }
                    break;
            }
        }
    }];
}


#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    MTPostsTabBarViewController *destination = (MTPostsTabBarViewController *)[segue destinationViewController];
    PFChallenges *challenge = sender;
    
    destination.challenge = challenge;
    destination.challengeNumber = challenge[@"challenge_number"];
}


@end
