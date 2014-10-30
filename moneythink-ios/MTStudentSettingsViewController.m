
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
@property (nonatomic) BOOL pushingSubview;

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
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 30.0f)];
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:footerView.frame];
    versionLabel.text = [NSString stringWithFormat:@"Version %@ (%@)",
                         [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"],
                         [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    versionLabel.backgroundColor = [UIColor clearColor];
    versionLabel.font = [UIFont mtFontOfSize:10.0f];
    versionLabel.textColor = [UIColor darkGrey];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [footerView addSubview:versionLabel];
    self.tableview.tableFooterView = footerView;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[MTUtil getAppDelegate] setWhiteNavBarAppearanceForNavigationBar:self.navigationController.navigationBar];

    self.parentViewController.navigationItem.title = @"Settings";
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    PFUser *user = [PFUser currentUser];
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
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (!self.pushingSubview) {
        [[MTUtil getAppDelegate] setDefaultNavBarAppearanceForNavigationBar:self.navigationController.navigationBar];
    }
    else {
        self.pushingSubview = NO;
    }
}


#pragma mark - UITableViewController delegate methods -
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
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdent];
    }
    
    [cell setBackgroundColor:[UIColor white]];
    [cell.textLabel setTextColor:[UIColor blackColor]];
    cell.textLabel.font = [UIFont mtFontOfSize:15.0f];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
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
    }
    else if ([self.sections[section] isEqualToString:@"PROFILE"]) {
        cell.textLabel.text = @"Edit Profile";
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
    }
    else if ([self.sections[section] isEqualToString:@"SHARE SIGN UP CODE"]) {
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
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
        cell.textLabel.text = @"Log Out";
        cell.accessoryType = UITableViewCellAccessoryNone;
        [cell.textLabel setTextColor:[UIColor primaryOrange]];
        [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
    }
    
    [cell.textLabel sizeToFit];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *titleHeader = self.sections[section];
    return titleHeader;
}


#pragma mark - UITableViewDelegate methods -
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    
    [header.textLabel setTextColor:[UIColor darkGrayColor]];
    header.textLabel.font = [UIFont mtFontOfSize:13.0f];
    [header.contentView setBackgroundColor:[UIColor clearColor]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    self.pushingSubview = YES;
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
    }
    else if ([self.sections[section] isEqualToString:@"PROFILE"]) {
        [self performSegueWithIdentifier:@"presentEditProfile" sender:self];
    }
    else if ([self.sections[section] isEqualToString:@"SHARE SIGN UP CODE"]) {
        
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
                [self presentViewController:activityViewController animated:YES completion:^{}];
            }
        }];
        
    }
    else {
        if ([UIAlertController class]) {
            UIAlertController *logoutSheet = [UIAlertController
                                              alertControllerWithTitle:nil
                                              message:nil
                                              preferredStyle:UIAlertControllerStyleActionSheet];
            
            UIAlertAction *cancel = [UIAlertAction
                                     actionWithTitle:@"Cancel"
                                     style:UIAlertActionStyleCancel
                                     handler:^(UIAlertAction *action) {}];
            
            UIAlertAction *logout = [UIAlertAction
                                        actionWithTitle:@"Logout"
                                        style:UIAlertActionStyleDestructive
                                        handler:^(UIAlertAction *action) {
                                            [PFUser logOut];
                                            [self performSegueWithIdentifier:@"unwindToSignUpLogin" sender:nil];
                                        }];
            
            [logoutSheet addAction:cancel];
            [logoutSheet addAction:logout];
            
            [self presentViewController:logoutSheet animated:YES completion:nil];
        }
        else {
            UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Logout" otherButtonTitles:nil, nil];
            [logoutSheet showInView:[UIApplication sharedApplication].keyWindow];
        }
    }
}


#pragma mark - UIActionSheetDelegate methods -
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex  // after animation
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [PFUser logOut];
        [self performSegueWithIdentifier:@"unwindToSignUpLogin" sender:self];
    }
}


@end
