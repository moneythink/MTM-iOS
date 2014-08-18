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

@property (assign, nonatomic) BOOL notificationsOn;

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
    
    self.notificationsOn = NO;
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
    NSInteger rows = 0;
    switch (section) {
        case 0: { // notifications
            rows = 1;
        }
            break;
            
        case 1: { //profile
            rows = 1;
        }
            break;
            
        case 2: { //signup code
            rows = 1;
        }
            break;
            
        default:
            break;
    }
    return rows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    NSInteger section = indexPath.section;
    
    if (self.notificationsOn == NO) {
        section += 1;
    }
    
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
            
        case 2: {
            PFUser *mentor = [PFUser currentUser];
            NSPredicate *signUpCode = [NSPredicate predicateWithFormat:@"class = %@", mentor[@"class"]];
            PFQuery *querySignUpCodes = [PFQuery queryWithClassName:[PFSignupCodes parseClassName] predicate:signUpCode];
            [querySignUpCodes findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    cell.textLabel.text = [objects firstObject][@"code"];
                } else {
                    NSLog(@"error - %@", error);
                }
            }];

            cell.textLabel.text = @"Signup Code";
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
    NSInteger sections = 4;
    
    if (self.notificationsOn == NO) {
        sections -= 1;
    }
    
    return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleHeader = @"";

    if (self.notificationsOn == NO) {
        section += 1;
    }
    

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
            titleHeader = @"SIGNUP CODE";
        }
            break;
            
        case 3: {
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
    
    if (self.notificationsOn == NO) {
        section += 1;
    }
    
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
            [self performSegueWithIdentifier:@"pushEditProfile" sender:self];
        }
            break;
            
        case 2: {
            NSLog(@"share code");
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
    switch (buttonIndex) {
        case 0: 
            break;
            
        case 1: {
            [PFUser logOut];
            [self performSegueWithIdentifier:@"unwindToSignUpLogin" sender:self];
        }
            break;
            
        default:
            break;
    }
}


@end
