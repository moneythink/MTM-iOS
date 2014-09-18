//
//  MTStudentChallengeRoomViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentChallengeRoomViewController.h"

@interface MTStudentChallengeRoomViewController ()

@property (strong, nonatomic) IBOutlet UISegmentedControl *challengeRoomControls;

@end

@implementation MTStudentChallengeRoomViewController

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UISegmentedControl appearance] setTintColor:[UIColor primaryOrange]];
    
    UIImage *postImage = [UIImage imageNamed:@"post"];
    UIBarButtonItem *postComment = [[UIBarButtonItem alloc]
                                    initWithImage:postImage
                                    style:UIBarButtonItemStyleBordered
                                    target:self
                                    action:@selector(postCommentTapped)];
    
    self.navigationItem.rightBarButtonItem = postComment;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateControlButton:) name:@"challengeRoomSwipe" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:NO];
    self.navigationItem.title = nil;
}

- (void)didReceiveMemoryWarnng
{
    [super didReceiveMemoryWarning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Methods

- (void)updateControlButton:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    NSInteger index = [[userInfo valueForKey:@"index"] intValue];
    self.challengeRoomControls.selectedSegmentIndex = index;
}

- (IBAction)controlTapped:(id)sender {
    NSInteger index = [self.challengeRoomControls selectedSegmentIndex];
    self.destinationVC.pendingIndex = index;
    [self.destinationVC.pageViewController setViewControllers:@[self.destinationVC.viewControllers[index]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (void)postCommentTapped {
    self.navigationItem.title = @"Cancel";
    [self performSegueWithIdentifier:@"commentSegue" sender:self];
}

- (void)dismissPostView {
    UIActionSheet *updateMessage = [[UIActionSheet alloc] initWithTitle:@"Your post is processing." delegate:nil cancelButtonTitle:@"OK" destructiveButtonTitle:nil otherButtonTitles:nil, nil];
    UIWindow* window = [[[UIApplication sharedApplication] delegate] window];
    if ([window.subviews containsObject:self.view]) {
        [updateMessage showInView:self.view];
    } else {
        [updateMessage showInView:window];
    }
}

- (void)dismissCommentView {
    
}

- (IBAction)unwindToChallengeRoom:(UIStoryboardSegue *)sender
{
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.

    NSString *segueID = [segue identifier];
    
    if ([segueID isEqualToString:@"commentSegue"]) {
        MTCommentViewController *destinationVC = (MTCommentViewController *)[segue destinationViewController];
        destinationVC.challenge = self.challenge;
        destinationVC.delegate = self;
    } else {
        self.destinationVC = (MTStudentChallengeRoomContentViewController *)[segue destinationViewController];
        self.destinationVC.challenge = self.challenge;
        self.destinationVC.challengeNumber = self.challengeNumber;
    }
}

@end
