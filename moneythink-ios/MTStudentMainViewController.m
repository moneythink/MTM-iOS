//
//  MTStudentMainViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentMainViewController.h"

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
}

- (void)tappedButtonItem0:(id)sender
{
    [PFUser logOut];
//    [self segueForUnwindingToViewController:<#(UIViewController *)#> fromViewController:<#(UIViewController *)#> identifier:<#(NSString *)#>]
}

- (void)tappedButtonItem1:(id)sender
{
    [PFUser logOut];
}

- (void)tappedButtonItem2:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"2" message:@"2" delegate:nil cancelButtonTitle:@"2" otherButtonTitles:nil, nil] show];
}

- (void)tappedButtonItem3:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"3" message:@"3" delegate:nil cancelButtonTitle:@"3" otherButtonTitles:nil, nil] show];
}

- (void)tappedButtonItem4:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"4" message:@"4" delegate:nil cancelButtonTitle:@"4" otherButtonTitles:nil, nil] show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
        // Dispose of any resources that can be recreated.
}

 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
     NSLog(@"sender %@", sender);
     id senderButton = [sender class];
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }



@end
