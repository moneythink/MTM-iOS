//
//  MTMentorStudentProfileTableViewController.m
//  moneythink-ios
//
//  Created by Colin Young on 12/11/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import "MTMentorStudentProfileTableViewController.h"

#import "MTStudentProfileTableViewCell.h"

#import "MTPostDetailViewController.h"
#define kHeightBase 120.f
#define kHeightPictureAndPadding 300.f

@interface MTMentorStudentProfileTableViewController ()

@property (strong, nonatomic) MTStudentProfileTableViewCell *dummyCell;

@end

@implementation MTMentorStudentProfileTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loadingResourceName = @"posts";
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadRemoteResultsForCurrentPage];
}

#pragma mark - Superclass methods
// @Override
- (void)loadLocalResults:(MTSuccessBlock)callback {
    MTMakeWeakSelf();
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([MTUser currentUser] == nil) return;
        
        NSArray *sorts = @[
                           [RLMSortDescriptor sortDescriptorWithProperty:@"createdAt" ascending:NO],
                           ];
        RLMResults *newResults = [[MTChallengePost objectsWhere:@"isDeleted = NO AND user.id = %lu AND challenge != NULL AND isCrossPost = NO", weakSelf.studentUser.id] sortedResultsUsingDescriptors:sorts];
        
        [self didLoadLocalResults:newResults withCallback:callback];
    });
}

// @Override
- (void)loadRemoteResultsForCurrentPage {
    [self willLoadRemoteResultsForCurrentPage];
    
    [[MTNetworkManager sharedMTNetworkManager] loadPostsForUserId:self.studentUser.id page:self.currentPage params:@{@"allow_fed_posts": @"false"} success:^(BOOL lastPage, NSUInteger numPages, NSUInteger totalCount) {
        struct MTIncrementalLoadingResponse response;
        response.lastPage = lastPage;
        response.numPages = numPages;
        response.totalCount = totalCount;
        [self didLoadRemoteResultsWithSuccessfulResponse:response];
    } failure:^(NSError *error) {
        [self didLoadRemoteResultsWithError:error];
    }];
}

#pragma mark - UITableViewCellDataSource methods
// @Override
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    MTStudentProfileTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"studentPosts"];
    if (cell == nil) {
        cell = [[MTStudentProfileTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"studentPosts"];
    }
    
    MTChallengePost *post = [self.results objectAtIndex:row];
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
    if (indexPath.row > self.results.count) {
        return [self tableView:tableView estimatedHeightForRowAtIndexPath:indexPath];
    }
    MTChallengePost *post = [self.results objectAtIndex:indexPath.row];
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

#pragma mark - Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MTChallengePost *post = [self.results objectAtIndex:indexPath.row];
    UIViewController *vc = [[UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"challengePost"];
    MTPostDetailViewController *postDetailViewController = (MTPostDetailViewController*)vc;
    postDetailViewController.challengePostId = post.id;
    [self.navigationController pushViewController:postDetailViewController animated:YES];
}

@end
