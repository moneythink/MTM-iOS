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

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *nameClass = [PFUser currentUser][@"class"];
    NSString *nameSchool = [PFUser currentUser][@"school"];
    NSString *type = @"student";
    NSPredicate *classStudents = [NSPredicate predicateWithFormat:@"class = %@ AND school = %@ AND type = %@", nameClass, nameSchool, type];
    PFQuery *studentsForClass = [PFQuery queryWithClassName:[PFUser parseClassName] predicate:classStudents];

    [studentsForClass orderByAscending:@"last_name"];
    
//    studentsForClass.cachePolicy = kPFCachePolicyCacheThenNetwork;
//    
    [studentsForClass findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.classStudents = objects;
            [self.tableView reloadData];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.parentViewController.navigationItem.title = @"Students";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)cloudCodeSchedule:(id)sender
{
    if (self.autoReleaseSwitch.on) {
        PFUser *user = [PFUser currentUser];
        NSString *userID = [user objectId];
        
        [PFCloud callFunctionInBackground:@"scheduleActivations" withParameters:@{@"user_id": userID} block:^(id object, NSError *error) {
            if (!error) {
                
                [self.tableView reloadData];
            } else {
                NSLog(@"error - %@", error);
            }
        }];
    } else {
        UIAlertView *confirm = [[UIAlertView alloc] initWithTitle:nil message:@"Do you want to put the Challenge schedule on hold? This will not affect open Challenges, and you can resume the schedule at any time from this screen." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
        
        [confirm show];
    }
}


#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0: // Cancel
            self.autoReleaseSwitch.on = YES;
            break;
            
        default: {  // OK
            PFUser *user = [PFUser currentUser];
            NSString *userID = [user objectId];
            
            [PFCloud callFunctionInBackground:@"cancelScheduledActivations" withParameters:@{@"user_id": userID} block:^(id object, NSError *error) {
                if (!error) {
                    
                    [self.tableView reloadData];
                } else {
                    NSLog(@"error - %@", error);
                }
            }];
        }
            break;
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
            
            if (cell == nil)
                {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identString];
                }
            
            self.autoReleaseSwitch = [[UISwitch alloc] init];
            
            // - future activation dates are nil
            
            
            NSPredicate *futureActivations = [NSPredicate predicateWithFormat:@"activation_date > %@", [NSDate date]];
            PFQuery *scheduledActivations = [PFQuery queryWithClassName:[PFScheduledActivations parseClassName] predicate:futureActivations];

            scheduledActivations.cachePolicy = kPFCachePolicyCacheThenNetwork;
            
            [scheduledActivations countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
                if (!error) {
                    self.autoReleaseSwitch.on = number > 0;
                } else {
                    NSLog(@"error - %@", error);
                }
            }];
            
            cell.textLabel.text = @"Auto-Release";
            [self.autoReleaseSwitch addTarget:self action:@selector(cloudCodeSchedule:) forControlEvents:UIControlEventTouchUpInside];
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
        if (cell == nil)
            {
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
        } else {
            cell.bankCheckbox.isChecked = NO;
        }
        
        NSString *resume = rowStudent[@"resume"];
        
        if ([resume intValue] == 1) {
            cell.resumeCheckbox.isChecked = YES;
        } else {
            cell.resumeCheckbox.isChecked = NO;
        }
        
        cell.userProfileImage.image = nil;
        cell.userProfileImage.image = [UIImage imageNamed:@"profile_image.png"];
        
        cell.userProfileImage.file = rowStudent[@"profile_picture"];
        [cell.userProfileImage loadInBackground:^(UIImage *image, NSError *error) {
            if (!error) {
                
            } else {
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


// Variable height support

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

// In a storyboard-based application, you will often want to do a little preparation before navigation
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
