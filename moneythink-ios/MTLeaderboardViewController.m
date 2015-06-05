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

@property (nonatomic, strong) NSArray *leaders;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

@implementation MTLeaderboardViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_actionbar"]];
    
    // Set the gesture
    //  Add tag = 5000 so panGestureRecognizer can be re-added
    self.navigationController.navigationBar.tag = 5000;
    [self.navigationController.navigationBar addGestureRecognizer:self.revealViewController.panGestureRecognizer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadLeaders];
}


#pragma mark - Private Methods -
- (void)loadLeaders
{
    NSString *userClass = [PFUser currentUser][@"class"];
    NSString *userSchool = [PFUser currentUser][@"school"];
    
    PFQuery *userClassQuery = [PFQuery queryWithClassName:[PFUser parseClassName]];
    [userClassQuery whereKey:@"class" equalTo:userClass];
    [userClassQuery whereKey:@"school" equalTo:userSchool];
    userClassQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Loading Leaders...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [userClassQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];
            });

            if (!error) {
                if (!IsEmpty(objects)) {
                    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"points" ascending:NO];
                    NSArray *sortedArray = [objects sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
                    weakSelf.leaders = sortedArray;
                    [weakSelf.tableView reloadData];
                }
            }
            else {
                NSLog(@"Error loading leaders: %@", [error localizedDescription]);
            }
        }];
    } afterDelay:0.35f];
}


#pragma mark - UITableViewDataSource methods -
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section;    // fixed font style. use custom view (UILabel) if you want something different
{
    return @"Leaderboard";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.leaders count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PFUser *user = [self.leaders objectAtIndex:indexPath.row];
    NSString *CellIdentifier = @"leaderCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    PFImageView *profileImage = (PFImageView *)[cell.contentView viewWithTag:1];
    UILabel *nameLabel = (UILabel *)[cell.contentView viewWithTag:2];
    UILabel *pointsLabel = (UILabel *)[cell.contentView viewWithTag:3];
    
    nameLabel.text = [NSString stringWithFormat:@"%@ %@", user[@"first_name"], user[@"last_name"]];
    
    id userPoints = user[@"points"];
    NSString *points = @"0";
    if (userPoints && userPoints != [NSNull null]) {
        points = [userPoints stringValue];
    }
    pointsLabel.text = points;

    profileImage.image = [UIImage imageNamed:@"profile_image"];
    profileImage.layer.cornerRadius = round(profileImage.frame.size.width / 2.0f);
    profileImage.layer.masksToBounds = YES;

    if (user[@"profile_picture"]) {
        profileImage.file = user[@"profile_picture"];
        [profileImage loadInBackground:^(UIImage *image, NSError *error) {
            if (!error) {
                if (image) {
                    profileImage.image = image;
                    [cell setNeedsDisplay];
                }
                else {
                    image = nil;
                }
            } else {
                NSLog(@"error - %@", error);
            }
        }];
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate Methods -
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    PFUser *rowStudent = [self.leaders objectAtIndex:indexPath.row];
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
        PFUser *student = sender;
        destinationVC.student = student;
    }
}


@end
