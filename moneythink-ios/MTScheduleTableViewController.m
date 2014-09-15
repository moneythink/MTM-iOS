
//  MTScheduleTableViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 8/5/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTScheduleTableViewController.h"

@interface MTScheduleTableViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *availableChallenges;
@property (strong, nonatomic) NSArray *futureChallenges;

@end

@implementation MTScheduleTableViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.title = @"Challenge Schedule";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString *userSchool = [PFUser currentUser][@"school"];
    NSString *userClass = [PFUser currentUser][@"class"];
    
    PFQuery *queryActivations = [PFQuery queryWithClassName:[PFScheduledActivations parseClassName]];
    [queryActivations whereKey:@"activated" equalTo:@YES];
    [queryActivations whereKey:@"school" equalTo:userSchool];
    [queryActivations whereKey:@"class" equalTo:userClass];
    
    [queryActivations orderByAscending:@"challenge_number"];

//    queryActivations.cachePolicy = kPFCachePolicyCacheThenNetwork;
//    
    [queryActivations findObjectsInBackgroundWithBlock:^(NSArray *availableObjects, NSError *error) {
        if (!error) {
            self.availableChallenges = availableObjects;
            [self.tableView reloadData];
        } else {
            NSLog(@"error - %@", error);
        }
    }];

    
    PFQuery *queryFuture = [PFQuery queryWithClassName:[PFScheduledActivations parseClassName]];
    [queryFuture whereKey:@"activated" equalTo:@NO];
    [queryFuture whereKey:@"school" equalTo:userSchool];
    [queryFuture whereKey:@"class" equalTo:userClass];

    [queryFuture orderByAscending:@"challenge_number"];

//    queryFuture.cachePolicy = kPFCachePolicyCacheThenNetwork;
//    
    [queryFuture findObjectsInBackgroundWithBlock:^(NSArray *scheduledObjects, NSError *error) {
        if (!error) {
            self.futureChallenges = scheduledObjects;
            [self.tableView reloadData];
        } else {
            
        }
    }];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sections = 0;
    
    if (self.futureChallenges.count > 0) {
        sections += 1;
    }
    
    if (self.availableChallenges.count > 0) {
        sections += 1;
    }
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger rows = 0;
    
    NSInteger available = self.availableChallenges.count;
    NSInteger future = self.futureChallenges.count;
    
    switch (section) {
        case 0: {
            if (available > 0) {
                rows = available;
            }
        }
            break;
            
        default: {
            if (future > 0) {
                rows = future;
            }
        }
            break;
    }
    
    return rows;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title = @"";

    NSInteger available = self.availableChallenges.count;
    NSInteger future = self.futureChallenges.count;
    
    switch (section) {
        case 0: {
            if (available > 0) {
                title = @"AVAILABLE CHALLENGES";
            }
        }
            break;
            
        default: {
            if (future > 0) {
                title = @"FUTURE CHALLENGES";
            }
        }
            break;
    }
    
    return title;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    [header.textLabel setTextColor:[UIColor blackColor]];
    [header.contentView setBackgroundColor:[UIColor mutedOrange]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = @"activationCell";
    
    MTActivationTableViewCell *cell = (MTActivationTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MTActivationTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    NSInteger available = self.availableChallenges.count;
    NSInteger future = self.futureChallenges.count;
    
    PFChallengesActivated *activation;
    
    switch (section) {
        case 0: {
            if (available > 0) {
                activation = self.availableChallenges[row];
            } else {
                return nil;
            }
        }
            break;
            
        default: {
            if (future > 0) {
                activation = self.futureChallenges[row];
            } else {
                return nil;
            }
        }
            break;
    }
    
    id challengeNumber = activation[@"challenge_number"];
    
    NSPredicate *challengePredicate = [NSPredicate predicateWithFormat:@"challenge_number = %@", challengeNumber];
    PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:challengePredicate];
    [challengeQuery whereKeyDoesNotExist:@"school"];
    [challengeQuery whereKeyDoesNotExist:@"class"];

//    challengeQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
//    
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
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
