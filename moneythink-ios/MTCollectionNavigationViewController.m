//
//  MTCollectionNavigationViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 8/10/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTCollectionNavigationViewController.h"
#import "MTPostViewController.h"

@interface MTCollectionNavigationViewController ()

@end

@implementation MTCollectionNavigationViewController

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
    
    self.title = @"Explore";
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
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    NSString *segueIdentifier = [segue identifier];
    
    MTPostViewController *destinationViewController = (MTPostViewController *)[segue destinationViewController];
    destinationViewController.challengePost = (PFChallengePost *)sender;

    if ([segueIdentifier isEqualToString:@"pushViewPost"]) {
    }
}

@end