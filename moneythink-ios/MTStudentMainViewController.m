//
//  MTStudentMainViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentMainViewController.h"
//#import "MTChallengesViewController.h"
//#import "MTChallengesContentViewController.h"

@interface MTStudentMainViewController ()

@end

@implementation MTStudentMainViewController

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
    
    self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *button0 = [[UIBarButtonItem alloc] initWithTitle:@"logo" style:UIBarButtonItemStyleBordered target:nil action:nil];

    UIBarButtonItem *button1 = [[UIBarButtonItem alloc] initWithTitle:@"one" style:UIBarButtonItemStyleBordered target:nil action:nil];
UIBarButtonItem *button2 = [[UIBarButtonItem alloc] initWithTitle:@"2" style:UIBarButtonItemStyleBordered target:nil action:nil];
    UIBarButtonItem *button3 = [[UIBarButtonItem alloc] initWithTitle:@"3" style:UIBarButtonItemStyleBordered target:nil action:nil];
    UIBarButtonItem *button4 = [[UIBarButtonItem alloc] initWithTitle:@"4" style:UIBarButtonItemStyleBordered target:nil action:nil];
    
    NSArray *rightBarButtonItems = @[button1, button2, button3, button4];
    
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    self.navigationItem.leftBarButtonItem = button0;
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


//- (IBAction)startWalkthrough:(id)sender {
//    MTChallengesContentViewController *startingViewController = [self viewControllerAtIndex:0];
//    NSArray *viewControllers = @[startingViewController];
//    [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionReverse animated:NO completion:nil];
//}

//- (MTChallengesContentViewController *)viewControllerAtIndex:(NSUInteger)index
//{
//    if (([self.pageTitles count] == 0) || (index >= [self.pageTitles count])) {
//        return nil;
//    }
//    
//        // Create a new view controller and pass suitable data.
//        // MTChallengesViewController
//        // challengesPageViewController
//    
////    MTChallengesViewController *pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"challengesPageViewController"];
//    
//    MTChallengesContentViewController *pageContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"challengesPageViewController"];
//
//    pageContentViewController.titleText = self.pageTitles[index];
//    
//    pageContentViewController.pageIndex = index;
//    
//    return pageContentViewController;
//}

//#pragma mark - Page View Controller Data Source
//
//- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
//{
//    NSUInteger index = ((MTChallengesContentViewController*) viewController).pageIndex;
//    
//    if ((index == 0) || (index == NSNotFound)) {
//        return nil;
//    }
//    
//    index--;
//    return [self viewControllerAtIndex:index];
//}
//
//- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
//{
//    NSUInteger index = ((MTChallengesContentViewController*) viewController).pageIndex;
//    
//    if (index == NSNotFound) {
//        return nil;
//    }
//    
//    index++;
//    if (index == [self.pageTitles count]) {
//        return nil;
//    }
//    return [self viewControllerAtIndex:index];
//}
//
//- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
//{
//    return [self.pageTitles count];
//}
//
//- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
//{
//    return 0;
//}


@end
