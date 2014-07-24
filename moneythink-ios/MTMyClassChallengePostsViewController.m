//
//  MTMyClassChallengePostsViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/24/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMyClassChallengePostsViewController.h"

@interface MTMyClassChallengePostsViewController ()

@end

@implementation MTMyClassChallengePostsViewController

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
}

- (void)viewWillAppear:(BOOL)animated
{
    
    self.toggleExploreMyClass.selectedSegmentIndex = 1;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tappedExploreMyClass:(id)sender {
    
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

@end
