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
@property (nonatomic, strong) IBOutlet UIImageView *challengeBanner;

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
    MTMakeWeakSelf();
    UIImage *bannerImage = [self.challenge loadBannerImageWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.challengeBanner.image = [self imageByScalingAndCroppingForSize:weakSelf.challengeBanner.frame.size withImage:responseData];
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load challenge banner: %@", [error mtErrorDescription]);
    }];
    
    self.challengeBanner.image = [self imageByScalingAndCroppingForSize:weakSelf.challengeBanner.frame.size withImage:bannerImage];
    
    [self.tagline setBackgroundColor:[UIColor primaryOrange]];
    [self.tagline setTextColor:[UIColor white]];
    
    self.tagline.text = self.challenge.studentInstructions;
    
    [self.tagline sizeToFit];
    [self.missionView sizeToFit];
    [self.missionView setNeedsUpdateConstraints];
    [self.missionView setNeedsLayout];
    
    NSString *perString = @"per post";
    
    RLMResults *buttons = [MTChallengeButton objectsWhere:@"isDeleted = NO AND challenge.id = %lu", self.challenge.id];
    if (!IsEmpty(buttons)) {
        perString = @"per tap";
    }
    
    NSString *pointsPerPostString = [NSString stringWithFormat:@"%ld pts %@,", (long)self.challenge.pointsPerPost, perString];
    NSString *theMessage = [NSString stringWithFormat:@"Reward: %@ %ld pts to complete", pointsPerPostString, (long)self.challenge.maxPoints];
    
    if (!IsEmpty(self.challenge.rewardsInfo)) {
        theMessage = [NSString stringWithFormat:@"Reward: %@", self.challenge.rewardsInfo];
    }
    
    NSMutableAttributedString *theAttributedTitle = [[NSMutableAttributedString alloc] initWithString:theMessage];
    [theAttributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:[theMessage rangeOfString:theMessage]];
    [theAttributedTitle addAttribute:NSFontAttributeName value:[UIFont mtFontOfSize:12.0f] range:[theMessage rangeOfString:theMessage]];

    [theAttributedTitle addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:[theMessage rangeOfString:@"Reward:"]];
    [theAttributedTitle addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:12.0f] range:[theMessage rangeOfString:theMessage]];

    self.rewardLabel.attributedText = theAttributedTitle;
    
    if ([MTUtil isCurrentUserMentor]) {
        self.mentorInstructions.text = self.challenge.mentorInstructions;
        [self.mentorInstructions setTextColor:[UIColor primaryOrange]];
    } else {
        self.mentorInstructions.hidden = YES;
        self.mentorLabel.hidden = YES;
    }
    
    NSInteger challengeNumber = self.pageIndex+1;
    self.challengeNumber.text = [NSString stringWithFormat:@"%lu", (long)challengeNumber];
    self.challengeTitle.text = self.challenge.title;
}


#pragma mark - Public Methods -
- (void)setChallenge:(MTChallenge *)challenge
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
