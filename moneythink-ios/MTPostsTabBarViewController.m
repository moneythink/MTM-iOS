//
//  MTPostsTabBarViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/27/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTPostsTabBarViewController.h"
#import "MTCommentViewController.h"

@interface MTPostsTabBarViewController ()

@end

@implementation MTPostsTabBarViewController

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
    
    UIImage *postImage = [UIImage imageNamed:@"post"];
    UIBarButtonItem *postComment = [[UIBarButtonItem alloc]
                                    initWithImage:postImage
                                    style:UIBarButtonItemStyleBordered
                                    target:self
                                    action:@selector(postCommentTapped)];
    
    self.navigationItem.rightBarButtonItem = postComment;
}

- (void)viewWillAppear:(BOOL)animated {
    
//    self.title = self.challenge[@"title"];
    self.navigationItem.title = self.challenge[@"title"];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)postCommentTapped {
    self.navigationItem.title = @"Cancel";
    [self performSegueWithIdentifier:@"commentSegue" sender:self];
}

 #pragma mark - Navigation
 
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     MTCommentViewController *destination = (MTCommentViewController *)[segue destinationViewController];
     
     destination.challenge = self.challenge;
 }


- (IBAction)unwindToPostsTabBar:(UIStoryboardSegue *)sender
{
}



@end
