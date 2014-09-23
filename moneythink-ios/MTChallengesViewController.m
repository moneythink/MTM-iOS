//
//  MTChallengesViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/19/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTChallengesViewController.h"

@interface MTChallengesViewController ()

@property (assign, nonatomic) NSInteger pendingPageIndex;
@property (assign, nonatomic) NSInteger pageIndex;

@property (strong, nonatomic) MTChallengesContentViewController *viewControllerBefore;
@property (strong, nonatomic) MTChallengesContentViewController *viewControllerAfter;

@end

@implementation MTChallengesViewController

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

    PFQuery *allChallenges = [PFQuery queryWithClassName:[PFChallenges parseClassName]];
    [allChallenges orderByAscending:@"challenge_number"];
    [allChallenges whereKeyDoesNotExist:@"school"];
    [allChallenges whereKeyDoesNotExist:@"class"];

//    allChallenges.cachePolicy = kPFCachePolicyCacheThenNetwork;
//    
    [allChallenges findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.challenges = objects;
            
            // Create page view controller
            self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChallengesViewController"];
            CGRect frame = self.pageViewController.view.frame;
            frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 235.0f);
            self.pageViewController.view.frame = frame;
            self.pageViewController.dataSource = self;
            self.pageViewController.delegate = self;
            
            MTChallengesContentViewController *startingViewController = [self viewControllerAtIndex:0];
            
            NSArray *viewControllers = @[startingViewController];
            
            [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
            
            [self addChildViewController:self.pageViewController];
            [self.view addSubview:self.pageViewController.view];
            [self.pageViewController didMoveToParentViewController:self];
            
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (MTChallengesContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.challenges count] <= 0) || (index >= [self.challenges count])) {
        return nil;
    }
    
    // Create a new view controller and pass suitable data.
    MTChallengesContentViewController *challengeContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChallengesContentViewController"];
    CGRect frame = self.pageViewController.view.frame;
    frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 235.0f);
    challengeContentViewController.view.frame = frame;

    PFChallenges *challenge = self.challenges[index];
    
    challengeContentViewController.challengePillarText = challenge[@"pillar"];
    challengeContentViewController.challengeTitleText = challenge[@"title"];
    challengeContentViewController.challengeNumberText = [challenge[@"challenge_number"] stringValue];
    challengeContentViewController.challengeDescriptionText = challenge[@"description"];
    challengeContentViewController.challengePointsText= [challenge[@"max_points"] stringValue];
    
    challengeContentViewController.pageIndex = index;
    challengeContentViewController.challenge = challenge;

    return challengeContentViewController;
}


#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    return self.viewControllerBefore;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    return self.viewControllerAfter;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.challenges count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    self.pageIndex = 0;
    self.viewControllerBefore = nil;
    self.viewControllerAfter = [self viewControllerAtIndex:1];
    return self.pageIndex;
}


#pragma mark - Page View Controller Delegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    self.pendingPageIndex = ((MTChallengesContentViewController *)[pendingViewControllers firstObject]).pageIndex;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        self.pageIndex = self.pendingPageIndex;
        if ((self.pageIndex == 0) || (self.pageIndex >= self.challenges.count)) {
            self.viewControllerBefore = nil;
        } else {
            self.viewControllerBefore = [self viewControllerAtIndex:(self.pageIndex - 1)];
        }
        
        if (self.pageIndex >= (self.challenges.count - 1)) {
            self.viewControllerAfter = nil;
        } else {
            self.viewControllerAfter = [self viewControllerAtIndex:(self.pageIndex + 1)];
        }
    }
}


#pragma mark - Navigation
/*
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

- (IBAction)unwindToMainMenu:(UIStoryboardSegue *)sender
{
    
}

@end
