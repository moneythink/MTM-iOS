//
//  MTMentorStudentProfileViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMentorStudentProfileViewController.h"
#import "MTStudentProfileTableViewCell.h"
#import "MTStudentProfileTableViewCell.h"
#import "MTPostDetailViewController.h"

@interface MTMentorStudentProfileViewController ()

@property (strong, nonatomic) RLMResults *studentPosts;
@property (strong, nonatomic) IBOutlet UILabel *userPoints;

@end

@implementation MTMentorStudentProfileViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *points = [NSString stringWithFormat:@"%lu", (long)self.student.points];
    self.userPoints.text = [points stringByAppendingString:@" pts"];
    self.title = [NSString stringWithFormat:@"%@ %@", self.student.firstName, self.student.lastName];
    
    __block UIImageView *weakImageView = self.profileImage;
    self.profileImage.layer.cornerRadius = round(self.profileImage.frame.size.width / 2.0f);
    self.profileImage.layer.masksToBounds = YES;
    self.profileImage.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImage.image = [self.student loadAvatarImageWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakImageView.image = responseData;
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load user avatar");
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:NO];
    
    [MTUtil GATrackScreen:@"Student Profile View: Mentor"];

    self.studentPosts = [[MTChallengePost objectsWhere:@"isDeleted = NO AND user.id = %lu", self.student.id] sortedResultsUsingProperty:@"createdAt" ascending:NO];
    [self.tableView reloadData];
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] loadPostsForUserId:self.student.id success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.studentPosts = [[MTChallengePost objectsWhere:@"isDeleted = NO AND user.id = %lu", weakSelf.student.id] sortedResultsUsingProperty:@"createdAt" ascending:NO];
            [weakSelf.tableView reloadData];
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load student posts");
    }];
}


#pragma mark - UITableViewController delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = [self.studentPosts count];
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    MTStudentProfileTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"studentPosts"];
    if (cell == nil) {
        cell = [[MTStudentProfileTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"studentPosts"];
    }
    
    MTChallengePost *post = [self.studentPosts objectAtIndex:row];
    MTUser *user = post.user;
    
    __block MTStudentProfileTableViewCell *weakCell = cell;
    
    cell.postProfileImage.layer.cornerRadius = round(cell.postProfileImage.frame.size.width / 2.0f);
    cell.postProfileImage.layer.masksToBounds = YES;
    cell.postProfileImage.contentMode = UIViewContentModeScaleAspectFill;
    cell.postProfileImage.image = [user loadAvatarImageWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakCell.postProfileImage.image = responseData;
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load user avatar");
    }];

    cell.rowPost = post;
    
    NSDate *dateObject = cell.rowPost.createdAt;
    
    if (dateObject) {
        cell.timeSince.text = [dateObject niceRelativeTimeFromNow];
    }
    
    // Only show verified assets if current user is Mentor
    cell.verifiedCheckbox.hidden = ![MTUtil isCurrentUserMentor];
    cell.verifiedLabel.hidden = ![MTUtil isCurrentUserMentor];

    if ([MTUtil isCurrentUserMentor]) {
        cell.verified.on = cell.rowPost.isVerified;
    }
    
    // >>>>> Attributed hashtag
    cell.postText.text = cell.rowPost.content;
    
    if (!IsEmpty(cell.postText.text)) {
        NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
        NSRange rangeAll = NSMakeRange(0, cell.postText.text.length);
        
        [hashtags enumerateMatchesInString:cell.postText.text options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
            NSMutableAttributedString *hashtag = [[NSMutableAttributedString alloc]initWithString:cell.postText.text];
            [hashtag addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
            
            cell.postText.attributedText = hashtag;
        }];
    }
    // Attributed hashtag

    // Get Likes
    NSString *complexId = [NSString stringWithFormat:@"%lu-%lu", (long)self.student.id, (long)post.id];
    MTUserPostPropertyCount *existing = [MTUserPostPropertyCount objectForPrimaryKey:complexId];
    if (existing && existing.likeCount > 0 && !existing.isDeleted) {
        cell.likes.image = [UIImage imageNamed:@"like_active"];
        cell.likeCount.text = [NSString stringWithFormat:@"%ld", (long)existing.likeCount];
    }
    else {
        cell.likes.image = [UIImage imageNamed:@"like_normal"];
        cell.likeCount.text = @"0";
    }
    
    [cell.likeCount sizeToFit];
    
    if (cell.rowPost.isVerified) {
        cell.verifiedCheckbox.isChecked = YES;
    } else {
        cell.verifiedCheckbox.isChecked = NO;
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate Methods -
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
}


#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueId = [segue identifier];
    
    if ([segueId isEqualToString:@"pushProfileToPost"]) {
        MTPostDetailViewController *destinationVC = (MTPostDetailViewController *)[segue destinationViewController];
        MTStudentProfileTableViewCell *cell = (MTStudentProfileTableViewCell *)sender;
        MTChallengePost *rowObject = cell.rowPost;
        destinationVC.challengePost = rowObject;
    }
}


@end
