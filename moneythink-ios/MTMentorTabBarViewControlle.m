//
//  MTMentorTabBarViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/25/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMentorTabBarViewControlle.h"

@interface MTMentorTabBarViewController ()

@end

@implementation MTMentorTabBarViewController

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
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [self navigationController].navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *button0 = [[UIBarButtonItem alloc]
                                initWithTitle:@"logo"
                                style:UIBarButtonItemStyleBordered
                                target:self
                                action:@selector(tappedButtonItem0:)];
    
    UIBarButtonItem *button1 = [[UIBarButtonItem alloc]
                                initWithTitle:@"1"
                                style:UIBarButtonItemStyleBordered
                                target:self
                                action:@selector(tappedButtonItem1:)];
    
    UIBarButtonItem *button2 = [[UIBarButtonItem alloc]
                                initWithTitle:@"2"
                                style:UIBarButtonItemStyleBordered
                                target:self
                                action:@selector(tappedButtonItem2:)];
    
    UIBarButtonItem *button3 = [[UIBarButtonItem alloc]
                                initWithTitle:@"3"
                                style:UIBarButtonItemStyleBordered
                                target:self
                                action:@selector(tappedButtonItem3:)];
    
    UIBarButtonItem *button4 = [[UIBarButtonItem alloc]
                                initWithTitle:@"4"
                                style:UIBarButtonItemStyleBordered
                                target:self
                                action:@selector(tappedButtonItem4:)];
    
    NSArray *rightBarButtonItems = @[button1, button2, button3, button4];
    
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    self.navigationItem.leftBarButtonItem = button0;
    self.navigationItem.title = @"Challenges";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Button selectors

- (void)tappedButtonItem0:(id)sender
{

}

- (void)tappedButtonItem1:(id)sender
{
    UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Logout", @"Settings", nil];
    
    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    if ([window.subviews containsObject:self.view]) {
        [logoutSheet showInView:self.view];
    } else {
        [logoutSheet showInView:window];
    }

}

- (void)tappedButtonItem2:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"Students" message:@"Students" delegate:nil cancelButtonTitle:@"Students" otherButtonTitles:nil, nil] show];
    //    UIViewController *imagPickerController = [UIViewController alloc] iniadsasdf
    //    UIImagePickerController *takeAPicture = [[UIImagePickerController alloc] initWithRootViewController:imagPickerController];
}

- (void)tappedButtonItem3:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"Challenges" message:@"Challenges" delegate:nil cancelButtonTitle:@"Challenges" otherButtonTitles:nil, nil] show];
}

- (void)tappedButtonItem4:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"Notifications" message:@"Notifications" delegate:nil cancelButtonTitle:@"Notifications" otherButtonTitles:nil, nil] show];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


#pragma mark - UIActionSheetDelegate methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex  // after animation
{
    switch (buttonIndex) {
        case 0:
            [PFUser logOut];
            [self performSegueWithIdentifier:@"unwindToSignUpLogin" sender:nil];
            break;
            
        case 1:
            break;
            
        default:
            break;
    }
}

#pragma mark = UITabBarControllerDelegate delegate methods

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController NS_AVAILABLE_IOS(3_0);
{
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController{
    
}

- (void)tabBarController:(UITabBarController *)tabBarController willBeginCustomizingViewControllers:(NSArray *)viewControllers NS_AVAILABLE_IOS(3_0)
{
    
}

- (void)tabBarController:(UITabBarController *)tabBarController willEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed NS_AVAILABLE_IOS(3_0)
{
    
}

- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
    
}

- (NSUInteger)tabBarControllerSupportedInterfaceOrientations:(UITabBarController *)tabBarController NS_AVAILABLE_IOS(7_0)
{
    return UIInterfaceOrientationPortrait;
}

//- (UIInterfaceOrientation)tabBarControllerPreferredInterfaceOrientationForPresentation:(UITabBarController *)tabBarController NS_AVAILABLE_IOS(7_0)
//{
//    return UIInterfaceOrientationPortrait;
//}

//- (id <UIViewControllerInteractiveTransitioning>)tabBarController:(UITabBarController *)tabBarController
//                      interactionControllerForAnimationController: (id <UIViewControllerAnimatedTransitioning>)animationController NS_AVAILABLE_IOS(7_0)
//{
//    return nil;
//}

//- (id <UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController *)tabBarController
//            animationControllerForTransitionFromViewController:(UIViewController *)fromVC
//                                              toViewController:(UIViewController *)toVC  NS_AVAILABLE_IOS(7_0)
//{
//    return nil;
//}


#pragma mark - UITabBarDelegate delegate methods

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item // called when a new view is selected by the user (but not programatically)
{
    
}

/* called when user shows or dismisses customize sheet. you can use the 'willEnd' to set up what appears underneath.
 changed is YES if there was some change to which items are visible or which order they appear. If selectedItem is no longer visible,
 it will be set to nil.
 */

//- (void)tabBar:(UITabBar *)tabBar willBeginCustomizingItems:(NSArray *)items // called before customize sheet is shown. items is current item list
//{
//    
//}

//- (void)tabBar:(UITabBar *)tabBar didBeginCustomizingItems:(NSArray *)items // called after customize sheet is shown. items is current item list
//{
//    
//}

//- (void)tabBar:(UITabBar *)tabBar willEndCustomizingItems:(NSArray *)items changed:(BOOL)changed // called before customize sheet is hidden. items is new item list
//{
//    
//}

//- (void)tabBar:(UITabBar *)tabBar didEndCustomizingItems:(NSArray *)items changed:(BOOL)changed // called after customize sheet is hidden. items is new item list
//{
//    
//}



@end