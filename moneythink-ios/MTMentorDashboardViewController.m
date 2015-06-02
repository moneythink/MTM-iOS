//
//  MTMentorDashboardViewController.m
//  moneythink-ios
//
//  Created by dsica on 5/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTMentorDashboardViewController.h"
#import "MTStudentProgressTableViewCell.h"
#import "MICheckBox.h"
#import "MTMentorStudentProfileViewController.h"
#import "MTScheduleTableViewController.h"

@interface MTMentorDashboardViewController ()

@property (nonatomic) BOOL scheduledActivationsOn;
@property (nonatomic, strong) PFImageView *profileImage;
@property (nonatomic, strong) PFUser *userCurrent;
@property (nonatomic) MTProgressNextStepState nextStepState;
@property (nonatomic) BOOL queriedForActivationsOn;
@property (nonatomic) BOOL queriedForStudents;

@end

@implementation MTMentorDashboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_actionbar"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.scheduledActivationsOn = NO;
    self.queriedForActivationsOn = NO;
    self.queriedForStudents = NO;
    
    [self setNextStepState];
    [self.tableView reloadData];
    
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Refreshing...";
    hud.dimBackground = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self loadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
}


#pragma mark - Actions -
- (void)presentEditProfile
{
    [self performSegueWithIdentifier:@"presentEditProfile" sender:self];
}

- (void)presentChallengeSchedule
{
    [self performSegueWithIdentifier:@"pushScheduleView" sender:self];
}

- (void)presentInviteStudents
{
    [[MTUtil getAppDelegate] selectSettingsTabView];
}


#pragma mark - Private Methods -
- (void)loadProfileImageForImageView:(UIImageView *)imageView
{
    __block PFFile *profileImageFile = [PFUser currentUser][@"profile_picture"];
    
    if (self.profileImage.image) {
        imageView.image = self.profileImage.image;
    }
    else {
        imageView.image = [UIImage imageNamed:@"profile_image.png"];
    }
    
    imageView.layer.cornerRadius = round(imageView.frame.size.width / 2.0f);
    imageView.layer.masksToBounds = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    
    if (profileImageFile) {
        // Load/update the profile image
        
        [self bk_performBlock:^(id obj) {
            self.profileImage = [[PFImageView alloc] init];
            [self.profileImage setFile:profileImageFile];
            
            [self.profileImage loadInBackground:^(UIImage *image, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [imageView setImage:self.profileImage.image];
                });
                
                [[PFUser currentUser] fetchInBackground];
            }];
        } afterDelay:0.35f];
    }
    else {
        // Set to default
        self.profileImage = [[PFImageView alloc] init];
        [self.profileImage setFile:nil];
        self.profileImage.image = [UIImage imageNamed:@"profile_image.png"];
        [imageView setImage:self.profileImage.image];
    }
}

- (void)setNextStepState
{
    BOOL savedProfile = NO;
    if ([PFUser currentUser][@"profile_picture"] || [[NSUserDefaults standardUserDefaults] boolForKey:kUserSavedProfileChanges]) {
        // Make sure to set in case of upgrade
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserSavedProfileChanges];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        savedProfile = YES;
    }
    
    BOOL activatedChallenges = NO;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kUserActivatedChallenges] ||
        (self.scheduledActivationsOn && self.queriedForActivationsOn)) {
        // Make sure to set in case of upgrade
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserActivatedChallenges];
        [[NSUserDefaults standardUserDefaults] synchronize];

        activatedChallenges = YES;
    }
    
    BOOL invitedStudents = NO;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kUserInvitedStudents] ||
        ([self.classStudents count] > 0 && self.queriedForStudents)) {
        // Make sure to set in case of upgrade
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserInvitedStudents];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        invitedStudents = YES;
    }
    
    if (!savedProfile) {
        self.nextStepState = MTProgressNextStepStateEditProfile;
    }
    else if (self.queriedForActivationsOn && !activatedChallenges) {
        self.nextStepState = MTProgressNextStepStateScheduleChallenges;
    }
    else if (self.queriedForStudents && !invitedStudents) {
        self.nextStepState = MTProgressNextStepStateInviteStudents;
    }
    else {
        self.nextStepState = MTProgressNextStepStateDone;
    }
}

- (void)loadData
{
    NSString *nameClass = [PFUser currentUser][@"class"];
    NSString *nameSchool = [PFUser currentUser][@"school"];
    
    NSPredicate *futureActivations = [NSPredicate predicateWithFormat:@"class = %@ AND school = %@ AND activation_date != nil AND activated = NO", nameClass, nameSchool];
    PFQuery *scheduledActivations = [PFQuery queryWithClassName:[PFScheduledActivations parseClassName] predicate:futureActivations];
    scheduledActivations.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    MTMakeWeakSelf();
    [scheduledActivations countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            weakSelf.scheduledActivationsOn = (number > 0);
            
        } else {
            NSLog(@"error - %@", error);
            if (![MTUtil internetReachable]) {
                [UIAlertView showNoInternetAlert];
            }
            else {
                NSString *errorMessage = [NSString stringWithFormat:@"Unable to update Auto-Release information. %ld: %@", (long)error.code, [error localizedDescription]];
                [[[UIAlertView alloc] initWithTitle:@"Update Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }
        }
        
        weakSelf.queriedForActivationsOn = YES;
        
        if (weakSelf.queriedForStudents) {
            [weakSelf setNextStepState];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            });
        }
    }];
    
    NSString *type = @"student";
    NSPredicate *classStudents = [NSPredicate predicateWithFormat:@"class = %@ AND school = %@ AND type = %@", nameClass, nameSchool, type];
    PFQuery *studentsForClass = [PFQuery queryWithClassName:[PFUser parseClassName] predicate:classStudents];
    
    [studentsForClass orderByAscending:@"last_name"];
    studentsForClass.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    [studentsForClass findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        weakSelf.classStudents = objects;
        weakSelf.queriedForStudents = YES;
        
        if (weakSelf.queriedForActivationsOn) {
            [weakSelf setNextStepState];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            });
        }
    }];
}


#pragma mark - UITableViewController delegate methods -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;
    
    switch (section) {
        case MTProgressSectionStudents:
            rows = [self.classStudents count];
            break;
            
        default:
            break;
    }
    
    return rows;
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    NSString *identString = @"mentorStudentProgressCell";
    
    MTStudentProgressTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identString];
    if (cell == nil) {
        cell = [[MTStudentProgressTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identString];
    }
    PFUser *rowStudent = self.classStudents[row];
    cell.user = rowStudent;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    NSString *fullName = rowStudent[@"first_name"];
    fullName = [[fullName stringByAppendingString:@" "] stringByAppendingString:rowStudent[@"last_name"]];
    cell.userFullName.text = fullName;

    NSString *bankAccount = rowStudent[@"bank_account"];

    if ([bankAccount intValue] == 1) {
        cell.bankCheckbox.isChecked = YES;
    }
    else {
        cell.bankCheckbox.isChecked = NO;
    }

    NSString *resume = rowStudent[@"resume"];

    if ([resume intValue] == 1) {
        cell.resumeCheckbox.isChecked = YES;
    }
    else {
        cell.resumeCheckbox.isChecked = NO;
    }

    cell.userProfileImage.image = nil;
    cell.userProfileImage.image = [UIImage imageNamed:@"profile_image.png"];
    cell.userProfileImage.layer.cornerRadius = round(cell.userProfileImage.frame.size.width / 2.0f);
    cell.userProfileImage.layer.masksToBounds = YES;
    cell.userProfileImage.contentMode = UIViewContentModeScaleAspectFill;

    cell.userProfileImage.file = rowStudent[@"profile_picture"];
    [cell.userProfileImage loadInBackground:^(UIImage *image, NSError *error) {
        if (!error) {
        }
        else {
            NSLog(@"error - %@", error);
        }
    }];

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    return 4;
}


#pragma mark - UITableViewDelegate methods -
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFUser *rowStudent = self.classStudents[indexPath.row];
    [self performSegueWithIdentifier:@"mentorStudentProfileView" sender:rowStudent];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == MTProgressSectionStudents) {
        return nil;
    }

    static NSString *CellIdentifier = @"NextStepHeaderView";
    
    switch (section) {
        case MTProgressSectionNextStep:
            CellIdentifier = @"NextStepHeaderView";
            break;
        case MTProgressSectionEditProfile:
            CellIdentifier = @"UserDetailHeaderView";
            break;
        case MTProgressSectionChallenges:
            CellIdentifier = @"ChallengesHeaderView";
            break;
    
        default:
            break;
    }
    
    UITableViewCell *headerView = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (headerView == nil){
        [NSException raise:@"headerView == nil.." format:@"No cells with matching CellIdentifier loaded from your storyboard"];
        return nil;
    }
    
    // Gets around long-press interaction on content.
    //  http://stackoverflow.com/questions/9219234/how-to-implement-custom-table-view-section-headers-and-footers-with-storyboard/
    while (headerView.contentView.gestureRecognizers.count) {
        [headerView.contentView removeGestureRecognizer:[headerView.contentView.gestureRecognizers objectAtIndex:0]];
    }
    
    switch (section) {
        case MTProgressSectionNextStep:
        {
            UIButton *nextStepButton = (UIButton *)[headerView viewWithTag:98];
            [nextStepButton setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreenDark] size:nextStepButton.frame.size] forState:UIControlStateHighlighted];
            [nextStepButton setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:nextStepButton.frame.size] forState:UIControlStateNormal];
            [nextStepButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
            [nextStepButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            
            [nextStepButton removeTarget:self action:@selector(presentEditProfile) forControlEvents:UIControlEventTouchUpInside];
            [nextStepButton removeTarget:self action:@selector(presentChallengeSchedule) forControlEvents:UIControlEventTouchUpInside];
            [nextStepButton removeTarget:self action:@selector(presentInviteStudents) forControlEvents:UIControlEventTouchUpInside];

            NSString *nextStepText;

            switch (self.nextStepState) {
                case MTProgressNextStepStateEditProfile:
                {
                    nextStepText = @"▶︎ NEXT STEP: Add Your Profile Photo";
                    [nextStepButton addTarget:self action:@selector(presentEditProfile) forControlEvents:UIControlEventTouchUpInside];
                    break;
                }
                    
                case MTProgressNextStepStateScheduleChallenges:
                {
                    nextStepText = @"▶︎ NEXT STEP: Schedule Your Challenges";
                    [nextStepButton addTarget:self action:@selector(presentChallengeSchedule) forControlEvents:UIControlEventTouchUpInside];
                    break;
                }
                    
                case MTProgressNextStepStateInviteStudents:
                {
                    nextStepText = @"▶︎ NEXT STEP: Invite Students";
                    [nextStepButton addTarget:self action:@selector(presentInviteStudents) forControlEvents:UIControlEventTouchUpInside];
                    break;
                }
  
                case MTProgressNextStepStateDone:
                {
                    return nil;
                    break;
                }
   
                default:
                    break;
            }
            
            if (nextStepButton) {
                [nextStepButton setTitle:nextStepText forState:UIControlStateNormal];
            }
            
            break;
        }
        case MTProgressSectionEditProfile:
        {
            UIImageView *profileView = (UIImageView *)[headerView viewWithTag:200];
            profileView.layer.masksToBounds = YES;
            [self loadProfileImageForImageView:profileView];
            
            self.userCurrent = [PFUser currentUser];
            
            UILabel *userNameLabel = (UILabel *)[headerView viewWithTag:201];
            userNameLabel.text = [NSString stringWithFormat:@"%@ %@", self.userCurrent[@"first_name"], self.userCurrent[@"last_name"]];
            UILabel *schoolLabel = (UILabel *)[headerView viewWithTag:202];
            schoolLabel.text = self.userCurrent[@"school"];
            UILabel *classLabel = (UILabel *)[headerView viewWithTag:203];
            classLabel.text = self.userCurrent[@"class"];
            UIButton *editButton = (UIButton *)[headerView viewWithTag:204];
            editButton.layer.cornerRadius = 15.0f;
            editButton.layer.masksToBounds = YES;
            [editButton setBackgroundImage:[UIImage imageWithColor:[UIColor darkGrayColor] size:editButton.frame.size] forState:UIControlStateHighlighted];
            [editButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"F2F2F2"] size:editButton.frame.size] forState:UIControlStateNormal];
            [editButton setTitleColor:[UIColor white] forState:UIControlStateHighlighted];
            [editButton setTitleColor:[UIColor colorWithHexString:@"58595b"] forState:UIControlStateNormal];
            [editButton addTarget:self action:@selector(presentEditProfile) forControlEvents:UIControlEventTouchUpInside];

            break;
        }
        case MTProgressSectionChallenges:
        {
            UIButton *challengesButton = (UIButton *)[headerView viewWithTag:300];
            challengesButton.layer.cornerRadius = 15.0f;
            challengesButton.layer.masksToBounds = YES;
            
            if (self.queriedForActivationsOn) {
                // Now, style appropriately

                if (self.scheduledActivationsOn) {
                    [challengesButton setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreenDark] size:challengesButton.frame.size] forState:UIControlStateHighlighted];
                    [challengesButton setBackgroundImage:[UIImage imageWithColor:[UIColor primaryGreen] size:challengesButton.frame.size] forState:UIControlStateNormal];
                    [challengesButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
                    [challengesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

                    [challengesButton setImage:[UIImage imageNamed:@"schedule-check.png"] forState:UIControlStateNormal];
                }
                else {
                    [challengesButton setBackgroundImage:[UIImage imageWithColor:[UIColor grayColor] size:challengesButton.frame.size] forState:UIControlStateHighlighted];
                    [challengesButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"58595b"] size:challengesButton.frame.size] forState:UIControlStateNormal];
                    [challengesButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
                    [challengesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

                    [challengesButton setImage:nil forState:UIControlStateNormal];
                }
            }
            else {
                // Just default to inactive style
                [challengesButton setImage:nil forState:UIControlStateNormal];
                [challengesButton setBackgroundImage:[UIImage imageWithColor:[UIColor grayColor] size:challengesButton.frame.size] forState:UIControlStateHighlighted];
                [challengesButton setBackgroundImage:[UIImage imageWithColor:[UIColor colorWithHexString:@"58595b"] size:challengesButton.frame.size] forState:UIControlStateNormal];
                [challengesButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
                [challengesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

            }
            
            [challengesButton addTarget:self action:@selector(presentChallengeSchedule) forControlEvents:UIControlEventTouchUpInside];

            break;
        }
        default:
            break;
    }
    
    return headerView.contentView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger section = indexPath.section;

    CGFloat height;
    
    switch (section) {
        case MTProgressSectionStudents:
            height = 60.0f;
            break;
            
        default:
            height = 0.0f;
            break;
    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height;
    
    switch (section) {
        case MTProgressSectionNextStep:
        {
            if (self.nextStepState == MTProgressNextStepStateDone) {
                height = 0.0f;
            }
            else {
                height = 50.0f;
            }
            break;
        }
            
        case MTProgressSectionEditProfile:
            height = 90.0f;
            break;
            
        case MTProgressSectionChallenges:
            height = 60.0f;
            break;

        case MTProgressSectionStudents:
            height = 0.0f;
            break;
            
        default:
            height = 0.0f;
            break;
    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0f;
}


#pragma mark - Navigation -
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSString *segueID = [segue identifier];
    if ([segueID isEqualToString:@"mentorStudentProfileView"]) {
        MTMentorStudentProfileViewController *destinationVC = (MTMentorStudentProfileViewController *)[segue destinationViewController];
        
        PFUser *student = sender;
        destinationVC.student = student;
        
    }
}


@end
