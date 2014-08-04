//
//  MTMentorStudentProgressViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMentorStudentProgressViewController.h"
#import "MTStudentProgressTableViewCell.h"

@interface MTMentorStudentProgressViewController ()

//@property (strong, nonatomic) IBOutlet UITableViewCell *rowZeroLabel;
//@property (strong, nonatomic) IBOutlet UITableViewCell *rowZeroSwitch;

//@property (strong, nonatomic) IBOutlet UILabel *rowOneLabel;
//@property (strong, nonatomic) IBOutlet UIButton *rowOneButton;

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
    
//    PFQuery *studentsForClass = [[PFQuery alloc] initWithClassName:[PFUser parseClassName]];
    
//    [studentsForClass whereKey:@"class" equalTo:[PFUser currentUser][@"class"]];

    NSString *nameClass = [PFUser currentUser][@"class"];
    NSPredicate *classStudents = [NSPredicate predicateWithFormat:@"class = %@", nameClass];
    PFQuery *studentsForClass = [PFQuery queryWithClassName:[PFUser parseClassName] predicate:classStudents];
    
    [studentsForClass findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.classStudents = objects;
            
            [self.tableView reloadData];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = [self.classStudents count] + 2;
    return rows;
}

    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    NSString *identString = @"mentorStudentProgressCell";
    
    switch (row) {
        case 0:
        {
        identString = @"mentorAutoReleaseSwitch";
        MTStudentProgressTableViewCell *cell = (MTStudentProgressTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:identString];
        
        if (cell == nil)
            {
            cell = [[MTStudentProgressTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identString];
            }
        
        cell.autoReleaseSwitch = [[UISwitch alloc] init];
        cell.autoReleaseSwitch.on = NO;
        
        cell.textLabel.text = @"Challenge Auto-Release";
        //            cell.accessoryView = self.autoReleaseSwitch;
        [cell.accessoryView addSubview:cell.autoReleaseSwitch];
        
        return cell;
        }
            break;
            
        case 1:
        {
        identString = @"mentorViewChallengeSchedule";
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identString];
        
        if (cell == nil)
            {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identString];
            }
        cell.textLabel.text = @"Challenge Schedule";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        return cell;
        }
            break;
            
        default:
        {
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identString];
        if (cell == nil)
            {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identString];
            }
        NSInteger offsetRow = row - 2;
        PFUser *rowStudent = self.classStudents[offsetRow];
        cell.textLabel.text = [rowStudent username];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"row %ld", (long)row];
        
        return cell;
        }
            break;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    return 1;
}


#pragma mark - UITableViewDelegate methods


// Variable height support

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0f;
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
