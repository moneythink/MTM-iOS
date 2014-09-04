//
//  MTExplorePostCollectionView.m
//  moneythink-ios
//
//  Created by jdburgie on 8/7/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTExplorePostCollectionView.h"
#import "MTPostsTabBarViewController.h"
#import "MTExploreCollectionViewCell.h"
#import "MTPostViewController.h"

@interface MTExplorePostCollectionView ()

@property (strong, nonatomic) NSArray *posts;

@property (strong, nonatomic) IBOutlet UICollectionView *exploreCollectionView;
@property (assign, nonatomic) BOOL hasButtons;

@end

@implementation MTExplorePostCollectionView

- (id)initWithCoder:(NSCoder *)aCoder {
    self = [super initWithCoder:aCoder];
    if (self) {
        // The title for this table in the Navigation Controller.
        self.title = @"Explore";
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSInteger challengNumber = [self.challenge[@"challenge_number"] intValue];
    NSPredicate *challengeNumberPredicate = [NSPredicate predicateWithFormat:@"challenge_number = %d", challengNumber];
    
    PFQuery *query = [PFQuery queryWithClassName:[PFChallengePost parseClassName] predicate:challengeNumberPredicate];

    [query orderByDescending:@"createdAt"];
    [query includeKey:@"user"];
    [query includeKey:@"reference_post"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.posts = objects;
            
            NSArray *buttons = self.challenge[@"buttons"];
            self.hasButtons = buttons.count;
            
            [self.exploreCollectionView reloadData];
        } else {
        }
    }];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (PFQuery *)queryForCollection
{
    NSInteger challengNumber = [self.challenge[@"challenge_number"] intValue];
    NSPredicate *challengeNumberPredicate = [NSPredicate predicateWithFormat:@"challenge_number = %d",
                                             challengNumber];
    
    PFQuery *query = [PFQuery queryWithClassName:[PFChallengePost parseClassName] predicate:challengeNumberPredicate];
    
    [query includeKey:@"user"];
    [query includeKey:@"reference_post"];
    
    return query;
}


- (void)objectsWillLoad {
    
}

- (void)objectsDidLoad:(NSError *)error {
    
}

# pragma mark - Collection View data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger itemCount = self.posts.count;
    
    return itemCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MTExploreCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"exploreChallenge" forIndexPath:indexPath];

    if (indexPath.row <= self.posts.count) {
        PFChallengePost *post = self.posts[indexPath.row];
        PFUser *user = post[@"user"];
        
        cell.postText.text = post[@"post_text"];
        cell.postUser.text = [NSString stringWithFormat:@"%@ %@", user[@"first_name"], user[@"last_name"]];
        
        cell.postImage.file = post[@"picture"];
        [cell.postImage loadInBackground];
        [cell.postImage loadInBackground:^(UIImage *image, NSError *error) {
            if (!error) {
                if (image) {
                    CGRect frame = cell.postImage.frame;
                    cell.postImage.image = [self imageByScalingAndCroppingForSize:frame.size withImage:image];
                    [cell setNeedsDisplay];
                } else {
                    cell.postImage.image = [UIImage imageNamed:@"photo_post"];
                }
            }
        }];
        
        cell.postUserImage.file = user[@"profile_picture"];
        
        [cell.postUserImage loadInBackground:^(UIImage *image, NSError *error) {
            if (!error) {
                if (image) {
                    CGRect frame = cell.postUserImage.frame;
                    cell.postUserImage.image = [self imageByScalingAndCroppingForSize:frame.size withImage:image];
                    [self.view setNeedsDisplay];
                } else {
                    cell.postUserImage.image = [UIImage imageNamed:@"profile_image"];
                }
            }
        }];
        
        return cell;
    } else {
        return nil;
    }
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


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    PFChallengePost *rowObject = self.posts[indexPath.row];
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueIdentifier = [segue identifier];
    
    if ([segueIdentifier hasPrefix:@"pushViewPost"]) {
        MTPostViewController *destinationViewController = (MTPostViewController *)[segue destinationViewController];
        destinationViewController.challengePost = (PFChallengePost *)sender;
        destinationViewController.challenge = self.challenge;
    } else if ([segueIdentifier isEqualToString:@"pushStudentProgressViewController"]) {
        
    }
}

@end
