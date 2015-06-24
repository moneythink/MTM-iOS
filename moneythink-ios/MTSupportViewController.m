
//  MTSupportViewController.m
//  moneythink-ios
//
//  Created by dsica on 5/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTSupportViewController.h"

#ifdef STAGE
static NSString *stageString = @"STAGE";
#else
static NSString *stageString = @"";
#endif

@interface MTSupportViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableview;

@property (strong, nonatomic) NSArray *sections;

@end

@implementation MTSupportViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 30.0f)];
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:footerView.frame];
    
    if (!IsEmpty(stageString)) {
        versionLabel.text = [NSString stringWithFormat:@"Version %@ (%@) - STAGE",
                             [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
                             [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    }
    else {
        versionLabel.text = [NSString stringWithFormat:@"Version %@ (%@)",
                             [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
                             [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    }
    
    versionLabel.backgroundColor = [UIColor clearColor];
    versionLabel.font = [UIFont mtFontOfSize:10.0f];
    versionLabel.textColor = [UIColor darkGrey];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [footerView addSubview:versionLabel];
    self.tableview.tableFooterView = footerView;
    
    [self.tableview reloadData];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_actionbar"]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[MTUtil getAppDelegate] configureZendesk];
}


#pragma mark - UITableViewControllerDelegate methods -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    NSString *cellIdent = @"defaultCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdent];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdent];
    }
    
    [cell setBackgroundColor:[UIColor white]];
    [cell.textLabel setTextColor:[UIColor blackColor]];
    cell.textLabel.font = [UIFont mtFontOfSize:15.0f];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    switch (row) {
        case 0:
            cell.textLabel.text = @"FAQs";
            [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
            break;
            
        case 1:
            cell.textLabel.text = @"Report a problem";
            cell.accessoryType = UITableViewCellAccessoryNone;
            [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
            break;
            
        case 2:
            cell.textLabel.text = @"Ask a question";
            cell.accessoryType = UITableViewCellAccessoryNone;
            [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
            break;
          
        case 3:
            cell.textLabel.text = @"Suggest an improvement";
            cell.accessoryType = UITableViewCellAccessoryNone;
            [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
            break;

        case 4:
            cell.textLabel.text = @"My Conversations";
            [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
            break;

        default:
            break;
    }
    
    [cell.textLabel sizeToFit];
    
    return cell;
}


#pragma mark - UITableViewDelegate methods -
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    [[MTUtil getAppDelegate] configureZendesk];

    switch (indexPath.row) {
        case 0:
        {
            [ZDKHelpCenter showHelpCenterWithNavController:self.navigationController];
            break;
        }
            
        case 1:
        {
            [ZDKRequests showRequestCreationWithNavController:self.navigationController];
            break;
        }
            
        case 2:
        {
            [ZDKRequests showRequestCreationWithNavController:self.navigationController];
            break;
        }
            
        case 3:
        {
            [ZDKRequests showRequestCreationWithNavController:self.navigationController];
            break;
        }

            
        case 4:
        {
            [ZDKRequests showRequestListWithNavController:self.navigationController];
            break;
        }
    }
}


#pragma mark - ZDKHelpCenterConversationsUIDelegate Methods -
//- (ZDKNavBarConversationsUIType) navBarConversationsUIType
//{
//    
//}
//
//- (UIImage *) conversationsBarButtonImage
//{
//    
//}
//
//- (NSString *) conversationsBarButtonLocalizedLabel
//{
//    
//}
//


@end
