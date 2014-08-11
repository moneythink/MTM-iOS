//
//  MTMyClassChallengePostsViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/24/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMyClassChallengePostsViewController.h"

@interface MTMyClassChallengePostsViewController ()

@property (nonatomic, strong) NSArray *posts;

@end

@implementation MTMyClassChallengePostsViewController

- (id)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = @"ChallengePost";
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = @"post_text";
        
        // The title for this table in the Navigation Controller.
        self.title = @"My Class";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSPredicate *findAllChallengePosts = [NSPredicate predicateWithFormat:@"challenge_number = %d AND class = %@", self.challengeNumber, [PFUser currentUser][@"class"]];
    PFQuery *findChallengePosts = [PFQuery queryWithClassName:[PFChallengePost parseClassName] predicate:findAllChallengePosts];
    
    [findChallengePosts findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            [self.tableView reloadData];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tappedExploreMyClass:(id)sender {
    
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

#pragma mark - UITableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.posts count];
}

    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.myClassPostsTableView dequeueReusableCellWithIdentifier:@"challengePostIdent"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"challengePostIdent"];
    }
    
    PFChallengePost *post = self.posts[indexPath.row];
    
    cell.textLabel.text = post.description;
    
    return cell;
}


#pragma mark - UITableViewDelegate methods

    // Called after the user changes the selection.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [self performSegueWithIdentifier:@"viewPost" sender:self];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(3_0)
{
    
}


@end
