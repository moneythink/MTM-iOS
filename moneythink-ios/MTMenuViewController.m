//
//  MTMenuViewController.m
//  moneythink-ios
//
//  Created by David Sica on 5/26/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTMenuViewController.h"
#import "MTMenuTableViewCell.h"

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
    
    [self.tableView reloadData];
    if ([MTUtil isCurrentUserMentor]) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    else {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    self.headerView.backgroundColor = [UIColor menuDarkGreen];
    self.footerView.backgroundColor = [UIColor menuLightGreen];
    self.tableView.backgroundColor = [UIColor menuLightGreen];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self loadProfileImageForImageView:self.profileImage];

    PFUser *user = [PFUser currentUser];
    self.profileName.text = user[@"first_name"];
    NSString *myPoints = user[@"points"] ? user[@"points"] : @"0";
    self.profilePoints.text = [NSString stringWithFormat:@"%@pts", myPoints];
    
    NSString *userClass = user[@"class"];
    NSString *userSchool = user[@"school"];
    
    if ([MTUtil isCurrentUserMentor]) {
        NSPredicate *signUpCode = [NSPredicate predicateWithFormat:@"class = %@ AND school = %@", userClass, userSchool];
        PFQuery *querySignUpCodes = [PFQuery queryWithClassName:[PFSignupCodes parseClassName] predicate:signUpCode];
        querySignUpCodes.cachePolicy = kPFCachePolicyCacheThenNetwork;
        
        MTMakeWeakSelf();
        [querySignUpCodes findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                weakSelf.signUpCodes = objects;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationNone];
                });
            }
        }];
    }
    
    [[MTUtil getAppDelegate] setDefaultNavBarAppearanceForNavigationBar:nil];
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
                    CellIdentifier = @"Support";
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
    // Reset user profile check for next user
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kUserSavedProfileChanges];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [MTUtil logout];
    [self.revealViewController setFrontViewController:[[MTUtil getAppDelegate] userViewController] animated:YES];
    [self.revealViewController revealToggleAnimated:YES];
}

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
    imageView.layer.borderColor = [UIColor whiteColor].CGColor;
    imageView.layer.borderWidth = 1.0f;
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


#pragma mark - UIActionSheetDelegate methods -
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex  // after animation
{
    if (buttonIndex == actionSheet.destructiveButtonIndex) {
        [self logoutAction];
    }
}


@end