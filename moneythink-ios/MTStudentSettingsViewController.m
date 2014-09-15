
//  MTStudentSettingsViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/25/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentSettingsViewController.h"
#import "MTStudentTabBarViewController.h"

@interface MTStudentSettingsViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableview;

@property (assign, nonatomic) BOOL signupOn;
@property (assign, nonatomic) BOOL notificationsOn;
@property (strong, nonatomic) NSArray *sections;

@property (strong, nonatomic) NSArray *signUpCodes;

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
    PFUser *user = [PFUser currentUser];
    NSString *userType = user[@"type"];
    self.signupOn = [userType isEqualToString:@"mentor"];
    

    NSString *userClass = user[@"class"];
    NSString *userSchool = user[@"school"];
    
    NSPredicate *signUpCode = [NSPredicate predicateWithFormat:@"class = %@ AND school = %@", userClass, userSchool];
    PFQuery *querySignUpCodes = [PFQuery queryWithClassName:[PFSignupCodes parseClassName] predicate:signUpCode];
    querySignUpCodes.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [querySignUpCodes findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.signUpCodes = objects;
            
            [self.tableview reloadData];
        }
    }];

    
    self.sections = @[@"PROFILE", @""];
    if (self.notificationsOn) {
        if (self.signupOn) {
            self.sections = @[@"NOTIFICATION", @"PROFILE", @"SHARE SIGN UP CODE", @""];
        } else {
            self.sections = @[@"NOTIFICATION", @"PROFILE", @""];
        }
    } else {
        if (self.signupOn) {
            self.sections = @[@"PROFILE", @"SHARE SIGN UP CODE", @""];
        }
    }
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    NSInteger sections = self.sections.count;
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 1;
    if ([self.sections[section] isEqualToString:@"NOTIFICATIONS"]) {
        rows = 1;
    } else if ([self.sections[section] isEqualToString:@"PROFILE"]) {
        rows = 1;
    } else if ([self.sections[section] isEqualToString:@"SHARE SIGN UP CODE"]) {
        rows = self.signUpCodes.count;
    } else {
        rows = 1;
    }
    return rows;
}


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
    
    [cell setBackgroundColor:[UIColor white]];
    [cell.textLabel setTextColor:[UIColor primaryOrange]];

    if ([self.sections[section] isEqualToString:@"NOTIFICATIONS"]) {
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
    } else if ([self.sections[section] isEqualToString:@"PROFILE"]) {
        cell.textLabel.text = @"Edit Profile";
        [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
    } else if ([self.sections[section] isEqualToString:@"SHARE SIGN UP CODE"]) {
        NSString *type = @"";
        NSString *msg = @"";
        NSString *code = @"";
        
        PFSignupCodes *signupCode = self.signUpCodes[row];
        type = signupCode[@"type"];
        code = signupCode[@"code"];
        
        if ([type isEqualToString:@"student"]) {
            msg = @"Student sign up code";
        } else if ([type isEqualToString:@"mentor"]) {
            msg = @"Mentor sign up code";
        }
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
        [cell.textLabel setFont:[UIFont systemFontOfSize:16.0f]];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", msg, code];
    } else {
        cell.textLabel.text = @"Log Out";
        [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
    }

    [cell.textLabel sizeToFit];
    
    [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleHeader = self.sections[section];

    return titleHeader;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    [header.textLabel setTextColor:[UIColor blackColor]];
    [header.contentView setBackgroundColor:[UIColor mutedOrange]];
}

    // Called after the user changes the selection.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSInteger section = indexPath.section;
    NSInteger row = indexPath.row;
    
    if ([self.sections[section] isEqualToString:@"NOTIFICATIONS"]) {
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
    } else if ([self.sections[section] isEqualToString:@"PROFILE"]) {
        [self performSegueWithIdentifier:@"pushEditProfile" sender:self];
    } else if ([self.sections[section] isEqualToString:@"SHARE SIGN UP CODE"]) {
        
        NSString *type = @"";
        NSString *msg = @"";
        
        switch (indexPath.row) {
            case 0: {
                type = @"student";
                msg = @"Student";
            }
                break;
                
            default: {
                type = @"mentor";
                msg = @"Mentor";
            }
                break;
        }
        
        NSPredicate *signUpCode = [NSPredicate predicateWithFormat:@"school = %@ AND class = %@ AND type = %@", [PFUser currentUser][@"school"], [PFUser currentUser][@"class"], type];
        PFQuery *querySignUpCodes = [PFQuery queryWithClassName:[PFSignupCodes parseClassName] predicate:signUpCode];
        querySignUpCodes.cachePolicy = kPFCachePolicyCacheThenNetwork
        ;
        
        [querySignUpCodes findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                NSString *signupCode = [objects firstObject][@"code"];
                signupCode = [NSString stringWithFormat:@"%@ sign up code for class '%@' is '%@'", msg, [PFUser currentUser][@"class"], signupCode];
                NSArray *dataToShare = @[signupCode];
                
                UIActivityViewController *activityViewController =
                [[UIActivityViewController alloc] initWithActivityItems:dataToShare
                                                  applicationActivities:nil];
                [self presentViewController:activityViewController animated:NO completion:^{}];
            }
        }];

    } else {
        UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:@"Cancel" otherButtonTitles:@"Logout", nil];
        
        UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
        if ([window.subviews containsObject:self.view]) {
            [logoutSheet showInView:self.view];
        } else {
            [logoutSheet showInView:window];
        }
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
