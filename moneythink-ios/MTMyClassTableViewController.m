//
//  MTMyClassTableViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 8/4/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMyClassTableViewController.h"
#import "MTPostsTabBarViewController.h"
#import "MTPostsTableViewCell.h"
#import "MTCommentViewController.h"

NSString *const kWillSaveNewChallengePostNotification = @"kWillSaveNewChallengePostNotification";
NSString *const kSavingWithPhotoNewChallengePostNotification = @"kSavingWithPhotoNewChallengePostNotification";
NSString *const kSavedMyClassChallengePostsdNotification = @"kSavedMyClassChallengePostsdNotification";
NSString *const kFailedMyClassChallengePostsdNotification = @"kFailedMyClassChallengePostsdNotification";

@interface MTMyClassTableViewController ()

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (assign, nonatomic) BOOL hasButtons;
@property (strong, nonatomic) NSArray *postsLiked;
@property (strong, nonatomic) NSDictionary *buttonsTapped;
@property (assign, nonatomic) BOOL iLike;
@property (nonatomic) NSInteger likeActionCount;
@property (nonatomic, strong) NSMutableArray *myObjects;
@property (nonatomic) BOOL postingNewComment;
@property (nonatomic) BOOL deletingPost;
@property (nonatomic, strong) UIImage *postImage;

@end

@implementation MTMyClassTableViewController

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        self.myObjects = [NSMutableArray array];
        
        // The className to query on
        self.parseClassName = [PFChallengePost parseClassName];
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = @"post_text";
        
        // The title for this table in the Navigation Controller.
        self.title = @"My Class";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(willSaveNewChallengePost:)
                                                 name:kWillSaveNewChallengePostNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(savingWithPhoto:)
                                                 name:kSavingWithPhotoNewChallengePostNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(postSucceeded)
                                                 name:kSavedMyClassChallengePostsdNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(postFailed)
                                                 name:kFailedMyClassChallengePostsdNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.title = @"My Class";
    
    if (!self.postingNewComment && !self.deletingPost) {
        [self loadObjects];
        [self userButtonsTapped];
        
        NSInteger challengNumber = [self.challengeNumber intValue];
        NSPredicate *thisChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %d", challengNumber];
        PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:thisChallenge];
        [challengeQuery includeKey:@"verified_by"];
        [challengeQuery whereKeyDoesNotExist:@"school"];
        [challengeQuery whereKeyDoesNotExist:@"class"];
        
        [challengeQuery orderByDescending:@"createdAt"];
        challengeQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
        
        MTMakeWeakSelf();
        [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                PFChallenges *challenge = (PFChallenges *)[objects firstObject];
                weakSelf.challenge = challenge;
                
                NSArray *buttons = challenge[@"buttons"];
                weakSelf.hasButtons = buttons.count;
                
                [weakSelf loadObjects];
            }
        }];
    }
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - Parse
- (void)objectsDidLoad:(NSError *)error
{
    [super objectsDidLoad:error];
    
    self.myObjects = [NSMutableArray arrayWithArray:self.objects];
    [self.tableView reloadData];
}

- (void)objectsWillLoad
{
    [super objectsWillLoad];
    // This method is called before a PFQuery is fired to get more objects
}

// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable
{
    self.className = [PFUser currentUser][@"class"];
    
    NSPredicate *challengeNumber = [NSPredicate predicateWithFormat:@"challenge_number = %d AND class = %@",
                                    [self.challengeNumber intValue], self.className];
    
    
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName predicate:challengeNumber];
    [query orderByDescending:@"createdAt"];
    
    [query includeKey:@"user"];
    [query includeKey:@"reference_post"];

    query.cachePolicy = kPFCachePolicyNetworkElseCache;

    return query;
}


#pragma mark - Class Methods
- (void)userButtonsTapped
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
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf loadObjects];
            });

        } else {
            NSLog(@"Error - %@", error);
        }
    }];
}


#pragma mark - NSNotification Methods -
- (void)willSaveNewChallengePost:(NSNotification *)notif;
{
    self.postingNewComment = YES;

    PFChallengePost *newPost = notif.object;
    [self.myObjects insertObject:newPost atIndex:0];
    
    [self.tableView reloadData];
}

- (void)savingWithPhoto:(NSNotificationCenter *)notif;
{
    [self.tableView reloadData];
}

- (void)postSucceeded
{
    self.postingNewComment = NO;
    [self loadObjects];
}

- (void)postFailed
{
    self.postingNewComment = NO;
    [self loadObjects];
    
    UIActionSheet *updateMessage = [[UIActionSheet alloc] initWithTitle:@"Your post failed to upload." delegate:nil cancelButtonTitle:@"OK" destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    if ([window.subviews containsObject:self.view]) {
        [updateMessage showInView:self.view];
    } else {
        [updateMessage showInView:window];
    }
}


#pragma mark - UITableViewDataSource methods -
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.myObjects count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Override to use self.myObjects in below method.  Otherwise, crashes because
    //  the PFQueryTableViewController gets called and can't find the object when
    //  adding a new item.
    return [self tableView:tableView cellForRowAtIndexPath:indexPath object:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object
{
    __block PFChallengePost *post = (PFChallengePost *)[self.myObjects objectAtIndex:indexPath.row];

    PFUser *user = post[@"user"];
    NSString *CellIdentifier = @"";
    UIImage *postImage = post[@"picture"];
    
    if (self.hasButtons && postImage) {
        CellIdentifier = @"postCellWithButtons";
    } else if (self.hasButtons) {
        CellIdentifier = @"postCellNoImageWithButtons";
    } else if (postImage) {
        CellIdentifier = @"postCell";
    } else {
        CellIdentifier = @"postCellNoImage";
    }
    
    MTPostsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    cell.post = post;
    
    BOOL canDelete = NO;
    if ([[user username] isEqualToString:[[PFUser currentUser] username]]) {
        canDelete = YES;
        [cell.deletePost removeTarget:self action:@selector(deletePostTapped:) forControlEvents:UIControlEventTouchUpInside];
        [cell.deletePost addTarget:self action:@selector(deletePostTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    id buttonID = [self.buttonsTapped valueForKey:[post objectId]];
    NSInteger button;
    if (buttonID) {
        button = [buttonID intValue];
    }
    if ((button == 0) && [self.buttonsTapped valueForKey:[post objectId]]) {
        [[cell.button1 layer] setBackgroundColor:[UIColor primaryGreen].CGColor];
        [cell.button1 setTintColor:[UIColor white]];
        
        [[cell.button2 layer] setBorderWidth:2.0f];
        [[cell.button2 layer] setBorderColor:[UIColor redOrange].CGColor];
        [cell.button2 setTintColor:[UIColor redOrange]];
        [[cell.button2 layer] setBackgroundColor:[UIColor white].CGColor];
    }
    else if (button == 1) {
        [[cell.button1 layer] setBorderWidth:2.0f];
        [[cell.button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
        [cell.button1 setTintColor:[UIColor primaryGreen]];
        [[cell.button1 layer] setBackgroundColor:[UIColor white].CGColor];
        
        [[cell.button2 layer] setBackgroundColor:[UIColor redOrange].CGColor];
        [cell.button2 setTintColor:[UIColor white]];
    }
    else {
        [[cell.button1 layer] setBorderWidth:2.0f];
        [[cell.button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
        [cell.button1 setTintColor:[UIColor primaryGreen]];
        [[cell.button1 layer] setBackgroundColor:[UIColor white].CGColor];
        
        [[cell.button2 layer] setBorderWidth:2.0f];
        [[cell.button2 layer] setBorderColor:[UIColor redOrange].CGColor];
        [cell.button2 setTintColor:[UIColor redOrange]];
        [[cell.button2 layer] setBackgroundColor:[UIColor white].CGColor];
    }
    
    [[cell.button1 layer] setCornerRadius:5.0f];
    [[cell.button2 layer] setCornerRadius:5.0f];
    
    [cell.button1 removeTarget:self action:@selector(button1Tapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button1 addTarget:self action:@selector(button1Tapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [cell.button2 removeTarget:self action:@selector(button2Tapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.button2 addTarget:self action:@selector(button2Tapped:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray *buttonTitles = self.challenge[@"buttons"];
    NSArray *buttonsClicked = post [@"buttons_clicked"];
    
    if (buttonTitles.count > 0) {
        NSString *button1Title;
        NSString *button2Title;
        
        if (buttonsClicked.count > 0) {
            button1Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[0], buttonsClicked[0]];
        }
        else {
            button1Title = [NSString stringWithFormat:@"%@ (0)", buttonTitles[0]];
        }
        
        if (buttonsClicked.count > 1) {
            button2Title = [NSString stringWithFormat:@"%@ (%@)", buttonTitles[1], buttonsClicked[1]];
        }
        else {
            button2Title = [NSString stringWithFormat:@"%@ (0)", buttonTitles[1]];
        }
        
        [cell.button1 setTitle:button1Title forState:UIControlStateNormal];
        [cell.button2 setTitle:button2Title forState:UIControlStateNormal];
    }
    
    cell.userName.text = [NSString stringWithFormat:@"%@ %@", user[@"first_name"], user[@"last_name"]];
    
    cell.profileImage.image = [UIImage imageNamed:@"profile_image"];
    cell.profileImage.file = user[@"profile_picture"];
    
    [cell.profileImage loadInBackground:^(UIImage *image, NSError *error) {
        if (!error) {
            if (image) {
                CGRect frame = cell.contentView.frame;
                image = [self imageByScalingAndCroppingForSize:frame.size withImage:image];
                cell.profileImage.image = image;
                [cell setNeedsDisplay];
            }
            else {
                image = nil;
            }
        } else {
            NSLog(@"error - %@", error);
        }
    }];
    
    cell.postText.text = post[@"post_text"];
    NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange rangeAll = NSMakeRange(0, cell.postText.text.length);
    
    [hashtags enumerateMatchesInString:cell.postText.text options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSMutableAttributedString *hashtag = [[NSMutableAttributedString alloc]initWithString:cell.postText.text];
        [hashtag addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
        
        cell.postText.attributedText = hashtag;
    }];
    
    if (postImage)
    {
        cell.postImage.image = nil;
        cell.postImage.file = post[@"picture"];
        [cell.postImage loadInBackground:^(UIImage *image, NSError *error) {
            if (!error)
            {
                if (image)
                {
                    CGRect frame = cell.postImage.frame;
                    cell.postImage.image = [self imageByScalingAndCroppingForSize:frame.size withImage:image];
                    [cell setNeedsDisplay];
                }
                else
                    cell.postImage.image = nil;
            }
            else
                NSLog(@"error - %@", error);
        }];
    }
    
    NSDate *dateObject = [post createdAt];
    
    if (dateObject) {
        cell.postedWhen.text = [dateObject niceRelativeTimeFromNow];
    }
    else {
        // New one
        cell.postedWhen.text = [[NSDate dateWithTimeIntervalSinceNow:0.1f] niceRelativeTimeFromNow];
    }
    
    NSInteger likes = 0;
    if (post[@"likes"]) {
        likes = [post[@"likes"] intValue];
    }
    
    // Set Like
    NSString *postID = [post objectId];
    self.postsLiked = [PFUser currentUser][@"posts_liked"];
    BOOL like = [self.postsLiked containsObject:postID];
    
    if (like) {
        [cell.likeButton setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
        [cell.likeButton setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateDisabled];
    }
    else {
        [cell.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
        [cell.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateDisabled];
    }
    
    // Set Likes Text
    NSString *likesString;
    if (likes > 0) {
        likesString = [NSString stringWithFormat:@"%ld", (long)likes];
    }
    else {
        likesString = @"0";
    }
    cell.likes.text = likesString;
    
    [cell.likeButton removeTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    if (dateObject) {
        // Don't retrieve comment count on newly created objects
        PFQuery *commentQuery = [PFQuery queryWithClassName:[PFChallengePostComment parseClassName]];
        [commentQuery whereKey:@"challenge_post" equalTo:post];
        commentQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
        
        __block MTPostsTableViewCell *weakCell = cell;
        [commentQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
            if (!error) {
                if (number > 0) {
                    weakCell.comments.text = [NSString stringWithFormat:@"%ld", (long)number];
                } else {
                    weakCell.comments.text = @"0";
                }
            } else {
                NSLog(@"error - %@", error);
            }
        }];
        
        cell.activityIndicator.hidden = YES;
        cell.deletePost.hidden = !canDelete;
        cell.loadingView.alpha = 0.0f;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    else {
        cell.comments.text = @"0";
        cell.activityIndicator.hidden = NO;
        [cell.activityIndicator startAnimating];
        cell.deletePost.hidden = YES;
        cell.loadingView.alpha = 0.3f;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate Methods -
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    if (cell.loadingView.alpha != 0.0f) {
        return;
    }
    
    PFChallengePost *rowObject = self.myObjects[indexPath.row];
    self.postImage = rowObject[@"picture"];
    
    [self performSegueWithIdentifier:@"pushViewPost" sender:rowObject];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    CGFloat height = 0.0f;
    
    if (row < [self.myObjects count]) {
        PFChallengePost *rowObject = self.myObjects[row];
        UIImage *postImage = rowObject[@"picture"];
        
        if (self.hasButtons && postImage) {
            height = 456.0f;
        } else if (self.hasButtons) {
            height = 180.0f;
        } else if (postImage) {
            height = 436.0f;
        } else {
            height = 150.0f;
        }
    }
    
    return height;
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


#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueIdentifier = [segue identifier];
    if ([segueIdentifier isEqualToString:@"commentOnPost"]) {
        UIButton *button = sender;
        
        MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[button findSuperViewWithClass:[MTPostsTableViewCell class]];
        PFChallengePost *post = cell.post;

        MTCommentViewController *destinationViewController = (MTCommentViewController *)[segue destinationViewController];
        destinationViewController.post = post;
        destinationViewController.challenge = self.challenge;
        [destinationViewController setDelegate:self];
        
    }
    else {
        MTPostViewController *destinationViewController = (MTPostViewController *)[segue destinationViewController];
        destinationViewController.challengePost = (PFChallengePost *)sender;
        destinationViewController.challenge = self.challenge;
        destinationViewController.delegate = self;
        
        if (self.hasButtons && self.postImage) {
            destinationViewController.postType = MTPostTypeWithButtonsWithImage;
        }
        else if (self.hasButtons) {
            destinationViewController.postType = MTPostTypeWithButtonsNoImage;
        }
        else if (self.postImage) {
            destinationViewController.postType = MTPostTypeNoButtonsWithImage;
        }
        else {
            destinationViewController.postType = MTPostTypeNoButtonsNoImage;
        }
    }
}


#pragma mark - MTCommentViewProtocol Methods -
- (void)dismissCommentView
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}


#pragma mark - MTPostViewControllerDelegate Methods -
- (void)didDeletePost:(PFChallengePost *)challengePost
{
    self.deletingPost = YES;
    self.tableView.userInteractionEnabled = NO;
    
    // Perform on delay after we get popped to here
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        NSUInteger row = [weakSelf.myObjects indexOfObject:challengePost];
        if (row != NSNotFound) {
            MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[weakSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0]];
            if (cell) {
                UIButton *button = cell.deletePost;
                [weakSelf bk_performBlock:^(id obj) {
                    weakSelf.tableView.userInteractionEnabled = YES;
                } afterDelay:0.3f];
                
                [weakSelf performDeletePostWithSender:button withConfirmation:NO];
            }
            else {
                weakSelf.tableView.userInteractionEnabled = YES;
            }
        }
        else {
            weakSelf.tableView.userInteractionEnabled = YES;
        }
        
        weakSelf.deletingPost = NO;
    } afterDelay:0.35f];
}


#pragma mark - IBAction methods
- (IBAction)unwindToMyClassTableView:(UIStoryboardSegue *)sender
{
}

- (IBAction)commentTapped:(id)sender
{
    if (![MTUtil internetReachable]) {
        [UIAlertView showNoInternetAlert];
        return;
    }

    [self performSegueWithIdentifier:@"commentOnPost" sender:sender];
}

- (void)deletePostTapped:(id)sender
{
    [self performDeletePostWithSender:sender withConfirmation:YES];
}

- (void)performDeletePostWithSender:(id)sender withConfirmation:(BOOL)withConfirmation
{
    UIButton *button = sender;
    PFUser *user = [PFUser currentUser];
    
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[button findSuperViewWithClass:[MTPostsTableViewCell class]];
    __block PFChallengePost *post = cell.post;
    __block NSString *userID = [user objectId];
    __block NSString *postID = [post objectId];
    
    if (withConfirmation) {
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
                                         
                                         NSInteger index = [weakSelf.myObjects indexOfObject:post];
                                         [weakSelf.myObjects removeObject:post];
                                         NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                                         [weakSelf.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];\
                                         
                                         [PFCloud callFunctionInBackground:@"deletePost" withParameters:@{@"user_id": userID, @"post_id": postID} block:^(id object, NSError *error) {
                                             [weakSelf loadObjects];
                                             if (error) {
                                                 [UIAlertView bk_showAlertViewWithTitle:@"Unable to Delete" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                                                 NSLog(@"error - %@", error);
                                             }
                                         }];
                                     }];
            
            [deletePostSheet addAction:cancel];
            [deletePostSheet addAction:delete];
            
            [self presentViewController:deletePostSheet animated:YES completion:nil];
        } else {
            
            MTMakeWeakSelf();
            UIActionSheet *deleteAction = [UIActionSheet bk_actionSheetWithTitle:@"Delete this post?"];
            [deleteAction bk_setDestructiveButtonWithTitle:@"Delete" handler:^{
                
                NSInteger index = [weakSelf.myObjects indexOfObject:post];
                [weakSelf.myObjects removeObject:post];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
                [weakSelf.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];\
                
                [PFCloud callFunctionInBackground:@"deletePost" withParameters:@{@"user_id": userID, @"post_id": postID} block:^(id object, NSError *error) {
                    [weakSelf loadObjects];
                    if (error) {
                        [UIAlertView bk_showAlertViewWithTitle:@"Unable to Delete" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
                        NSLog(@"error - %@", error);
                    }
                }];
                
            }];
            [deleteAction bk_setCancelButtonWithTitle:@"Cancel" handler:nil];
            [deleteAction showInView:[UIApplication sharedApplication].keyWindow];
        }
    }
    else {
        NSInteger index = [self.myObjects indexOfObject:post];
        [self.myObjects removeObject:post];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        MTMakeWeakSelf();
        [PFCloud callFunctionInBackground:@"deletePost" withParameters:@{@"user_id": userID, @"post_id": postID} block:^(id object, NSError *error) {
            [weakSelf loadObjects];
            if (error) {
                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Delete" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
        }];
    }
}

- (void)likeButtonTapped:(id)sender
{
    self.likeActionCount++;
    
    __block UIButton *button = sender;
    
    __block MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[button findSuperViewWithClass:[MTPostsTableViewCell class]];
    PFChallengePost *post = cell.post;

    PFUser *user = [PFUser currentUser];

    NSString *userID = [user objectId];
    NSString *postID = [post objectId];
    
    self.postsLiked = [PFUser currentUser][@"posts_liked"];
    BOOL like = [self.postsLiked containsObject:postID];
    
    NSMutableArray *likes = [NSMutableArray arrayWithArray:self.postsLiked];
    NSInteger likesCount = [post[@"likes"] intValue];
    NSString *likePostString = nil;
    if (!like) {
        likePostString = @"1";
        likesCount += 1;
        [likes addObject:postID];
    } else {
        likePostString = @"0";
        likesCount -= 1;
        [likes removeObject:postID];
    }
    
    post[@"likes"] = [NSNumber numberWithInteger:likesCount];
    self.postsLiked = likes;
    [PFUser currentUser][@"posts_liked"] = self.postsLiked;
    
    // Optimistically update view (can roll back on error below)
    cell.likes.text = [NSString stringWithFormat:@"%ld", (long)likesCount];
    
    if (!like) {
        [cell.likeButton setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
        [cell.likeButton setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateDisabled];
        
        // Animations are borked on < iOS 8.0 because of autolayout?
        // http://stackoverflow.com/questions/25286022/animation-of-cgaffinetransform-in-ios8-looks-different-than-in-ios7?rq=1
        if(NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) {
            // no animation
        } else {
            [UIView animateWithDuration:0.2f animations:^{
                cell.likeButton.transform = CGAffineTransformMakeScale(1.5, 1.5);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.2f animations:^{
                    cell.likeButton.transform = CGAffineTransformMakeScale(1, 1);
                } completion:NULL];
            }];
        }

    }
    else {
        [cell.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
        [cell.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateDisabled];
    }
    
    MTMakeWeakSelf();
    [PFCloud callFunctionInBackground:@"toggleLikePost" withParameters:@{@"user_id": userID, @"post_id" : postID, @"like" : likePostString} block:^(id object, NSError *error) {
        
        weakSelf.likeActionCount--;
        if (weakSelf.likeActionCount > 0) {
            return;
        }
        
        if (!error) {
            [user fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {}];
            [post fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                // Load/update the objects but don't clear the table
                [weakSelf loadObjects];
            }];
        }
        else {
            NSLog(@"error - %@", error);
            [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            
            // Reload to revert optimistic update
            [weakSelf loadObjects];
        }
    }];
}

- (void)button1Tapped:(id)sender
{
    UIButton *button = sender;
    button.enabled = NO;
    
    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[button findSuperViewWithClass:[MTPostsTableViewCell class]];
    PFChallengePost *post = cell.post;

    PFUser *user = [PFUser currentUser];

    NSString *userID = [user objectId];
    NSString *postID = [post objectId];
    
    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:0]};
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Submitting...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
            if (!error) {
                [[PFUser currentUser] fetch];
                [weakSelf.challenge fetch];
                [post fetch];
                [weakSelf userButtonsTapped];
                [weakSelf loadObjects];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
                
                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
            
            button.enabled = YES;
        }];
    } afterDelay:0.35f];
    
}

- (void)button2Tapped:(id)sender
{
    UIButton *button = sender;
    button.enabled = NO;

    MTPostsTableViewCell *cell = (MTPostsTableViewCell *)[button findSuperViewWithClass:[MTPostsTableViewCell class]];
    PFChallengePost *post = cell.post;

    PFUser *user = [PFUser currentUser];

    NSString *userID = [user objectId];
    NSString *postID = [post objectId];
    
    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:1]};
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Submitting...";
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
            if (!error) {
                [[PFUser currentUser] fetch];
                [weakSelf.challenge fetch];
                [post fetch];
                [weakSelf userButtonsTapped];
                [weakSelf loadObjects];
            }
            else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });

                NSLog(@"error - %@", error);
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            }
            
            button.enabled = YES;
        }];
    } afterDelay:0.35f];
}


@end
