
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
@property (nonatomic, strong) UISwitch *autoReleaseSwitch;
@property (nonatomic) BOOL scheduledActivationsOn;

@property (nonatomic) BOOL queriedAvailableChallenges;
@property (nonatomic) BOOL queriedFutureChallenges;
@property (nonatomic) BOOL queriedForActivationsOn;

@end

@implementation MTScheduleTableViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.title = @"Schedule";
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.queriedAvailableChallenges = NO;
    self.queriedFutureChallenges = NO;
    self.queriedForActivationsOn = NO;
    
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Loading...";
    hud.dimBackground = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self loadData];
    [[MTUtil getAppDelegate] setGrayNavBarAppearanceForNavigationBar:self.navigationController.navigationBar];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Start at 1 to include activation toggle
    NSInteger sections = 1;
    
    if (self.futureChallenges.count > 0) {
        sections += 1;
    }
    
    if (self.availableChallenges.count > 0) {
        sections += 1;
    }
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    
    NSInteger available = self.availableChallenges.count;
    NSInteger future = self.futureChallenges.count;
    
    switch (section) {
        case 0:
        {
            return 1;
            break;
        }
        case 1:
        {
            if (available > 0) {
                rows = available;
            }
            break;
        }
            
        default:
        {
            if (future > 0) {
                rows = future;
            }
            break;
        }
    }
    
    return rows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height;
    
    switch (section) {
        case 0:
        {
            height = 0.0f;
            break;
        }
            
        default:
            height = 40.0f;
            break;
    }
    
    return height;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return nil;
    }
    
    static NSString *CellIdentifier = @"ScheduleSectionHeader";
    
    UITableViewCell *headerView = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (headerView == nil) {
        [NSException raise:@"headerView == nil.." format:@"No cells with matching CellIdentifier loaded from your storyboard"];
        return nil;
    }
    
    // Gets around long-press interaction on content.
    //  http://stackoverflow.com/questions/9219234/how-to-implement-custom-table-view-section-headers-and-footers-with-storyboard/
    while (headerView.contentView.gestureRecognizers.count) {
        [headerView.contentView removeGestureRecognizer:[headerView.contentView.gestureRecognizers objectAtIndex:0]];
    }
    
    UILabel *headerLabel = (UILabel *)[headerView viewWithTag:99];
    if (headerLabel) {
        headerLabel.text = [self titleForSection:section];
    }
    
    [[headerView.contentView viewWithTag:1000] removeFromSuperview];
    [[headerView.contentView viewWithTag:1001] removeFromSuperview];

    UIView *topSeparator = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, headerView.contentView.frame.size.width, 0.5f)];
    topSeparator.backgroundColor = [UIColor lightGrayColor];
    topSeparator.tag = 1000;
    [headerView.contentView addSubview:topSeparator];
    
    CGFloat sectionHeight = [self tableView:tableView heightForHeaderInSection:section];
    UIView *bottomSeparator = [[UIView alloc] initWithFrame:CGRectMake(0.0f, sectionHeight-0.5f, headerView.frame.size.width, 0.5f)];
    bottomSeparator.backgroundColor = [UIColor lightGrayColor];
    bottomSeparator.tag = 1001;
    [headerView.contentView addSubview:bottomSeparator];
    
    return headerView.contentView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
        case 0:
        {
            UITableViewCell *cell = (UITableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:@"autorelease"];

            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"autorelease"];
            }

            if (!self.autoReleaseSwitch) {
                self.autoReleaseSwitch = [[UISwitch alloc] init];
            }

            self.autoReleaseSwitch.on = self.scheduledActivationsOn;

            cell.textLabel.text = @"Challenges On/Off";
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            [self.autoReleaseSwitch removeTarget:self action:@selector(challengesOnOffToggle:) forControlEvents:UIControlEventValueChanged];
            [self.autoReleaseSwitch addTarget:self action:@selector(challengesOnOffToggle:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = self.autoReleaseSwitch;
        
            return cell;

            break;
        }
        case 1:
        {
            if (available > 0) {
                activation = self.availableChallenges[row];
            } else {
                return nil;
            }
        }
            break;
            
        default:
        {
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

    challengeQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;

    [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            PFChallenges *challenge = (PFChallenges *)[objects firstObject];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (challenge) {
                    if ([MTUtil displayingCustomPlaylist]) {
                        NSInteger ordering = [MTUtil orderingForChallengeObjectId:challenge.objectId];
                        if (ordering != -1) {
                            // Set ordering at +1 (starts at 0 in Parse) to match Android
                            cell.challengeNumber.text = [NSString stringWithFormat:@"%lu)", (long)ordering+1];
                        }
                        else {
                            cell.challengeNumber.text = @"";
                        }
                    }
                    else {
                        cell.challengeNumber.text = [NSString stringWithFormat:@"%@)", [challengeNumber stringValue]];
                    }
                    
                    
                    cell.challengeTitle.text = challenge[@"title"];
                }
                else {
                    cell.challengeNumber.text = @"";
                    cell.challengeTitle.text = @"";
                }
                
                NSDate *activationDate = activation[@"activation_date"];
                
                if (activationDate) {
                    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                    [dateFormat setDateFormat:@"MM-dd-yyyy"];
                    cell.activationDate.text = [dateFormat stringFromDate:activationDate];
                }
                else {
                    cell.activationDate.text = @"Paused";
                }
            });
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


#pragma mark - UIAlertViewDelegate methods -
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (self.autoReleaseSwitch.on) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            self.scheduledActivationsOn = NO;
            self.autoReleaseSwitch.enabled = YES;
            [self.tableView reloadData];
        }
        else {
            [self activateSchedules];
        }
    }
    else {
        if (buttonIndex == alertView.cancelButtonIndex) {
            self.scheduledActivationsOn = YES;
            self.autoReleaseSwitch.enabled = YES;
            [self.tableView reloadData];
        }
        else {
            [self deactivateSchedules];
        }
    }
}


#pragma mark - Private -
- (void)challengesOnOffToggle:(id)sender
{
    if (![MTUtil internetReachable]) {
        [UIAlertView showNoInternetAlert];
        return;
    }
    
    self.autoReleaseSwitch.enabled = NO;
    
    if (self.autoReleaseSwitch.on) {
        NSString *title = @"Turn Challenges ON";
        NSString *message = @"Woohoo! You're about to unlock challenges for your students! Every week at this time, a new challenge will be unlocked. Check out the schedule for details.";
        
        [[[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] show];
        
    } else {
        NSString *title = @"Turn Challenges OFF";
        NSString *message = @"Are you sure you want to turn challenges off?  No new challenges will be unlocked until you turn challenges back on. (The challenges that are already open will stay open.)";
        
        [[[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil] show];
    }
}

- (void)activateSchedules
{
    // Mark user activated challenges
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserActivatedChallenges];
    [[NSUserDefaults standardUserDefaults] synchronize];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Turning ON...";
    hud.dimBackground = YES;
    
    PFUser *user = [PFUser currentUser];
    NSString *userID = [user objectId];
    
    MTMakeWeakSelf();
    [PFCloud callFunctionInBackground:@"scheduleActivations" withParameters:@{@"user_id": userID} block:^(id object, NSError *error) {
        if (!error) {
            
            // Make sure we have future challenges, otherwise display message
            NSString *nameClass = [PFUser currentUser][@"class"];
            NSString *nameSchool = [PFUser currentUser][@"school"];
            
            NSPredicate *futureActivations = [NSPredicate predicateWithFormat:@"class = %@ AND school = %@ AND activation_date != nil AND activated = NO", nameClass, nameSchool];
            PFQuery *scheduledActivations = [PFQuery queryWithClassName:[PFScheduledActivations parseClassName] predicate:futureActivations];
            scheduledActivations.cachePolicy = kPFCachePolicyNetworkOnly;
            
            MTMakeWeakSelf();
            [scheduledActivations countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    weakSelf.autoReleaseSwitch.enabled = YES;

                    if (!error) {
                        weakSelf.scheduledActivationsOn = (number > 0);
                        
                        if (number == 0) {
                            [weakSelf.tableView reloadData];
                            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                            [[[UIAlertView alloc] initWithTitle:@"Update Error" message:@"All of the Challenges in this schedule have been activated." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                            return;
                        }
                        
                    }
                    else {
                        weakSelf.scheduledActivationsOn = NO;
                        
                        // Log error but fail silently, we'll call loadData again anyway
                        NSLog(@"error - %@", error);
                    }
                    
                    [weakSelf loadData];
                });
            }];
            
        }
        else {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                
                NSLog(@"error - %@", error);
                NSString *errorMessage = [NSString stringWithFormat:@"Unable to turn ON schedules. %ld: %@", (long)error.code, [error localizedDescription]];
                [[[UIAlertView alloc] initWithTitle:@"Update Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                weakSelf.scheduledActivationsOn = NO;
                [weakSelf.tableView reloadData];
            });
        }
    }];
}

- (void)deactivateSchedules
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Turning OFF...";
    hud.dimBackground = YES;
    
    PFUser *user = [PFUser currentUser];
    NSString *userID = [user objectId];
    
    MTMakeWeakSelf();
    [PFCloud callFunctionInBackground:@"cancelScheduledActivations" withParameters:@{@"user_id": userID} block:^(id object, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            weakSelf.autoReleaseSwitch.enabled = YES;
            
            if (!error) {
                weakSelf.scheduledActivationsOn = NO;
                [weakSelf loadData];
            } else {
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];

                weakSelf.scheduledActivationsOn = YES;
                
                NSLog(@"error - %@", error);
                if (![MTUtil internetReachable]) {
                    [UIAlertView showNoInternetAlert];
                }
                else {
                    NSString *errorMessage = [NSString stringWithFormat:@"Unable to turn OFF schedules. %ld: %@", (long)error.code, [error localizedDescription]];
                    [[[UIAlertView alloc] initWithTitle:@"Update Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                }
                
                [weakSelf.tableView reloadData];
            }
        });
    }];
}

- (NSString *)titleForSection:(NSInteger)section
{
    NSString *title = @"";

    NSInteger available = self.availableChallenges.count;
    NSInteger future = self.futureChallenges.count;

    switch (section) {
        case 0:
        {
            break;
        }
        case 1:
        {
            if (available > 0) {
                title = @"AVAILABLE CHALLENGES";
            }
        }
            break;

        default:
        {
            if (future > 0) {
                title = @"FUTURE CHALLENGES";
            }
        }
            break;
    }

    return title;
}

- (void)loadData
{
    NSString *userSchool = [PFUser currentUser][@"school"];
    NSString *userClass = [PFUser currentUser][@"class"];
    
    PFQuery *queryActivations = [PFQuery queryWithClassName:[PFScheduledActivations parseClassName]];
    [queryActivations whereKey:@"activated" equalTo:@YES];
    [queryActivations whereKey:@"school" equalTo:userSchool];
    [queryActivations whereKey:@"class" equalTo:userClass];
    
    [queryActivations orderByAscending:@"activation_date"];
    [queryActivations addAscendingOrder:@"challenge_number"];
    queryActivations.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    MTMakeWeakSelf();
    [queryActivations findObjectsInBackgroundWithBlock:^(NSArray *availableObjects, NSError *error) {
        if (!error) {
            weakSelf.availableChallenges = availableObjects;
        } else {
            NSLog(@"error - %@", error);
        }
        
        weakSelf.queriedAvailableChallenges = YES;
        [weakSelf checkForRefresh];
    }];
    
    PFQuery *queryFuture = [PFQuery queryWithClassName:[PFScheduledActivations parseClassName]];
    [queryFuture whereKey:@"activated" equalTo:@NO];
    [queryFuture whereKey:@"school" equalTo:userSchool];
    [queryFuture whereKey:@"class" equalTo:userClass];
    
    [queryFuture orderByAscending:@"activation_date"];
    
    // TODO: Should determine proper sorting for custom playlist when "Paused"
    if (![MTUtil displayingCustomPlaylist]) {
        [queryFuture addAscendingOrder:@"challenge_number"];
    }
    
    queryFuture.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    [queryFuture findObjectsInBackgroundWithBlock:^(NSArray *scheduledObjects, NSError *error) {
        if (!error) {
            weakSelf.futureChallenges = scheduledObjects;
        }
        
        weakSelf.queriedFutureChallenges = YES;
        [weakSelf checkForRefresh];
    }];
    
    // Query for activations on
    NSString *nameClass = [PFUser currentUser][@"class"];
    NSString *nameSchool = [PFUser currentUser][@"school"];
    NSPredicate *futureActivations = [NSPredicate predicateWithFormat:@"class = %@ AND school = %@ AND activation_date != nil AND activated = NO", nameClass, nameSchool];
    PFQuery *scheduledActivations = [PFQuery queryWithClassName:[PFScheduledActivations parseClassName] predicate:futureActivations];
    scheduledActivations.cachePolicy = kPFCachePolicyNetworkOnly;
    
    [scheduledActivations countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            weakSelf.scheduledActivationsOn = (number > 0);
            weakSelf.autoReleaseSwitch.enabled = YES;

        } else {
            weakSelf.autoReleaseSwitch.enabled = NO;

            NSLog(@"error - %@", error);
            if (![MTUtil internetReachable]) {
                [UIAlertView showNoInternetAlert];
            }
            else {
                NSString *errorMessage = [NSString stringWithFormat:@"Unable to update Auto-Release information. %ld: %@", (long)error.code, [error localizedDescription]];
                [[[UIAlertView alloc] initWithTitle:@"Update Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }
        }
        
        weakSelf.queriedForActivationsOn = YES;
        [weakSelf checkForRefresh];
    }];
}

- (void)checkForRefresh
{
    if (self.queriedAvailableChallenges && self.queriedFutureChallenges && self.queriedForActivationsOn) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
            
            self.queriedAvailableChallenges = NO;
            self.queriedFutureChallenges = NO;
            self.queriedForActivationsOn = NO;

            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        });
    }
}


@end
