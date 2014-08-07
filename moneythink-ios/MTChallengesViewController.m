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
    
    PFQuery *allChallenges = [PFQuery queryWithClassName:@"Challenges"];
    
    if (YES) {
        [allChallenges findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                self.challenges = objects;
                
                // Create page view controller
                self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChallengesViewController"];
                self.pageViewController.dataSource = self;
                
                MTChallengesContentViewController *startingViewController = [self viewControllerAtIndex:0];
                
                NSArray *viewControllers = @[startingViewController];
                
                [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
                
                [self addChildViewController:_pageViewController];
                [self.view addSubview:_pageViewController.view];
                [self.pageViewController didMoveToParentViewController:self];
            }
        }];
    } else {
        self.challenges = [allChallenges findObjects];
        
        // Create page view controller
        self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChallengesViewController"];
        self.pageViewController.dataSource = self;
        
        MTChallengesContentViewController *startingViewController = [self viewControllerAtIndex:0];
        NSArray *viewControllers = @[startingViewController];
        
        [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        
        [self addChildViewController:_pageViewController];
        [self.view addSubview:_pageViewController.view];
        [self.pageViewController didMoveToParentViewController:self];
    }
    
    
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
    BOOL mentor = [[PFUser currentUser][@"type"] isEqualToString:@"student"];
    MTChallengesContentViewController *challengeContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChallengesContentViewController"];
    
    PFChallenges *challenge = self.challenges[index];
    NSPredicate *challengePredicate = [NSPredicate predicateWithFormat:@"challenge_number = %@", challenge[@"challenge_number"]];
    PFQuery *queryActivated = [PFQuery queryWithClassName:@"ChallengesActivated" predicate:challengePredicate];
    
    //        [queryActivated countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
    //            if (!error) {
    //                challengeContentViewController.challengeStateText = number > 0 ? @"OPEN CHALLENGE" : @"FUTURE CHALLENGE";
    //                NSLog(@"state - %@", challengeContentViewController.challengeStateText);
    //                [challengeContentViewController.view setNeedsDisplay];
    //            } else {
    //                NSLog(@"error - %@", error);
    //            }
    //        }];
    
    NSInteger count = [queryActivated countObjects];
    challengeContentViewController.challengeStateText = (count > 0) ? @"OPEN CHALLENGE" : @"FUTURE CHALLENGE";
    
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
    NSUInteger index = ((MTChallengesContentViewController*) viewController).pageIndex;
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return [self viewControllerAtIndex:index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = ((MTChallengesContentViewController *)viewController).pageIndex;
    
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


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

- (IBAction)unwindToMainMenu:(UIStoryboardSegue *)sender
{
    
}

@end
