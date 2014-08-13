//
//  MTStudentSettingsViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/25/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentSettingsViewController.h"
#import "MTStudentTabBarViewController.h"

@interface MTStudentSettingsViewController ()

//@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UITableViewCell *logout;
@property (strong, nonatomic) IBOutlet UITableViewCell *editProfile;
@end

@implementation MTStudentSettingsViewController

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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdent];
    
    if (cell == nil)
        {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdent];
        }
    

    switch (section) {
        case 0: {
            switch (row) {
                case 0: {
                    cell.textLabel.text = @"Push Notifications";
                    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

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
            [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
        }
            break;
            
        default:
            cell.textLabel.text = @"Log Out";
            [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
            break;
    }


    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
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


#pragma mark - UITableViewDelegate methods

    // Called after the user changes the selection.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    switch (section) {
        case 0: {
            switch (row) {
                case 0: {
//                    cell.textLabel.text = @"Push Notifications";
                    
                }
                    break;
                    
                case 1: {
//                    cell.textLabel.text = @"Vibrate";
                    
                }
                    break;
                    
                default:
//                    cell.textLabel.text = @"Sound";
                    break;
            }
        }
            break;
            
        case 1: {
//            cell.textLabel.text = @"Edit Profile";
            [self performSegueWithIdentifier:@"pushEditProfile" sender:self];
        }
            break;
            
        default: {
            UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Cancel" otherButtonTitles:@"Logout", nil];
            
            UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
            if ([window.subviews containsObject:self.view]) {
                [logoutSheet showInView:self.view];
            } else {
                [logoutSheet showInView:window];
            }
        }
            break;
    }
}

#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex  // after animation
{
    //unwindMTUserViewController
    //unwindMTSignUpOrSignInViewController
    MTStudentTabBarViewController *parent = (MTStudentTabBarViewController *)self.parentViewController;
    
    switch (buttonIndex) {
        case 0: 
            break;
            
        case 1: {
            [PFUser logOut];
            [self performSegueWithIdentifier:@"unwindToSignUpLogin" sender:self];
//            [self performSegueWithIdentifier:@"unwindToSignInOrSignUpLogin" sender:self];
        }
            break;
            
        default:
            break;
    }
}


@end
