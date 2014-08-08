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

@interface MTMentorNotificationViewController ()

@end

@implementation MTMentorNotificationViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = @"Notifications";
        
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Parse

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    // This method is called every time objects are loaded from Parse via the PFQuery
}

- (void)objectsWillLoad {
    [super objectsWillLoad];
    
    // This method is called before a PFQuery is fired to get more objects
}


- (PFQuery *)queryForTable {
    
    
    PFQuery *query = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    
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
    static NSString *CellIdentifier = @"postCell";
    
    PFTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[PFTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    PFNotifications *notification = (PFNotifications *)object;
    
    NSLog(@"object - %@", object);
    
    __block NSString *longText = @"";
    
    if (notification[@"comment"]) {
        NSLog(@"<><><><><><><><>comment - %@", notification[@"comment"]);
        longText = [longText stringByAppendingString:@", comment: "];
        PFChallengePost *post = notification[@"comment"];
        longText = [longText stringByAppendingString:post[@"comment_text"]];
    }
    
    if (notification[@"post_liked"]) {
        NSLog(@"<><><><><><><><>post_liked - %@", notification[@"post_liked"]);
        longText = [longText stringByAppendingString:@", post_liked: "];
        PFChallengePost *post = notification[@"post_liked"];
        longText = [longText stringByAppendingString:post[@"post_text"]];
    }
    
    if (notification[@"post_verified"]) {
        NSLog(@"<><><><><><><><>post_verified - %@", notification[@"post_verified"]);
        longText = [longText stringByAppendingString:@", post_verified: "];
        PFChallengePost *post = notification[@"post_verified"];
        longText = [longText stringByAppendingString:post[@"post_text"]];
    }
    
    if (notification[@"recipient"]) {
        NSLog(@"<><><><><><><><>recipient - %@", notification[@"recipient"]);
        longText = [longText stringByAppendingString:@", recipient: "];
        PFUser *user = notification[@"recipient"];
        longText = [longText stringByAppendingString:[user username]];
    }
    
    if (notification[@"user"]) {
        NSLog(@"<><><><><><><><>user - %@", notification[@"user"]);
        longText = [longText stringByAppendingString:@", user: "];
        PFUser *user = notification[@"user"];
        longText = [longText stringByAppendingString:[user username]];
    }
    
    if (notification[@"challenge_activated"]) {
        NSLog(@"<><><><><><><><>challenge_activated - %@", notification[@"challenge_activated"]);
        longText = [longText stringByAppendingString:@", challenge_activated: "];
        NSPredicate *predChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %@", notification[@"challenge_activated"]];
        PFQuery *challenge = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:predChallenge];
        [challenge findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                PFChallenges *challenge = [objects firstObject];
                longText = [longText stringByAppendingString:challenge[@"title"]];
            } else {
                longText = [longText stringByAppendingString:@"error - challenge_activated"];
            }
        }];
    }
    
    if (notification[@"challenge_closed"]) {
        NSLog(@"<><><><><><><><>challenge_closed - %@", notification[@"challenge_closed"]);
        longText = [longText stringByAppendingString:@", challenge_closed: "];
        
        NSPredicate *predChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %@", notification[@"challenge_closed"]];
        PFQuery *challenge = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:predChallenge];
        [challenge findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                PFChallenges *challenge = [objects firstObject];
                longText = [longText stringByAppendingString:challenge[@"title"]];
            } else {
                longText = [longText stringByAppendingString:@"error - challenge_closed"];
            }
        }];
    }
    
    if (notification[@"challenge_completed"]) {
        NSLog(@"<><><><><><><><>challenge_completed - %@", notification[@"challenge_completed"]);
        longText = [longText stringByAppendingString:@", challenge_completed: "];
        
        NSPredicate *predChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %@", notification[@"challenge_completed"]];
        PFQuery *challenge = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:predChallenge];
        [challenge findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                PFChallenges *challenge = [objects firstObject];
                longText = [longText stringByAppendingString:challenge[@"title"]];
            } else {
                longText = [longText stringByAppendingString:@"error - challenge_completed"];
            }
        }];
    }
    
    if (notification[@"challenge_started"]) {
        NSLog(@"<><><><><><><><>challenge_started - %@", notification[@"challenge_started"]);
        longText = [longText stringByAppendingString:@", challenge_started: "];
        
        NSPredicate *predChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %@", notification[@"challenge_started"]];
        PFQuery *challenge = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:predChallenge];
        [challenge findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                PFChallenges *challenge = [objects firstObject];
                longText = [longText stringByAppendingString:challenge[@"title"]];
            } else {
                longText = [longText stringByAppendingString:@"error - challenge_started"];
            }
        }];
    }
    
    if ([cell.textLabel.text isEqualToString:@""]) {
        longText = [longText stringByAppendingString:@"<><><><><><><><>row - %d"];
    }
    
    NSString *rowString = [NSString stringWithFormat:@"%d", indexPath.row];
    longText = [rowString stringByAppendingString:longText];
    cell.textLabel.text = longText;
    
    return cell;
}


/*
 // Override if you need to change the ordering of objects in the table.
 - (PFObject *)objectAtIndex:(NSIndexPath *)indexPath {
 return [objects objectAtIndex:indexPath.row];
 }
 */

// Override to customize the look of the cell that allows the user to load the next page of objects.
// The default implementation is a UITableViewCellStyleDefault cell with simple labels.
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
//    static NSString *CellIdentifier = @"NextPage";
//
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//
//    if (cell == nil) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//    }
//
//    cell.selectionStyle = UITableViewCellSelectionStyleNone;
//
//    return cell;
//}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    PFObject *rowObject = self.objects[indexPath.row];
    
    [self performSegueWithIdentifier:@"someNamedSegue" sender:self.objects[indexPath.row]];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    
}

@end
