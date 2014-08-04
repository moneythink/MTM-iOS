//
//  MTChallengePostsViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/26/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTChallengePostsViewController.h"
#import "MTPostsTableViewCell.h"

@interface MTChallengePostsViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MTChallengePostsViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = @"ChallengePost";
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = @"post_text";
        
        // The title for this table in the Navigation Controller.
        self.title = @"Explore";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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


// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable {
    MTChallengePostsViewController *postTabBarViewController = (MTChallengePostsViewController *)self.parentViewController;
    self.challengeNumber = postTabBarViewController.challengeNumber;
    
    self.className = [PFUser currentUser][@"class"];
    
    NSPredicate *challengeNumber = [NSPredicate predicateWithFormat:@"challenge_number = %d AND class = %@",
                                    [self.challengeNumber intValue], self.className];
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName predicate:challengeNumber];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [query includeKey:@"user"];
    [query includeKey:@"reference_post"];
    
    return query;
}


// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"postCell";
    
    MTPostsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MTPostsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    PFChallengePost *post = (PFChallengePost *)object;
    
    PFUser *user = post[@"user"];
    cell.userName.text = [user username];
    
    cell.profileImage.file = user[@"profile_picture"];
    [cell.profileImage loadInBackground];
    
    cell.postText.text = post[@"post_text"];
    
    cell.postImage.file = post[@"picture"];
    [cell.postImage loadInBackground];
    
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
