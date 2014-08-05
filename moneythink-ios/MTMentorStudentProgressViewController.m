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
#import "MBProgressHUD.h"
#import "MTMentorStudentProfileViewController.h"

@interface MTMentorStudentProgressViewController ()

@property (nonatomic, strong) UISwitch *autoReleaseSwitch;

@end

@implementation MTMentorStudentProgressViewController

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
    NSPredicate *classStudents = [NSPredicate predicateWithFormat:@"class = %@", nameClass];
    PFQuery *studentsForClass = [PFQuery queryWithClassName:[PFUser parseClassName] predicate:classStudents];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [studentsForClass findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.classStudents = objects;
            
            [self.tableView reloadData];
        } else {
            NSLog(@"error - %@", error);
        }
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        
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
            
            //            UISwitch *autoReleaseSwitch = [[UISwitch alloc] init];
            //            autoReleaseSwitch.on = NO;
            
            // - future activation dates are nil
            self.autoReleaseSwitch.on = NO;
            
            cell.textLabel.text = @"Auto-Release";
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
                if (image) {
                    cell.userProfileImage.image = image;
                }
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
    NSInteger section = indexPath.section;
    
    switch (section) {
        case 1: {
            PFUser *rowStudent = self.classStudents[indexPath.row];
            [self performSegueWithIdentifier:@"mentorStudentProfileView" sender:rowStudent];
        }
            break;
            
        default:
            break;
    }
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
    NSInteger row = indexPath.row;
    
    switch (section) {
        case  0:
            row = 44.0f;
            break;
            
        default:
            row = 60.0f;
            break;
    }
    
    return row;
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
        
        destinationVC.student = sender;
    }
}

@end
