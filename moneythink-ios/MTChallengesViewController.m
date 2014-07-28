//
//  MTChallengesViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/19/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTChallengesViewController.h"

@interface MTChallengesViewController ()

@end

@implementation MTChallengesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    PFQuery *allChallenges = [PFQuery queryWithClassName:@"Challenges"];
    
    self.challenges = [allChallenges findObjects];

        // Create the data model
    _pageTitles = @[@"Over 200 Tips and Tricks", @"Discover Hidden Features", @"Bookmark Favorite Tip", @"Free Regular Update", @"Free Regular Update", @"Free Regular Update", @"Free Regular Update", @"Free Regular Update"];
    
        // Create page view controller
    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChallengesViewController"];
    self.pageViewController.dataSource = self;
    
    MTChallengesContentViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = @[startingViewController];
    
    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
        // Change the size of page view controller
//    self.pageViewController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 30);
    
//    UIPageControl *pageControl = [UIPageControl appearance];
//    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
//    pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
//    pageControl.backgroundColor = [UIColor blueColor];
    
    [self addChildViewController:_pageViewController];
    [self.view addSubview:_pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (MTChallengesContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.challenges count] == 0) || (index >= [self.challenges count])) {
        return nil;
    }
    
        // Create a new view controller and pass suitable data.
    MTChallengesContentViewController *challengeContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChallengesContentViewController"];

    
    challengeContentViewController.challengeStateText = @"OPEN CHALLENGE";
    
    challengeContentViewController.challengeTitleText = [self.challenges[index] valueForUndefinedKey:@"title"];
    
    challengeContentViewController.challengeNumberText = [[self.challenges[index] valueForUndefinedKey:@"challenge_number"] stringValue];
    
//    NSArray *allKeys = [self.challenges[index] allKeys];
    
    challengeContentViewController.challengeDescriptionText = [self.challenges[index] valueForUndefinedKey:@"description"];
    
    challengeContentViewController.challengePointsText= [[self.challenges[index] valueForUndefinedKey:@"max_points"] stringValue];
    
    
    challengeContentViewController.pageIndex = index;
    
    return challengeContentViewController;
}


#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = ((MTChallengesContentViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((MTChallengesContentViewController*) viewController).pageIndex;
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.challenges count]) {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.challenges count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
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

- (IBAction)unwindToMainMenu:(UIStoryboardSegue *)sender
{

}

@end
