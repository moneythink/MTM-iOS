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

@interface MTMyClassTableViewController ()

@property (assign, nonatomic) BOOL hasButtons;
@property (strong, nonatomic) NSArray *postsLiked;

@property (assign, nonatomic) BOOL reachable;

@end

@implementation MTMyClassTableViewController

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // Custom the table
        
        // The className to query on
        self.parseClassName = @"ChallengePost";
        
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
    
    NSInteger challengNumber = [self.challengeNumber intValue];
    NSPredicate *thisChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %d", challengNumber];
    PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:thisChallenge];
    
    [challengeQuery orderByDescending:@"createdAt"];
    [challengeQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            PFChallenges *challenge = (PFChallenges *)[objects firstObject];
            self.challenge = challenge;

            NSArray *buttons = challenge[@"buttons"];
            self.hasButtons = buttons.count;

            [self.tableView reloadData];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.title = @"My Class";

    [self queryForTable];
    [self.tableView reloadData];
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
    
}

- (void)objectsWillLoad {
    [super objectsWillLoad];
    
    // This method is called before a PFQuery is fired to get more objects
}


// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable {
    MTPostsTabBarViewController *postTabBarViewController = (MTPostsTabBarViewController *)self.parentViewController;
    self.challengeNumber = postTabBarViewController.challengeNumber;
    
    self.className = [PFUser currentUser][@"class"];
    
    NSPredicate *challengeNumber = [NSPredicate predicateWithFormat:@"challenge_number = %d AND class = %@",
                       [self.challengeNumber intValue], self.className];
    
    
    /*
     self.schoolName = [PFUser currentUser][@"school"];
     
     NSPredicate *challengeNumber = [NSPredicate predicateWithFormat:@"challenge_number = %d AND class = %@",
     [self.challengeNumber intValue], self.className];
     
     challengeNumber = [NSPredicate predicateWithFormat:@"challenge_number = %d",
     [self.challengeNumber intValue]];
     
     challengeNumber = [NSPredicate predicateWithFormat:@"challenge_number = %d AND class = %@ AND school = %@",
     [self.challengeNumber intValue], self.className, self.schoolName];
     */
    
    
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName predicate:challengeNumber];
    [query orderByDescending:@"createdAt"];
    
    if ([self.objects count] == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
    
    [query includeKey:@"user"];
    [query includeKey:@"reference_post"];
    
    return query;
}


// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the first key in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    PFChallengePost *post = (PFChallengePost *)object;
    
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

    cell.userName.text = [user username];
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
    if (likes > 0) {
        NSString *likesString = [NSString stringWithFormat:@"%ld", (long)likes];
        cell.likes.text = likesString;
    } else {
        cell.likes.text = @"0";
    }
    
    self.postsLiked = [PFUser currentUser][@"posts_liked"];
    NSString *postID = [post objectId];
    
    NSInteger index = [self.postsLiked indexOfObject:postID];
    
    if (index == NSNotFound) {
        [cell.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
    } else {
        [cell.likeButton setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
    }
    
    PFQuery *commentQuery = [PFQuery queryWithClassName:@"ChallengePostComment"];
    [commentQuery whereKey:@"challenge_post" equalTo:post];
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
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
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
        PFChallengePost *post = self.objects[row];
        UIImage *postImage = post[@"picture"];
        if (!postImage) {
            height = 120.0f;
        } else {
            height = 396.0f;
        }
    } else {
        NSLog(@"out of bounds");
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
    

    MTPostViewController *destinationViewController = (MTPostViewController *)[segue destinationViewController];
    destinationViewController.challengePost = (PFChallengePost *)sender;
    destinationViewController.challenge = self.challenge;

    if ([segueIdentifier isEqualToString:@"pushViewPost"]) {
    } else if ([segueIdentifier isEqualToString:@"pushViewPostWithButtons"]) {
    } else if ([segueIdentifier isEqualToString:@"pushViewPostNoImage"]) {
    } else if ([segueIdentifier isEqualToString:@"pushStudentProgressViewController"]) {
    }
}



#pragma mark Notification

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

- (IBAction)deletePostTapped:(id)sender {
//    // call function deletePost
//    PFUser *user = [PFUser currentUser];
//    NSString *userID = [user objectId];
//    
//    NSString *postID = [self.challengePost objectId];
//    
//    [PFCloud callFunctionInBackground:@"deletePost" withParameters:@{@"user_id": userID, @"post_id": postID} block:^(id object, NSError *error) {
//        if (!error) {
//            [self.navigationController popViewControllerAnimated:YES];
//        } else {
//            NSLog(@"error - %@", error);
//        }
//    }];
}

- (IBAction)verifiedTapped:(id)sender {
//    NSString *postID = [self.challengePost objectId];
//    NSString *verifiedBy = [[PFUser currentUser] objectId];
//    
//    if (self.verifiedCheckBox.isChecked) {
//        verifiedBy = @"";
//    }
//    
//    [PFCloud callFunctionInBackground:@"updatePostVerification" withParameters:@{@"verified_by" : verifiedBy, @"post_id" : postID} block:^(id object, NSError *error) {
//        if (error) {
//            NSLog(@"error - %@", error);
//        } else {
//            [[PFUser currentUser] refresh];
//            [self.challenge refresh];
//            [self.challengePost refresh];
//            
//            [self.view setNeedsLayout];
//        }
//    }];
//    
//    self.verifiedCheckBox.isChecked = !self.verifiedCheckBox.isChecked;
}

- (IBAction)likeButtonTapped:(id)sender {
//    NSString *postID = [self.challengePost objectId];
//    NSString *userID = [[PFUser currentUser] objectId];
//    
//    
//    [PFCloud callFunctionInBackground:@"toggleLikePost" withParameters:@{@"user_id": userID, @"post_id" : postID, @"like" : [NSNumber numberWithBool:!self.iLike]} block:^(id object, NSError *error) {
//        if (!error) {
//            PFChallengePost *post = self.challengePost;
//            NSPredicate *predPost = [NSPredicate predicateWithFormat:@"objectId = %@", [post objectId]];
//            PFQuery *queryChallengePost = [PFQuery queryWithClassName:[PFChallengePost parseClassName] predicate:predPost];
//            [queryChallengePost findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//                if (!error) {
//                    self.iLike = !self.iLike;
//                    
//                    if (self.iLike) {
//                        [self.likePost setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
//                        self.postLikesCount += 1;
//                    } else {
//                        [self.likePost setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
//                        self.postLikesCount -= 1;
//                    }
//                    self.postLikes.text = [NSString stringWithFormat:@"%ld", (long)self.postLikesCount];
//                    
//                    [[PFUser currentUser] refresh];
//                    [self.challenge refresh];
//                    [self.challengePost refresh];
//                    
//                    [self.view setNeedsLayout];
//                }
//            }];
//        } else {
//            NSLog(@"error - %@", error);
//        }
//    }];
}

- (void)button1Tapped:(id)sender {
    UIButton *button = sender;
    NSInteger buttonTag = button.tag;

    NSLog(@"button tag - %ld", (long)buttonTag);
    
    PFUser *user = [PFUser currentUser];
    PFChallengePost *post = self.objects[buttonTag];
    
    NSString *userID = [user objectId];
    NSString *postID = [post objectId];

    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:0]};
    [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
        if (!error) {
            NSLog(@"button1Tapped");
            [[PFUser currentUser] refresh];
            [self.challenge refresh];
            [post refresh];
            
            [self.tableView reloadData];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (void)button2Tapped:(id)sender {
//    PFUser *user = [PFUser currentUser];
//    PFChallengePost *post = self.challengePost;
//    
//    NSString *userID = [user objectId];
//    NSString *postID = [post objectId];
//    
//    NSDictionary *buttonTappedDict = @{@"user": userID, @"post": postID, @"button": [NSNumber numberWithInt:1]};
//    [PFCloud callFunctionInBackground:@"challengePostButtonClicked" withParameters:buttonTappedDict block:^(id object, NSError *error) {
//        if (!error) {
//            NSLog(@"button2Tapped");
//            [[PFUser currentUser] refresh];
//            [self.challenge refresh];
//            [self.challengePost refresh];
//            
//            [self.view setNeedsLayout];
//        } else {
//            NSLog(@"error - %@", error);
//        }
//    }];
}


@end
