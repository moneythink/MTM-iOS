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
#import <Google/Analytics.h>

@interface MTMentorDashboardViewController ()

@property (nonatomic, strong) UIImageView *profileImage;
@property (nonatomic, strong) MTUser *userCurrent;
@property (nonatomic, strong) RLMResults *classStudents;

@end

@implementation MTMentorDashboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_actionbar"]];
    [self loadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // GA Track - 'Dashboard: Mentor'
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:@"Dashboard: Mentor"];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if ([self.tableView indexPathForSelectedRow]) {
        [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    }
}


#pragma mark - Private Methods -
- (void)loadData
{
    self.classStudents = [[MTUser objectsWhere:@"isDeleted = NO AND roleCode = %@ AND userClass.id = %lu", @"STUDENT", [MTUser currentUser].userClass.id] sortedResultsUsingProperty:@"lastName" ascending:YES];
    [self.tableView reloadData];
    
    if (IsEmpty(self.classStudents)) {
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Loading...";
        hud.dimBackground = YES;
    }

    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] loadDashboardUsersWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            weakSelf.classStudents = [[MTUser objectsWhere:@"isDeleted = NO AND roleCode = %@ AND userClass.id = %lu", @"STUDENT", [MTUser currentUser].userClass.id] sortedResultsUsingProperty:@"lastName" ascending:YES];
            [weakSelf.tableView reloadData];
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load dashboard user: %@", [error mtErrorDescription]);
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        });
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    NSString *identString = @"mentorStudentProgressCell";
    
    MTStudentProgressTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identString];
    if (cell == nil) {
        cell = [[MTStudentProgressTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identString];
    }
    
    MTUser *rowStudent = [self.classStudents objectAtIndex:row];
    cell.user = rowStudent;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    NSString *fullName = rowStudent.firstName;
    fullName = [[fullName stringByAppendingString:@" "] stringByAppendingString:rowStudent.lastName];
    cell.userFullName.text = fullName;

    cell.bankCheckbox.isChecked = rowStudent.hasBankAccount;
    cell.resumeCheckbox.isChecked = rowStudent.hasResume;

    cell.userProfileImage.layer.cornerRadius = round(cell.userProfileImage.frame.size.width / 2.0f);
    cell.userProfileImage.layer.masksToBounds = YES;
    cell.userProfileImage.contentMode = UIViewContentModeScaleAspectFill;
    __block MTStudentProgressTableViewCell *weakCell = cell;
    cell.userProfileImage.image = [rowStudent loadAvatarImageWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakCell.userProfileImage.image = responseData;
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load user avatar");
    }];

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}


#pragma mark - UITableViewDelegate methods -
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MTUser *rowStudent = [self.classStudents objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"mentorStudentProfileView" sender:rowStudent];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section != MTProgressSectionEditProfile) {
        return nil;
    }
    
    static NSString *CellIdentifier = @"UserDetailHeaderView";
    
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
    
    self.userCurrent = [MTUser currentUser];

    UIImageView *profileView = (UIImageView *)[headerView viewWithTag:200];
    profileView.layer.masksToBounds = YES;
    profileView.layer.cornerRadius = round(profileView.frame.size.width / 2.0f);
    profileView.layer.masksToBounds = YES;
    profileView.contentMode = UIViewContentModeScaleAspectFill;
    
    __block UIImageView *weakImageView = profileView;
    profileView.image = [self.userCurrent loadAvatarImageWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakImageView.image = responseData;
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load user avatar");
    }];
    
    UILabel *userNameLabel = (UILabel *)[headerView viewWithTag:201];
    userNameLabel.text = [NSString stringWithFormat:@"%@ %@", self.userCurrent.firstName, self.userCurrent.lastName];
    UILabel *schoolLabel = (UILabel *)[headerView viewWithTag:202];
    schoolLabel.text = self.userCurrent.organization.name;
    UILabel *classLabel = (UILabel *)[headerView viewWithTag:203];
    classLabel.text = self.userCurrent.userClass.name;
    
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
        case MTProgressSectionEditProfile:
            height = 90.0f;
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
        MTUser *studentUser = sender;
        destinationVC.studentUser = studentUser;
    }
}


@end
