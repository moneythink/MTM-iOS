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
#import "MTPostViewController.h"

@interface MTMentorStudentProfileViewController ()

@property (strong, nonatomic) NSArray *studentPosts;

@property (strong, nonatomic) IBOutlet UILabel *userPoints;

@end

@implementation MTMentorStudentProfileViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    id studentPoints = self.student[@"points"];
    NSString *points = @"0";
    if (studentPoints && studentPoints != [NSNull null]) {
        points = [studentPoints stringValue];
    }
    self.userPoints.text = [points stringByAppendingString:@" pts"];
    self.title = [NSString stringWithFormat:@"%@ %@", self.student[@"first_name"], self.student[@"last_name"]];
    
    self.profileImage.file = self.student[@"profile_picture"];
    self.profileImage.layer.cornerRadius = round(self.profileImage.frame.size.width / 2.0f);
    self.profileImage.layer.masksToBounds = YES;
    self.profileImage.contentMode = UIViewContentModeScaleAspectFill;
    
    MTMakeWeakSelf();
    [self.profileImage loadInBackground:^(UIImage *image, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                if (image) {
                    weakSelf.profileImage.image = image;
                } else {
                    weakSelf.profileImage.image = [UIImage imageNamed:@"profile_image.png"];
                }
            } else {
                NSLog(@"error - %@", error);
                weakSelf.profileImage.image = [UIImage imageNamed:@"profile_image.png"];
            }
        });
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:NO];
    
    PFQuery *studentPostsQuery = [PFQuery queryWithClassName:[PFChallengePost parseClassName]];
    [studentPostsQuery whereKey:@"user" equalTo:self.student];
    [studentPostsQuery includeKey:@"verified_by"];
    [studentPostsQuery includeKey:@"user"];
    [studentPostsQuery orderByDescending:@"createdAt"];
    
    studentPostsQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [studentPostsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.studentPosts = objects;
            [self.tableView reloadData];
        } else {
            // error
        }
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
    
    PFChallengePost *post = self.studentPosts[row];
    PFUser *user = post[@"user"];
    
    cell.postProfileImage.image = [UIImage imageNamed:@"profile_image"];
    cell.postProfileImage.file = user[@"profile_picture"];
    cell.postProfileImage.layer.cornerRadius = round(cell.postProfileImage.frame.size.width / 2.0f);
    cell.postProfileImage.layer.masksToBounds = YES;
    cell.postProfileImage.contentMode = UIViewContentModeScaleAspectFill;
    
    [cell.postProfileImage loadInBackground:^(UIImage *image, NSError *error) {
        if (!error) {
            if (image) {
                cell.postProfileImage.image = image;
                [cell setNeedsDisplay];
            }
            else {
                image = nil;
            }
        } else {
            NSLog(@"error - %@", error);
        }
    }];

    cell.rowPost = post;
    
    NSDate *dateObject = [cell.rowPost createdAt];
    
    if (dateObject) {
        cell.timeSince.text = [dateObject niceRelativeTimeFromNow];
    }
    
    // Only show verified assets if current user is Mentor
    cell.verifiedCheckbox.hidden = ![MTUtil isCurrentUserMentor];
    cell.verifiedLabel.hidden = ![MTUtil isCurrentUserMentor];

    if ([MTUtil isCurrentUserMentor]) {
        PFUser *verifier = cell.rowPost[@"verified_by"];
        cell.verified.on = ![[verifier username] isEqualToString:@""];
    }
    
    // >>>>> Attributed hashtag
    cell.postText.text = cell.rowPost[@"post_text"];
    NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange rangeAll = NSMakeRange(0, cell.postText.text.length);
    
    [hashtags enumerateMatchesInString:cell.postText.text options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSMutableAttributedString *hashtag = [[NSMutableAttributedString alloc]initWithString:cell.postText.text];
        [hashtag addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
        
        cell.postText.attributedText = hashtag;
    }];
    
    // Attributed hashtag

    NSInteger likesCount = 0;
    if (cell.rowPost[@"likes"]) {
        likesCount = [cell.rowPost[@"likes"] intValue];
    }
    if (likesCount > 0) {
        cell.likes.image = [UIImage imageNamed:@"like_active"];
        cell.likeCount.text = [NSString stringWithFormat:@"%ld", (long)likesCount];
    } else {
        cell.likes.image = [UIImage imageNamed:@"like_normal"];
        cell.likeCount.text = @"0";
    }
    [cell.likeCount sizeToFit];
    
    if (cell.rowPost[@"verified_by"]) {
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
        MTPostViewController *destinationVC = (MTPostViewController *)[segue destinationViewController];
        MTStudentProfileTableViewCell *cell = (MTStudentProfileTableViewCell *)sender;
        PFChallengePost *rowObject = cell.rowPost;
        destinationVC.challengePost = rowObject;
    }
}


@end
