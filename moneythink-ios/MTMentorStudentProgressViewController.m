//
//  MTMentorStudentProgressViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMentorStudentProgressViewController.h"
#import "MTStudentProgressTableViewCell.h"
#import "MICheckBox.h"
#import "MTMentorStudentProfileViewController.h"
#import "MTScheduleTableViewController.h"

@interface MTMentorStudentProgressViewController ()

@property (nonatomic, strong) UISwitch *autoReleaseSwitch;
@property (nonatomic) BOOL scheduledActivationsOn;

@end

@implementation MTMentorStudentProgressViewController

- (id)init
{
    self = [super init];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.parentViewController.navigationItem.title = @"Students";
    
    [self.tableView reloadData];
    
    self.autoReleaseSwitch.enabled = NO;
    
    NSPredicate *futureActivations = [NSPredicate predicateWithFormat:@"activation_date != nil && activated = NO"];
    PFQuery *scheduledActivations = [PFQuery queryWithClassName:[PFScheduledActivations parseClassName] predicate:futureActivations];
    scheduledActivations.cachePolicy = kPFCachePolicyNetworkOnly;
    
    MTMakeWeakSelf();
    [scheduledActivations countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            weakSelf.scheduledActivationsOn = (number > 0);
        } else {
            NSLog(@"error - %@", error);
            if (![MTUtil internetReachable]) {
                [UIAlertView showNoInternetAlert];
            }
            else {
                NSString *errorMessage = [NSString stringWithFormat:@"Unable to update Auto-Release information. %lu: %@", error.code, [error localizedDescription]];
                [[[UIAlertView alloc] initWithTitle:@"Update Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }
        }
        
        weakSelf.autoReleaseSwitch.enabled = YES;
        [weakSelf.tableView reloadData];
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:NO];
    
    NSString *nameClass = [PFUser currentUser][@"class"];
    NSString *nameSchool = [PFUser currentUser][@"school"];
    NSString *type = @"student";
    NSPredicate *classStudents = [NSPredicate predicateWithFormat:@"class = %@ AND school = %@ AND type = %@", nameClass, nameSchool, type];
    PFQuery *studentsForClass = [PFQuery queryWithClassName:[PFUser parseClassName] predicate:classStudents];
    
    [studentsForClass orderByAscending:@"last_name"];
    studentsForClass.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    MTMakeWeakSelf();
    [studentsForClass findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            weakSelf.classStudents = objects;
            [weakSelf.tableView reloadData];
        }
    }];
}

- (void)cloudCodeSchedule:(id)sender
{
    if (![MTUtil internetReachable]) {
        [UIAlertView showNoInternetAlert];
        return;
    }

    self.autoReleaseSwitch.enabled = NO;
    
    if (self.autoReleaseSwitch.on) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Activating...";
        hud.dimBackground = YES;

        PFUser *user = [PFUser currentUser];
        NSString *userID = [user objectId];
        
        MTMakeWeakSelf();
        [PFCloud callFunctionInBackground:@"scheduleActivations" withParameters:@{@"user_id": userID} block:^(id object, NSError *error) {
            if (!error) {
                
                // Make sure we have future challenges, otherwise display message
                NSPredicate *futureActivations = [NSPredicate predicateWithFormat:@"activation_date != nil && activated = NO"];
                PFQuery *scheduledActivations = [PFQuery queryWithClassName:[PFScheduledActivations parseClassName] predicate:futureActivations];
                scheduledActivations.cachePolicy = kPFCachePolicyNetworkOnly;
                
                MTMakeWeakSelf();
                [scheduledActivations countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                        
                        if (!error) {
                            weakSelf.scheduledActivationsOn = (number > 0);
                            
                            if (number == 0) {
                                [[[UIAlertView alloc] initWithTitle:@"Update Error" message:@"All of the Challenges in this schedule have been activated." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                            }
                            
                        } else {
                            weakSelf.scheduledActivationsOn = NO;
                            
                            NSLog(@"error - %@", error);
                            if (![MTUtil internetReachable]) {
                                [UIAlertView showNoInternetAlert];
                            }
                            else {
                                NSString *errorMessage = [NSString stringWithFormat:@"Unable to update Auto-Release information. %lu: %@", error.code, [error localizedDescription]];
                                [[[UIAlertView alloc] initWithTitle:@"Update Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                            }
                        }
                        
                        weakSelf.autoReleaseSwitch.enabled = YES;
                        [weakSelf.tableView reloadData];
                    });

                }];

            } else {
                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                    
                    NSLog(@"error - %@", error);
                    NSString *errorMessage = [NSString stringWithFormat:@"Unable to update Auto-Release information. %lu: %@", error.code, [error localizedDescription]];
                    [[[UIAlertView alloc] initWithTitle:@"Update Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                    weakSelf.scheduledActivationsOn = NO;
                    [weakSelf.tableView reloadData];
                });
            }
        }];
    } else {
        UIAlertView *confirm = [[UIAlertView alloc] initWithTitle:nil message:@"Do you want to put the Challenge schedule on hold? This will not affect open Challenges, and you can resume the schedule at any time from this screen." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        [confirm show];
    }
}


#pragma mark - UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
        {// Cancel
            self.scheduledActivationsOn = YES;
            self.autoReleaseSwitch.enabled = YES;
            [self.tableView reloadData];
            
            break;
        }
            
        default:
        {  // OK
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
                hud.labelText = @"Deactivating...";
                hud.dimBackground = YES;
                
                PFUser *user = [PFUser currentUser];
                NSString *userID = [user objectId];
                
                MTMakeWeakSelf();
                [PFCloud callFunctionInBackground:@"cancelScheduledActivations" withParameters:@{@"user_id": userID} block:^(id object, NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
                        
                        weakSelf.autoReleaseSwitch.enabled = YES;
                        
                        if (!error) {
                            weakSelf.scheduledActivationsOn = NO;
                        } else {
                            weakSelf.scheduledActivationsOn = YES;
                            [UIAlertView bk_showAlertViewWithTitle:@"Unable to Cancel" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                            NSLog(@"error - %@", error);
                        }
                        
                        [weakSelf.tableView reloadData];
                    });
                }];

            });
            
            break;
        }
    }
}


#pragma mark - UITableViewController delegate methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    
    switch (section) {
        case 0:
            rows = 2;
            break;
            
        case 1:
            rows = [self.classStudents count];
            break;
            
        default:
            break;
    }
    
    return rows;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    
    NSString *identString = @"mentorStudentProgressCell";
    
    switch (section) {
        case 0:
        {
            switch (row) {
                case 0:
                {
                    identString = @"autorelease";
                    UITableViewCell *cell = (UITableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:identString];
                    
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identString];
                    }
                    
                    if (!self.autoReleaseSwitch) {
                        self.autoReleaseSwitch = [[UISwitch alloc] init];
                    }
                    
                    self.autoReleaseSwitch.on = self.scheduledActivationsOn;
                    
                    cell.textLabel.text = @"Auto-Release";
                    
                    [self.autoReleaseSwitch removeTarget:self action:@selector(cloudCodeSchedule:) forControlEvents:UIControlEventValueChanged];
                    [self.autoReleaseSwitch addTarget:self action:@selector(cloudCodeSchedule:) forControlEvents:UIControlEventValueChanged];
                    cell.accessoryView = self.autoReleaseSwitch;
                
                    return cell;
                }
                    break;
                    
                default:
                {
                    identString = @"schedule";
                    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identString];
                    
                    if (cell == nil)
                        {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identString];
                        }
                    cell.textLabel.text = @"Schedule";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    
                    return cell;
                }
                    break;
            }
        }
        break;
            
        default:
        {
            MTStudentProgressTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identString];
            if (cell == nil) {
                cell = [[MTStudentProgressTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identString];
            }
            PFUser *rowStudent = self.classStudents[row];
            cell.user = rowStudent;
            
            NSString *fullName = rowStudent[@"first_name"];
            fullName = [[fullName stringByAppendingString:@" "] stringByAppendingString:rowStudent[@"last_name"]];
            cell.userFullName.text = fullName;
            
            NSString *bankAccount = rowStudent[@"bank_account"];
            
            if ([bankAccount intValue] == 1) {
                cell.bankCheckbox.isChecked = YES;
            }
            else {
                cell.bankCheckbox.isChecked = NO;
            }
            
            NSString *resume = rowStudent[@"resume"];
            
            if ([resume intValue] == 1) {
                cell.resumeCheckbox.isChecked = YES;
            }
            else {
                cell.resumeCheckbox.isChecked = NO;
            }
            
            cell.userProfileImage.image = nil;
            cell.userProfileImage.image = [UIImage imageNamed:@"profile_image.png"];
            
            cell.userProfileImage.file = rowStudent[@"profile_picture"];
            [cell.userProfileImage loadInBackground:^(UIImage *image, NSError *error) {
                if (!error) {
                }
                else {
                    NSLog(@"error - %@", error);
                }
            }];
            
            return cell;
        }
            break;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    return 2;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    
    switch (section) {
        case 0: {
            switch (row) {
                case 1:
                    [self performSegueWithIdentifier:@"pushScheduleView" sender:self];
                    break;
                    
                default:
                    break;
            }
        }
            break;
            
        case 1: {
            PFUser *rowStudent = self.classStudents[indexPath.row];
            [self performSegueWithIdentifier:@"mentorStudentProfileView" sender:rowStudent];
        }
            break;
            
        default:
            break;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    [header.textLabel setTextColor:[UIColor blackColor]];
    [header.contentView setBackgroundColor:[UIColor mutedOrange]];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = @"";
    
    switch (section) {
        case 0:
            title = @"CHALLENGES";
            break;
            
        default:
            title = @"STUDENTS";
            break;
    }
    
    return title;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;

    CGFloat height;
    
    switch (section) {
        case  0:
            height = 44.0f;
            break;
            
        default:
            height = 60.0f;
            break;
    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 32.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1.0f;
}


#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSString *segueID = [segue identifier];
    
    if ([segueID isEqualToString:@"mentorStudentProfileView"]) {
        MTMentorStudentProfileViewController *destinationVC = (MTMentorStudentProfileViewController *)[segue destinationViewController];
        
        PFUser *student = sender;
        destinationVC.student = student;
        
    } else if ([segueID isEqualToString:@"pushScheduleView"]) {
//        MTScheduleTableViewController *destinationVC = (MTScheduleTableViewController *)[segue destinationViewController];
    }
}


@end
