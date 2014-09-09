//
//  MTNotificationsViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTNotificationsViewController.h"
#import "MTPostsTabBarViewController.h"
#import "MTPostViewController.h"

@interface MTNotificationsViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MTNotificationsViewController

- (id)init
{
    self = [super init];

    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = [PFNotifications parseClassName];
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = @"class";
        
        // The title for this table in the Navigation Controller.
        self.title = @"Notifications";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
    } else {

    }
    return self;
}

- (void)viewDidLoad
{
    
}

- (void)viewWillAppear:(BOOL)animated
{
    self.parentViewController.navigationItem.title = @"Notifications";
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
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


// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable {
    PFUser *user = [PFUser currentUser];
    NSString *userID = [user objectId];
    NSString *className = user[@"class"];
    NSString *schoolName = user[@"school"];
    
    
    PFQuery *queryMe = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryMe whereKey:@"recipient" equalTo:user];
    [queryMe whereKey:@"read_by" notEqualTo:userID];
    [queryMe whereKey:@"class" equalTo:className];
    [queryMe whereKey:@"school" equalTo:schoolName];
    
    
    PFQuery *queryNoOne = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryNoOne whereKeyDoesNotExist:@"recipient"];
    [queryNoOne whereKey:@"read_by" notEqualTo:userID];
    [queryNoOne whereKey:@"class" equalTo:className];
    [queryNoOne whereKey:@"school" equalTo:schoolName];
    
    PFQuery *queryActivated = [PFQuery queryWithClassName:[PFNotifications parseClassName]];
    [queryActivated whereKeyExists:@"challenge_activated"];
    
    [queryActivated whereKey:@"school" equalTo:schoolName];
    [queryActivated whereKey:@"read_by" notEqualTo:userID];
    
    PFQuery *query = [PFQuery orQueryWithSubqueries:@[queryMe, queryNoOne, queryActivated]];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [query includeKey:@"comment"];
    [query includeKey:@"post_liked"];
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
    
    if (notification[@"post_liked"]) {
        PFChallengePost *post = notification[@"post_liked"];
        
        
        // >>>>> Attributed hashtag
        cell.textLabel.text = post[@"post_text"];
        NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
        NSRange rangeAll = NSMakeRange(0, cell.textLabel.text.length);
        
        [hashtags enumerateMatchesInString:cell.textLabel.text options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSMutableAttributedString *hashtag = [[NSMutableAttributedString alloc]initWithString:cell.textLabel.text];
            [hashtag addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
            
            cell.textLabel.attributedText = hashtag;
        }];
        // Attributed hashtag
        
        
    } else if (notification[@"challenge_started"]) {
        cell.textLabel.text = notification[@"challenge_started"];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"notification #%ld", (long)indexPath.row];
    }
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFObject *rowObject = self.objects[indexPath.row];
    
    [self performSegueWithIdentifier:@"pushNotificationToPosts" sender:rowObject];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueIdentifier = [segue identifier];
    
    if ([segueIdentifier isEqualToString:@"pushViewPost"]) {
        MTPostViewController *destinationViewController = (MTPostViewController *)[segue destinationViewController];
        destinationViewController.challengePost = (PFChallengePost *)sender;
    } else if ([segueIdentifier isEqualToString:@"pushNotificationToPosts"]) {

    }
}

@end
