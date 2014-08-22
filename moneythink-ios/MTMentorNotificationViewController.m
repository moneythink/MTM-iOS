//
//  MTMentorNotificationViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMentorNotificationViewController.h"
#import "MBProgressHUD.h"
#import "MTMentorStudentProfileViewController.h"
#import "MTMentorStudentProgressViewController.h"
#import "MTStudentProgressTabBarViewController.h"
#import "MTNotificationTableViewCell.h"

@interface MTMentorNotificationViewController ()

@end

@implementation MTMentorNotificationViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        PFUser *user = [PFUser currentUser];
        
        PFQuery *queryMe = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
        [queryMe whereKey:@"read_by" notEqualTo:[user objectId]];
        [queryMe whereKey:@"recipient" equalTo:[user objectId]];
        [queryMe whereKeyDoesNotExist:@"challenge_activated"];
        
        PFQuery *queryNoOne = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
        [queryNoOne whereKeyDoesNotExist:@"recipient"];
        [queryNoOne whereKeyDoesNotExist:@"challenge_activated"];

        PFQuery *query = [PFQuery orQueryWithSubqueries:@[queryMe, queryNoOne]];
        [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
            if (number > 0) {
                NSString *badgeNumber = [NSString stringWithFormat:@"%d", number];
                [self.navigationController.tabBarItem setBadgeValue:badgeNumber];
            } else {
                [self.navigationController.tabBarItem setBadgeValue:nil];
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
        
        self.paginationEnabled = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.title = self.title;
}

- (void)viewWillAppear:(BOOL)animated {
    
    self.navigationController.parentViewController.navigationItem.title = @"Notifications";

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Parse

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    // This method is called every time objects are loaded from Parse via the PFQuery
    
    PFUser *user = [PFUser currentUser];
    
    [PFCloud callFunction:@"markAllNotificationsRead" withParameters:@{@"user_id": [user objectId]}];
    
    PFQuery *queryMe = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryMe whereKey:@"read_by" notEqualTo:[user objectId]];
    [queryMe whereKey:@"recipient" equalTo:[user objectId]];
    [queryMe whereKeyDoesNotExist:@"challenge_activated"];

    PFQuery *queryNoOne = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryNoOne whereKeyDoesNotExist:@"recipient"];
    [queryNoOne whereKeyDoesNotExist:@"challenge_activated"];

    PFQuery *query = [PFQuery orQueryWithSubqueries:@[queryMe, queryNoOne]];
    [query countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (number > 0) {
            NSString *badgeNumber = [NSString stringWithFormat:@"%d", number];
            [self.navigationController.tabBarItem setBadgeValue:badgeNumber];
        } else {
            [self.navigationController.tabBarItem setBadgeValue:nil];
        }
    }];
}

- (void)objectsWillLoad {
    [super objectsWillLoad];
    
    // This method is called before a PFQuery is fired to get more objects
}


- (PFQuery *)queryForTable {
    PFUser *user = [PFUser currentUser];
    PFQuery *query = [[PFQuery alloc] init];
    
    PFQuery *queryMe = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryMe whereKey:@"read_by" notEqualTo:[user objectId]];
    [queryMe whereKey:@"recipient" equalTo:[user objectId]];
    
    PFQuery *queryNoOne = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryNoOne whereKeyDoesNotExist:@"recipient"];
    
    query = [PFQuery orQueryWithSubqueries:@[queryMe, queryNoOne]];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
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
    
    PFNotifications *notification = (PFNotifications *)object;
    
    if (notification[@"user"]) {
        PFUser *user = notification[@"user"];
        cell.userName.text = [NSString stringWithFormat:@"%@ %@", user[@"first_name"], user[@"last_name"]];
        [cell.userName sizeToFit];
    }
    
    cell.agePosted.text = [self dateDiffFromDate:[notification createdAt]];
    [cell.agePosted sizeToFit];
    
    
    
     //<><><><><><><><><><> - Challenge
     // ****************** - Post
    
    if (notification[@"comment"]) { // ******************
        
        PFChallengePostComment *post = notification[@"comment"];
        cell.message.text = [NSString stringWithFormat:@"Comment: %@", post[@"comment_text"]];
        
    } else if (notification[@"post_liked"]) { // ******************
        
        PFChallengePost *post = notification[@"post_liked"];
        cell.message.text = [NSString stringWithFormat:@"Liked: %@", post[@"post_text"]];

    } else if (notification[@"post_verified"]) { // ******************
        
        PFChallengePost *post = notification[@"post_verified"];
        cell.message.text = [NSString stringWithFormat:@"Verified: %@", post[@"post_text"]];
        
    } else if (notification[@"challenge_activated"]) { //<><><><><><><><><><>
        
        NSPredicate *predChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %@", notification[@"challenge_activated"]];
        PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:predChallenge];
        [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                PFChallenges *challenge = [objects firstObject];
                cell.message.text = [NSString stringWithFormat:@"Activated: %@", challenge[@"title"]];
//            } else {
//                NSString *msg = [NSString stringWithFormat:@"%@" ,error];
//                UIAlertView *reachableAlert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                                         message:msg
//                                                                        delegate:nil
//                                                               cancelButtonTitle:@"OK"
//                                                               otherButtonTitles:nil, nil];
//                [reachableAlert show];

            }
        }];
    } else if (notification[@"challenge_closed"]) { //<><><><><><><><><><>
        NSPredicate *predChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %@", notification[@"challenge_closed"]];
        PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:predChallenge];
        [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                PFChallenges *challenge = [objects firstObject];
                cell.message.text = [NSString stringWithFormat:@"Closed: %@", challenge[@"title"]];
//            } else {
//                NSString *msg = [NSString stringWithFormat:@"%@" ,error];
//                UIAlertView *reachableAlert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                                         message:msg
//                                                                        delegate:nil
//                                                               cancelButtonTitle:@"OK"
//                                                               otherButtonTitles:nil, nil];
//                [reachableAlert show];

            }
        }];
    } else if (notification[@"challenge_completed"]) { //<><><><><><><><><><>
        NSPredicate *predChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %@", notification[@"challenge_completed"]];
        PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:predChallenge];
        [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                PFChallenges *challenge = [objects firstObject];
                cell.message.text = [NSString stringWithFormat:@"Completed: %@", challenge[@"title"]];
//            } else {
//                NSString *msg = [NSString stringWithFormat:@"%@" ,error];
//                UIAlertView *reachableAlert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                                         message:msg
//                                                                        delegate:nil
//                                                               cancelButtonTitle:@"OK"
//                                                               otherButtonTitles:nil, nil];
//                [reachableAlert show];

            }
        }];
    } else if (notification[@"challenge_started"]) { //<><><><><><><><><><>
        NSPredicate *predChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %@", notification[@"challenge_started"]];
        PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:predChallenge];
        [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                PFChallenges *challenge = [objects firstObject];
                cell.message.text = [NSString stringWithFormat:@"Started: %@", challenge[@"title"]];
//            } else {
//                NSString *msg = [NSString stringWithFormat:@"%@" ,error];
//                UIAlertView *reachableAlert = [[UIAlertView alloc] initWithTitle:@"Error"
//                                                                         message:msg
//                                                                        delegate:nil
//                                                               cancelButtonTitle:@"OK"
//                                                               otherButtonTitles:nil, nil];
//                [reachableAlert show];

            }
        }];
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
//    [self performSegueWithIdentifier:@"pushNotificationToPosts" sender:self.objects[indexPath.row]];
}

#pragma mark - date diff methods


- (NSString *)dateDiffFromDate:(NSDate *)origDate {
    NSDate *todayDate = [NSDate date];
    
    double interval     = [origDate timeIntervalSinceDate:todayDate];
    
    interval = interval * -1;
    if(interval < 1) {
    	return @"";
    } else 	if (interval < 60) {
    	return @"less than a minute ago";
    } else if (interval < 3600) {
    	int diff = round(interval / 60);
    	return [NSString stringWithFormat:@"%d minutes ago", diff];
    } else if (interval < 86400) {
    	int diff = round(interval / 60 / 60);
    	return[NSString stringWithFormat:@"%d hours ago", diff];
    } else if (interval < 604800) {
    	int diff = round(interval / 60 / 60 / 24);
    	return[NSString stringWithFormat:@"%d days ago", diff];
    } else {
    	int diff = round(interval / 60 / 60 / 24 / 7);
    	return[NSString stringWithFormat:@"%d wks ago", diff];
    }
}

- (NSString *)dateDiffFromString:(NSString *)origDate {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setFormatterBehavior:NSDateFormatterBehavior10_4];
    [df setDateFormat:@"EEE, dd MMM yy HH:mm:ss VVVV"];
    
    NSDate *convertedDate = [df dateFromString:origDate];
    
    return [self dateDiffFromDate:convertedDate];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
 */

@end
