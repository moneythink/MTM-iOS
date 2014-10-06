//
//  MTPostViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTPostViewController.h"
#import "MTMentorStudentProfileViewController.h"

@interface MTPostViewController ()

@property (strong, nonatomic) PFUser *currentUser;
@property (strong, nonatomic) PFUser *postUser;

@property (strong, nonatomic) IBOutlet UILabel *postUsername;
@property (strong, nonatomic) IBOutlet PFImageView *postUserImage;
@property (strong, nonatomic) IBOutlet UIButton *postUserButton;
@property (strong, nonatomic) IBOutlet UILabel *whenPosted;

@property (strong, nonatomic) IBOutlet PFImageView *postImage;
@property (strong, nonatomic) IBOutlet UILabel *postText;

@property (strong, nonatomic) IBOutlet UIButton *commentPost;
@property (strong, nonatomic) IBOutlet UIButton *comment;
@property (strong, nonatomic) IBOutlet UILabel *commentCount;
@property (assign, nonatomic) NSInteger commentsCount;

@property (strong, nonatomic) IBOutlet UIButton *likePost;
@property (strong, nonatomic) NSArray *postsLiked;
@property (assign, nonatomic) NSInteger postLikesCount;
@property (strong, nonatomic) IBOutlet UILabel *postLikes;
@property (assign, nonatomic) BOOL iLike;
@property (assign, nonatomic) BOOL isMyClass;

@property (strong, nonatomic) IBOutlet UIButton *button1;
@property (strong, nonatomic) IBOutlet UIButton *button2;

@property (strong, nonatomic) IBOutlet MICheckBox *verifiedCheckBox;
@property (strong, nonatomic) IBOutlet UILabel *verfiedLabel;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollFields;

@property (strong, nonatomic) IBOutlet UIButton *deletePost;

@property (strong, nonatomic) IBOutlet UITableView *commentsTableView;
@property (strong, nonatomic) NSArray *comments;

@property (strong, nonatomic) NSDictionary *buttonsTapped;
@property (nonatomic) NSInteger likeActionCount;

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
    // Do any additional setup after loading the view.
    
    [self.commentPost setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
    
    self.postsLiked = [PFUser currentUser][@"posts_liked"];
    NSString *postID = [self.challengePost objectId];
    self.iLike = [self.postsLiked containsObject:postID];
}

- (void)viewWillAppear:(BOOL)animated
{
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
    
    [findPoster findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.postUser = [objects firstObject];
            NSString *firstName = self.postUser[@"first_name"];
            NSString *lastName = self.postUser[@"last_name"];
            self.postUsername.text = [NSString stringWithFormat:@"%@ %@", firstName, lastName];
            self.postUserImage.file = self.postUser[@"profile_picture"];
            
            [self.postUserImage loadInBackground:^(UIImage *image, NSError *error) {
                CGRect frame = self.postUserButton.frame;
                
                if (image.size.width > frame.size.width) {
                    CGFloat scale = frame.size.width / image.size.width;
                    CGFloat heightNew = scale * image.size.height;
                    CGSize sizeNew = CGSizeMake(frame.size.width, heightNew);
                    UIGraphicsBeginImageContext(sizeNew);
                    [image drawInRect:CGRectMake(0.0f, 0.0f, sizeNew.width, sizeNew.height)];
                    image = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                }
                
                [self.postUserButton setImage:image forState:UIControlStateNormal];
            }];
        }
    }];
    
    PFQuery *queryPostComments = [PFQuery queryWithClassName:[PFChallengePostComment parseClassName]];
    [queryPostComments whereKey:@"challenge_post" equalTo:self.challengePost];
    [queryPostComments includeKey:@"user"];
    
    queryPostComments.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [queryPostComments findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.commentsCount = objects.count;
            if (self.commentsCount > 0) {
                self.comments = objects;
                self.commentCount.text = [NSString stringWithFormat:@"%ld", (long)self.commentsCount];
                [self.commentsTableView reloadData];
                [self.view setNeedsLayout];
            } else {
                self.commentCount.text = @"0";
            }
        } else {
            NSLog(@"error - %@", error);
        }
    }];

}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGRect frame = self.scrollFields.frame;
    
    CGFloat w = frame.size.width;
    CGFloat h = frame.size.height;

    CGSize size = CGSizeMake(w, h);

    self.scrollFields.contentSize = size;

    CGRect commentsFrame = self.commentsTableView.frame;
    NSInteger commentCount = self.comments.count;
    if (commentCount > 2) {
        commentsFrame.size.height = self.comments.count * [self.commentsTableView rowHeight];
    }
    self.commentsTableView.frame = commentsFrame;

    frame = self.view.frame;
    frame.origin.y  = 0.0f;
    self.scrollFields.frame = frame;
}

- (void)viewWillLayoutSubviews {
    [self loadChallengePost];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Class Methods

- (void)userButtonsTapped:(BOOL)loadObjects
{
    PFQuery *buttonsTapped = [PFQuery queryWithClassName:[PFChallengePostButtonsClicked parseClassName]];
    [buttonsTapped whereKey:@"user" equalTo:[PFUser currentUser]];
    //    buttonsTapped.cachePolicy = kPFCachePolicyCacheElseNetwork;
    //    __block BOOL cacheCheck = YES;
    [buttonsTapped findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        //        cacheCheck = !cacheCheck;
        if (!error) {
            NSMutableDictionary *tappedButtonObjects = [NSMutableDictionary dictionary];
            for (PFChallengePostButtonsClicked *clicks in objects) {
                id button = clicks[@"button_clicked"];
                id post = [(PFChallengePost *)clicks[@"post"] objectId];
                [tappedButtonObjects setValue:button forKey:post];
            }
            self.buttonsTapped = tappedButtonObjects;
            //            if (loadObjects) {
            [self.view setNeedsLayout];
            //            }
        } else {
            NSLog(@"Error - %@", error);
        }
    }];
}

- (void)loadChallengePost
{
    // >>>>> Attributed hashtag
    self.postText.text = self.challengePost[@"post_text"];
    
    NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange rangeAll = NSMakeRange(0, self.postText.text.length);
    
    [hashtags enumerateMatchesInString:self.postText.text options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        
        NSMutableAttributedString *hashtag = [[NSMutableAttributedString alloc]initWithString:self.postText.text];
        [hashtag addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
        
        self.postText.attributedText = hashtag;
    }];
    // Attributed hashtag
    
    self.postImage.file = self.challengePost[@"picture"];
    
    [self.postImage loadInBackground:^(UIImage *image, NSError *error) {
        if (!error) {
            if (image) {
                CGRect frame = self.postImage.frame;
                self.postImage.image = [self imageByScalingAndCroppingForSize:frame.size withImage:image];
            } else {
                self.postImage.image = nil;
            }
        } else {
            NSLog(@"error - %@", error);
        }
    }];
    
    self.whenPosted.text = [self dateDiffFromDate:[self.challengePost createdAt]];

    NSInteger button = [[self.buttonsTapped valueForKey:[self.challengePost objectId]] intValue];
    if ((button == 0) && (self.buttonsTapped.count > 0)) {
        [[self.button1 layer] setBackgroundColor:[UIColor primaryGreen].CGColor];
        [self.button1 setTintColor:[UIColor white]];
        
        [[self.button2 layer] setBorderWidth:2.0f];
        [[self.button2 layer] setBorderColor:[UIColor redOrange].CGColor];
        [self.button2 setTintColor:[UIColor redOrange]];
        [[self.button2 layer] setBackgroundColor:[UIColor white].CGColor];
    } else if (button == 1) {
        [[self.button1 layer] setBorderWidth:2.0f];
        [[self.button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
        [self.button1 setTintColor:[UIColor primaryGreen]];
        [[self.button1 layer] setBackgroundColor:[UIColor white].CGColor];
        
        [[self.button2 layer] setBackgroundColor:[UIColor redOrange].CGColor];
        [self.button2 setTintColor:[UIColor white]];
    } else {
        [[self.button1 layer] setBorderWidth:2.0f];
        [[self.button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
        [self.button1 setTintColor:[UIColor primaryGreen]];
        [[self.button1 layer] setBackgroundColor:[UIColor white].CGColor];
        
        [[self.button2 layer] setBorderWidth:2.0f];
        [[self.button2 layer] setBorderColor:[UIColor redOrange].CGColor];
        [self.button2 setTintColor:[UIColor redOrange]];
        [[self.button2 layer] setBackgroundColor:[UIColor white].CGColor];
    }
    
    [[self.button1 layer] setCornerRadius:5.0f];
    [[self.button2 layer] setCornerRadius:5.0f];
    
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
        
        [self.button1 setTitle:button1Title forState:UIControlStateNormal];
        [self.button2 setTitle:button2Title forState:UIControlStateNormal];
    }
    
    BOOL isMentor = [self.currentUser[@"type"] isEqualToString:@"mentor"];
    BOOL autoVerify = [self.challenge[@"auto_verify"] boolValue];
    BOOL hideVerifySwitch = !isMentor || autoVerify;
    self.verfiedLabel.hidden = hideVerifySwitch;
    self.verifiedCheckBox.hidden = hideVerifySwitch;
    
    self.verifiedCheckBox.isChecked = self.challengePost[@"verified_by"] != nil;
    
    NSString *likesString;
    
    if (self.postLikesCount > 0) {
        likesString = [NSString stringWithFormat:@"%ld", (long)self.postLikesCount];
    } else {
        likesString = @"0";
    }
    
    self.postLikes.text = likesString;
    
    if (self.iLike) {
        [self.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
        [self.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateDisabled];
    }
    else {
        [self.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
        [self.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateDisabled];
    }
    
    if ([[self.postUser username] isEqualToString:[self.currentUser username]]) {
        self.deletePost.hidden = NO;
        self.deletePost.enabled = YES;
    } else {
        self.deletePost.hidden = YES;
        self.deletePost.enabled = NO;
    }
}


#pragma mark - IBActions
- (IBAction)likeButtonTapped:(id)sender {
    self.likeActionCount++;
    
    __block NSString *postID = [self.challengePost objectId];
    NSString *userID = [self.currentUser objectId];
    
    self.iLike = !self.iLike;
    
    NSInteger oldPostLikesCount = self.postLikesCount;
    NSMutableArray *oldLikePosts = [NSMutableArray arrayWithArray:self.postsLiked];
    NSMutableArray *likePosts = [NSMutableArray arrayWithArray:self.postsLiked];
    
    if (self.iLike) {
        [likePosts addObject:postID];
        
        [self.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
        [self.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateDisabled];
        self.postLikesCount += 1;
        
        [UIView animateWithDuration:0.2f animations:^{
            self.likePost.transform = CGAffineTransformMakeScale(1.5, 1.5);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.2f animations:^{
                self.likePost.transform = CGAffineTransformMakeScale(1, 1);
            } completion:NULL];
        }];
    }
    else {
        [likePosts removeObject:postID];
        [self.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
        [self.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateDisabled];
        if (self.postLikesCount > 0) {
            self.postLikesCount -= 1;
        }
    }
    
    self.postsLiked = likePosts;
    [PFUser currentUser][@"posts_liked"] = self.postsLiked;
    self.challengePost[@"likes"] = [NSNumber numberWithInteger:self.postLikesCount];
    self.postLikes.text = [NSString stringWithFormat:@"%ld", (long)self.postLikesCount];
    
    [self.view setNeedsLayout];
    
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
                    [weakSelf.view setNeedsLayout];
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
                weakSelf.postLikes.text = [NSString stringWithFormat:@"%ld", (long)oldPostLikesCount];
                [weakSelf.view setNeedsLayout];
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            });
        }
    }];
}

- (IBAction)commentTapped:(id)sender {
    [self performSegueWithIdentifier:@"commentOnPost" sender:sender];
}

- (void)dismissCommentView {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)dismissPostViewWithCompletion:(void (^)(void))completion {
    
}

- (IBAction)deletePostTapped:(id)sender {
    // call function deletePost
    NSString *userID = [self.postUser objectId];
    NSString *postID = [self.challengePost objectId];
    
    [PFCloud callFunctionInBackground:@"deletePost" withParameters:@{@"user_id": userID, @"post_id": postID} block:^(id object, NSError *error) {
        if (!error) {
            [self.navigationController popViewControllerAnimated:NO];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (IBAction)verifiedTapped:(id)sender {
    NSString *postID = [self.challengePost objectId];
    NSString *verifiedBy = [self.currentUser objectId];
    
    if (self.verifiedCheckBox.isChecked) {
        verifiedBy = @"";
    }
    
    [PFCloud callFunctionInBackground:@"updatePostVerification" withParameters:@{@"verified_by" : verifiedBy, @"post_id" : postID} block:^(id object, NSError *error) {
        if (error) {
            NSLog(@"error - %@", error);
        } else {
            [self.currentUser refresh];
            [self.challenge refresh];
            [self.challengePost refresh];
            
            [self.view setNeedsLayout];
        }
    }];
    
    self.verifiedCheckBox.isChecked = !self.verifiedCheckBox.isChecked;
}

- (IBAction)button1Tapped:(id)sender {

    self.button1.enabled = NO;
    
    PFChallengePost *post = self.challengePost;
    
    NSString *userID = [self.currentUser objectId];
    NSString *postID = [post objectId];
    
    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:0]};
    [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
        if (!error) {
            [self.currentUser refresh];
            [self.challenge refresh];
            [self.challengePost refresh];
            
            self.button1.enabled = YES;
            
            [self.view setNeedsLayout];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (IBAction)button2Tapped:(id)sender {
    
    self.button2.enabled = NO;

    PFChallengePost *post = self.challengePost;
    
    NSString *userID = [self.currentUser objectId];
    NSString *postID = [post objectId];
    
    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:1]};
    [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
        if (!error) {
            [self.currentUser refresh];
            [self.challenge refresh];
            [self.challengePost refresh];
            
            self.button2.enabled = YES;
            
            [self.view setNeedsLayout];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}


#pragma mark - date diff methods

- (NSString *)dateDiffFromDate:(NSDate *)origDate {
    NSDate *todayDate = [NSDate date];
    
    double interval     = [origDate timeIntervalSinceDate:todayDate];
    
    interval = interval * -1;
    if(interval < 1) {
    	return @"";
    } else 	if (interval < 60) {
    	return @"less than a minute ago";
    } else if (interval < 3600) {
    	int diff = round(interval / 60);
    	return [NSString stringWithFormat:@"%d minutes ago", diff];
    } else if (interval < 86400) {
    	int diff = round(interval / 60 / 60);
    	return[NSString stringWithFormat:@"%d hours ago", diff];
    } else if (interval < 604800) {
    	int diff = round(interval / 60 / 60 / 24);
    	return[NSString stringWithFormat:@"%d days ago", diff];
    } else {
    	int diff = round(interval / 60 / 60 / 24 / 7);
    	return[NSString stringWithFormat:@"%d wks ago", diff];
    }
}

- (NSString *)dateDiffFromString:(NSString *)origDate {
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setFormatterBehavior:NSDateFormatterBehavior10_4];
    [df setDateFormat:@"EEE, dd MMM yy HH:mm:ss VVVV"];
    
    NSDate *convertedDate = [df dateFromString:origDate];
    
    return [self dateDiffFromDate:convertedDate];
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
    
    if (CGSizeEqualToSize(imageSize, targetSize) == NO)
        {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor > heightFactor)
            {
            scaleFactor = widthFactor; // scale to fit height
            }
        else
            {
            scaleFactor = heightFactor; // scale to fit width
            }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor)
            {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
            }
        else
            {
            if (widthFactor < heightFactor)
                {
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueIdentifier = [segue identifier];
    if ([segueIdentifier isEqualToString:@"commentOnPost"]) {
        MTCommentViewController *destinationViewController = (MTCommentViewController *)[segue destinationViewController];
        destinationViewController.post = self.challengePost;
        destinationViewController.challenge = self.challenge;
        [destinationViewController setDelegate:self];
    } else if ([segueIdentifier isEqualToString:@"pushStudentProfileFromPost"]) {
        MTMentorStudentProfileViewController *destinationVC = (MTMentorStudentProfileViewController *)[segue destinationViewController];
        destinationVC.student = self.challengePost[@"user"];
    }
}


#pragma mark - UITableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = self.comments.count;
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.commentsTableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    PFChallengePostComment *comment = self.comments[indexPath.row];
    cell.textLabel.text = comment[@"comment_text"];
    [cell.textLabel setFont:[UIFont systemFontOfSize:13.0f]];
    cell.textLabel.textColor = [UIColor darkGrey];
    
    PFUser *commentPoster = comment[@"user"];
    
    NSString *detailString = [NSString stringWithFormat:@"%@ %@", commentPoster[@"first_name"], commentPoster[@"last_name"]];
    cell.detailTextLabel.text = detailString;
    [cell.detailTextLabel setFont:[UIFont systemFontOfSize:11.0f]];
    cell.detailTextLabel.textColor = [UIColor darkGrey];
    
    [cell setAccessoryType:UITableViewCellAccessoryNone];
    return cell;
}


- (IBAction)unwindToPostView:(UIStoryboardSegue *)sender
{
}

@end
