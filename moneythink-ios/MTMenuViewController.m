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
@property (nonatomic, strong) IBOutlet PFImageView *profileImage;
@property (nonatomic, strong) IBOutlet UILabel *profileName;
@property (nonatomic, strong) IBOutlet UILabel *profilePoints;
@property (nonatomic, strong) IBOutlet UIView *footerView;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSArray *signUpCodes;

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
    
    [self loadProfileImage];

    PFUser *user = [PFUser currentUser];
    self.profileName.text = user[@"first_name"];
    
    if ([MTUtil isCurrentUserMentor]) {
        self.profilePoints.hidden = YES;
    }
    else {
        id userPoints = user[@"points"];
        NSString *points = @"0";
        if (userPoints && userPoints != [NSNull null]) {
            points = [userPoints stringValue];
        }
        
        self.profilePoints.text = [NSString stringWithFormat:@"%@pts", points];
    }
    
    NSString *userClass = user[@"class"];
    NSString *userSchool = user[@"school"];
    
    __block NSIndexPath *indexPathForSelected = [self.tableView indexPathForSelectedRow];
    
    if ([MTUtil isCurrentUserMentor]) {
        NSPredicate *signUpCode = [NSPredicate predicateWithFormat:@"class = %@ AND school = %@", userClass, userSchool];
        PFQuery *querySignUpCodes = [PFQuery queryWithClassName:[PFSignupCodes parseClassName] predicate:signUpCode];
        querySignUpCodes.cachePolicy = kPFCachePolicyNetworkElseCache;
        
        MTMakeWeakSelf();
        [querySignUpCodes findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                weakSelf.signUpCodes = objects;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.tableView reloadData];
                    if (!indexPathForSelected) {
                        [weakSelf.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionNone];
                    }
                    else {
                        [weakSelf.tableView selectRowAtIndexPath:indexPathForSelected animated:NO scrollPosition:UITableViewScrollPositionNone];
                    }
                });
            }
        }];
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
            if ([MTUtil isCurrentUserMentor]) {
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
            if ([MTUtil isCurrentUserMentor]) {
                return [self.signUpCodes count];
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
            
            NSString *type = @"";
    
            PFSignupCodes *signupCode = self.signUpCodes[row];
            type = signupCode[@"type"];
            code = signupCode[@"code"];
    
            if ([type isEqualToString:@"student"]) {
                msg = @"Student Sign Up Code:";
            } else if ([type isEqualToString:@"mentor"]) {
                msg = @"Mentor Sign Up Code:";
            }
    
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
        
        NSString *msg = @"";

        switch (indexPath.row) {
            case 0: {
                msg = @"Student";

                // Mark user invited students
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserInvitedStudents];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
                break;

            default: {
                msg = @"Mentor";
            }
                break;
        }

        PFSignupCodes *signupCode = self.signUpCodes[indexPath.row];
        NSString *signupCodeString = [NSString stringWithFormat:@"%@ sign up code for class '%@' is '%@'", msg, [PFUser currentUser][@"class"], signupCode[@"code"]];
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
    [MTUtil logout];
    [[MTUtil getAppDelegate] setDarkNavBarAppearanceForNavigationBar:nil];
    NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
    if (selectedIndexPath) {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:NO];
    }

    [self.revealViewController setFrontViewController:[[MTUtil getAppDelegate] userViewController] animated:YES];
    [self.revealViewController revealToggleAnimated:YES];
}

- (void)loadProfileImage
{
    __block PFFile *profileImageFile = [PFUser currentUser][@"profile_picture"];
    
    if (!self.profileImage.image) {
        self.profileImage.image = [UIImage imageNamed:@"profile_image.png"];
    }
    
    self.profileImage.layer.cornerRadius = round(self.profileImage.frame.size.width / 2.0f);
    self.profileImage.layer.borderColor = [UIColor whiteColor].CGColor;
    self.profileImage.layer.borderWidth = 1.0f;
    self.profileImage.layer.masksToBounds = YES;
    self.profileImage.contentMode = UIViewContentModeScaleAspectFill;
    
    if (profileImageFile) {
        // Load/update the profile image
        MTMakeWeakSelf();
        [self bk_performBlock:^(id obj) {
            [self.profileImage setFile:profileImageFile];
            [self.profileImage loadInBackground:^(UIImage *image, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.profileImage.image = image;
                });
                
                [[PFUser currentUser] fetchInBackground];
            }];
        } afterDelay:0.35f];
    }
    else {
        // Set to default
        [self.profileImage setFile:nil];
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
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionNone];
    if (self.revealViewController.frontViewPosition == FrontViewPositionRight) {
        [self.revealViewController revealToggleAnimated:NO];
    }
    
    UINavigationController *leaderboardVCNav = [self.storyboard instantiateViewControllerWithIdentifier:@"leaderboardVCNav"];
    [self.revealViewController setFrontViewController:leaderboardVCNav animated:YES];
}

- (void)openNotificationsWithId:(NSString *)notificationId
{
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionNone];
    if (self.revealViewController.frontViewPosition == FrontViewPositionRight) {
        [self.revealViewController revealToggleAnimated:NO];
    }

    UINavigationController *notificationsVCNav = [self.storyboard instantiateViewControllerWithIdentifier:@"mentorNotificationsNav"];
    MTNotificationViewController *notificationVC = (MTNotificationViewController *)notificationsVCNav.topViewController;
    notificationVC.actionableNotificationId = notificationId;

    [self.revealViewController setFrontViewController:notificationsVCNav animated:YES];
}

- (void)openChallengesForChallengeId:(NSString *)challengeId
{
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionNone];
    if (self.revealViewController.frontViewPosition == FrontViewPositionRight) {
        [self.revealViewController revealToggleAnimated:NO];
    }

    UINavigationController *challengesVCNav = [self.storyboard instantiateViewControllerWithIdentifier:@"challengesViewControllerNav"];
    MTChallengesViewController *challengesVC = (MTChallengesViewController *)challengesVCNav.topViewController;
    
    if (!IsEmpty(challengeId)) {
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
        if ([MTUtil isCurrentUserMentor]) {
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
}


@end
