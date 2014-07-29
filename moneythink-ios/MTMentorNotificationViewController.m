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
    UIImage *logoImage = [UIImage imageNamed:@"logo_actionbar_medium"];
    UIBarButtonItem *barButtonLogo = [[UIBarButtonItem alloc] initWithImage:logoImage style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.leftBarButtonItem = barButtonLogo;
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [self navigationController].navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *button0 = [[UIBarButtonItem alloc]
                                initWithTitle:@"zlogo"
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
                                target:nil
                                action:nil];
    
    UIBarButtonItem *button4 = [[UIBarButtonItem alloc]
                                initWithTitle:@"4"
                                style:UIBarButtonItemStyleBordered
                                target:nil
                                action:nil];
    
    NSArray *rightBarButtonItems = @[button1, button2, button3, button4];
    
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    self.navigationItem.leftBarButtonItem = button0;
    self.navigationItem.title = @"Challenges";
    
    NSString *testString = [PFUser currentUser][@"class"];
    NSPredicate *findStudentsInClass = [NSPredicate predicateWithFormat:@"class = %@", [PFUser currentUser][@"class"]];
    PFQuery *findStudents = [PFQuery queryWithClassName:[PFUser parseClassName] predicate:findStudentsInClass];
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [findStudents findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            self.studentsInClass = objects;
            [self.studentsTableView reloadData];
            
            [MBProgressHUD hideHUDForView:self.view animated:YES];
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tappedButtonItem0:(id)sender
{
    
}

- (void)tappedButtonItem1:(id)sender
{
    [self performSegueWithIdentifier:@"pushStudentProgressViewController" sender:self];
}

- (void)tappedButtonItem2:(id)sender
{
    UIActionSheet *logoutSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Logout", @"Settings", nil];
    
    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    if ([window.subviews containsObject:self.view]) {
        [logoutSheet showInView:self.view];
    } else {
        [logoutSheet showInView:window];
    }
}

- (void)tappedButtonItem3:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"3" message:@"3" delegate:nil cancelButtonTitle:@"3" otherButtonTitles:nil, nil] show];
}

- (void)tappedButtonItem4:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"4" message:@"4" delegate:nil cancelButtonTitle:@"4" otherButtonTitles:nil, nil] show];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    MTMentorStudentProfileViewController *destinationViewController = [segue destinationViewController];
    
    if ([destinationViewController isKindOfClass:[MTMentorStudentProfileViewController class]]) {
        
    } else if ([destinationViewController isKindOfClass:[MTMentorStudentProgressViewController class]]) {
        
    }

}

#pragma mark - UITableViewController delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger rows = [self.studentsInClass count];
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [self.studentsTableView dequeueReusableCellWithIdentifier:@"studentCell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"studentCell"];
    }
    
    PFUser *userForRow = self.studentsInClass[indexPath.row];
    NSString *userName = [self.studentsInClass[indexPath.row] username];
    cell.detailTextLabel.text = [userForRow username];
    
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
