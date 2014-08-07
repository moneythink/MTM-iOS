//
//  MTStudentSettingsViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/25/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentSettingsViewController.h"

@interface MTStudentSettingsViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UITableViewCell *logout;
@property (strong, nonatomic) IBOutlet UITableViewCell *editProfile;
@end

@implementation MTStudentSettingsViewController

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
    } else {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.title = @"Settings";
}

- (void)viewWillAppear:(BOOL)animated
{
    self.parentViewController.navigationItem.title = @"Settings";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark - UITableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
        {
        
        }
            break;
            
        case 1:
        {
        
        }
            break;
            
        case 2:
        {
        
        }
            break;
            
        default:
            break;
    }
    return 1;
}

    // Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
    // Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    
    NSString *cellIdent = @"defaultCell";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdent];
    
    if (cell == nil)
        {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdent];
        }
    

    switch (section) {
        case 0: {
            switch (row) {
                case 0: {
                    cell.textLabel.text = @"Push Notifications";

                }
                    break;
                    
                case 1: {
                    cell.textLabel.text = @"Vibrate";

                }
                    break;
                    
                default:
                    cell.textLabel.text = @"Sound";
                    break;
            }
        }
            break;
            
        case 1: {
            cell.textLabel.text = @"Edit Profile";

        }
            break;
            
        default:
            cell.textLabel.text = @"Log Out";
            break;
    }


    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section // fixed font style. use custom view (UILabel) if you want something different
{
    NSString *titleHeader = @"";
    
    switch (section) {
        case 0: {
            titleHeader = @"NOTIFICATIONS";
        }
            break;
            
        case 1: {
            titleHeader = @"PROFILE";
        }
            break;
            
        case 2: {
            titleHeader = @"";
        }
            break;
            
        default:
            break;
    }
    return titleHeader;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSString *segueID = [segue identifier];
}

@end
