//
//  MTPostViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTPostViewController.h"
#import "MTMentorStudentProfileViewController.h"
#import "MTPostUserInfoTableViewCell.h"
#import "MTPostImageTableViewCell.h"
#import "MTPostCommentTableViewCell.h"
#import "MTPostLikeCommentTableViewCell.h"
#import "MTPostCommentItemsTableViewCell.h"

typedef enum {
    MTPostTableCellTypeUserInfo = 0,
    MTPostTableCellTypeImage,
    MTPostTableCellTypeCommentText,
    MTPostTableCellTypeButtons,
    MTPostTableCellTypeLikeComment,
    MTPostTableCellTypePostComments
} MTPostTableCellType;

@interface MTPostViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) PFUser *currentUser;
@property (strong, nonatomic) PFUser *postUser;
@property (strong, nonatomic) NSArray *postsLiked;
@property (assign, nonatomic) NSInteger postLikesCount;
@property (assign, nonatomic) BOOL iLike;
@property (assign, nonatomic) BOOL isMyClass;
@property (strong, nonatomic) NSArray *comments;
@property (strong, nonatomic) NSDictionary *buttonsTapped;
@property (nonatomic) NSInteger likeActionCount;
@property (nonatomic, strong) UIImage *userAvatarImage;
@property (nonatomic, strong) UIImage *postImage;
@property (nonatomic, strong) NSMutableAttributedString *postText;
@property (nonatomic) CGFloat postTextHeight;
@property (nonatomic) BOOL isMentor;
@property (nonatomic) BOOL autoVerify;
@property (nonatomic) BOOL hideVerifySwitch;

@end

@implementation MTPostViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.postsLiked = [PFUser currentUser][@"posts_liked"];
    NSString *postID = [self.challengePost objectId];
    self.iLike = [self.postsLiked containsObject:postID];
 
    [self loadPostText];
    [self loadChallengePost];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = self.challenge[@"title"];
    self.postUser = self.challengePost[@"user"];
    self.currentUser = [PFUser currentUser];
    self.postLikesCount = 0;
    if (self.challengePost[@"likes"]) {
        self.postLikesCount = [self.challengePost[@"likes"] intValue];
    }
    
    NSPredicate *posterWithID = [NSPredicate predicateWithFormat:@"objectId = %@", [self.postUser objectId]];
    PFQuery *findPoster = [PFQuery queryWithClassName:[PFUser parseClassName] predicate:posterWithID];
    
    findPoster.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    MTMakeWeakSelf();
    [findPoster findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            weakSelf.postUser = [objects firstObject];
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }
    }];
    
    [self loadComments];
    [self updateButtonsTapped];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Private Methods -
- (void)loadComments
{
    MTMakeWeakSelf();
    PFQuery *queryPostComments = [PFQuery queryWithClassName:[PFChallengePostComment parseClassName]];
    [queryPostComments whereKey:@"challenge_post" equalTo:self.challengePost];
    [queryPostComments includeKey:@"user"];
    
    queryPostComments.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [queryPostComments findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            weakSelf.comments = objects;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (void)loadPostText
{
    NSString *textString = self.challengePost[@"post_text"];
    self.postText = [[NSMutableAttributedString alloc] initWithString:textString];
    
    NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange rangeAll = NSMakeRange(0, textString.length);
    
    [hashtags enumerateMatchesInString:textString options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        
        NSMutableAttributedString *hashtag = [[NSMutableAttributedString alloc] initWithString:textString];
        [hashtag addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
        
        self.postText = hashtag;
    }];
}

- (void)updateButtonsTapped
{
    PFQuery *buttonsTapped = [PFQuery queryWithClassName:[PFChallengePostButtonsClicked parseClassName]];
    [buttonsTapped whereKey:@"user" equalTo:[PFUser currentUser]];
    
    MTMakeWeakSelf();
    [buttonsTapped findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        });

        if (!error) {
            NSMutableDictionary *tappedButtonObjects = [NSMutableDictionary dictionary];
            for (PFChallengePostButtonsClicked *clicks in objects) {
                id button = clicks[@"button_clicked"];
                id post = [(PFChallengePost *)clicks[@"post"] objectId];
                [tappedButtonObjects setValue:button forKey:post];
            }
            weakSelf.buttonsTapped = tappedButtonObjects;
            [weakSelf.tableView reloadData];
        }
        else {
            NSLog(@"Error - %@", error);
            [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
        }
    }];
}

- (void)loadChallengePost
{
    self.isMentor = [self.currentUser[@"type"] isEqualToString:@"mentor"];
    self.autoVerify = [self.challenge[@"auto_verify"] boolValue];
    self.hideVerifySwitch = !self.isMentor || self.autoVerify;
}

- (void)setupButtonsForCell:(UITableViewCell *)cell
{
    UIButton *button1 = (UIButton *)[cell.contentView viewWithTag:1];
    UIButton *button2 = (UIButton *)[cell.contentView viewWithTag:2];
    
    NSInteger button = [[self.buttonsTapped valueForKey:[self.challengePost objectId]] intValue];
    if ((button == 0) && (self.buttonsTapped.count > 0)) {
        [[button1 layer] setBackgroundColor:[UIColor primaryGreen].CGColor];
        [button1 setTintColor:[UIColor white]];

        [[button2 layer] setBorderWidth:2.0f];
        [[button2 layer] setBorderColor:[UIColor redOrange].CGColor];
        [button2 setTintColor:[UIColor redOrange]];
        [[button2 layer] setBackgroundColor:[UIColor white].CGColor];
    }
    else if (button == 1) {
        [[button1 layer] setBorderWidth:2.0f];
        [[button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
        [button1 setTintColor:[UIColor primaryGreen]];
        [[button1 layer] setBackgroundColor:[UIColor white].CGColor];

        [[button2 layer] setBackgroundColor:[UIColor redOrange].CGColor];
        [button2 setTintColor:[UIColor white]];
    }
    else {
        [[button1 layer] setBorderWidth:2.0f];
        [[button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
        [button1 setTintColor:[UIColor primaryGreen]];
        [[button1 layer] setBackgroundColor:[UIColor white].CGColor];

        [[button2 layer] setBorderWidth:2.0f];
        [[button2 layer] setBorderColor:[UIColor redOrange].CGColor];
        [button2 setTintColor:[UIColor redOrange]];
        [[button2 layer] setBackgroundColor:[UIColor white].CGColor];
    }

    [[button1 layer] setCornerRadius:5.0f];
    [[button2 layer] setCornerRadius:5.0f];

    NSArray *buttonTitles = self.challenge[@"buttons"];
    NSArray *buttonsClicked = self.challengePost [@"buttons_clicked"];

    if (buttonTitles.count > 0) {
        NSString *button1Title;
        NSString *button2Title;

        if (buttonsClicked.count > 0) {
            button1Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[0], buttonsClicked[0]];
        } else {
            button1Title = [NSString stringWithFormat:@"%@ (0)", buttonTitles[0]];
        }

        if (buttonsClicked.count > 1) {
            button2Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[1], buttonsClicked[1]];
        } else {
            button2Title = [NSString stringWithFormat:@"%@ (0)", buttonTitles[1]];
        }
        
        [button1 setTitle:button1Title forState:UIControlStateNormal];
        [button2 setTitle:button2Title forState:UIControlStateNormal];
    }
}


#pragma mark - Variable Cell Height calculations -
- (CGFloat)heightForPostTextCellAtIndexPath:(NSIndexPath *)indexPath {
    static MTPostCommentTableViewCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommentTextCell"];
    });
    
    [self configurePostTextCell:sizingCell atIndexPath:indexPath];
    return [self calculateHeightForConfiguredSizingCell:sizingCell];
}

- (CGFloat)calculateHeightForConfiguredSizingCell:(UITableViewCell *)sizingCell {
    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
}

- (void)configurePostTextCell:(MTPostCommentTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    cell.postText.attributedText = self.postText;
}

- (CGFloat)heightForPostCommentsCellAtIndexPath:(NSIndexPath *)indexPath {
    static MTPostCommentItemsTableViewCell *sizingCell = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sizingCell = [self.tableView dequeueReusableCellWithIdentifier:@"PostCommentItemsCell"];
    });
    
    [self configurePostCommentsCell:sizingCell atIndexPath:indexPath];
    return [self calculateHeightForCommentsConfiguredSizingCell:sizingCell];
}

- (CGFloat)calculateHeightForCommentsConfiguredSizingCell:(UITableViewCell *)sizingCell {
    sizingCell.bounds = CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.tableView.bounds), 0.0f);

    [sizingCell setNeedsLayout];
    [sizingCell layoutIfNeeded];
    
    CGSize size = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
}

- (void)configurePostCommentsCell:(MTPostCommentItemsTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    PFChallengePostComment *comment = self.comments[indexPath.row];
    cell.commentLabel.text = comment[@"comment_text"];
    [cell.commentLabel setFont:[UIFont mtLightFontOfSize:13.0f]];
    
    PFUser *commentPoster = comment[@"user"];
    NSString *detailString = [NSString stringWithFormat:@"%@ %@", commentPoster[@"first_name"], commentPoster[@"last_name"]];
    cell.userLabel.text = detailString;
    [cell.userLabel setFont:[UIFont mtLightFontOfSize:11.0f]];
}


#pragma mark - Actions -
- (IBAction)likeButtonTapped:(id)sender
{
    __block MTPostLikeCommentTableViewCell *likeCommentCell = (MTPostLikeCommentTableViewCell *)[sender findSuperViewWithClass:[MTPostLikeCommentTableViewCell class]];
    
    self.likeActionCount++;
    
    __block NSString *postID = [self.challengePost objectId];
    NSString *userID = [self.currentUser objectId];
    
    self.iLike = !self.iLike;
    
    NSInteger oldPostLikesCount = self.postLikesCount;
    NSMutableArray *oldLikePosts = [NSMutableArray arrayWithArray:self.postsLiked];
    NSMutableArray *likePosts = [NSMutableArray arrayWithArray:self.postsLiked];
    
    if (self.iLike) {
        [likePosts addObject:postID];
        
        [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
        [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateDisabled];
        self.postLikesCount += 1;
        
        // Animations are borked on < iOS 8.0 because of autolayout?
        // http://stackoverflow.com/questions/25286022/animation-of-cgaffinetransform-in-ios8-looks-different-than-in-ios7?rq=1
        if(NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
            // no animation
        } else {
            [UIView animateWithDuration:0.2f animations:^{
                likeCommentCell.likePost.transform = CGAffineTransformMakeScale(1.5, 1.5);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2f animations:^{
                    likeCommentCell.likePost.transform = CGAffineTransformMakeScale(1, 1);
                } completion:NULL];
            }];
        }

    }
    else {
        [likePosts removeObject:postID];
        [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
        [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateDisabled];
        if (self.postLikesCount > 0) {
            self.postLikesCount -= 1;
        }
    }
    
    self.postsLiked = likePosts;
    [PFUser currentUser][@"posts_liked"] = self.postsLiked;
    self.challengePost[@"likes"] = [NSNumber numberWithInteger:self.postLikesCount];
    likeCommentCell.postLikes.text = [NSString stringWithFormat:@"%ld", (long)self.postLikesCount];
    
    NSString *likeString = [NSString stringWithFormat:@"%d", self.iLike];
    
    MTMakeWeakSelf();
    [PFCloud callFunctionInBackground:@"toggleLikePost" withParameters:@{@"user_id": userID, @"post_id" : postID, @"like" : likeString} block:^(id object, NSError *error) {
        
        weakSelf.likeActionCount--;
        if (weakSelf.likeActionCount > 0) {
            return;
        }

        if (!error) {
            [weakSelf.currentUser refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {}];
            [weakSelf.challengePost refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf.tableView reloadData];
                });
            }];
        } else {
            NSLog(@"Error updating: %@", [error localizedDescription]);
            
            // Rollback
            weakSelf.iLike = !weakSelf.iLike;
            weakSelf.postsLiked = oldLikePosts;
            weakSelf.postLikesCount = oldPostLikesCount;
            [PFUser currentUser][@"posts_liked"] = oldLikePosts;
            weakSelf.challengePost[@"likes"] = [NSNumber numberWithInteger:oldPostLikesCount];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                likeCommentCell.postLikes.text = [NSString stringWithFormat:@"%ld", (long)oldPostLikesCount];
                [weakSelf.tableView reloadData];
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            });
        }
    }];
}

- (IBAction)commentTapped:(id)sender
{
    [self performSegueWithIdentifier:@"commentOnPost" sender:sender];
}

- (void)dismissCommentView
{
    [self loadComments];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)deletePostTapped:(id)sender
{
    if ([UIAlertController class]) {
        UIAlertController *deletePostSheet = [UIAlertController
                                              alertControllerWithTitle:@"Delete this post?"
                                              message:nil
                                              preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *cancel = [UIAlertAction
                                 actionWithTitle:@"Cancel"
                                 style:UIAlertActionStyleCancel
                                 handler:^(UIAlertAction *action) {
                                 }];
        
        MTMakeWeakSelf();
        UIAlertAction *delete = [UIAlertAction
                                 actionWithTitle:@"Delete"
                                 style:UIAlertActionStyleDestructive
                                 handler:^(UIAlertAction *action) {
                                     [weakSelf performDeletePost];
                                 }];
        
        [deletePostSheet addAction:cancel];
        [deletePostSheet addAction:delete];
        
        [self presentViewController:deletePostSheet animated:YES completion:nil];
    } else {
        
        MTMakeWeakSelf();
        UIActionSheet *deleteAction = [UIActionSheet bk_actionSheetWithTitle:@"Delete this post?"];
        [deleteAction bk_setDestructiveButtonWithTitle:@"Delete" handler:^{
            [weakSelf performDeletePost];
        }];
        [deleteAction bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
        [deleteAction showInView:[UIApplication sharedApplication].keyWindow];
    }
}

- (void)performDeletePost
{
    if ([self.delegate respondsToSelector:@selector(didDeletePost:)]) {
        [self.delegate didDeletePost:self.challengePost];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else {
        NSString *userID = [self.postUser objectId];
        NSString *postID = [self.challengePost objectId];
        
        [PFCloud callFunctionInBackground:@"deletePost" withParameters:@{@"user_id": userID, @"post_id": postID} block:^(id object, NSError *error) {
            if (!error) {
                [self.navigationController popViewControllerAnimated:NO];
            } else {
                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Delete" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
        }];
    }
}

- (IBAction)verifiedTapped:(id)sender
{
    __block MTPostLikeCommentTableViewCell *likeCommentCell = (MTPostLikeCommentTableViewCell *)[sender findSuperViewWithClass:[MTPostLikeCommentTableViewCell class]];

    NSString *postID = [self.challengePost objectId];
    NSString *verifiedBy = [self.currentUser objectId];
    
    if (likeCommentCell.verifiedCheckBox.isChecked) {
        verifiedBy = @"";
    }
    
    MTMakeWeakSelf();
    [PFCloud callFunctionInBackground:@"updatePostVerification" withParameters:@{@"verified_by" : verifiedBy, @"post_id" : postID} block:^(id object, NSError *error) {
        if (error) {
            NSLog(@"error - %@", error);
            [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];

        } else {
            [weakSelf.currentUser refresh];
            [weakSelf.challenge refresh];
            [weakSelf.challengePost refresh];
            
            [weakSelf.tableView reloadData];
        }
    }];
    
    likeCommentCell.verifiedCheckBox.isChecked = !likeCommentCell.verifiedCheckBox.isChecked;
}

- (IBAction)button1Tapped:(id)sender
{
    __block id weakSender = sender;
    ((UIButton *)sender).enabled = NO;
    
    PFChallengePost *post = self.challengePost;
    
    NSString *userID = [self.currentUser objectId];
    NSString *postID = [post objectId];
    
    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:0]};
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Submitting...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
            if (!error) {
                [weakSelf.currentUser refresh];
                [weakSelf.challenge refresh];
                [weakSelf.challengePost refresh];
                ((UIButton *)weakSender).enabled = YES;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf updateButtonsTapped];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
                
                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
        }];
    } afterDelay:0.35f];
    
}

- (IBAction)button2Tapped:(id)sender
{
    __block id weakSender = sender;
    ((UIButton *)sender).enabled = NO;

    PFChallengePost *post = self.challengePost;
    
    NSString *userID = [self.currentUser objectId];
    NSString *postID = [post objectId];
    
    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:1]};
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Submitting...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
            if (!error) {
                [weakSelf.currentUser refresh];
                [weakSelf.challenge refresh];
                [weakSelf.challengePost refresh];
                ((UIButton *)weakSender).enabled = YES;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf updateButtonsTapped];
                });
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });

                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
        }];
    } afterDelay:0.35f];
}

- (UIImage*)imageByScalingAndCroppingForSize:(CGSize)targetSize withImage:(UIImage *)image
{
    UIImage *newImage = nil;
    CGSize imageSize = image.size;
    CGFloat width = imageSize.width;
    CGFloat height = imageSize.height;
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor) {
            scaleFactor = widthFactor; // scale to fit height
        }
        else {
            scaleFactor = heightFactor; // scale to fit width
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        }
        else {
            if (widthFactor < heightFactor) {
                thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
            }
        }
    }
    
    UIGraphicsBeginImageContext(targetSize); // this will crop
    
    CGRect thumbnailRect = CGRectZero;
    thumbnailRect.origin = thumbnailPoint;
    thumbnailRect.size.width  = scaledWidth;
    thumbnailRect.size.height = scaledHeight;
    
    [image drawInRect:thumbnailRect];
    
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    if(newImage == nil) {
        NSLog(@"could not scale image");
    }
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    return newImage;
}


#pragma mark - Navigation -
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueIdentifier = [segue identifier];
    if ([segueIdentifier isEqualToString:@"commentOnPost"]) {
        MTCommentViewController *destinationViewController = (MTCommentViewController *)[segue destinationViewController];
        destinationViewController.post = self.challengePost;
        destinationViewController.challenge = self.challenge;
        [destinationViewController setDelegate:self];
    }
    else if ([segueIdentifier isEqualToString:@"pushStudentProfileFromPost"]) {
        MTMentorStudentProfileViewController *destinationVC = (MTMentorStudentProfileViewController *)[segue destinationViewController];
        destinationVC.student = self.challengePost[@"user"];
    }
}


#pragma mark - UITableViewDataSource & Delegate Methods -
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = 0.0f;
    NSInteger section = indexPath.section;
    
    switch (self.postType) {
        case MTPostTypeWithButtonsWithImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    height = 57.0f;
                    break;
                case MTPostTableCellTypeImage:
                    height = 320.0f;
                    break;
                case MTPostTableCellTypeCommentText:
                    height = [self heightForPostTextCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeButtons:
                    height = 44.0f;
                    break;
                case MTPostTableCellTypeLikeComment:
                    height = 46.0f;
                    break;
                case MTPostTableCellTypePostComments:
                    height = [self heightForPostCommentsCellAtIndexPath:indexPath];
                    break;
                    
                default:
                    break;
            }
            break;
        }
            
        case MTPostTypeWithButtonsNoImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    height = 57.0f;
                    break;
                case MTPostTableCellTypeImage:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeCommentText:
                    height = [self heightForPostTextCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeButtons:
                    height = 44.0f;
                    break;
                case MTPostTableCellTypeLikeComment:
                    height = 46.0f;
                    break;
                case MTPostTableCellTypePostComments:
                    height = [self heightForPostCommentsCellAtIndexPath:indexPath];
                    break;
                    
                default:
                    break;
            }
            break;
        }
        case MTPostTypeNoButtonsWithImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    height = 57.0f;
                    break;
                case MTPostTableCellTypeImage:
                    height = 320.0f;
                    break;
                case MTPostTableCellTypeCommentText:
                    height = [self heightForPostTextCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeButtons:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeLikeComment:
                    height = 46.0f;
                    break;
                case MTPostTableCellTypePostComments:
                    height = [self heightForPostCommentsCellAtIndexPath:indexPath];
                    break;
                    
                default:
                    break;
            }
            break;
        }
        case MTPostTypeNoButtonsNoImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    height = 57.0f;
                    break;
                case MTPostTableCellTypeImage:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeCommentText:
                    height = [self heightForPostTextCellAtIndexPath:indexPath];
                    break;
                case MTPostTableCellTypeButtons:
                    height = 0.0f;
                    break;
                case MTPostTableCellTypeLikeComment:
                    height = 46.0f;
                    break;
                case MTPostTableCellTypePostComments:
                    height = [self heightForPostCommentsCellAtIndexPath:indexPath];
                    break;
                    
                default:
                    break;
            }
            break;
        }
            
        default:
            break;
    }
    
    return height;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = 0;

    switch (self.postType) {
        case MTPostTypeWithButtonsWithImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    rows = 1;
                    break;
                case MTPostTableCellTypeImage:
                    rows = 1;
                    break;
                case MTPostTableCellTypeCommentText:
                    rows = 1;
                    break;
                case MTPostTableCellTypeButtons:
                    rows = 1;
                    break;
                case MTPostTableCellTypeLikeComment:
                    rows = 1;
                    break;
                case MTPostTableCellTypePostComments:
                    rows = self.comments.count;
                    break;
   
                default:
                    break;
            }
            break;
        }
         
        case MTPostTypeWithButtonsNoImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    rows = 1;
                    break;
                case MTPostTableCellTypeImage:
                    rows = 0;
                    break;
                case MTPostTableCellTypeCommentText:
                    rows = 1;
                    break;
                case MTPostTableCellTypeButtons:
                    rows = 1;
                    break;
                case MTPostTableCellTypeLikeComment:
                    rows = 1;
                    break;
                case MTPostTableCellTypePostComments:
                    rows = self.comments.count;
                    break;
                    
                default:
                    break;
            }
            break;
        }
        case MTPostTypeNoButtonsWithImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    rows = 1;
                    break;
                case MTPostTableCellTypeImage:
                    rows = 1;
                    break;
                case MTPostTableCellTypeCommentText:
                    rows = 1;
                    break;
                case MTPostTableCellTypeButtons:
                    rows = 0;
                    break;
                case MTPostTableCellTypeLikeComment:
                    rows = 1;
                    break;
                case MTPostTableCellTypePostComments:
                    rows = self.comments.count;
                    break;
                    
                default:
                    break;
            }
            break;
        }
        case MTPostTypeNoButtonsNoImage:
        {
            switch (section) {
                case MTPostTableCellTypeUserInfo:
                    rows = 1;
                    break;
                case MTPostTableCellTypeImage:
                    rows = 0;
                    break;
                case MTPostTableCellTypeCommentText:
                    rows = 1;
                    break;
                case MTPostTableCellTypeButtons:
                    rows = 0;
                    break;
                case MTPostTableCellTypeLikeComment:
                    rows = 1;
                    break;
                case MTPostTableCellTypePostComments:
                    rows = self.comments.count;
                    break;
                    
                default:
                    break;
            }
            break;
        }

        default:
            break;
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id cell = nil;
    
    switch (indexPath.section) {
        case MTPostTableCellTypeUserInfo:
        {
            __block MTPostUserInfoTableViewCell *userInfoCell = [tableView dequeueReusableCellWithIdentifier:@"PostUserInfoCell" forIndexPath:indexPath];
            
            NSString *firstName = self.postUser[@"first_name"];
            NSString *lastName = self.postUser[@"last_name"];
            userInfoCell.postUsername.text = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            
            userInfoCell.whenPosted.text = [[self.challengePost createdAt] niceRelativeTimeFromNow];

            if (self.userAvatarImage) {
                [userInfoCell.postUserButton setImage:self.userAvatarImage forState:UIControlStateNormal];
            }
            else {
                userInfoCell.postImage.file = self.postUser[@"profile_picture"];
                
                MTMakeWeakSelf();
                [userInfoCell.postImage loadInBackground:^(UIImage *image, NSError *error) {
                    weakSelf.userAvatarImage = image;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        CGRect frame = userInfoCell.postUserButton.frame;
                        
                        if (weakSelf.userAvatarImage.size.width > frame.size.width) {
                            CGFloat scale = frame.size.width / weakSelf.userAvatarImage.size.width;
                            CGFloat heightNew = scale * weakSelf.userAvatarImage.size.height;
                            CGSize sizeNew = CGSizeMake(frame.size.width, heightNew);
                            UIGraphicsBeginImageContext(sizeNew);
                            [weakSelf.userAvatarImage drawInRect:CGRectMake(0.0f, 0.0f, sizeNew.width, sizeNew.height)];
                            weakSelf.userAvatarImage = UIGraphicsGetImageFromCurrentImageContext();
                            UIGraphicsEndImageContext();
                        }
                        
                        if (weakSelf.userAvatarImage) {
                            [userInfoCell.postUserButton setImage:weakSelf.userAvatarImage forState:UIControlStateNormal];
                        }
                    });
                    
                }];
            }
            
            if ([[self.postUser username] isEqualToString:[self.currentUser username]]) {
                userInfoCell.deletePost.hidden = NO;
                userInfoCell.deletePost.enabled = YES;
            }
            else {
                userInfoCell.deletePost.hidden = YES;
                userInfoCell.deletePost.enabled = NO;
            }
            
            cell = userInfoCell;
            
            break;
        }
        case MTPostTableCellTypeImage:
        {
            __block MTPostImageTableViewCell *imageCell = [tableView dequeueReusableCellWithIdentifier:@"PostImageCell" forIndexPath:indexPath];
            
            imageCell.postImage.file = self.challengePost[@"picture"];
            
            MTMakeWeakSelf();
            [imageCell.postImage loadInBackground:^(UIImage *image, NSError *error) {
                if (!error) {
                    if (image) {
                        CGRect frame = imageCell.postImage.frame;
                        imageCell.postImage.image = [weakSelf imageByScalingAndCroppingForSize:frame.size withImage:image];
                    }
                    else {
                        imageCell.postImage.image = nil;
                    }
                }
                else {
                    NSLog(@"error - %@", error);
                }
            }];

            cell = imageCell;

            break;
        }
        case MTPostTableCellTypeCommentText:
        {
            MTPostCommentTableViewCell *commentTextCell = [tableView dequeueReusableCellWithIdentifier:@"CommentTextCell" forIndexPath:indexPath];
            commentTextCell.postText.attributedText = self.postText;
            cell = commentTextCell;
            
            break;
        }
        case MTPostTableCellTypeButtons:
        {
            UITableViewCell *buttonsCell = [tableView dequeueReusableCellWithIdentifier:@"ButtonsCell" forIndexPath:indexPath];
            [self setupButtonsForCell:buttonsCell];
            cell = buttonsCell;

            break;
        }
        case MTPostTableCellTypeLikeComment:
        {
            MTPostLikeCommentTableViewCell *likeCommentCell = [tableView dequeueReusableCellWithIdentifier:@"LikeCommentCell" forIndexPath:indexPath];
            
            NSString *likesString;
        
            if (self.postLikesCount > 0) {
                likesString = [NSString stringWithFormat:@"%ld", (long)self.postLikesCount];
            }
            else {
                likesString = @"0";
            }
        
            likeCommentCell.postLikes.text = likesString;
        
            if (self.iLike) {
                [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
                [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateDisabled];
            }
            else {
                [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
                [likeCommentCell.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateDisabled];
            }
            
            if (self.comments) {
                likeCommentCell.commentCount.text = [NSString stringWithFormat:@"%ld", (unsigned long)[self.comments count]];
            }
            else {
                likeCommentCell.commentCount.text = @"0";
            }
            
            likeCommentCell.verfiedLabel.hidden = self.hideVerifySwitch;
            likeCommentCell.verifiedCheckBox.hidden = self.hideVerifySwitch;
            likeCommentCell.verifiedCheckBox.isChecked = self.challengePost[@"verified_by"] != nil;

            [likeCommentCell.commentPost setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
            [likeCommentCell.commentPost setTitleColor:[UIColor primaryOrangeDark] forState:UIControlStateHighlighted];

            cell = likeCommentCell;
            
            break;
        }
        case MTPostTableCellTypePostComments:
        {
            MTPostCommentItemsTableViewCell *defaultCell = [tableView dequeueReusableCellWithIdentifier:@"PostCommentItemsCell" forIndexPath:indexPath];
            defaultCell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            PFChallengePostComment *comment = self.comments[indexPath.row];
            defaultCell.commentLabel.text = comment[@"comment_text"];
            [defaultCell.commentLabel setFont:[UIFont mtLightFontOfSize:13.0f]];
            defaultCell.commentLabel.textColor = [UIColor darkGrey];
            
            PFUser *commentPoster = comment[@"user"];
            
            NSString *detailString = [NSString stringWithFormat:@"%@ %@", commentPoster[@"first_name"], commentPoster[@"last_name"]];
            defaultCell.userLabel.text = detailString;
            [defaultCell.userLabel setFont:[UIFont mtLightFontOfSize:11.0f]];
            defaultCell.userLabel.textColor = [UIColor darkGrey];
            
            [defaultCell setAccessoryType:UITableViewCellAccessoryNone];
            
            cell = defaultCell;

            break;
        }
            
        default:
            break;
    }

    ((UITableViewCell *)cell).selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (IBAction)unwindToPostView:(UIStoryboardSegue *)sender
{
}


@end
