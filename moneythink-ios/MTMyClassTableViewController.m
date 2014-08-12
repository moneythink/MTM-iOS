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

@property (strong, nonatomic) IBOutlet UITabBarItem *postsTabBarItem;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (assign, nonatomic) BOOL hasButtons;

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
    
    self.parentViewController.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Good Buy, Bad Buy" style:UIBarButtonItemStylePlain target:nil action:nil];

    NSInteger challengNumber = [self.challengeNumber intValue];
    NSPredicate *thisChallenge = [NSPredicate predicateWithFormat:@"challenge_number = %d", challengNumber];
    PFQuery *challengeQuery = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:thisChallenge];
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

- (void)postCommentSelector {
    
}

- (void)viewWillAppear:(BOOL)animated
{
    self.title = @"My Class";

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
    
    // This method is called every time objects are loaded from Parse via the PFQuery
    
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
    
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName predicate:challengeNumber];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
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
    if (!postImage) {
        CellIdentifier = @"postCellNoImage";
    } else {
        CellIdentifier = @"postCell";
    }

    MTPostsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MTPostsTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.userName.text = [user username];
    
    cell.profileImage.file = user[@"profile_picture"];
    [cell.profileImage loadInBackground];
    [cell.profileImage loadInBackground:^(UIImage *image, NSError *error) {
        CGRect frame = cell.contentView.frame;
        
        if (image.size.width > frame.size.width) {
            CGFloat scale = frame.size.width / image.size.width;
            CGFloat heightNew = scale * image.size.height;
            CGSize sizeNew = CGSizeMake(frame.size.width, heightNew);
            UIGraphicsBeginImageContext(sizeNew);
            [image drawInRect:CGRectMake(0.0f, 0.0f, sizeNew.width, sizeNew.height)];
            image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
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
    }
    
    NSInteger likes = [post[@"likes"] intValue];
    if (likes) {
        NSString *likesString = [NSString stringWithFormat:@"%ld", (long)likes];
        cell.likes.text = likesString;
        if ([likesString isEqualToString:@"0"]) {
            [cell.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
        } else {
            [cell.likeButton setImage:[UIImage imageNamed:@"like_active"] forState:UIControlStateNormal];
        }
    } else {
        cell.likes.text = @"0";
        [cell.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
    }
    
    PFQuery *commentQuery = [PFQuery queryWithClassName:@"ChallengePostComment"];
    [commentQuery whereKey:@"challenge_post" equalTo:post];
    [commentQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (number > 0) {
            cell.comments.text = [NSString stringWithFormat:@"%ld", (long)number];
        } else {
            cell.comments.text = @"0";
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
    PFChallengePost *post = self.objects[indexPath.row];
    CGFloat height;
    UIImage *postImage = post[@"picture"];
    if (!postImage) {
        height = 120.0f;
    } else {
        height = 396.0f;
    }
    
    return height;
}


#pragma mark - date dif methods


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
    
    if(newImage == nil)
        {
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
    

    MTPostViewController *destinationViewController = (MTPostViewController *)[segue destinationViewController];
    destinationViewController.challengePost = (PFChallengePost *)sender;
    destinationViewController.challenge = self.challenge;

    if ([segueIdentifier isEqualToString:@"pushViewPost"]) {
    } else if ([segueIdentifier isEqualToString:@"pushViewPostWithButtons"]) {
    } else if ([segueIdentifier isEqualToString:@"pushViewPostNoImage"]) {
    } else if ([segueIdentifier isEqualToString:@"pushStudentProgressViewController"]) {
    }
}



@end
