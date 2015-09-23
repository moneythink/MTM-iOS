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

@interface MTExplorePostCollectionView () <DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>

@property (nonatomic, strong) RLMResults *posts;

@property (nonatomic, strong) IBOutlet UICollectionView *exploreCollectionView;
@property (nonatomic) BOOL hasButtons;
@property (nonatomic) BOOL hasSecondaryButtons;
@property (nonatomic) BOOL hasTertiaryButtons;

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
    
    // Make sure posts get updated on appearance.
    [self loadPostsFromDatabase];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postSucceeded) name:kSavedMyClassChallengePostNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    [self loadPostsFromDatabase];
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] loadExplorePostsForChallengeId:self.challenge.id success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf loadPostsFromDatabase];
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load explore posts: %@", [error mtErrorDescription]);
    }];
}

- (void)loadPostsFromDatabase
{
    self.posts = [[MTChallengePost objectsWhere:@"challenge.id = %d AND isDeleted = NO AND hasPostImage = YES", self.challenge.id] sortedResultsUsingProperty:@"createdAt" ascending:NO];
    [self.collectionView reloadData];
}

- (void)loadButtons
{
    RLMResults *buttons = [[MTChallengeButton objectsWhere:@"isDeleted = NO AND challenge.id = %lu", self.challenge.id] sortedResultsUsingProperty:@"ranking" ascending:YES];
    
    self.hasButtons = NO;
    self.hasSecondaryButtons = NO;
    self.hasTertiaryButtons = NO;
    
    BOOL isMentor = [MTUser isCurrentUserMentor];

    if (!IsEmpty(buttons)) {
        if ([[((MTChallengeButton *)[buttons firstObject]).buttonTypeCode uppercaseString] isEqualToString:@"VOTE"]) {
            // Voting buttons (primary or tertiary)
            if ([buttons count] == 4) {
                // Tertiary
                self.hasTertiaryButtons = YES;
            }
            else {
                // Primary
                self.hasButtons = YES;
            }
        }
        else if (!isMentor) {
            // Secondary
            self.hasSecondaryButtons = YES;
        }
    }
}


#pragma mark - Public -
- (void)setChallenge:(MTChallenge *)challenge
{
    if (_challenge != challenge) {
        BOOL refresh = (_challenge == nil || (_challenge != nil && (_challenge.id != challenge.id)));
        _challenge = challenge;
        
        if (refresh) {
            [self loadPosts];
            [self loadButtons];
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

    if (indexPath.row <= self.posts.count) {
        MTChallengePost *post = self.posts[indexPath.row];
        MTUser *user = post.user;
        
        cell.postText.text = post.content;
        cell.postUser.text = [NSString stringWithFormat:@"%@ %@", user.firstName, user.lastName];
        
        __block MTExploreCollectionViewCell *weakCell = cell;
        if (post.hasPostImage) {
            cell.postImage.image = [post loadPostImageWithSuccess:^(id responseData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakCell.postImage.image = responseData;
                });
            } failure:^(NSError *error) {
                NSLog(@"Unable to load post image");
            }];
        }
        
        cell.postUserImage.layer.cornerRadius = round(cell.postUserImage.frame.size.width / 2.0f);
        cell.postUserImage.layer.masksToBounds = YES;
        cell.postUserImage.contentMode = UIViewContentModeScaleAspectFill;
        
        cell.postUserImage.image = [user loadAvatarImageWithSuccess:^(id responseData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakCell.postUserImage.image = responseData;
            });
        } failure:^(NSError *error) {
            NSLog(@"Unable to load user avatar");
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
    [self performSegueWithIdentifier:@"pushViewPost" sender:self.posts[indexPath.row]];
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
        MTPostDetailViewController *destinationViewController = (MTPostDetailViewController *)[segue destinationViewController];
        destinationViewController.challengePost = (MTChallengePost *)sender;
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
    NSString *text = @"No Posts With Photos";
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0],
                                 NSForegroundColorAttributeName: [UIColor darkGrayColor]};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Be the first to post (w/photo) to this Challenge!";
    
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
