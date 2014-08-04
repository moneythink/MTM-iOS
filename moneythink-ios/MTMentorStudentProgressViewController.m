//
//  MTMentorStudentProgressViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMentorStudentProgressViewController.h"

@interface MTMentorStudentProgressViewController ()

@property (strong, nonatomic) NSArray *classStudents;
@property (strong, nonatomic) IBOutlet UITableViewCell *rowZeroLabel;
@property (strong, nonatomic) IBOutlet UITableViewCell *rowZeroSwitch;

@property (strong, nonatomic) IBOutlet UILabel *rowOneLabel;
@property (strong, nonatomic) IBOutlet UIButton *rowOneButton;

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
    
    PFQuery *studentsForClass = [[PFQuery alloc] initWithClassName:@"users"];
    
    [studentsForClass whereKey:@"class" equalTo:[PFUser currentUser][@"class"]];
    
    [studentsForClass findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.classStudents = objects;
            
            [self.view setNeedsDisplay];
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
            identString = @"mentorAutoReleaseSwitch";
            break;
            
        case 1:
            identString = @"mentorViewChallengeSchedule";
            break;
            
        default:
            break;
    }
    
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identString];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identString];
    }
    
    self.autoReleaseSwitch = [[UISwitch alloc] init];
    self.autoReleaseSwitch.on = NO;
    
    switch (row) {
        case 0:
            cell.textLabel.text = @"Challenge Auto-Release";
            [cell.accessoryView addSubview:self.autoReleaseSwitch];
            break;
            
        case 1:
            cell.textLabel.text = @"Challenge Schedule";
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
            
        default:
        {
        NSInteger offsetRow = row - 2;
        PFUser *rowStudent = self.classStudents[offsetRow];
        cell.textLabel.text = [rowStudent username];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"row %ld", (long)row];
        }
            break;
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    return 5;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section // fixed font style. use custom view (UILabel) if you want something different
{
    return @"titleForHeaderInSection";
}

//- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
//{
//    return @"titleForFooterInSection";
//}



#pragma mark - UITableViewDelegate methods


// Variable height support

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 40.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0f;
}


// Section header & footer information. Views are preferred over title should you decide to provide both

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section // custom view for header. will be adjusted to default or specified header height
//{
//    return nil;
//}

//- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section // custom view for footer. will be adjusted to default or specified footer height
//{
//    return nil;
//}

    // Accessories (disclosures).

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    
}




#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
