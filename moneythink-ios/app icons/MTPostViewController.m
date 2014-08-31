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
@property (strong, nonatomic) IBOutlet UITextField *postComment;

@property (strong, nonatomic) IBOutlet UIButton *likePost;
@property (strong, nonatomic) NSArray *postsLiked;
@property (assign, nonatomic) NSInteger postLikesCount;
@property (strong, nonatomic) IBOutlet UILabel *postLikes;
@property (assign, nonatomic) BOOL iLike;
@property (assign, nonatomic) BOOL isMyClass;

@property (strong, nonatomic) IBOutlet UIButton *comment;
@property (strong, nonatomic) IBOutlet UILabel *commentCount;
@property (assign, nonatomic) NSInteger commentsCount;

@property (strong, nonatomic) IBOutlet UIButton *button1;
@property (strong, nonatomic) IBOutlet UIButton *button2;

@property (strong, nonatomic) IBOutlet MICheckBox *verifiedCheckBox;
@property (strong, nonatomic) IBOutlet UILabel *verfiedLabel;

@property (strong, nonatomic) IBOutlet UIScrollView *scrollFields;
@property (assign, nonatomic) NSInteger keyboardHeight;
@property (assign, nonatomic) CGRect oldViewFieldsRect;
@property (assign, nonatomic) CGSize oldViewFieldsContentSize;

@property (strong, nonatomic) IBOutlet UIButton *deletePost;

@property (strong, nonatomic) IBOutlet UITableView *commentsTableView;
@property (strong, nonatomic) NSArray *comments;

@end

@implementation MTPostViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.scrollFields.scrollEnabled = YES;
    self.scrollFields.alwaysBounceVertical = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.scrollFields.delegate = self;
    self.keyboardHeight = 0.0f;
    
    [self.commentPost setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.postComment.delegate = self;

    self.postLikesCount = [self.challengePost[@"likes"] intValue];
    self.postLikes.text = [NSString stringWithFormat:@"%ld", (long)self.postLikesCount];
    
    PFQuery *queryPostComments = [PFQuery queryWithClassName:[PFChallengePostComment parseClassName]];
    [queryPostComments whereKey:@"challenge_post" equalTo:self.challengePost];
    [queryPostComments includeKey:@"user"];
    
    [queryPostComments findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.commentsCount = objects.count;
            if (self.commentsCount > 0) {
                self.comments = objects;
                self.commentCount.text = [NSString stringWithFormat:@"%ld", (long)self.commentsCount];
                [self.commentsTableView reloadData];
            } else {
                self.commentCount.text = @"0";
            }
        } else {
            NSLog(@"error - %@", error);
        }
    }];
    
    self.postUser = self.challengePost[@"user"];
    self.currentUser = [PFUser currentUser];
    
    NSPredicate *posterWithID = [NSPredicate predicateWithFormat:@"objectId = %@", [self.postUser objectId]];
    PFQuery *findPoster = [PFQuery queryWithClassName:[PFUser parseClassName] predicate:posterWithID];
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
    
}

- (void)viewWillAppear:(BOOL)animated
{
    self.title = self.challenge[@"title"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasDismissed:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    CGRect frame = self.view.frame;
    frame = self.scrollFields.frame;
    frame = self.commentsTableView.frame;
    
    CGFloat w = self.scrollFields.frame.size.width;
    CGFloat h = self.commentsTableView.frame.origin.y + self.commentsTableView.frame.size.height + 108.0f;

    CGSize size = CGSizeMake(w, h);

    self.scrollFields.contentSize = size;
}

- (void)viewWillLayoutSubviews {
    [self loadChallengePost];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self dismissKeyboard];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark -

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
    
    [[self.button1 layer] setBorderWidth:2.0f];
    [[self.button1 layer] setCornerRadius:5.0f];
    [[self.button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
    [self.button1 setTintColor:[UIColor primaryGreen]];
    
    [[self.button2 layer] setCornerRadius:5.0f];
    [[self.button2 layer] setBackgroundColor:[UIColor redOrange].CGColor];
    [self.button2 setTintColor:[UIColor white]];
    
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
    
    self.postsLiked = self.currentUser[@"posts_liked"];
    NSString *postID = [self.challengePost objectId];
    NSInteger index = [self.postsLiked indexOfObject:postID];
    self.iLike = !(index == NSNotFound);
        
    if (self.iLike) {
        [self.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
    } else {
        [self.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
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

- (IBAction)commentTapped:(id)sender {
    PFChallengePostComment *postComment = [[PFChallengePostComment alloc] initWithClassName:[PFChallengePostComment parseClassName]];
    postComment[@"comment_text"] = self.postComment.text;
    postComment[@"challenge_post"] = self.challengePost;
    postComment[@"class"] = self.challengePost[@"class"];
    postComment[@"school"] = self.challengePost[@"school"];
    postComment[@"user"] = [PFUser currentUser];
    
    [self.navigationController popViewControllerAnimated:YES];

    [postComment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
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

- (IBAction)likeButtonTapped:(id)sender {
    NSString *postID = [self.challengePost objectId];
    NSString *userID = [self.currentUser objectId];
    
    
    [PFCloud callFunctionInBackground:@"toggleLikePost" withParameters:@{@"user_id": userID, @"post_id" : postID, @"like" : [NSNumber numberWithBool:!self.iLike]} block:^(id object, NSError *error) {
        if (!error) {
            PFChallengePost *post = self.challengePost;
            NSPredicate *predPost = [NSPredicate predicateWithFormat:@"objectId = %@", [post objectId]];
            PFQuery *queryChallengePost = [PFQuery queryWithClassName:[PFChallengePost parseClassName] predicate:predPost];
            [queryChallengePost findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error) {
                    self.iLike = !self.iLike;
                    
                    if (self.iLike) {
                        [self.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
                        self.postLikesCount += 1;
                    } else {
                        [self.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
                        self.postLikesCount -= 1;
                    }
                    self.postLikes.text = [NSString stringWithFormat:@"%ld", (long)self.postLikesCount];
                    
                    [self.currentUser refresh];
                    [self.challenge refresh];
                    [self.challengePost refresh];
                    
                    [self.view setNeedsLayout];
                }
            }];
        }
    }];
}

- (IBAction)button1Tapped:(id)sender {
    PFChallengePost *post = self.challengePost;
    
    NSString *userID = [self.currentUser objectId];
    NSString *postID = [post objectId];
    
    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:0]};
    [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
        if (!error) {
            [self.currentUser refresh];
            [self.challenge refresh];
            [self.challengePost refresh];
            
            [self.view setNeedsLayout];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (IBAction)button2Tapped:(id)sender {
    PFChallengePost *post = self.challengePost;
    
    NSString *userID = [self.currentUser objectId];
    NSString *postID = [post objectId];
    
    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:1]};
    [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
        if (!error) {
            [self.currentUser refresh];
            [self.challenge refresh];
            [self.challengePost refresh];
            
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


#pragma mark - Keyboard methods

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) keyboardWasShown:(NSNotification *)nsNotification {
    CGRect viewFrame = self.view.frame;
    self.oldViewFieldsRect = self.scrollFields.frame;
    self.oldViewFieldsContentSize = self.scrollFields.contentSize;
    
    CGRect fieldsFrame = self.scrollFields.frame;
    
    NSDictionary *userInfo = [nsNotification userInfo];
    CGRect kbRect = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGSize kbSize = kbRect.size;
    NSInteger kbTop = viewFrame.origin.y + viewFrame.size.height - kbSize.height;
    self.keyboardHeight = kbSize.height;
    
    CGFloat x = fieldsFrame.origin.x;
    CGFloat y = fieldsFrame.origin.y;
    CGFloat w = fieldsFrame.size.width;
    CGFloat h = fieldsFrame.size.height - kbTop + 60.0f;
    
    CGRect fieldsContentRect = CGRectMake(x, y, w, kbTop + 320.0f);
    
    self.scrollFields.contentSize = fieldsContentRect.size;
    
    h = self.scrollFields.contentSize.height + self.keyboardHeight;
    self.scrollFields.contentSize = CGSizeMake(w, h);
    
    self.scrollFields.frame = fieldsFrame;
}

- (void)keyboardWasDismissed:(NSNotification *)notification
{
    self.scrollFields.frame = self.oldViewFieldsRect;
    self.scrollFields.contentSize = self.oldViewFieldsContentSize;
}



#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSInteger nextTag = textField.tag + 1;
    // Try to find next responder
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
        // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
    } else {
        // Not found, so remove keyboard.
        [textField resignFirstResponder];
    }
    return NO; // We do not want UITextField to insert line-breaks.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueID = [segue identifier];
    if ([segueID isEqualToString:@"pushStudentProfileFromPost"]) {
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    PFChallengePostComment *comment = self.comments[indexPath.row];
    cell.textLabel.text = comment[@"comment_text"];
    
    PFUser *commentPoster = comment[@"user"];
    cell.detailTextLabel.text = [commentPoster username];
    
    return cell;
}


#pragma mark - UITableViewDelegate methods

    // Accessories (disclosures).

- (UITableViewCellAccessoryType)tableView:(UITableView *)tableView accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath NS_DEPRECATED_IOS(2_0, 3_0)
{
    return UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    
}


- (IBAction)unwindToPostView:(UIStoryboardSegue *)sender
{
}

@end
