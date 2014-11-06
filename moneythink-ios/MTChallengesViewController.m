//
//  MTChallengesViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/19/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTChallengesViewController.h"

@interface MTChallengesViewController ()

@property (assign, nonatomic) NSInteger pendingPageIndex;
@property (assign, nonatomic) NSInteger pageIndex;

@property (strong, nonatomic) MTChallengesContentViewController *viewControllerBefore;
@property (strong, nonatomic) MTChallengesContentViewController *viewControllerAfter;
@property (nonatomic) BOOL userChangedClass;

@end

@implementation MTChallengesViewController

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeClass:) name:kUserDidChangeClass object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (IsEmpty(self.challenges)) {
        [self loadChallenges];
    }
}


#pragma mark - Private -
- (void)loadChallenges
{
    self.pageViewController.view.alpha = 0.0f;

    NSString *userClass = [PFUser currentUser][@"class"];
    NSString *userSchool = [PFUser currentUser][@"school"];
    
    PFQuery *userClassQuery = [PFQuery queryWithClassName:[PFClasses parseClassName]];
    [userClassQuery whereKey:@"name" equalTo:userClass];
    [userClassQuery whereKey:@"school" equalTo:userSchool];
    userClassQuery.cachePolicy = kPFCachePolicyNetworkElseCache;
    
    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:NO];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    if (self.userChangedClass) {
        self.userChangedClass = NO;
        hud.labelText = @"Updating Challenges...";
    }
    else {
        hud.labelText = @"Loading Challenges...";
    }
    hud.dimBackground = YES;
    
    MTMakeWeakSelf();
    [self bk_performBlock:^(id obj) {
        [userClassQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                if (!IsEmpty(objects)) {
                    PFClasses *userClass = [objects firstObject];
                    NSLog(@"%@", userClass);
                    
                    // Next, determine if this class has custom challenges
                    PFQuery *customPlaylist = [PFQuery queryWithClassName:[PFPlaylist parseClassName]];
                    [customPlaylist whereKey:@"class" equalTo:userClass];
                    customPlaylist.cachePolicy = kPFCachePolicyNetworkElseCache;
                    
                    [customPlaylist findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        if (!error) {
                            if (!IsEmpty(objects)) {
                                // Assume we're on custom playlist for this class
                                [weakSelf loadCustomChallengesForPlaylist:[objects firstObject]];
                            }
                            else {
                                [weakSelf loadDefaultChallenges];
                            }
                        }
                        else {
                            NSLog(@"Error loading custom playlists: %@", [error localizedDescription]);
                            [weakSelf loadDefaultChallenges];
                        }
                    }];
                    
                }
                else {
                    [weakSelf loadDefaultChallenges];
                }
            }
            else {
                NSLog(@"Error loading custom playlists: %@", [error localizedDescription]);
                [weakSelf loadDefaultChallenges];
            }
        }];
    } afterDelay:0.35f];
}

- (void)loadCustomChallengesForPlaylist:(PFPlaylist *)playlist
{
    [MTUtil setDisplayingCustomPlaylist:YES];
    
    PFQuery *allCustomChallenges = [PFQuery queryWithClassName:[PFPlaylistChallenges parseClassName]];
    [allCustomChallenges whereKey:@"playlist" equalTo:playlist];
    [allCustomChallenges orderByAscending:@"ordering"];
    [allCustomChallenges includeKey:@"challenge"];

    MTMakeWeakSelf();
    [allCustomChallenges findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        });
        
        if (!error) {
            NSMutableArray *customChallenges = [NSMutableArray arrayWithCapacity:[objects count]];
            for (PFPlaylistChallenges *thisPlaylistChallenge in objects) {
                PFCustomChallenges *thisChallenge = thisPlaylistChallenge[@"challenge"];
                
                NSInteger ordering = [thisPlaylistChallenge[@"ordering"] integerValue];
                [MTUtil setOrdering:ordering forChallengeObjectId:thisChallenge.objectId];
                [customChallenges addObject:thisChallenge];
            }
            
            weakSelf.challenges = [NSArray arrayWithArray:customChallenges];
            
            // Create page view controller
            if (!weakSelf.pageViewController) {
                weakSelf.pageViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"ChallengesViewController"];
                CGRect frame = weakSelf.pageViewController.view.frame;
                frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 235.0f);
                weakSelf.pageViewController.view.frame = frame;
                weakSelf.pageViewController.dataSource = weakSelf;
                weakSelf.pageViewController.delegate = weakSelf;
                
                MTChallengesContentViewController *startingViewController = [weakSelf viewControllerAtIndex:0];
                NSArray *viewControllers = @[startingViewController];
                [weakSelf.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
                
                [weakSelf addChildViewController:weakSelf.pageViewController];
                [weakSelf.view addSubview:weakSelf.pageViewController.view];
                [weakSelf.pageViewController didMoveToParentViewController:weakSelf];
            }
            else {
                MTChallengesContentViewController *startingViewController = [weakSelf viewControllerAtIndex:0];
                NSArray *viewControllers = @[startingViewController];
                [self.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
            }
            
            [UIView animateWithDuration:0.2f animations:^{
                weakSelf.pageViewController.view.alpha = 1.0f;
            }];
        }
        else {
            NSLog(@"Unable to load custom challenges");
        }
    }];
}

- (void)loadDefaultChallenges
{
    [MTUtil setDisplayingCustomPlaylist:NO];
    
    PFQuery *allChallenges = [PFQuery queryWithClassName:[PFChallenges parseClassName]];
    [allChallenges orderByAscending:@"challenge_number"];
    [allChallenges whereKeyDoesNotExist:@"school"];
    [allChallenges whereKeyDoesNotExist:@"class"];
    
    MTMakeWeakSelf();
    [allChallenges findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
        });

        if (!error) {
            weakSelf.challenges = objects;
            
            // Create page view controller
            if (!weakSelf.pageViewController) {
                weakSelf.pageViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"ChallengesViewController"];
                CGRect frame = weakSelf.pageViewController.view.frame;
                frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 235.0f);
                weakSelf.pageViewController.view.frame = frame;
                weakSelf.pageViewController.dataSource = weakSelf;
                weakSelf.pageViewController.delegate = weakSelf;
                
                MTChallengesContentViewController *startingViewController = [weakSelf viewControllerAtIndex:0];
                NSArray *viewControllers = @[startingViewController];
                [weakSelf.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
                
                [weakSelf addChildViewController:weakSelf.pageViewController];
                [weakSelf.view addSubview:weakSelf.pageViewController.view];
                [weakSelf.pageViewController didMoveToParentViewController:weakSelf];
            }
            else {
                MTChallengesContentViewController *startingViewController = [weakSelf viewControllerAtIndex:0];
                NSArray *viewControllers = @[startingViewController];
                [weakSelf.pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
            }
            
            [UIView animateWithDuration:0.2f animations:^{
                weakSelf.pageViewController.view.alpha = 1.0f;
            }];
        }
    }];
}

- (MTChallengesContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.challenges count] <= 0) || (index >= [self.challenges count])) {
        return nil;
    }
    
    // Create a new view controller and pass suitable data.
    MTChallengesContentViewController *challengeContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChallengesContentViewController"];
    CGRect frame = self.pageViewController.view.frame;
    frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 235.0f);
    challengeContentViewController.view.frame = frame;

    PFChallenges *challenge = self.challenges[index];
    
    challengeContentViewController.challengePillarText = challenge[@"pillar"];
    challengeContentViewController.challengeTitleText = challenge[@"title"];
    
    if ([MTUtil displayingCustomPlaylist]) {
        NSInteger ordering = [MTUtil orderingForChallengeObjectId:challenge.objectId];
        if (ordering != -1) {
            challengeContentViewController.challengeNumberText = [NSString stringWithFormat:@"%lu", ordering];
        }
        else {
            challengeContentViewController.challengeNumberText = @"";
        }
    }
    else {
        challengeContentViewController.challengeNumberText = [challenge[@"challenge_number"] stringValue];
    }
    
    challengeContentViewController.challengeDescriptionText = challenge[@"student_instructions"];
    challengeContentViewController.challengePointsText= [challenge[@"max_points"] stringValue];
    
    challengeContentViewController.pageIndex = index;
    challengeContentViewController.challenge = challenge;

    return challengeContentViewController;
}


#pragma mark - Page View Controller Data Source
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    return self.viewControllerBefore;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    return self.viewControllerAfter;
}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.challenges count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    self.pageIndex = 0;
    self.viewControllerBefore = nil;
    self.viewControllerAfter = [self viewControllerAtIndex:1];
    return self.pageIndex;
}


#pragma mark - Page View Controller Delegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    self.pendingPageIndex = ((MTChallengesContentViewController *)[pendingViewControllers firstObject]).pageIndex;
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        self.pageIndex = self.pendingPageIndex;
        if ((self.pageIndex == 0) || (self.pageIndex >= self.challenges.count)) {
            self.viewControllerBefore = nil;
        } else {
            self.viewControllerBefore = [self viewControllerAtIndex:(self.pageIndex - 1)];
        }
        
        if (self.pageIndex >= (self.challenges.count - 1)) {
            self.viewControllerAfter = nil;
        } else {
            self.viewControllerAfter = [self viewControllerAtIndex:(self.pageIndex + 1)];
        }
    }
}


#pragma mark - Navigation
- (IBAction)unwindToMainMenu:(UIStoryboardSegue *)sender
{
}


#pragma mark - Notifications -
- (void)userDidChangeClass:(NSNotification *)notif
{
    self.userChangedClass = YES;
    self.challenges = nil;
}


@end
