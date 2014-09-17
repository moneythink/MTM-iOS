//
//  MTExploreChallengeViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/23/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTExploreChallengeViewController.h"
#import "MTPostsTabBarViewController.h"

@interface MTExploreChallengeViewController ()

@end

@implementation MTExploreChallengeViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    MTPostsTabBarViewController *postTabBarViewController = (MTPostsTabBarViewController *)self.parentViewController;
    self.challengeNumber = [postTabBarViewController.challengeNumber intValue];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:NO];
    
    NSPredicate *findAllChallengePosts = [NSPredicate predicateWithFormat:@"challenge_number = %d", self.challengeNumber];
    PFQuery *findChallengePosts = [PFQuery queryWithClassName:[PFChallengePost parseClassName] predicate:findAllChallengePosts];
    
    findChallengePosts.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [findChallengePosts findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.challenges = objects;
            
            [self.explorePostsTableView reloadData];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tappedExploreMyClass:(id)sender {
    
}

- (IBAction)unwindToExploreChallanges:(UIStoryboardSegue *)sender
{
}

- (IBAction)swipeChallengePostsMyClass:(id)sender {
    [self performSegueWithIdentifier:@"pushMyClass" sender:nil];
}

#pragma mark - UITableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = [self.challenges count];
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.explorePostsTableView dequeueReusableCellWithIdentifier:@"challengePostIdent"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"challengePostIdent"];
    }
    
    PFChallengePost *post = self.challenges[indexPath.row];
    
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

    PFUser *poster = post[@"user"];
    NSPredicate *posterWithID = [NSPredicate predicateWithFormat:@"objectId = %@", [poster objectId]];
    PFQuery *findPoster = [PFQuery queryWithClassName:[PFUser parseClassName] predicate:posterWithID];
    poster = [[findPoster findObjects] firstObject];
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@", poster[@"first_name"], poster[@"last_name"]];
    
    return cell;
}


@end
