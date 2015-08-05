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

@interface MTMentorDashboardViewController ()

@property (nonatomic, strong) PFImageView *profileImage;
@property (nonatomic, strong) PFUser *userCurrent;

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
            self.profileImage.contentMode = UIViewContentModeScaleAspectFill;
            
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
        self.profileImage.contentMode = UIViewContentModeScaleAspectFill;
        [self.profileImage setFile:nil];
        self.profileImage.image = [UIImage imageNamed:@"profile_image.png"];
        [imageView setImage:self.profileImage.image];
    }
}

- (void)loadData
{
    NSString *nameClass = [PFUser currentUser][@"class"];
    NSString *nameSchool = [PFUser currentUser][@"school"];

    NSString *type = @"student";
    NSPredicate *classStudents = [NSPredicate predicateWithFormat:@"class = %@ AND school = %@ AND type = %@", nameClass, nameSchool, type];
    PFQuery *studentsForClass = [PFQuery queryWithClassName:[PFUser parseClassName] predicate:classStudents];
    
    [studentsForClass orderByAscending:@"last_name"];
    studentsForClass.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    MTMakeWeakSelf();
    [studentsForClass findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        weakSelf.classStudents = objects;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
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
        
        PFUser *student = sender;
        destinationVC.student = student;
        
    }
}


@end
