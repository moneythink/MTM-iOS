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

@property (assign, nonatomic) BOOL signupOn;
@property (assign, nonatomic) BOOL notificationsOn;
@property (strong, nonatomic) NSArray *sections;

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
    self.signupOn = [user[@"type"] isEqualToString:@"mentor"];
    
    self.sections = @[@"PROFILE", @""];
    if (self.notificationsOn) {
        if (self.signupOn) {
            self.sections = @[@"NOTIFICATION", @"PROFILE", @"SIGN UP CODE", @""];
        } else {
            self.sections = @[@"NOTIFICATION", @"PROFILE", @""];
        }
    } else {
        if (self.signupOn) {
            self.sections = @[@"PROFILE", @"SIGN UP CODE", @""];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 1;
    if ([self.sections[section] isEqualToString:@"NOTIFICATIONS"]) {
        rows = 1;
    } else if ([self.sections[section] isEqualToString:@"PROFILE"]) {
        rows = 1;
    } else if ([self.sections[section] isEqualToString:@"SIGN UP CODE"]) {
        rows = 1;
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
    } else if ([self.sections[section] isEqualToString:@"SIGN UP CODE"]) {
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
    } else {
        cell.textLabel.text = @"Log Out";
        [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
    }

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    NSInteger sections = self.sections.count;
    
    return sections;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *titleHeader = self.sections[section];

    return titleHeader;
}


#pragma mark - UITableViewDelegate methods

    // Called after the user changes the selection.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
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
    } else if ([self.sections[section] isEqualToString:@"SIGN UP CODE"]) {
        NSLog(@"share code");
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
