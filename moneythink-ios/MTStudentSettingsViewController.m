
//  MTStudentSettingsViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/25/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentSettingsViewController.h"
#import "MTStudentTabBarViewController.h"

#ifdef STAGE
static NSString *stageString = @"STAGE";
#else
static NSString *stageString = @"";
#endif

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
    
    self.sections = @[@"PROFILE", @"HELP", @""];
    if (self.notificationsOn) {
        if (self.signupOn) {
            self.sections = @[@"NOTIFICATION", @"PROFILE", @"SHARE SIGN UP CODE", @"HELP", @""];
        }
        else {
            self.sections = @[@"NOTIFICATION", @"PROFILE", @"HELP", @""];
        }
    } else {
        if (self.signupOn) {
            self.sections = @[@"PROFILE", @"SHARE SIGN UP CODE", @"HELP", @""];
        }
    }
    
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
    
    [[MTUtil getAppDelegate] configureZendesk];
    
    PFUser *user = [PFUser currentUser];
    NSString *userClass = user[@"class"];
    NSString *userSchool = user[@"school"];
    
    NSPredicate *signUpCode = [NSPredicate predicateWithFormat:@"class = %@ AND school = %@", userClass, userSchool];
    PFQuery *querySignUpCodes = [PFQuery queryWithClassName:[PFSignupCodes parseClassName] predicate:signUpCode];
    querySignUpCodes.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    MTMakeWeakSelf();
    [querySignUpCodes findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            weakSelf.signUpCodes = objects;
            
            if (self.signupOn) {
                if ([weakSelf.signUpCodes count] == 0) {
                    weakSelf.sections = @[@"PROFILE", @"HELP", @""];
                }
                else {
                    weakSelf.sections = @[@"PROFILE", @"SHARE SIGN UP CODE", @"HELP", @""];
                }
            }

            [weakSelf.tableview reloadData];
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
    NSInteger sections = [self.sections count];
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 1;
    if ([self.sections[section] isEqualToString:@"NOTIFICATIONS"]) {
        rows = 1;
    }
    else if ([self.sections[section] isEqualToString:@"PROFILE"]) {
        rows = 1;
    }
    else if ([self.sections[section] isEqualToString:@"SHARE SIGN UP CODE"]) {
        rows = self.signUpCodes.count;
    }
    else if ([self.sections[section] isEqualToString:@"HELP"]) {
        rows = 3;
    }
    else {
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
    else if ([self.sections[section] isEqualToString:@"HELP"]) {
        switch (row) {
            case 0:
                cell.textLabel.text = @"Contact Us";
                cell.accessoryType = UITableViewCellAccessoryNone;
                [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
                break;
                
            case 1:
                cell.textLabel.text = @"My Tickets";
                [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
                break;
                
            case 2:
                cell.textLabel.text = @"Support";
                [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];
                break;
                
            default:
                break;
        }
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


#pragma mark - UITableViewDelegate methods -
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == [self.sections count]-1) {
        return 20.0f;
    }
    else {
        return 30.0f;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat height = 30.0f;
    if (section == [self.sections count]-1) {
        height = 20.0f;
    }
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableView.frame.size.width, height)];
    headerView.backgroundColor = [UIColor clearColor];
    
    if (section != [self.sections count] -1) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, 0.0f, tableView.frame.size.width-30.0f, 30.0f)];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.text = self.sections[section];
        titleLabel.textColor = [UIColor darkGrayColor];
        titleLabel.font = [UIFont mtFontOfSize:13.0f];
        
        [headerView addSubview:titleLabel];
    }
    
    return headerView;
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
                
                // Mark user invited students
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserInvitedStudents];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
                break;
                
            default: {
                type = @"mentor";
                msg = @"Mentor";
            }
                break;
        }
        
        PFSignupCodes *signupCode = self.signUpCodes[row];
        NSString *signupCodeString = [NSString stringWithFormat:@"%@ sign up code for class '%@' is '%@'", msg, [PFUser currentUser][@"class"], signupCode[@"code"]];
        NSArray *dataToShare = @[signupCodeString];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:dataToShare
                                                                                             applicationActivities:nil];
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
    else if ([self.sections[section] isEqualToString:@"HELP"]) {
        [[MTUtil getAppDelegate] configureZendesk];

        switch (row) {
            case 0:
            {
                [ZDKRequests showRequestCreationWithNavController:self.navigationController];
                break;
            }
                
            case 1:
            {
                [ZDKRequests showRequestListWithNavController:self.navigationController];
                break;
            }
                
            case 2:
            {
                [ZDKHelpCenter showHelpCenterWithNavController:self.navigationController];
                break;
            }
        }
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
                                         [MTUtil logout];
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
        [MTUtil logout];
        [self performSegueWithIdentifier:@"unwindToSignUpLogin" sender:self];
    }
}


@end
