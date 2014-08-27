
//  MTScheduleTableViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 8/5/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTScheduleTableViewController.h"

@interface MTScheduleTableViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation MTScheduleTableViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = [PFScheduledActivations parseClassName];
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = @"challenge_number";
        
        // The title for this table in the Navigation Controller.
        self.title = @"Challenge Schedule";
        
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
    
    PFQuery *queryActivations = [PFQuery queryWithClassName:[PFScheduledActivations parseClassName]];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if ([self.objects count] == 0) {
        queryActivations.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [queryActivations orderByAscending:@"challenge_number"];
    
    return queryActivations;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    NSString *CellIdentifier = @"activationCell";
    
    MTActivationTableViewCell *cell = (MTActivationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MTActivationTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    PFScheduledActivations *activation = (PFScheduledActivations *)object;
    id challengeNumber = activation[@"challenge_number"];
    
    NSPredicate *challengePredicate = [NSPredicate predicateWithFormat:@"challenge_number = %@", challengeNumber];
    PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:challengePredicate];
    
    [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            PFChallenges *challenge = (PFChallenges *)[objects firstObject];
            cell.challengeNumber.text = [challengeNumber stringValue];
            cell.challengeTitle.text = challenge[@"title"];
            NSDate *activationDate = activation[@"activation_date"];
            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateStyle:NSDateFormatterMediumStyle];
            [dateFormat setTimeStyle:NSDateFormatterNoStyle];
            cell.activationDate.text = [dateFormat stringFromDate:activationDate];
        }
    }];
    
    BOOL activated = [activation[@"activated"] boolValue];
    
    if (activated) {
        [cell setBackgroundColor:[UIColor primaryGreen]];
    } else {
        [cell setBackgroundColor:[UIColor white]];
    }

    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
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
