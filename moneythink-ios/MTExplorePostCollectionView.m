//
//  MTExplorePostCollectionView.m
//  moneythink-ios
//
//  Created by jdburgie on 8/7/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTExplorePostCollectionView.h"
#import "MTExploreCollectionViewCell.h"
#import "MTPostDetailViewController.h"
#import "MTMyClassTableViewController.h"
#import "DRPLoadingSpinner.h"

#define kExplorePageSize 20
#define kOpenPostSegueIdentifier @"pushViewPost"

@interface MTExplorePostCollectionView () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) RLMResults *posts;

@property (nonatomic, strong) IBOutlet UICollectionView *exploreCollectionView;
@property (nonatomic) BOOL hasButtons;
@property (nonatomic) BOOL hasSecondaryButtons;
@property (nonatomic) BOOL hasTertiaryButtons;
@property (nonatomic, retain) DRPLoadingSpinner *spinner;

@end

@implementation MTExplorePostCollectionView

BOOL isLoadingMore = false;
NSUInteger currentPage = 0;
NSInteger numberOfPages = 0;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.collectionView.emptyDataSetSource = self;
    self.collectionView.emptyDataSetDelegate = self;
    isLoadingMore = false;
    currentPage = 0;
    numberOfPages = 0;
    
    // Spinner
    self.spinner = [[DRPLoadingSpinner alloc] initWithFrame:CGRectMake(0, 0, 28, 28)];
    self.spinner.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2,
                                      [UIScreen mainScreen].bounds.size.height - 38);
    self.spinner.rotationCycleDuration = 2;
    self.spinner.minimumArcLength = M_PI / 4;
    self.spinner.drawCycleDuration = 1;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Make sure posts get updated on appearance.
    [self loadPosts];
    
    [self.collectionView reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postSucceeded) name:kSavedMyClassChallengePostNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.spinner stopAnimating];
    [self.spinner removeFromSuperview];
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
    
    // Don't load until we know how many local posts we have
    if (currentPage == 0) return;
    
    MTMakeWeakSelf();
    if (numberOfPages > 0 && currentPage > numberOfPages) {
        // No more to load
        [self loadPostsFromDatabase];
        return;
    };
    
    isLoadingMore = YES;
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [[MTNetworkManager sharedMTNetworkManager] loadExplorePostsForChallengeId:self.challenge.id page:currentPage success:^(BOOL lastPage, NSUInteger numPages, NSUInteger totalCount) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            if (numPages == 0) {
                numberOfPages = -1; // None at all to find
            } else {
                numberOfPages = numPages;
            }
            NSLog(@"total would be %lu across %lu", (unsigned long)totalCount, numberOfPages);
            if (numPages > 0) {
                currentPage++;
            }
            [weakSelf loadPostsFromDatabase];
            [weakSelf.collectionView reloadData];
            isLoadingMore = NO;
            [self.spinner stopAnimating];
        });
    } failure:^(NSError *error) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        isLoadingMore = NO;
        [self.spinner stopAnimating];
        NSLog(@"Unable to load explore posts: %@", [error mtErrorDescription]);
    }];
}

- (void)loadPostsFromDatabase
{
    if ([MTUser currentUser] == nil) return;
    
    self.posts = [[MTExplorePost objectsWhere:@"challengeId = %d", self.challenge.id] sortedResultsUsingProperty:@"createdAt" ascending:NO];
    
    if (currentPage == 0) {
        if (self.posts.count == 0) {
            currentPage = 1;
        } else {
            currentPage = self.posts.count / kExplorePageSize + 1;
            NSLog(@"Starting page is %lu", (unsigned long)currentPage);
        }
    }
}

#pragma mark - Public -
- (void)setChallenge:(MTChallenge *)challenge
{
    if (_challenge != challenge) {
        BOOL firstLoad = _challenge == nil;
        BOOL refresh = (firstLoad || (_challenge != nil && (_challenge.id != challenge.id)));
        _challenge = challenge;
        
        if (refresh) {
            currentPage = 0; // Reset for new challenge
            self.posts = nil;
            [self loadPostsFromDatabase];
            [self viewWillAppear:YES];
        }
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

    MTExplorePost *post = self.posts[indexPath.row];
    
    cell.postText.text = post.postContent;
    cell.postUser.text = post.userName;
    
    cell.postImage.layer.masksToBounds = YES;
    cell.postImage.image = [UIImage imageNamed:@"placeholder"];
    cell.postImage.contentMode = UIViewContentModeScaleAspectFill;

    cell.postImage.image = [post loadPostImageWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MTExploreCollectionViewCell *cell = (MTExploreCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
            cell.postImage.image = responseData;
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load post image");
    }];
    
    cell.postUserImage.layer.cornerRadius = round(cell.postUserImage.frame.size.width / 2.0f);
    cell.postUserImage.layer.masksToBounds = YES;
    cell.postUserImage.contentMode = UIViewContentModeScaleAspectFill;
    
    cell.postUserImage.image = [post loadUserAvatarWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MTExploreCollectionViewCell *cell = (MTExploreCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
            cell.postUserImage.image = responseData;
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load user avatar");
    }];
    
    return cell;
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
    
    MTExplorePost *explorePost = self.posts[indexPath.row];
    
    // If post is already loaded, open it immediately
    RLMResults *results = [MTChallengePost objectsWhere:@"id = %@", explorePost.postId];
    if ([results count] > 0) {
        [self performSegueWithIdentifier:kOpenPostSegueIdentifier sender:[results firstObject]];
        return;
    }
    
    // Otherwise, briefly show a hud and then load it
    MBProgressHUD *hud = [[MBProgressHUD alloc] init];
    hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Loading...";
    hud.dimBackground = YES;
    
    [[MTNetworkManager sharedMTNetworkManager] loadPostId:[explorePost.postId integerValue] optionalThumbnailImage:explorePost.postPicture success:^(id responseData) {
        [hud hide:YES];
        MTChallengePost *post = [MTChallengePost objectForPrimaryKey:explorePost.postId];
        [self performSegueWithIdentifier:kOpenPostSegueIdentifier sender:post];
    } failure:^(NSError *error) {
        [hud hide:YES];
        [[[UIAlertView alloc] initWithTitle:@"Error" message:@"Error loading post." delegate:nil cancelButtonTitle:@"Continue" otherButtonTitles:nil] show];
    }];
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

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (isLoadingMore) return;
    
    if (indexPath.row == [collectionView numberOfItemsInSection:indexPath.section] - 1) {
        if (self.spinner.superview == nil) {
            [[UIApplication sharedApplication].keyWindow addSubview:self.spinner];
        }
        
        if (self.isVisible) {
            [self.spinner startAnimating];
        }
        [self loadPosts];
    }
}


#pragma mark - Navigation -
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueIdentifier = [segue identifier];
    
    if ([segueIdentifier hasPrefix:@"pushViewPost"]) {
        MTPostDetailViewController *destinationViewController = (MTPostDetailViewController *)[segue destinationViewController];
        destinationViewController.challengePostId = ((MTChallengePost *)sender).id;
        destinationViewController.challenge = self.challenge;
        
        MTChallengePost *post = (MTChallengePost *)sender;
        MTUser *user = post[@"user"];
        
        BOOL myPost = NO;
        if ([MTUser isUserMe:user]) {
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
        
        if (showButtons && post.hasPostImage)
            destinationViewController.postType = MTPostTypeWithButtonsWithImage;
        else if (showButtons)
            destinationViewController.postType = MTPostTypeWithButtonsNoImage;
        else if (post.hasPostImage)
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
    NSString *text;
    if (numberOfPages == -1) {
        text = @"No posts to load.";
    } else {
        text = @"Loading posts...";
    }
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text;
    if (numberOfPages == -1) {
        text = @"This challenge doesn't have any posts at all. Be the first!";
    } else {
        text = @"Explore posts from other Moneythink students everywhere.";;
    }
    
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
    if (IsEmpty(self.posts)) {
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

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return -56.0f;
}


#pragma mark - NSNotification Methods -
- (void)postSucceeded
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        [self loadPostsFromDatabase];
    });
}


@end
