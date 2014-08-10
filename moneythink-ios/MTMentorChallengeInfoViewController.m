//
//  MTMentorChallengeInfoViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 8/6/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMentorChallengeInfoViewController.h"

@interface MTMentorChallengeInfoViewController ()
@property (strong, nonatomic) IBOutlet PFImageView *challengeBanner;

@property (strong, nonatomic) IBOutlet UIView *missionView;
@property (strong, nonatomic) IBOutlet UIView *rewardsView;
@property (strong, nonatomic) IBOutlet UIView *instructionsView;

@property (strong, nonatomic) IBOutlet UITextView *tagline;

@property (strong, nonatomic) IBOutlet UILabel *levelLabel;
@property (strong, nonatomic) IBOutlet UILabel *rewardLabel;
@property (strong, nonatomic) IBOutlet UILabel *ptsPerPost;
@property (strong, nonatomic) IBOutlet UILabel *maxPts;
@property (strong, nonatomic) IBOutlet UIImageView *levelImage1;
@property (strong, nonatomic) IBOutlet UIImageView *levelImage2;
@property (strong, nonatomic) IBOutlet UIImageView *levelImage3;

@property (strong, nonatomic) IBOutlet UIImageView *pillarImage;

@property (strong, nonatomic) IBOutlet UILabel *pointsPerPost;
@property (strong, nonatomic) IBOutlet UILabel *maxPoints;

@property (strong, nonatomic) IBOutlet UILabel *mentorLabel;
@property (strong, nonatomic) IBOutlet UITextView *mentorInstructions;

@end

@implementation MTMentorChallengeInfoViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.missionView setBackgroundColor:[UIColor primaryOrange]];
    [self.rewardsView setBackgroundColor:[UIColor mutedOrange]];
    
    MTPostsTabBarViewController *postTabBarViewController = (MTPostsTabBarViewController *)self.parentViewController;
    PFChallenges *challenge = postTabBarViewController.challenge;
    
    NSPredicate *predicateChallengeBanner = [NSPredicate predicateWithFormat:@"challenge_number = %@", challenge[@"challenge_number"]];
    PFQuery *queryChallangeBanners = [PFQuery queryWithClassName:@"ChallengeBanners" predicate:predicateChallengeBanner];
    
    [queryChallangeBanners findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            PFChallengeBanner *banner = [objects firstObject];
            PFFile *bannerFile = banner[@"image_mdpi"];
            self.challengeBanner.file = bannerFile;
            [self.challengeBanner loadInBackground:^(UIImage *image, NSError *error) {
                if (!error) {
                    NSLog(@"no error");
                    self.challengeBanner.image = [self imageByScalingAndCroppingForSize:self.challengeBanner.frame.size withImage:image];
                }
            }];
        }
    }];
    
    [self.tagline setBackgroundColor:[UIColor primaryOrange]];
    [self.tagline setTextColor:[UIColor white]];
    NSLog(@">>>>> tagline - %@", self.tagline);
    self.tagline.text = challenge[@"student_instructions"];
    [self.tagline sizeToFit];
    NSLog(@">>>>> tagline - %@", self.tagline);
    
    [self.levelLabel setTextColor:[UIColor primaryOrange]];
    [self.rewardLabel setTextColor:[UIColor primaryOrange]];
    self.pointsPerPost.text = [NSString stringWithFormat:@"%@ pts x post", challenge[@"points_per_post"]];
    self.maxPoints.text = [NSString stringWithFormat:@"(up to %@ pts)", challenge[@"max_points"]];
    
    NSInteger level = [challenge[@"level"] intValue];
    if (level < 3) {
        self.levelImage1.image = [UIImage imageNamed:@"bg_progress_orange1"];
        self.levelImage2.image = [UIImage imageNamed:@"bg_progress_white2"];
        self.levelImage3.image = [UIImage imageNamed:@"bg_progress_white3"];
    } else if (level < 7) {
        self.levelImage1.image = [UIImage imageNamed:@"bg_progress_orange1"];
        self.levelImage2.image = [UIImage imageNamed:@"bg_progress_white2"];
        self.levelImage3.image = [UIImage imageNamed:@"bg_progress_orange3"];
    } else {
        self.levelImage1.image = [UIImage imageNamed:@"bg_progress_orange1"];
        self.levelImage2.image = [UIImage imageNamed:@"bg_progress_orange2"];
        self.levelImage3.image = [UIImage imageNamed:@"bg_progress_orange3"];
    }
    
    if ([[PFUser currentUser][@"type"] isEqualToString:@"mentor"]) {
        self.mentorInstructions.text = challenge[@"mentor_instructions"];
        [self.mentorInstructions setTextColor:[UIColor primaryOrange]];
    } else {
        self.mentorInstructions.hidden = YES;
        self.mentorLabel.hidden = YES;
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
    
    if(newImage == nil)
        {
        NSLog(@"could not scale image");
        }
    
    //pop the context to get back to the default
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
