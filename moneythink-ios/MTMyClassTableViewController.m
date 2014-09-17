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
#import "MTPostViewController.h"
#import "MTCommentViewController.h"

@interface MTMyClassTableViewController ()

@property (assign, nonatomic) BOOL hasButtons;
@property (strong, nonatomic) NSArray *postsLiked;
@property (strong, nonatomic) NSArray *myObjects;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (assign, nonatomic) BOOL iLike;

@property (assign, nonatomic) BOOL reachable;

@end

@implementation MTMyClassTableViewController

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        
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

}

- (void)viewWillAppear:(BOOL)animated
{
    self.title = @"My Class";
    [self loadObjects];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:NO];
    
    NSInteger challengNumber = [self.challengeNumber intValue];
    NSPredicate *thisChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %d", challengNumber];
    PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:thisChallenge];
    [challengeQuery whereKeyDoesNotExist:@"school"];
    [challengeQuery whereKeyDoesNotExist:@"class"];
    
    [challengeQuery orderByDescending:@"createdAt"];
    challengeQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            PFChallenges *challenge = (PFChallenges *)[objects firstObject];
            self.challenge = challenge;
            
            NSArray *buttons = challenge[@"buttons"];
            self.hasButtons = buttons.count;
            
            //            [self.tableView reloadData];
            [self loadObjects];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - Parse

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    self.myObjects = self.objects;
}

- (void)objectsWillLoad {
    [super objectsWillLoad];
    
    // This method is called before a PFQuery is fired to get more objects
}


// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable {
    
    self.className = [PFUser currentUser][@"class"];
    
    NSPredicate *challengeNumber = [NSPredicate predicateWithFormat:@"challenge_number = %d AND class = %@",
                                    [self.challengeNumber intValue], self.className];
    
    
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName predicate:challengeNumber];
    [query orderByDescending:@"createdAt"];
    
    [query includeKey:@"user"];
    [query includeKey:@"reference_post"];

    query.cachePolicy = kPFCachePolicyCacheThenNetwork;

    return query;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    
    PFChallengePost *post = (PFChallengePost *)object;
    NSInteger objectIndex = [self.objects indexOfObject:object];
    if (objectIndex < self.myObjects.count) {
        post = (PFChallengePost *)self.myObjects[objectIndex];
    }
    
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
    
    
    MTPostsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MTPostsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    if ([[user username] isEqualToString:[[PFUser currentUser] username]]) {
        cell.deletePost.hidden = NO;
        cell.deletePost.tag = indexPath.row;
        [cell.deletePost addTarget:self action:@selector(deletePostTapped:) forControlEvents:UIControlEventTouchUpInside];
    } else {
        cell.deletePost.hidden = YES;
    }
    
    cell.button1.tag = indexPath.row;
    cell.button2.tag = indexPath.row;
    
    [[cell.button1 layer] setBorderWidth:2.0f];
    [[cell.button1 layer] setCornerRadius:5.0f];
    [[cell.button1 layer] setBorderColor:[UIColor primaryGreen].CGColor];
    [cell.button1 setTintColor:[UIColor primaryGreen]];
    [cell.button1 addTarget:self action:@selector(button1Tapped:) forControlEvents:UIControlEventTouchUpInside];
    
    [[cell.button2 layer] setCornerRadius:5.0f];
    [[cell.button2 layer] setBackgroundColor:[UIColor redOrange].CGColor];
    [cell.button2 setTintColor:[UIColor white]];
    [cell.button2 addTarget:self action:@selector(button2Tapped:) forControlEvents:UIControlEventTouchUpInside];
    
    NSArray *buttonTitles = self.challenge[@"buttons"];
    NSArray *buttonsClicked = post [@"buttons_clicked"];
    
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
        
        [cell.button1 setTitle:button1Title forState:UIControlStateNormal];
        [cell.button2 setTitle:button2Title forState:UIControlStateNormal];
    }
    
    cell.userName.text = [NSString stringWithFormat:@"%@ %@", user[@"first_name"], user[@"last_name"]];
    cell.comments.text = @"";
    
    cell.profileImage.image = [UIImage imageNamed:@"profile_image"];
    cell.profileImage.file = user[@"profile_picture"];
    
    [cell.profileImage loadInBackground:^(UIImage *image, NSError *error) {
        if (!error) {
            if (image) {
                CGRect frame = cell.contentView.frame;
                image = [self imageByScalingAndCroppingForSize:frame.size withImage:image];
                cell.profileImage.image = image;                [cell setNeedsDisplay];
            } else {
                image = nil;
            }
        } else {
            NSLog(@"error - %@", error);
        }
    }];
    
    
    
    // >>>>> Attributed hashtag
    cell.postText.text = post[@"post_text"];
    NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange rangeAll = NSMakeRange(0, cell.postText.text.length);
    
    [hashtags enumerateMatchesInString:cell.postText.text options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSMutableAttributedString *hashtag = [[NSMutableAttributedString alloc]initWithString:cell.postText.text];
        [hashtag addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
        
        cell.postText.attributedText = hashtag;
    }];
    // Attributed hashtag
    
    
    
    if (postImage) {
        cell.postImage.file = post[@"picture"];
        
        [cell.postImage loadInBackground:^(UIImage *image, NSError *error) {
            if (!error) {
                if (image) {
                    CGRect frame = cell.postImage.frame;
                    cell.postImage.image = [self imageByScalingAndCroppingForSize:frame.size withImage:image];
                    [cell setNeedsDisplay];
                } else {
                    cell.postImage.image = nil;
                }
            } else {
                NSLog(@"error - %@", error);
            }
        }];
    }
    
    NSDate *dateObject = [post createdAt];
    
    if (dateObject) {
        cell.postedWhen.text = [self dateDiffFromDate:dateObject];
        [cell.postedWhen sizeToFit];
    }
    
    NSInteger likes = [post[@"likes"] intValue];
    NSString *likesString;
    if (likes > 0) {
        likesString = [NSString stringWithFormat:@"%ld", (long)likes];
    } else {
        likesString = @"0";
    }
    cell.likes.text = likesString;

    self.postsLiked = [PFUser currentUser][@"posts_liked"];
    NSString *postID = [post objectId];
    NSInteger index = [self.postsLiked indexOfObject:postID];
    
    BOOL like_active = (index > 0);
    like_active &= (index != NSNotFound);
    like_active &= (index < self.postsLiked.count);
    like_active |= likes > 0;
    
    if (like_active) {
        [cell.likeButton setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
    } else {
        [cell.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
    }
    
    cell.likeButton.tag = indexPath.row;
    [cell.likeButton addTarget:self action:@selector(likeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    cell.commentBUtton.tag = indexPath.row;

    PFQuery *commentQuery = [PFQuery queryWithClassName:[PFChallengePostComment parseClassName]];
    [commentQuery whereKey:@"challenge_post" equalTo:post];
    commentQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [commentQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            if (number > 0) {
                cell.comments.text = [NSString stringWithFormat:@"%ld", (long)number];
            } else {
                cell.comments.text = @"0";
            }
        } else {
            NSLog(@"error - %@", error);
        }
    }];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    PFChallengePost *rowObject = self.objects[indexPath.row];
    UIImage *postImage = rowObject[@"picture"];
    
    if (self.hasButtons && postImage) {
        [self performSegueWithIdentifier:@"pushViewPostWithButtons" sender:rowObject];
    } else if (self.hasButtons) {
        [self performSegueWithIdentifier:@"pushViewPostWithButtonsNoImage" sender:rowObject];
    } else if (postImage) {
        [self performSegueWithIdentifier:@"pushViewPost" sender:rowObject];
    } else {
        [self performSegueWithIdentifier:@"pushViewPostNoImage" sender:rowObject];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger row = indexPath.row;
    
    CGFloat height = 0.0f;
    
    if (row < self.objects.count) {
        PFChallengePost *rowObject = self.objects[row];
        UIImage *postImage = rowObject[@"picture"];
        
        if (self.hasButtons && postImage) {
            height = 436.0f;
        } else if (self.hasButtons) {
            height = 160.0f;
        } else if (postImage) {
            height = 416.0f;
        } else {
            height = 130.0f;
        }
    } else {

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
    
    if(newImage == nil)
        {
        NSLog(@"could not scale image");
        }
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    return newImage;
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueIdentifier = [segue identifier];
    if ([segueIdentifier isEqualToString:@"commentOnPost"]) {
        UIButton *button = sender;
        NSInteger buttonTag = button.tag;
        
        PFChallengePost *post = self.objects[buttonTag];

        MTCommentViewController *destinationViewController = (MTCommentViewController *)[segue destinationViewController];
        destinationViewController.post = post;
        destinationViewController.challenge = self.challenge;
        [destinationViewController setDelegate:self];
        
//    } else if ([segueIdentifier isEqualToString:@"pushViewPost"]) {
//    } else if ([segueIdentifier isEqualToString:@"pushViewPostWithButtons"]) {
//    } else if ([segueIdentifier isEqualToString:@"pushViewPostNoImage"]) {
//    } else if ([segueIdentifier isEqualToString:@"pushStudentProgressViewController"]) {
    } else {
        MTPostViewController *destinationViewController = (MTPostViewController *)[segue destinationViewController];
        destinationViewController.challengePost = (PFChallengePost *)sender;
        destinationViewController.challenge = self.challenge;
    }
}



#pragma mark - Notification

-(void)reachabilityChanged:(NSNotification*)note
{
    Reachability * reach = [note object];
    
    if([reach isReachable]) {
        self.reachable = YES;
    } else {
        self.reachable = NO;
    }
}


#pragma mark - IBAction methods

- (IBAction)unwindToMyClassTableView:(UIStoryboardSegue *)sender
{
}

- (IBAction)commentTapped:(id)sender {
    [self performSegueWithIdentifier:@"commentOnPost" sender:sender];
}

- (void)dismissCommentView {
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)deletePostTapped:(id)sender {
    
    UIButton *button = sender;
    NSInteger buttonTag = button.tag;
    
    PFUser *user = [PFUser currentUser];
    PFChallengePost *post = self.objects[buttonTag];
    
    NSString *userID = [user objectId];
    NSString *postID = [post objectId];
    
    [PFCloud callFunctionInBackground:@"deletePost" withParameters:@{@"user_id": userID, @"post_id": postID} block:^(id object, NSError *error) {
        if (!error) {
            [self.navigationController popViewControllerAnimated:NO];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (void)likeButtonTapped:(id)sender {
    UIButton *button = sender;
    NSInteger buttonTag = button.tag;
    
    PFUser *user = [PFUser currentUser];
    PFChallengePost *post = self.objects[buttonTag];
    
    NSString *userID = [user objectId];
    NSString *postID = [post objectId];
    
    BOOL like = YES;
    NSInteger index = 0;
    self.postsLiked = [PFUser currentUser][@"posts_liked"];
    if (self.postsLiked.count > 0) {
        index = [self.postsLiked indexOfObject:postID];
        like = (index == NSNotFound);
    } else {
        like = YES;
    }
    
    NSMutableArray *likes = [NSMutableArray arrayWithArray:self.postsLiked];
    NSMutableArray *objects = [NSMutableArray arrayWithArray:self.objects];
    NSInteger likesCount = [post[@"likes"] intValue];
    if (like) {
        likesCount += 1;
        [likes addObject:postID];
    } else {
        likesCount -= 1;
        [likes removeObjectAtIndex:index];
    }
    post[@"likes"] = [NSNumber numberWithInteger:likesCount];
    self.postsLiked = likes;
    [PFUser currentUser][@"posts_liked"] = self.postsLiked;
    objects[buttonTag] = post;
    self.myObjects = objects;
    [self loadObjects];

    NSString *likeString = [NSString stringWithFormat:@"%d", like];
    
    [PFCloud callFunctionInBackground:@"toggleLikePost" withParameters:@{@"user_id": userID, @"post_id" : postID, @"like" : likeString} block:^(id object, NSError *error) {
        if (!error) {
            [user refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                [self loadObjects];
            }];
            [post refreshInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                [self loadObjects];
            }];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (void)button1Tapped:(id)sender {
    UIButton *button = sender;
    NSInteger buttonTag = button.tag;
    
    PFUser *user = [PFUser currentUser];
    PFChallengePost *post = self.objects[buttonTag];
    
    NSString *userID = [user objectId];
    NSString *postID = [post objectId];
    
    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:0]};
    [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
        if (!error) {
            [[PFUser currentUser] refresh];
            [self.challenge refresh];
            [post refresh];
            
            [self loadObjects];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (void)button2Tapped:(id)sender {
    UIButton *button = sender;
    NSInteger buttonTag = button.tag;
    
    PFUser *user = [PFUser currentUser];
    PFChallengePost *post = self.objects[buttonTag];
    
    NSString *userID = [user objectId];
    NSString *postID = [post objectId];
    
    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:1]};
    [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
        if (!error) {
            [[PFUser currentUser] refresh];
            [self.challenge refresh];
            [post refresh];
            
            [self loadObjects];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}


@end
