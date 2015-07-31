//
//  MTMentorChallengeInfoViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 8/6/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTChallengeInfoViewController.h"

@interface MTChallengeInfoViewController ()

@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet PFImageView *challengeBanner;

@property (nonatomic, strong) IBOutlet UIView *rewardsView;
@property (nonatomic, strong) IBOutlet UILabel *rewardLabel;
@property (nonatomic, strong) IBOutlet UIView *missionView;
@property (nonatomic, strong) IBOutlet UITextView *tagline;
@property (nonatomic, strong) IBOutlet UIView *instructionsView;
@property (nonatomic, strong) IBOutlet UILabel *mentorLabel;
@property (nonatomic, strong) IBOutlet UITextView *mentorInstructions;
@property (nonatomic, strong) IBOutlet UILabel *challengeNumber;
@property (nonatomic, strong) IBOutlet UIView *challengeNumberView;
@property (nonatomic, strong) IBOutlet UILabel *challengeTitle;
@property (nonatomic, strong) IBOutlet UIButton *closeButton;

@end

@implementation MTChallengeInfoViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.missionView setBackgroundColor:[UIColor primaryOrange]];
    [self.rewardsView setBackgroundColor:[UIColor mutedOrange]];
    
    self.challengeNumberView.layer.cornerRadius = self.challengeNumberView.frame.size.width/2.0f;
    
    [self updateView];
}

- (void)viewDidLayoutSubviews {
    CGRect scrollViewFrame = self.scrollView.frame;

//    CGSize contentSize = self.scrollView.contentSize;
    CGRect instructionsViewFrame = self.instructionsView.frame;

    if ([self.mentorInstructions isHidden]) {
        instructionsViewFrame = CGRectZero;
    }
    
    CGFloat contentHeight = instructionsViewFrame.origin.y + instructionsViewFrame.size.height + 44.0f;
    CGSize contentSize = CGSizeMake(scrollViewFrame.size.width, contentHeight);
    
    CGFloat x = scrollViewFrame.origin.x;
    CGFloat y = scrollViewFrame.origin.y;
    CGFloat w = scrollViewFrame.size.width;
    CGFloat h = self.view.frame.size.height;
    
    self.scrollView.frame = CGRectMake(x, y, w, h);
    self.scrollView.contentSize = contentSize;
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
        } else {
            scaleFactor = heightFactor; // scale to fit width
        }
        
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
        
        // center the image
        if (widthFactor > heightFactor) {
            thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5;
        } else {
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

#pragma mark - Private Methods -
- (void)updateView
{
    NSPredicate *predicateChallengeBanner = [NSPredicate predicateWithFormat:@"challenge = %@", self.challenge];
    PFQuery *queryChallangeBanners = [PFQuery queryWithClassName:[PFChallengeBanner parseClassName] predicate:predicateChallengeBanner];
    
    queryChallangeBanners.cachePolicy = kPFCachePolicyCacheThenNetwork;
    
    MTMakeWeakSelf();
    [queryChallangeBanners findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            PFChallengeBanner *banner = [objects firstObject];
            PFFile *bannerFile = banner[@"image_mdpi"];
            weakSelf.challengeBanner.file = bannerFile;
            [weakSelf.challengeBanner loadInBackground:^(UIImage *image, NSError *error) {
                if (!error) {
                    weakSelf.challengeBanner.image = [self imageByScalingAndCroppingForSize:weakSelf.challengeBanner.frame.size withImage:image];
                }
            }];
        }
    }];
        
    [self.tagline setBackgroundColor:[UIColor primaryOrange]];
    [self.tagline setTextColor:[UIColor white]];
    
    self.tagline.text = self.challenge[@"student_instructions"];
    
    [self.tagline sizeToFit];
    [self.missionView sizeToFit];
    [self.missionView setNeedsUpdateConstraints];
    [self.missionView setNeedsLayout];
    
    NSString *pointsPerPostString = [NSString stringWithFormat:@"%@ pts x post", self.challenge[@"points_per_post"]];
    NSString *theMessage = [NSString stringWithFormat:@"Reward: %@ (up to %@ pts)", pointsPerPostString, self.challenge[@"max_points"]];
    NSMutableAttributedString *theAttributedTitle = [[NSMutableAttributedString alloc] initWithString:theMessage];
    [theAttributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:[theMessage rangeOfString:theMessage]];
    [theAttributedTitle addAttribute:NSFontAttributeName value:[UIFont mtFontOfSize:12.0f] range:[theMessage rangeOfString:theMessage]];

    [theAttributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:[theMessage rangeOfString:@"Reward:"]];
    [theAttributedTitle addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:12.0f] range:[theMessage rangeOfString:pointsPerPostString]];

    self.rewardLabel.attributedText = theAttributedTitle;
    
    if ([[PFUser currentUser][@"type"] isEqualToString:@"mentor"]) {
        self.mentorInstructions.text = self.challenge[@"mentor_instructions"];
        [self.mentorInstructions setTextColor:[UIColor primaryOrange]];
    } else {
        self.mentorInstructions.hidden = YES;
        self.mentorLabel.hidden = YES;
    }
    
    self.challengeNumber.text = [NSString stringWithFormat:@"%lu", self.pageIndex+1];
    self.challengeTitle.text = self.challenge[@"title"];
}


#pragma mark - Public Methods -
- (void)setChallenge:(PFChallenges *)challenge
{
    if (_challenge != challenge) {
        _challenge = challenge;
        [self updateView];
    }
}


#pragma mark - Actions -
- (IBAction)closeAction
{
    [self dismissViewControllerAnimated:YES completion:^{
        //
    }];
}


@end
