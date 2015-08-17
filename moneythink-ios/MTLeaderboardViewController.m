//
//  MTLeaderboardViewController.m
//  moneythink-ios
//
//  Created by David Sica on 5/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTLeaderboardViewController.h"
#import "MTMentorStudentProfileViewController.h"

@interface MTLeaderboardViewController ()

@property (nonatomic, strong) RLMResults *leaders;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

@implementation MTLeaderboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_actionbar"]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadLeaders];
}


#pragma mark - Private Methods -
- (void)loadLeaders
{
    // TODO: Load leaders
//    NSString *userClass = [PFUser currentUser][@"class"];
//    NSString *userSchool = [PFUser currentUser][@"school"];
//    
//    PFQuery *userClassQuery = [PFQuery queryWithClassName:[PFUser parseClassName]];
//    [userClassQuery whereKey:@"class" equalTo:userClass];
//    [userClassQuery whereKey:@"school" equalTo:userSchool];
//    [userClassQuery whereKey:@"type" notEqualTo:@"mentor"];
//    userClassQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
//    
//    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
//    
//    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
//    hud.labelText = @"Loading Leaders...";
//    hud.dimBackground = YES;
//    
//    MTMakeWeakSelf();
//    [self bk_performBlock:^(id obj) {
//        [userClassQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
//            });
//
//            if (!error) {
//                if (!IsEmpty(objects)) {
//                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"points" ascending:NO];
//                    NSArray *sortedArray = [objects sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
//                    weakSelf.leaders = sortedArray;
//                    [weakSelf.tableView reloadData];
//                }
//            }
//            else {
//                NSLog(@"Error loading leaders: %@", [error localizedDescription]);
//            }
//        }];
//    } afterDelay:0.35f];
}


#pragma mark - UITableViewDataSource methods -
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableView.frame.size.width, 20.0f)];
    headerView.backgroundColor = [UIColor colorWithHexString:@"#f5f5f5"];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 0.0f, 300.0f, 20.0f)];
    headerLabel.backgroundColor = [UIColor clearColor];
    headerLabel.textColor = [UIColor colorWithHexString:@"#1a1a1a"];
    headerLabel.font = [UIFont boldSystemFontOfSize:13.0f];
    headerLabel.text = @"LEADERBOARD";
    [headerView addSubview:headerLabel];
    
    return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.leaders count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MTUser *user = [self.leaders objectAtIndex:indexPath.row];
    NSString *CellIdentifier = @"leaderCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    PFImageView *profileImage = (PFImageView *)[cell.contentView viewWithTag:1];
    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:2];
    UILabel *pointsLabel = (UILabel *)[cell.contentView viewWithTag:3];
    
    nameLabel.text = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
    pointsLabel.text = [NSString stringWithFormat:@"%ld", (long)user.points];

    profileImage.image = [UIImage imageNamed:@"profile_image"];
    profileImage.contentMode = UIViewContentModeScaleAspectFill;
    profileImage.layer.cornerRadius = round(profileImage.frame.size.width / 2.0f);
    profileImage.layer.masksToBounds = YES;

    // TODO: Load user avatars
//    if (user[@"profile_picture"]) {
//        profileImage.file = user[@"profile_picture"];
//        [profileImage loadInBackground:^(UIImage *image, NSError *error) {
//            if (!error) {
//                if (image) {
//                    profileImage.image = image;
//                    [cell setNeedsDisplay];
//                }
//                else {
//                    image = nil;
//                }
//            } else {
//                NSLog(@"error - %@", error);
//            }
//        }];
//    }
    
    return cell;
}


#pragma mark - UITableViewDelegate Methods -
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    MTUser *rowStudent = [self.leaders objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"userProfileView" sender:rowStudent];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}


#pragma mark - Navigation -
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    NSString *segueID = [segue identifier];
    if ([segueID isEqualToString:@"userProfileView"]) {
        MTMentorStudentProfileViewController *destinationVC = (MTMentorStudentProfileViewController *)[segue destinationViewController];
        MTUser *student = sender;
        destinationVC.student = student;
    }
}


@end
