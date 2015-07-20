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

@interface MTExplorePostCollectionView () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (strong, nonatomic) NSArray *posts;

@property (strong, nonatomic) IBOutlet UICollectionView *exploreCollectionView;
@property (nonatomic) BOOL hasButtons;
@property (nonatomic) BOOL hasSecondaryButtons;
@property (nonatomic) BOOL hasTertiaryButtons;

@property (nonatomic, strong) UIImage *postImage;
@property (nonatomic) BOOL pulledData;

@end

@implementation MTExplorePostCollectionView

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.emptyDataSetSource = self;
    self.collectionView.emptyDataSetDelegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.pulledData = NO;
    [self loadPosts];
}

- (void)dealloc
{
    if ([self isViewLoaded]) {
        self.collectionView.emptyDataSetSource = nil;
        self.collectionView.emptyDataSetDelegate = nil;
    }
}


#pragma mark - Private Methods -
- (void)loadPosts
{
    NSPredicate *postsWithPicturePredicate = [NSPredicate predicateWithFormat:@"picture != nil"];
    PFQuery *query = [PFQuery queryWithClassName:[PFChallengePost parseClassName] predicate:postsWithPicturePredicate];
    
    [query orderByDescending:@"createdAt"];
    [query includeKey:@"user"];
    [query whereKey:@"challenge" equalTo:self.challenge];
    [query setLimit:20];
    
    query.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    MTMakeWeakSelf();
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            weakSelf.posts = objects;
            
            NSArray *buttons = weakSelf.challenge[@"buttons"];
            NSArray *secondaryButtons = weakSelf.challenge[@"secondary_buttons"];
            BOOL isMentor = [[PFUser currentUser][@"type"] isEqualToString:@"mentor"];
            
            if (!IsEmpty(buttons) && [buttons firstObject] != [NSNull null]) {
                if ([buttons count] == 4) {
                    weakSelf.hasTertiaryButtons = YES;
                }
                else {
                    weakSelf.hasButtons = YES;
                }
            }
            else if (!IsEmpty(secondaryButtons) && ([secondaryButtons firstObject] != [NSNull null]) && !isMentor) {
                weakSelf.hasSecondaryButtons = YES;
            }
            else {
                weakSelf.hasButtons = NO;
            }
            
            weakSelf.pulledData = YES;
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

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    MTExploreCollectionViewCell *cell = (MTExploreCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithHexString:@"#d1d1d1"];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    MTExploreCollectionViewCell *cell = (MTExploreCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.backgroundColor = [UIColor whiteColor];
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
        if (self.hasButtons || (self.hasSecondaryButtons && myPost) || self.hasTertiaryButtons) {
            showButtons = YES;
        }
        
        if (showButtons) {
            destinationViewController.hasButtons = self.hasButtons;
            destinationViewController.hasSecondaryButtons = self.hasSecondaryButtons;
            destinationViewController.hasTertiaryButtons = self.hasTertiaryButtons;
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


#pragma mark - DZNEmptyDataSetDelegate/Datasource Methods -
- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"No Posts";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Be the first to post to this Challenge!";
    
    NSMutableParagraphStyle *paragraph = [NSMutableParagraphStyle new];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:14.0],
                                 NSForegroundColorAttributeName: [UIColor lightGrayColor],
                                 NSParagraphStyleAttributeName: paragraph};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    if (IsEmpty(self.posts) && self.pulledData) {
        return YES;
    }
    else {
        return NO;
    }
}

- (UIColor *)backgroundColorForEmptyDataSet:(UIScrollView *)scrollView
{
    return [UIColor whiteColor];
}

- (CGPoint)offsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return CGPointMake(0, -56.0f);
}


@end
