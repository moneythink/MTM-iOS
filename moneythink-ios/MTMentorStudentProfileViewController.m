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

@interface MTMentorStudentProfileViewController ()

@property (strong, nonatomic) NSArray *studentPosts;

@property (strong, nonatomic) IBOutlet UILabel *userPoints;
@property (strong, nonatomic) IBOutlet UIImageView *managerProgress;
@property (strong, nonatomic) IBOutlet UIImageView *makerProgress;

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
    
    NSString *points = [self.student[@"points"] stringValue];
    if (!points) {
        points = @"0";
    }
    self.userPoints.text = [points stringByAppendingString:@" pts"];
    
    self.profileImage.file = self.student[@"profile_picture"];
    
    self.profileImage.layer.cornerRadius = round(self.profileImage.frame.size.width / 2.0f);
    self.profileImage.layer.masksToBounds = YES;
    
    [self.profileImage loadInBackground:^(UIImage *image, NSError *error) {
        if (!error) {
            if (image) {
                CGRect frame = self.profileImage.frame;
                self.profileImage.image = [self imageByScalingAndCroppingForSize:frame.size withImage:image];
            } else {
                self.profileImage.image = nil;
            }
        } else {
            NSLog(@"error - %@", error);
        }
    }];
    
    NSInteger managerProgressValue = [self.student[@"money_manager"] intValue];
    NSInteger makerProgressValue = [self.student[@"money_maker"] intValue];
    
    if (makerProgressValue == 100) {
        self.makerProgress.image = [UIImage imageNamed:@"bg_money_maker_2"];
    } else if (makerProgressValue >= 50) {
        self.makerProgress.image = [UIImage imageNamed:@"bg_money_maker_1"];
    } else {
        self.makerProgress.image = nil;
    }

    if (managerProgressValue == 100) {
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_7"];
    } else if (managerProgressValue >= 86) {
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_6"];
    } else if (managerProgressValue >= 72) {
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_5"];
    } else if (managerProgressValue >= 58) {
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_4"];
    } else if (managerProgressValue >= 44) {
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_3"];
    } else if (managerProgressValue >= 30) {
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_2"];
    } else if (managerProgressValue >= 16) {
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_1"];
    } else {
        self.managerProgress.image = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:NO];
    
    PFQuery *studentPostsQuery = [PFQuery queryWithClassName:[PFChallengePost parseClassName]];
    [studentPostsQuery whereKey:@"user" equalTo:self.student];
    [studentPostsQuery includeKey:@"verified_by"];
    [studentPostsQuery orderByDescending:@"createdAt"];
    
    studentPostsQuery.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    [studentPostsQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.studentPosts = objects;
            [self.tableView reloadData];
        } else {
            // error
        }
    }];
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


#pragma mark - UITableViewController delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
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
    
    cell.rowPost = self.studentPosts[row];
    
    NSDate *dateObject = [cell.rowPost createdAt];
    
    if (dateObject) {
        cell.timeSince.text = [dateObject niceRelativeTimeFromNow];
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

    NSInteger likesCount = 0;
    if (cell.rowPost[@"likes"]) {
        likesCount = [cell.rowPost[@"likes"] intValue];
    }
    if (likesCount > 0) {
        cell.likes.image = [UIImage imageNamed:@"like_active"];
        cell.likeCount.text = [NSString stringWithFormat:@"%ld", (long)likesCount];
    } else {
        cell.likes.image = [UIImage imageNamed:@"like_normal"];
        cell.likeCount.text = @"0";
    }
    [cell.likeCount sizeToFit];
    
    if (cell.rowPost[@"verified_by"]) {
        cell.verifiedCheckbox.isChecked = YES;
    } else {
        cell.verifiedCheckbox.isChecked = NO;
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate Methods -
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
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
