//
//  MTStudentChallengeRoomContentViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 9/2/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentChallengeRoomContentViewController.h"
#import "MTStudentChallengeRoomViewController.h"

@interface MTStudentChallengeRoomContentViewController ()

@end

@implementation MTStudentChallengeRoomContentViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"studentChallengeRoomView"];
    
    self.pageViewController.dataSource = self;
    self.pageViewController.delegate = self;
    
    self.exploreCollectionView = [self.storyboard instantiateViewControllerWithIdentifier:@"exploreCollectionView"];
    self.exploreCollectionView.challenge = self.challenge;
    
    self.myClassTableView = [self.storyboard instantiateViewControllerWithIdentifier:@"MyClassChallengePosts"];
    self.myClassTableView.challenge = self.challenge;
    self.myClassTableView.challengeNumber = self.challengeNumber;
    
    self.challengeInfoView = [self.storyboard instantiateViewControllerWithIdentifier:@"challengeInfoModal"];
    self.challengeInfoView.challenge = self.challenge;
    
    self.viewControllers = @[self.myClassTableView, self.exploreCollectionView, self.challengeInfoView];
    self.pageViewControllers = @[self.myClassTableView];
    
    [self.pageViewController setViewControllers:self.pageViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.pageViewController];
    [self.view addSubview:self.pageViewController.view];
    [self.pageViewController didMoveToParentViewController:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Page View Controller Delegate

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"challengeRoomSwipe" object:self userInfo:@{@"index": [NSNumber numberWithInteger:self.pendingIndex]}];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    self.pendingIndex = [self.viewControllers indexOfObject:[pendingViewControllers firstObject]];
}


#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return self.viewControllers[index];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.viewControllers count]) {
        return nil;
    }
    
    return self.viewControllers[index];
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.viewControllers count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    NSInteger page = 0;
    
    if (self.pendingIndex) {
        page = self.pendingIndex;
    }
    
    return page;
}


 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
@end
