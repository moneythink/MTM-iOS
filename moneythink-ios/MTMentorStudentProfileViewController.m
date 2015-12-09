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
#import "JYPullToRefreshController.h"
#import "JYPullToLoadMoreController.h"
#import "MTRefreshView.h"

#define kHeightBase 120.f
#define kHeightPictureAndPadding 300.f

@interface MTMentorStudentProfileViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) RLMResults *studentPosts;
@property (strong, nonatomic) IBOutlet UILabel *userPoints;
@property (strong, nonatomic) MTStudentProfileTableViewCell *dummyCell;
@property (strong, nonatomic) JYPullToRefreshController *refreshController;
@property (strong, nonatomic) JYPullToLoadMoreController *loadMoreController;
@property (strong, nonatomic) MTRefreshView *refreshControllerRefreshView;
@property (strong, nonatomic) MTRefreshView *loadMoreControllerRefreshView;

- (void)configureRefreshController;
- (void)configureLoadMoreController;

@end

@implementation MTMentorStudentProfileViewController

NSUInteger currentPage = 1;
NSInteger totalItems = -1;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.loadingView setMessage:@"Loading latest posts..."];
    [self.loadingView setHidden:YES];
        
    NSString *points = [NSString stringWithFormat:@"%lu", (long)self.studentUser.points];
    self.userPoints.text = [points stringByAppendingString:@" pts"];
    self.title = [NSString stringWithFormat:@"%@ %@", self.studentUser.firstName, self.studentUser.lastName];
    
    __block UIImageView *weakImageView = self.profileImage;
    self.profileImage.layer.cornerRadius = round(self.profileImage.frame.size.width / 2.0f);
    self.profileImage.layer.masksToBounds = YES;
    self.profileImage.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImage.image = [self.studentUser loadAvatarImageWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakImageView.image = responseData;
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load user avatar");
    }];
}

- (void)configureRefreshController {
    if (self.refreshController || self.refreshControllerRefreshView) return;
    
    MTMakeWeakSelf();
    self.refreshController = [[JYPullToRefreshController alloc] initWithScrollView:self.tableView];
    
    MTRefreshView *refreshView = [[MTRefreshView alloc] initWithFrame:CGRectMake(0,0,self.tableView.frame.size.width, 44.0f)];
    [self.refreshController setCustomView:refreshView];
    self.refreshControllerRefreshView = refreshView;
    
    self.refreshController.pullToRefreshHandleAction = ^{
        currentPage = 1;
        [weakSelf loadRemotePostsForCurrentPage];
    };
}

- (void)configureLoadMoreController {
    if (self.loadMoreController || self.loadMoreControllerRefreshView) return;
    
    MTMakeWeakSelf();
    self.loadMoreController = [[JYPullToLoadMoreController alloc] initWithScrollView:self.tableView];
    self.loadMoreController.autoLoadMore = NO;
    
    MTRefreshView *refreshView = [[MTRefreshView alloc] initWithFrame:CGRectMake(0,0,self.tableView.frame.size.width, 44.0f)];
    [self.loadMoreController setCustomView:refreshView];
    self.loadMoreControllerRefreshView = refreshView;
    
    self.loadMoreController.pullToLoadMoreHandleAction = ^{
        [weakSelf loadRemotePostsForCurrentPage];
    };
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.loadingView setHidden:YES];
    [self loadLocalPosts:^(NSError *error) {
        if (error == nil) {
            [self.loadingView setHidden:self.studentPosts.count > 0];
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:NO];
    
    [self configureRefreshController];
    [self configureLoadMoreController];
    
    [MTUtil GATrackScreen:@"Student Profile View: Mentor"];
}

- (void)loadLocalPosts {
    [self loadLocalPosts:nil];
}

// @Private
- (void)loadLocalPosts:(MTSuccessBlock)callback {
    MTMakeWeakSelf();
    
    NSArray *sorts = @[
       [RLMSortDescriptor sortDescriptorWithProperty:@"createdAt" ascending:NO],
    ];
    RLMResults *newResults = [[MTChallengePost objectsWhere:@"isDeleted = NO AND user.id = %lu AND challenge != NULL AND isCrossPost = NO", self.studentUser.id] sortedResultsUsingDescriptors:sorts];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.studentPosts = newResults;
        [weakSelf.tableView beginUpdates];
        [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [weakSelf.tableView endUpdates];
        
        [weakSelf.refreshController stopRefreshWithAnimated:YES completion:nil];
        
        if (callback != nil) {
            callback(nil);
        }
    });
}


#pragma mark - UITableViewController delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.studentPosts == nil) return 0;
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
    
    // TODO: Fix the intermittent crash here.
    if (row >= self.studentPosts.count) return cell;
    
    MTChallengePost *post = [self.studentPosts objectAtIndex:row];
    MTUser *user = post.user;
    
    __block MTStudentProfileTableViewCell *weakCell = cell;
    
    cell.postImage.layer.masksToBounds = YES;
    cell.postImage.contentMode = UIViewContentModeScaleAspectFill;
    
    if (post.hasPostImage) {
        cell.postImage.image = [post loadPostImageWithSuccess:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakCell.postImage.image = responseData;
            });
        } failure:^(NSError *error) {
            NSLog(@"Unable to load post image");
        }];
    } else {
        cell.postImageHeightConstraint.constant = 0;
        [cell.postImage setHidden:YES];
    }
    
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
    MTChallenge *challenge = post.challenge;
    if (challenge != nil) {
        cell.challengeIsAutoVerified = [challenge autoVerify];
    } else {
        cell.challengeIsAutoVerified = NO;
    }
    cell.verifiedCheckbox.hidden = ![MTUser isCurrentUserMentor];
    cell.verifiedLabel.hidden = ![MTUser isCurrentUserMentor];

    if ([MTUser isCurrentUserMentor]) {
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
    NSString *complexId = [NSString stringWithFormat:@"%lu-%lu", (long)self.studentUser.id, (long)post.id];
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
    
    [cell setNeedsLayout];
    [cell layoutIfNeeded];
    
    return cell;
}


#pragma mark - UITableViewDelegate Methods -
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kHeightBase + kHeightPictureAndPadding;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    if (indexPath.row > self.studentPosts.count) {
        return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
    }
    MTChallengePost *post = [self.studentPosts objectAtIndex:indexPath.row];
    if (post.hasPostImage) {
        CGFloat textHeight = 0.f;

        if (self.dummyCell == nil ) {
            NSIndexPath *dummyIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            self.dummyCell = (MTStudentProfileTableViewCell *)[self tableView:tableView cellForRowAtIndexPath:dummyIndexPath];
        }
        
        CGSize postTextSize = CGSizeMake(self.dummyCell.postText.frame.size.width, CGFLOAT_MAX);
        
        // Calculate for this postText
        self.dummyCell.postText.text = post.content;
        NSDictionary *attributes = @{NSFontAttributeName: self.dummyCell.postText.font};
        CGRect dummyContentRect = [post.content boundingRectWithSize:postTextSize
                                                             options:NSStringDrawingUsesLineFragmentOrigin
                                                          attributes:attributes
                                                             context:nil];
        textHeight = dummyContentRect.size.height;

        return kHeightBase + kHeightPictureAndPadding + textHeight;
    } else {
        return kHeightBase;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1) {
        // this is the last cell, load the next page
        if (totalItems > 0 && totalItems < indexPath.row) {
            [self loadRemotePostsForCurrentPage];
        }
    }
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
        destinationVC.challengePostId = rowObject.id;
    }
}

- (void)loadRemotePostsForCurrentPage {
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] loadPostsForUserId:self.studentUser.id page:currentPage params:@{@"allow_fed_posts": @"false"} success:^(BOOL lastPage, NSUInteger numPages, NSUInteger totalCount) {
        totalItems = totalCount;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.loadingView setHidden:YES];
            
            if (self.refreshController.refreshState == JYRefreshStateLoading) {
                [self.refreshController stopRefreshWithAnimated:YES completion:nil];
            }
            if (self.loadMoreController.loadMoreState == JYLoadMoreStateLoading) {
                [self.loadMoreController stopLoadMoreCompletion:nil];
            }
            NSLog(@"Loaded page %lu of %lu", (unsigned long)currentPage, (unsigned long)numPages);
            if (!lastPage) {
                currentPage++;
            }
            [weakSelf loadLocalPosts];
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load student posts");
        [self.refreshController stopRefreshWithAnimated:YES completion:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf loadLocalPosts];
            [self.loadingView setIsLoading:NO];
            if (weakSelf.studentPosts.count == 0) {
                [self.loadingView setHidden:NO];
                [self.loadingView setMessage:@"No posts yet by this student."];
            } else {
                [self.loadingView setHidden:YES];
            }
        });
    }];
}

// MARK: UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < 0) {
        [self.refreshControllerRefreshView scrollView:scrollView contentOffsetDidUpdate:scrollView.contentOffset];
    } else {
        [self.loadMoreControllerRefreshView scrollView:scrollView contentOffsetDidUpdate:scrollView.contentOffset];
    }
}

@end
