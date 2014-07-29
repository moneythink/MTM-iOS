//
//  MTMentorNotificationViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMentorNotificationViewController.h"
#import "MBProgressHUD.h"
#import "MTMentorStudentProfileViewController.h"
#import "MTMentorStudentProgressViewController.h"
#import "MTStudentProgressTabBarViewController.h"

@interface MTMentorNotificationViewController ()

@end

@implementation MTMentorNotificationViewController

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
//    UIImage *logoImage = [UIImage imageNamed:@"logo_actionbar_medium"];
//    UIBarButtonItem *barButtonLogo = [[UIBarButtonItem alloc] initWithImage:logoImage style:UIBarButtonItemStylePlain target:nil action:nil];
//    self.navigationItem.leftBarButtonItem = barButtonLogo;
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [self navigationController].navigationItem.hidesBackButton = YES;
    
    
    [self tappedSettingsButton:self];
    
    
//    UIImage *imageLogo = [UIImage imageNamed:@"logo_actionbar_medium"];
//    UIImage *imageChallenges = [UIImage imageNamed:@"action_bar_icon_challenges_normal"];
//    UIImage *imageStudents = [UIImage imageNamed:@"action_bar_icon_friends_normal"];
//    UIImage *imageNotification = [UIImage imageNamed:@"action_bar_icon_activity_normal"];
//    UIImage *imageSettings = [UIImage imageNamed:@"action_bar_icon_post_normal"];
//    
//    UIButton *buttonLogo = [UIButton buttonWithType:UIButtonTypeCustom];
//    [buttonLogo setImage:imageLogo forState:UIControlStateNormal];
//    [buttonLogo addTarget:self action:@selector(tappedLogoButton:) forControlEvents:UIControlEventTouchUpInside];
//
//    UIButton *buttonChallenges = [UIButton buttonWithType:UIButtonTypeCustom];
//    [buttonChallenges setImage:imageChallenges forState:UIControlStateNormal];
//    [buttonChallenges addTarget:self action:@selector(tappedChallengesButton:) forControlEvents:UIControlEventTouchUpInside];
//
//    UIButton *buttonStudents = [UIButton buttonWithType:UIButtonTypeCustom];
//    [buttonStudents setImage:imageStudents forState:UIControlStateNormal];
//    [buttonLogo addTarget:self action:@selector(tappedStudentsButton:) forControlEvents:UIControlEventTouchUpInside];
//
//    UIButton *buttonNotifications = [UIButton buttonWithType:UIButtonTypeCustom];
//    [buttonNotifications setImage:imageNotification forState:UIControlStateNormal];
//    [buttonNotifications addTarget:self action:@selector(tappedNotificationButton:) forControlEvents:UIControlEventTouchUpInside];
//    
//    UIButton *buttonSettings = [UIButton buttonWithType:UIButtonTypeCustom];
//    [buttonSettings setImage:imageSettings forState:UIControlStateNormal];
//    [buttonSettings addTarget:self action:@selector(tappedSettingsButton:) forControlEvents:UIControlEventTouchUpInside];
    

    

    
    
    
    
//    CGRect bounds = CGRectMake( 0, 0, imageLogo.size.width, imageLogo.size.height );
//    buttonLogo.bounds = bounds;
//    UIEdgeInsets insets = UIEdgeInsetsZero;
//    insets = (UIEdgeInsets){.right=-10};
//    buttonLogo.contentEdgeInsets = insets;
//    NSLog(@"buttonLogo %@", buttonLogo);
//    NSLog(@"imageLogo %@", imageLogo);
    
//    bounds = CGRectMake( 0, 0, imageLogo.size.width, imageChallenges.size.height );
//    buttonChallenges.bounds = bounds;
//    buttonChallenges.contentEdgeInsets = insets;
//    NSLog(@"buttonChallenges width - %f", buttonChallenges.frame.size.width);
//    NSLog(@"imageChallenges width - %f", imageChallenges.size.width);
    
//    bounds = CGRectMake( 0, 0, imageLogo.size.width, imageStudents.size.height );
//    buttonStudents.bounds = bounds;
//    buttonStudents.contentEdgeInsets = insets;
//    NSLog(@"buttonStudents width - %f", buttonStudents.frame.size.width);

//    bounds = CGRectMake( 0, 0, imageLogo.size.width, imageNotification.size.height );
//    buttonNotifications.bounds = bounds;
//    buttonNotifications.contentEdgeInsets = insets;
//    NSLog(@"buttonNotifications %@", buttonLogo);
//    NSLog(@"imageNotification %@", imageLogo);

//    bounds = CGRectMake( 0, 0, imageLogo.size.width, imageSettings.size.height );
//    buttonSettings.bounds = bounds;
//    buttonSettings.contentEdgeInsets = insets;
//    NSLog(@"buttonSettings width - %f", buttonSettings.frame.size.width);

    
    
    
    
    
    
//    
//    NSArray *rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithCustomView:buttonSettings],
//                                     [[UIBarButtonItem alloc] initWithCustomView:buttonChallenges],
//                                     [[UIBarButtonItem alloc] initWithCustomView:buttonNotifications],
//                                     [[UIBarButtonItem alloc] initWithCustomView:buttonStudents]];
    
//    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
//
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:buttonLogo];
    
    
    
    
    NSPredicate *findClassNotifications = [NSPredicate predicateWithFormat:@"class = %@", [PFUser currentUser][@"class"]];
    PFQuery *findNotifications = [PFQuery queryWithClassName:[PFNotifications parseClassName] predicate:findClassNotifications];
    [findNotifications includeKey:@"user"];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [findNotifications findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.classNotifications = objects;
            
            [self.notificationsTableView reloadData];
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button selectors

- (void)tappedLogoButton:(id)sender
{
    //    [PFUser logOut];
}

- (void)tappedSettingsButton:(id)sender
{
    //    [PFUser logOut];
    //    [self performSegueWithIdentifier:@"unwindToSignUpLogin" sender:self];
    
    UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Logout", @"Settings", nil];
    
    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    if ([window.subviews containsObject:self.view]) {
        [logoutSheet showInView:self.view];
    } else {
        [logoutSheet showInView:window];
    }
    
}

- (void)tappedStudentsButton:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"Students" message:@"Students" delegate:nil cancelButtonTitle:@"Students" otherButtonTitles:nil, nil] show];
    //    UIViewController *imagPickerController = [UIViewController alloc] iniadsasdf
    //    UIImagePickerController *takeAPicture = [[UIImagePickerController alloc] initWithRootViewController:imagPickerController];
}

- (void)tappedChallengesButton:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"Challenges" message:@"Challenges" delegate:nil cancelButtonTitle:@"Challenges" otherButtonTitles:nil, nil] show];
}

- (void)tappedNotificationButton:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"Notifications" message:@"Notifications" delegate:nil cancelButtonTitle:@"Notifications" otherButtonTitles:nil, nil] show];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueIdentifier = [segue identifier];
//    id destinationViewController = [segue destinationViewController];
    
    if ([segueIdentifier isEqualToString:@"pushMentorStudentProfileView"]) {
        NSLog(@"foo");
    } else if ([segueIdentifier isEqualToString:@"foo"]) {
        NSLog(@"foo");
    } else if ([segueIdentifier isEqualToString:@"pushStudentProgressViewController"]) {
        NSLog(@"foo");
        MTStudentProgressTabBarViewController *destinationViewController = (MTStudentProgressTabBarViewController *)[segue destinationViewController];
        destinationViewController.mentor = [PFUser currentUser];
    }

}

#pragma mark - UITableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = [self.classNotifications count];
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.notificationsTableView dequeueReusableCellWithIdentifier:@"notificationCell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"notificationCell"];
    }
    
    PFNotifications *notificationForRow = self.classNotifications[indexPath.row];
    PFUser *user = [notificationForRow objectForKey:@"user"];

    if (notificationForRow[@"challenge_activated"]) {
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Challenge activated = %@", notificationForRow[@"challenge_activated"]];
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    [self performSegueWithIdentifier:@"pushMentorStudentProfileView" sender:self];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(3_0)
{
    
}


#pragma mark - UIACtionSheetDelegate methods

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


@end
