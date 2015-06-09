//
//  MTExplorePostCollectionView.m
//  moneythink-ios
//
//  Created by jdburgie on 8/7/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTExplorePostCollectionView.h"
#import "MTExploreCollectionViewCell.h"
#import "MTPostViewController.h"

@interface MTExplorePostCollectionView ()

@property (strong, nonatomic) NSArray *posts;

@property (strong, nonatomic) IBOutlet UICollectionView *exploreCollectionView;
@property (nonatomic) BOOL hasButtons;
@property (nonatomic) BOOL hasSecondaryButtons;

@property (nonatomic, strong) UIImage *postImage;

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadPosts];
}

- (void)objectsWillLoad
{
    
}

- (void)objectsDidLoad:(NSError *)error
{
    
}

#pragma mark - Private Methods -
- (void)loadPosts
{
    NSInteger challengeNumber = [self.challenge[@"challenge_number"] intValue];
    NSPredicate *challengeNumberPredicate = [NSPredicate predicateWithFormat:@"challenge_number = %d AND picture != nil", challengeNumber];
    PFQuery *query = [PFQuery queryWithClassName:[PFChallengePost parseClassName] predicate:challengeNumberPredicate];
    
    [query orderByDescending:@"createdAt"];
    [query includeKey:@"user"];
    [query includeKey:@"reference_post"];
    
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    MTMakeWeakSelf();
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            weakSelf.posts = objects;
            
            NSArray *buttons = weakSelf.challenge[@"buttons"];
            NSArray *secondaryButtons = weakSelf.challenge[@"secondary_buttons"];
            BOOL isMentor = [[PFUser currentUser][@"type"] isEqualToString:@"mentor"];
            
            if (!IsEmpty(buttons)) {
                weakSelf.hasButtons = YES;
            }
            else if (!IsEmpty(secondaryButtons) && !isMentor) {
                weakSelf.hasSecondaryButtons = YES;
            }
            else {
                weakSelf.hasButtons = NO;
            }
            
            [weakSelf.exploreCollectionView reloadData];
        } else {
            NSLog(@"Error getting Explore challenges: %@", [error localizedDescription]);
        }
    }];
}


#pragma mark - Public -
- (void)setChallenge:(PFChallenges *)challenge
{
    if (_challenge != challenge) {
        _challenge = challenge;
        
        [self loadPosts];
    }
}


# pragma mark - UICollectionViewDataSource Methods -
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
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
        
        cell.postImage.image = [UIImage imageNamed:@"photo_post"];
        cell.postImage.file = post[@"picture"];
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
        
        cell.postUserImage.image = [UIImage imageNamed:@"profile_image"];
        cell.postUserImage.file = user[@"profile_picture"];
        cell.postUserImage.layer.cornerRadius = round(cell.postUserImage.frame.size.width / 2.0f);
        cell.postUserImage.layer.masksToBounds = YES;
        cell.postUserImage.contentMode = UIViewContentModeScaleAspectFill;
        
        [cell.postUserImage loadInBackground:^(UIImage *image, NSError *error) {
            if (!error) {
                if (image) {
                    cell.postUserImage.image = image;
                    [cell setNeedsDisplay];
                }
                else {
                    cell.postUserImage.image = [UIImage imageNamed:@"profile_image"];
                }
            } else {
                NSLog(@"error - %@", error);
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

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    PFChallengePost *rowObject = self.posts[indexPath.row];
    self.postImage = rowObject[@"picture"];
    
    [self performSegueWithIdentifier:@"pushViewPost" sender:rowObject];
}


#pragma mark - Navigation -
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueIdentifier = [segue identifier];
    
    if ([segueIdentifier hasPrefix:@"pushViewPost"]) {
        MTPostViewController *destinationViewController = (MTPostViewController *)[segue destinationViewController];
        destinationViewController.challengePost = (PFChallengePost *)sender;
        destinationViewController.challenge = self.challenge;
        
        PFChallengePost *post = (PFChallengePost*)sender;
        PFUser *user = post[@"user"];
        
        BOOL myPost = NO;
        if ([[user username] isEqualToString:[[PFUser currentUser] username]]) {
            myPost = YES;
        }

        BOOL showButtons = NO;
        if (self.hasButtons || (self.hasSecondaryButtons && myPost)) {
            showButtons = YES;
        }
        
        if (showButtons) {
            destinationViewController.hasButtons = self.hasButtons;
            destinationViewController.hasSecondaryButtons = self.hasSecondaryButtons;
        }
        
        if (showButtons && self.postImage)
            destinationViewController.postType = MTPostTypeWithButtonsWithImage;
        else if (showButtons)
            destinationViewController.postType = MTPostTypeWithButtonsNoImage;
        else if (self.postImage)
            destinationViewController.postType = MTPostTypeNoButtonsWithImage;
        else
            destinationViewController.postType = MTPostTypeNoButtonsNoImage;
        
    }
    else if ([segueIdentifier isEqualToString:@"pushStudentProgressViewController"]) {
        
    }
}


@end
