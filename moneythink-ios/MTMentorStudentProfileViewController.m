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
#import "MBProgressHUD.h"

@interface MTMentorStudentProfileViewController ()

@property (strong, nonatomic) IBOutlet UILabel *userPoints;
@property (strong, nonatomic) NSArray *studentPosts;

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
    // Do any additional setup after loading the view.
    
    PFQuery *studentPostsQuery = [PFQuery queryWithClassName:@"ChallengePost"];
    [studentPostsQuery whereKey:@"user" equalTo:self.student];
    [studentPostsQuery includeKey:@"verified_by"];
    [studentPostsQuery orderByDescending:@"createdAt"];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [studentPostsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.studentPosts = objects;
            
            [self.tableView reloadData];
        } else {
            NSLog(@"error - %@", error);
        }
        
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    }];

    NSString *points = [self.student[@"points"] stringValue];
    self.userPoints.text = [points stringByAppendingString:@" pts"];
    
    self.profileImage.file = self.student[@"profile_picture"];
    
    self.profileImage.layer.cornerRadius = round(self.profileImage.frame.size.width / 2.0f);
    self.profileImage.layer.masksToBounds = YES;
    
    [self.profileImage loadInBackground:^(UIImage *image, NSError *error) {
        if (!error) {
            NSLog(@"not error");
            
            CGRect frame = self.profileImage.frame;
            
            if (image.size.width > frame.size.width) {
                CGFloat scale = frame.size.width / image.size.width;
                CGFloat heightNew = scale * image.size.height;
                CGSize sizeNew = CGSizeMake(frame.size.width, heightNew);
                UIGraphicsBeginImageContext(sizeNew);
                [image drawInRect:CGRectMake(0.0f, 0.0f, sizeNew.width, sizeNew.height)];
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                self.profileImage.image = image;
            }
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - methods


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


#pragma mark - UITableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = [self.studentPosts count];
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger row = indexPath.row;
    
    MTStudentProfileTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"studentPosts"];
    if (cell == nil)
        {
        cell = [[MTStudentProfileTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"studentPosts"];
        }
    
    /*
     @property (strong, nonatomic) IBOutlet PFImageView *postProfileImage;
     @property (strong, nonatomic) IBOutlet UILabel *timeSince;
     @property (strong, nonatomic) IBOutlet UILabel *postText;
     @property (strong, nonatomic) IBOutlet UISwitch *verified;
     @property (strong, nonatomic) IBOutlet UIImageView *comment;
     @property (strong, nonatomic) IBOutlet UILabel *commentCount;
     @property (strong, nonatomic) IBOutlet UIImageView *likes;
     @property (strong, nonatomic) IBOutlet UILabel *likeCount;
     */
    
    cell.rowPost = self.studentPosts[row];
    
//    PFFile *postImageFile = rowPost[@"image"];
//    cell.postProfileImage.file = postImageFile;
//    [cell.postProfileImage loadInBackground:^(UIImage *image, NSError *error) {
//        if (!error) {
//            NSLog(@"not error");
//            
//            CGRect frame = cell.postProfileImage.frame;
//            
//            if (image.size.width > frame.size.width) {
//                CGFloat scale = frame.size.width / image.size.width;
//                CGFloat heightNew = scale * image.size.height;
//                CGSize sizeNew = CGSizeMake(frame.size.width, heightNew);
//                UIGraphicsBeginImageContext(sizeNew);
//                [image drawInRect:CGRectMake(0.0f, 0.0f, sizeNew.width, sizeNew.height)];
//                image = UIGraphicsGetImageFromCurrentImageContext();
//                UIGraphicsEndImageContext();
//                
//                self.profileImage.image = image;
//            }
//        } else {
//            NSLog(@"error - %@", error);
//        }
//    }];
    
    NSDate *dateObject = [cell.rowPost createdAt];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
//    [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
//    NSString *dateString = [dateFormatter stringFromDate:dateObject];
//    dateString = [dateObject description];

    if (dateObject) {
        cell.timeSince.text = [self dateDiffFromDate:dateObject];
    }
    
    PFUser *verifier = cell.rowPost[@"verified_by"];
    cell.verified.on = ![[verifier username] isEqualToString:@""];

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

    id likesCount = cell.rowPost[@"likes"];
    if (likesCount > 0) {
        cell.likes.image = [UIImage imageNamed:@"like_active"];
        cell.likeCount.text = [NSString stringWithFormat:@"%@", likesCount];
    } else {
        cell.likes.image = [UIImage imageNamed:@"like_normal"];
        cell.likeCount.text = @"0";
    }
    [cell.likeCount sizeToFit];
    
    PFQuery *findComments = [PFQuery queryWithClassName:[PFChallengePostComment parseClassName]];
    [findComments whereKey:@"challenge_post" equalTo:cell.rowPost];
    [findComments countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            NSLog(@"check point - %d", number);
            cell.commentCount.text = [NSString stringWithFormat:@"%d", number];
        } else {
            cell.commentCount.text = @"0";
        }
    }];

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    return 2;
}


#pragma mark - UITableViewDelegate methods

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//    NSString *title = @"";
//    
//    return title;
//}


// Variable height support

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    NSInteger section = indexPath.section;
//    NSInteger row = indexPath.row;
//    
//    switch (section) {
//        case  0:
//            row = 44.0f;
//            break;
//            
//        default:
//            row = 60.0f;
//            break;
//    }
//    
//    return row;
//}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
//{
//    return 32.0f;
//}

//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
//{
//    return 1.0f;
//}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    PFChallengePost *rowObject = self.studentPosts[indexPath.row];
//    [self performSegueWithIdentifier:@"pushProfileToPost" sender:rowObject];
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
