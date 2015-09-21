//
//  MTMenuViewController.m
//  moneythink-ios
//
//  Created by David Sica on 5/26/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTMenuViewController.h"
#import "MTMenuTableViewCell.h"
#import "MTNotificationViewController.h"
#import "MTChallengesViewController.h"
#import "MTLeaderboardViewController.h"

@interface MTMenuViewController ()

@property (nonatomic, strong) IBOutlet UIView *headerView;
@property (nonatomic, strong) IBOutlet UIImageView *profileImage;
@property (nonatomic, strong) IBOutlet UILabel *profileName;
@property (nonatomic, strong) IBOutlet UILabel *profilePoints;
@property (nonatomic, strong) IBOutlet UIView *footerView;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSIndexPath *currentlySelectedIndexPath;

@end

@implementation MTMenuViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.headerView.backgroundColor = [UIColor menuDarkGreen];
    self.footerView.backgroundColor = [UIColor menuLightGreen];
    self.tableView.backgroundColor = [UIColor menuLightGreen];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unreadCountUpdate:) name:kUnreadNotificationCountNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSavedProfileChanges:) name:kUserSavedProfileChanges object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [MTUtil GATrackScreen:@"Menu"];
    
    [self loadProfileImage];

    MTUser *user = [MTUser currentUser];
    self.profileName.text = user.firstName;
    
    if ([MTUser isCurrentUserMentor]) {
        self.profilePoints.hidden = YES;
    }
    else {
        self.profilePoints.hidden = NO;
        self.profilePoints.text = [NSString stringWithFormat:@"%ldpts", (long)user.points];
        
        if ([MTUtil shouldRefreshForKey:kRefreshForMeUser]) {
            MTMakeWeakSelf();
            [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MTUtil setRefreshedForKey:kRefreshForMeUser];
                    MTUser *user = [MTUser currentUser];
                    weakSelf.profilePoints.text = [NSString stringWithFormat:@"%ldpts", (long)user.points];
                });
            } failure:^(NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    MTUser *user = [MTUser currentUser];
                    weakSelf.profilePoints.text = [NSString stringWithFormat:@"%ldpts", (long)user.points];
                });
            }];

        }
    }

    __block NSIndexPath *indexPathForSelected = [self.tableView indexPathForSelectedRow];
    if (self.currentlySelectedIndexPath) {
        indexPathForSelected = [NSIndexPath indexPathForRow:self.currentlySelectedIndexPath.row inSection:self.currentlySelectedIndexPath.section];
        self.currentlySelectedIndexPath = nil;
    }
    
    [[MTUtil getAppDelegate] setDarkNavBarAppearanceForNavigationBar:nil];
    [self.tableView reloadData];

    if (!indexPathForSelected) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    else {
        [self.tableView selectRowAtIndexPath:indexPathForSelected animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[MTUtil getAppDelegate] setWhiteNavBarAppearanceForNavigationBar:nil];
}


#pragma mark - UITableViewDelegate Methods -
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 10.0f;
    }
    else {
        return 0.0f;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section != 0) {
        return nil;
    }
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableView.frame.size.width, 10.0f)];
    headerView.backgroundColor = [UIColor menuLightGreen];
    
    return headerView;
}


#pragma mark - UITableViewDataSource Methods -
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
        {
            if ([MTUser isCurrentUserMentor]) {
                return 1;
            }
            else {
                return 0;
            }
            break;
        }
            
        case 1:
        {
            return 5;
            break;
        }
          
        case 2:
        {
            if ([MTUser isCurrentUserMentor]) {
                if (!IsEmpty([MTUser currentUser].userClass.studentSignupCode)) {
                    return 1;
                }
                else {
                    return 0;
                }
            }
            else {
                return 0;
            }
            break;
        }

        default:
            break;
    }
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    NSInteger row = indexPath.row;
    
    NSString *msg = @"";
    NSString *code = @"";

    switch (indexPath.section)
    {
        // Mentor Dashboard
        case 0:
        {
            CellIdentifier = @"Dashboard";
            break;
        }
           
        // Common Content
        case 1:
        {
            switch (row) {
                case 0:
                    CellIdentifier = @"Challenges";
                    break;
                  
                case 1:
                    CellIdentifier = @"Leaderboard";
                    break;

                case 2:
                    CellIdentifier = @"Notifications";
                    break;

                case 3:
                    CellIdentifier = @"Edit Profile";
                    break;

                case 4:
                    CellIdentifier = @"Talk to Moneythink";
                    break;

                default:
                    break;
            }
            
            break;
        }

        // Mentor Code(s)
        case 2:
        {
            CellIdentifier = @"Signup";
            msg = @"Student Sign Up Code:";
            code = [MTUser currentUser].userClass.studentSignupCode;
    
            break;
        }
    }

    MTMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier: CellIdentifier forIndexPath: indexPath];
    
    if (indexPath.section == 2) {
        cell.signupLabel.text = msg;
        cell.signupCode.text = code;
    }
    
    if (indexPath.section == 1 && indexPath.row == 2) {
        cell.unreadCountLabel.text = [NSString stringWithFormat:@"%ld", (long)((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount];
        if (((AppDelegate *)[MTUtil getAppDelegate]).currentUnreadCount > 0) {
            cell.unreadCountView.hidden = NO;
        }
        else {
            cell.unreadCountView.hidden = YES;
        }
    }
 
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.section == 2) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        NSString *signupCodeString = [NSString stringWithFormat:@"Student sign up code for class '%@' is '%@'", [MTUser currentUser].userClass.name, [MTUser currentUser].userClass.studentSignupCode];
        NSArray *dataToShare = @[signupCodeString];

        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:dataToShare
                                                                                             applicationActivities:nil];
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}


#pragma mark - Private -
- (IBAction)logout
{
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
                                     [self logoutAction];
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

- (void)logoutAction
{
    [[MTNetworkManager sharedMTNetworkManager] cancelExistingOperations];
    
    // Try deleting push registration first before deleting token
    if ([MTUtil pushMessagingRegistrationId]) {
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Logging out...";
        hud.dimBackground = YES;
        
        MTMakeWeakSelf();
        [[MTNetworkManager sharedMTNetworkManager] deletePushMessagingRegistrationId:[MTUtil pushMessagingRegistrationId] success:^(id responseData) {
            NSLog(@"Successfully deleted push messaging registration ID");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                [weakSelf continueLogout];
            });
            
        } failure:^(NSError *error) {
            NSLog(@"Failed to delete push messaging registration ID");
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                [weakSelf continueLogout];
            });
        }];
    }
    else {
        [self continueLogout];
    }
}

- (void)continueLogout
{
    [MTUtil logout];

    [[MTUtil getAppDelegate] setDarkNavBarAppearanceForNavigationBar:nil];
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
    }
    
    [self.revealViewController setFrontViewController:[[MTUtil getAppDelegate] userViewController] animated:YES];
    [self.revealViewController setFrontViewPosition:FrontViewPositionLeft animated:YES];
    //    [self.revealViewController revealToggleAnimated:YES];
}

- (void)loadProfileImage
{
    self.profileImage.layer.cornerRadius = self.profileImage.frame.size.width/2.0f;
    self.profileImage.layer.masksToBounds = YES;
    if ([MTUser currentUser].userAvatar) {
        self.profileImage.image = [UIImage imageWithData:[MTUser currentUser].userAvatar.imageData];
    }
    else {
        self.profileImage.image = [UIImage imageNamed:@"profile_image.png"];
    }
}


#pragma mark - UIActionSheetDelegate methods -
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex  // after animation
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self logoutAction];
    }
}


#pragma mark - Public Methods -
- (void)openLeaderboard
{
    self.currentlySelectedIndexPath = [NSIndexPath indexPathForRow:1 inSection:1];
    [self.tableView selectRowAtIndexPath:self.currentlySelectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    if (self.revealViewController.frontViewPosition == FrontViewPositionRight) {
        [self.revealViewController revealToggleAnimated:NO];
    }
    
    UINavigationController *leaderboardVCNav = [self.storyboard instantiateViewControllerWithIdentifier:@"leaderboardVCNav"];
    [self.revealViewController setFrontViewController:leaderboardVCNav animated:YES];
}

- (void)openNotificationsWithId:(NSInteger)notificationId
{
    self.currentlySelectedIndexPath = [NSIndexPath indexPathForRow:2 inSection:1];
    [self.tableView selectRowAtIndexPath:self.currentlySelectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    if (self.revealViewController.frontViewPosition == FrontViewPositionRight) {
        [self.revealViewController revealToggleAnimated:NO];
    }

    UINavigationController *notificationsVCNav = [self.storyboard instantiateViewControllerWithIdentifier:@"mentorNotificationsNav"];
    MTNotificationViewController *notificationVC = (MTNotificationViewController *)notificationsVCNav.topViewController;
    notificationVC.actionableNotificationId = notificationId;

    [self.revealViewController setFrontViewController:notificationsVCNav animated:YES];
}

- (void)openChallengesForChallengeId:(NSInteger)challengeId
{
    self.currentlySelectedIndexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    [self.tableView selectRowAtIndexPath:self.currentlySelectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    if (self.revealViewController.frontViewPosition == FrontViewPositionRight) {
        [self.revealViewController revealToggleAnimated:NO];
    }

    UINavigationController *challengesVCNav = [self.storyboard instantiateViewControllerWithIdentifier:@"challengesViewControllerNav"];
    MTChallengesViewController *challengesVC = (MTChallengesViewController *)challengesVCNav.topViewController;
    
    if (challengeId > 0) {
        challengesVC.actionableChallengeId = challengeId;
    }
    
    [self.revealViewController setFrontViewController:challengesVCNav animated:YES];
}


#pragma mark - Notifications -
- (void)unreadCountUpdate:(NSNotification *)note
{
    __block NSIndexPath *indexPathForSelected = [self.tableView indexPathForSelectedRow];
    [self.tableView reloadData];

    if (!indexPathForSelected) {
        if ([MTUser isCurrentUserMentor]) {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        else {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    else {
        [self.tableView selectRowAtIndexPath:indexPathForSelected animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
}

- (void)userSavedProfileChanges:(NSNotification *)note
{
    [self loadProfileImage];
    self.profileName.text = [MTUser currentUser].firstName;
}


@end
