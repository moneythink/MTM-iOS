//
//  MTChallengesViewController.m
//  moneythink-ios
//
//  Created by dsica on 5/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTChallengesViewController.h"
#import "MTExplorePostCollectionView.h"
#import "MTChallengeInfoViewController.h"
#import "MTMyClassTableViewController.h"

@interface MTChallengesViewController ()

@property (nonatomic, strong) IBOutlet UIView *challengesView;
@property (nonatomic, strong) IBOutlet UIView *feedExploreToggleView;
@property (nonatomic, strong) IBOutlet UIView *myClassView;

@property (nonatomic, strong) IBOutlet UIButton *myFeedButton;
@property (nonatomic, strong) IBOutlet UIView *myFeedHighlightView;
@property (nonatomic, strong) IBOutlet UIButton *exploreButton;
@property (nonatomic, strong) IBOutlet UIView *exploreHighlightView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *challengeBarHeightConstraint;

@property (nonatomic) NSInteger challengesPageIndex;
@property (nonatomic, strong) MTChallengeContentViewController *challengeContentViewControllerBefore;
@property (nonatomic, strong) MTChallengeContentViewController *challengeContentViewControllerAfter;
@property (nonatomic) BOOL userChangedClass;
@property (nonatomic, strong) PFChallenges *currentChallenge;
@property (nonatomic, strong) NSArray *challenges;
@property (nonatomic, strong) NSArray *viewControllers;
@property (nonatomic, strong) NSArray *pageViewControllers;
@property (nonatomic, strong) UIPageViewController *myClassPageViewController;
@property (nonatomic, strong) UIPageViewController *challengesPageViewController;
@property (nonatomic, assign) NSInteger challengesPendingIndex;
@property (nonatomic, strong) MTExplorePostCollectionView *exploreCollectionView;
@property (nonatomic, strong) MTMyClassTableViewController  *myClassTableView;
@property (nonatomic, strong) MTChallengeInfoViewController *challengeInfoView;
@property (nonatomic, strong) MTChallengeListViewController *challengeListView;
@property (nonatomic, strong) NSArray *emojiObjects;
@property (nonatomic) BOOL shouldLoadPreviousChallenge;

@end

@implementation MTChallengesViewController


#pragma mark - Lifecycle -
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidChangeClass:) name:kUserDidChangeClass object:nil];

    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_actionbar"]];

    [self setupViews];
    [self loadEmoji];
    
    self.shouldLoadPreviousChallenge = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Do this to work around bug with challenge bar when in-call status bar showing
    // Still need to handle challenge list resizing when in-call status bar change occur while in view.
    CGFloat statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    if (statusBarHeight > 20.0f) {
        self.verticalSpaceConstraint.constant = -20.0f;
        self.challengeBarHeightConstraint.constant = 68.0f;
        self.myClassPageViewController.view.frame = ({
            CGRect newFrame = self.myClassPageViewController.view.frame;
            newFrame.origin.y = 0.0f;
            newFrame;
        });
    }
    else {
        self.verticalSpaceConstraint.constant = 0.0f;
        self.challengeBarHeightConstraint.constant = 48.0f;
    }
    
    self.myClassPageViewController.view.frame = ({
        CGRect newFrame = self.myClassPageViewController.view.frame;
        newFrame.origin.y = 0.0f;
        newFrame;
    });
    
    if (IsEmpty(self.challenges)) {
        [self loadChallenges];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // If already loaded, need to do this in ViewDidAppear vs ViewWillAppear
    if (!IsEmpty(self.challenges) && IsEmpty([self.challengesPageViewController viewControllers])) {
        MTChallengeContentViewController *startingViewController = [self viewControllerAtIndex:self.challengesPageIndex];
        NSArray *viewControllers = @[startingViewController];
        [self.challengesPageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [MTUtil setLastViewedChallengedId:self.currentChallenge.objectId];
}

- (void)didReceiveMemoryWarnng
{
    [super didReceiveMemoryWarning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [MTUtil setLastViewedChallengedId:self.currentChallenge.objectId];
}


#pragma mark - Private Methods -
- (void)setupViews
{
    self.myClassPageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"myClassChallengePostsPageViewController"];
    self.myClassPageViewController.view.frame = ({
        CGRect newFrame = self.myClassPageViewController.view.frame;
        newFrame.size.height = self.myClassView.frame.size.height;
        newFrame;
    });

    self.myClassPageViewController.dataSource = self;
    self.myClassPageViewController.delegate = self;
    
    self.exploreCollectionView = [self.storyboard instantiateViewControllerWithIdentifier:@"exploreCollectionView"];
    self.exploreCollectionView.view.frame = self.myClassView.frame;
    
    self.myClassTableView = [self.storyboard instantiateViewControllerWithIdentifier:@"myClassChallengePostsTableView"];
    self.myClassTableView.view.frame = self.myClassView.frame;
    
    self.challengeInfoView = [self.storyboard instantiateViewControllerWithIdentifier:@"challengeInfoModal"];
    
    self.viewControllers = @[self.myClassTableView, self.exploreCollectionView];
    self.pageViewControllers = @[self.myClassTableView];
    
    [self.myClassPageViewController setViewControllers:self.pageViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.myClassPageViewController];
    [self.myClassView addSubview:self.myClassPageViewController.view];
    [self.myClassPageViewController didMoveToParentViewController:self];
    
    [self.myFeedButton setBackgroundImage:[UIImage imageWithColor:[UIColor challengeViewToggleButtonBackgroundNormal] size:self.myFeedButton.frame.size] forState:UIControlStateNormal];
    [self.myFeedButton setBackgroundImage:[UIImage imageWithColor:[UIColor challengeViewToggleButtonBackgroundHighlighted] size:self.myFeedButton.frame.size] forState:UIControlStateHighlighted];
    [self.myFeedButton setBackgroundImage:[UIImage imageWithColor:[UIColor challengeViewToggleButtonBackgroundSelected] size:self.myFeedButton.frame.size] forState:UIControlStateSelected];
    [self.myFeedButton setTitleColor:[UIColor challengeViewToggleButtonTitleNormal] forState:UIControlStateNormal];
    [self.myFeedButton setTitleColor:[UIColor challengeViewToggleButtonTitleHighlighted] forState:UIControlStateHighlighted];
    [self.myFeedButton setTitleColor:[UIColor challengeViewToggleButtonTitleSelected] forState:UIControlStateSelected];
    self.myFeedButton.selected = YES;

    [self.exploreButton setBackgroundImage:[UIImage imageWithColor:[UIColor challengeViewToggleButtonBackgroundNormal] size:self.myFeedButton.frame.size] forState:UIControlStateNormal];
    [self.exploreButton setBackgroundImage:[UIImage imageWithColor:[UIColor challengeViewToggleButtonBackgroundHighlighted] size:self.myFeedButton.frame.size] forState:UIControlStateHighlighted];
    [self.exploreButton setBackgroundImage:[UIImage imageWithColor:[UIColor challengeViewToggleButtonBackgroundSelected] size:self.myFeedButton.frame.size] forState:UIControlStateSelected];
    [self.exploreButton setTitleColor:[UIColor challengeViewToggleButtonTitleNormal] forState:UIControlStateNormal];
    [self.exploreButton setTitleColor:[UIColor challengeViewToggleButtonTitleHighlighted] forState:UIControlStateHighlighted];
    [self.exploreButton setTitleColor:[UIColor challengeViewToggleButtonTitleSelected] forState:UIControlStateSelected];
    
    [self.myFeedHighlightView setBackgroundColor:[UIColor primaryGreen]];
    [self.exploreHighlightView setBackgroundColor:[UIColor challengeViewToggleHighlightNormal]];
    
    self.challengeListView = [self.storyboard instantiateViewControllerWithIdentifier:@"challengeListModal"];
    self.challengeListView.delegate = self;

    self.challengeListView.view.frame = ({
        CGRect newFrame = self.myClassView.frame;
        newFrame.origin.y = -self.myClassView.frame.size.height;
        newFrame.size.height = self.view.frame.size.height - self.challengesView.frame.size.height;
        newFrame;
    });
    
    [self addChildViewController:self.challengeListView];
    [self.view insertSubview:self.challengeListView.view belowSubview:self.challengesView];
    
    self.challengeListView.tableView.scrollsToTop = NO;
    self.exploreCollectionView.collectionView.scrollsToTop = NO;
    self.myClassTableView.tableView.scrollsToTop = YES;
}

- (void)updateViews
{
    if (self.shouldLoadPreviousChallenge) {
        self.shouldLoadPreviousChallenge = NO;
        
        PFChallenges *challengeToGoTo = nil;
        if (!IsEmpty(self.actionableChallengeId)) {
            // If we're at this challenge, no need to animate
            if ([self.actionableChallengeId isEqualToString:self.currentChallenge.objectId]) {
                // do nothing
            }
            else {
                for (PFChallenges *thisChallenge in self.challenges) {
                    if ([thisChallenge.objectId isEqualToString:self.actionableChallengeId]) {
                        challengeToGoTo = thisChallenge;
                        break;
                    }
                }
            }
        }
        else if (!IsEmpty([MTUtil lastViewedChallengeId])) {
            NSString *lastOne = [MTUtil lastViewedChallengeId];
            
            if (!IsEmpty(lastOne)) {
                // If first Challenge, no need to go to that one
                PFChallenges *firstChallenge = [self.challenges firstObject];
                if ([firstChallenge.objectId isEqualToString:lastOne]) {
                    // do nothing
                }
                else {
                    for (PFChallenges *thisChallenge in self.challenges) {
                        if ([thisChallenge.objectId isEqualToString:lastOne]) {
                            challengeToGoTo = thisChallenge;
                            break;
                        }
                    }
                }
            }
        }
        
        // Reset to avoid infinite loop
        [MTUtil setLastViewedChallengedId:nil];
        self.actionableChallengeId = nil;
        
        if (challengeToGoTo) {
            self.currentChallenge = challengeToGoTo;
            [self loadChallenge:self.currentChallenge withIndex:[self.challenges indexOfObject:self.currentChallenge] toggleChallengeList:NO];
        }
    }
    
    self.myClassTableView.challenge = self.currentChallenge;
    self.exploreCollectionView.challenge = self.currentChallenge;
    self.challengeInfoView.challenge = self.currentChallenge;
}

- (void)toggleFeedExploreControl
{
    if (self.myFeedButton.selected) {
        self.myClassTableView.tableView.scrollsToTop = NO;
        self.exploreCollectionView.collectionView.scrollsToTop = YES;
        
        self.exploreButton.selected = YES;
        self.myFeedButton.selected = NO;
        self.exploreHighlightView.backgroundColor = [UIColor primaryGreen];
        self.myFeedHighlightView.backgroundColor = [UIColor challengeViewToggleHighlightNormal];
    }
    else {
        self.exploreCollectionView.collectionView.scrollsToTop = NO;
        self.myClassTableView.tableView.scrollsToTop = YES;

        self.myFeedButton.selected = YES;
        self.exploreButton.selected = NO;
        self.myFeedHighlightView.backgroundColor = [UIColor primaryGreen];
        self.exploreHighlightView.backgroundColor = [UIColor challengeViewToggleHighlightNormal];
    }
}

- (void)loadEmoji
{
    PFQuery *query = [PFQuery queryWithClassName:[PFEmoji parseClassName] predicate:nil];
    query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    [query orderByAscending:@"emoji_order"];
    
    MTMakeWeakSelf();
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            weakSelf.emojiObjects = objects;
            weakSelf.myClassTableView.emojiObjects = weakSelf.emojiObjects;
            [weakSelf.myClassTableView.tableView reloadData];
        } else {
            NSLog(@"Error getting Explore challenges: %@", [error localizedDescription]);
        }
    }];
}

- (void)loadChallenge:(PFChallenges *)challenge withIndex:(NSInteger)index toggleChallengeList:(BOOL)toggleChallengeList
{
    UIPageViewControllerNavigationDirection direction = UIPageViewControllerNavigationDirectionForward;
    if (index < self.challengesPageIndex) {
        direction = UIPageViewControllerNavigationDirectionReverse;
    }
    self.challengesPageIndex = index;
    
    MTChallengeContentViewController *newViewController = [self viewControllerAtIndex:self.challengesPageIndex];
    NSArray *viewControllers = @[newViewController];
    [self.challengesPageViewController setViewControllers:viewControllers direction:direction animated:YES completion:nil];
    
    self.currentChallenge = [self.challenges objectAtIndex:self.challengesPageIndex];
    [self updateViews];
    
    if (toggleChallengeList) {
        [self didTapChallengeList];
    }
}


#pragma mark - Load Challenges Private Methods -
- (void)loadChallenges
{
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
    PFQuery *allCustomChallenges = [PFQuery queryWithClassName:[PFPlaylistChallenges parseClassName]];
    [allCustomChallenges whereKey:@"playlist" equalTo:playlist];
    [allCustomChallenges orderByAscending:@"ordering"];
    [allCustomChallenges includeKey:@"challenge"];
    
    MTMakeWeakSelf();
    [allCustomChallenges findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            MBProgressHUD *currentHUD = [MBProgressHUD HUDForView:[UIApplication sharedApplication].keyWindow];
            if ([currentHUD.labelText isEqualToString:@"Updating Challenges..."] || [currentHUD.labelText isEqualToString:@"Loading Challenges..."]) {
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            }
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
            if (!weakSelf.challengesPageViewController) {
                weakSelf.challengesPageViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"ChallengeContentPageViewController"];
                CGRect frame = weakSelf.challengesPageViewController.view.frame;
                frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 84.0f);
                weakSelf.challengesPageViewController.view.frame = frame;
                weakSelf.challengesPageViewController.dataSource = weakSelf;
                weakSelf.challengesPageViewController.delegate = weakSelf;
                
                MTChallengeContentViewController *startingViewController = [weakSelf viewControllerAtIndex:0];
                NSArray *viewControllers = @[startingViewController];
                [weakSelf.challengesPageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
                
                [weakSelf addChildViewController:weakSelf.challengesPageViewController];
                [weakSelf.challengesView addSubview:weakSelf.challengesPageViewController.view];
                [weakSelf.challengesPageViewController didMoveToParentViewController:weakSelf];
            }
            else {
                MTChallengeContentViewController *startingViewController = [weakSelf viewControllerAtIndex:0];
                NSArray *viewControllers = @[startingViewController];
                [weakSelf.challengesPageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
            }
            
            if (!IsEmpty(weakSelf.challenges)) {
                weakSelf.currentChallenge = [weakSelf.challenges objectAtIndex:0];
            }
            
            [weakSelf updateViews];
        }
        else {
            NSLog(@"Unable to load custom challenges");
        }
    }];
}

- (void)loadDefaultChallenges
{
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
            if (!weakSelf.challengesPageViewController) {
                weakSelf.challengesPageViewController = [weakSelf.storyboard instantiateViewControllerWithIdentifier:@"ChallengeContentPageViewController"];
                CGRect frame = weakSelf.challengesPageViewController.view.frame;
                frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 84.0f);
                weakSelf.challengesPageViewController.view.frame = frame;
                weakSelf.challengesPageViewController.dataSource = weakSelf;
                weakSelf.challengesPageViewController.delegate = weakSelf;
                
                MTChallengeContentViewController *startingViewController = [weakSelf viewControllerAtIndex:0];
                NSArray *viewControllers = @[startingViewController];
                [weakSelf.challengesPageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
                
                [weakSelf addChildViewController:weakSelf.challengesPageViewController];
                [weakSelf.challengesView addSubview:weakSelf.challengesPageViewController.view];
                [weakSelf.challengesPageViewController didMoveToParentViewController:weakSelf];
            }
            else {
                MTChallengeContentViewController *startingViewController = [weakSelf viewControllerAtIndex:0];
                NSArray *viewControllers = @[startingViewController];
                [weakSelf.challengesPageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
            }
            
            if (!IsEmpty(weakSelf.challenges)) {
                weakSelf.currentChallenge = [weakSelf.challenges objectAtIndex:0];
            }
            
            [weakSelf updateViews];
        }
    }];
}

- (MTChallengeContentViewController *)viewControllerAtIndex:(NSUInteger)index
{
    if (([self.challenges count] <= 0) || (index >= [self.challenges count])) {
        return nil;
    }
    
    // Create a new view controller and pass suitable data.
    MTChallengeContentViewController *challengeContentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"ChallengeContentViewController"];
    CGRect frame = self.challengesPageViewController.view.frame;
    frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, 84.0f);
    challengeContentViewController.view.frame = frame;
    
    PFChallenges *challenge = self.challenges[index];
    
    challengeContentViewController.challengeTitleText = challenge[@"title"];
    challengeContentViewController.pageIndex = index;
    challengeContentViewController.challenge = challenge;
    challengeContentViewController.challenges = self.challenges;
    
    challengeContentViewController.leftButton.enabled = YES;
    challengeContentViewController.rightButton.enabled = YES;
    challengeContentViewController.delegate = self;

    if (index == 0) {
        challengeContentViewController.leftButton.enabled = NO;
    }
    
    if (index == [self.challenges count]-1) {
        challengeContentViewController.rightButton.enabled = NO;
    }
    
    return challengeContentViewController;
}


#pragma mark - Actions -
- (IBAction)myFeedButtonAction:(id)sender
{
    if (!self.myFeedButton.selected) {
        [self toggleFeedExploreControl];
        
        self.pageViewControllers = @[self.myClassTableView];
        [self.myClassPageViewController setViewControllers:self.pageViewControllers direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:nil];
    }
}

- (IBAction)exploreButtonAction:(id)sender
{
    if (!self.exploreButton.selected) {
        [self toggleFeedExploreControl];
        
        self.pageViewControllers = @[self.exploreCollectionView];
        [self.myClassPageViewController setViewControllers:self.pageViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    }
}

- (void)postCommentTapped
{
    if (![MTUtil internetReachable]) {
        [UIAlertView showNoInternetAlert];
        return;
    }
    
    self.navigationItem.title = @"Cancel";
    [self performSegueWithIdentifier:@"commentSegue" sender:self];
}

- (void)dismissCommentView
{
}

- (IBAction) unwindToChallengeRoom:(UIStoryboardSegue*) sender
{
    // segue from MTCommentViewController
}


#pragma mark - UIPageViewControllerDataSource/Delegate Methods -
- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (pageViewController == self.myClassPageViewController) {
        [self myClassPageViewController:pageViewController didFinishAnimating:finished previousViewControllers:previousViewControllers transitionCompleted:completed];
    }
    else {
        [self challengesPageViewController:pageViewController didFinishAnimating:finished previousViewControllers:previousViewControllers transitionCompleted:completed];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    if (pageViewController == self.myClassPageViewController) {
        // do nothing
    }
    else {
        [self challengesPageViewController:pageViewController willTransitionToViewControllers:pendingViewControllers];
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    if (pageViewController == self.myClassPageViewController) {
        return [self myClassPageViewController:pageViewController viewControllerBeforeViewController:viewController];
    }
    else {
        return [self challengesPageViewController:pageViewController viewControllerBeforeViewController:viewController];
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if (pageViewController == self.myClassPageViewController) {
        return [self myClassPageViewController:pageViewController viewControllerAfterViewController:viewController];
    }
    else {
        return [self challengesPageViewController:pageViewController viewControllerAfterViewController:viewController];
    }

}

- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    // return 0 to remove paging dots
    if (pageViewController == self.myClassPageViewController) {
        return 0;
    }
    else {
        return [self challengesPresentationCountForPageViewController:pageViewController];
    }
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    if (pageViewController == self.myClassPageViewController) {
        return 0;
    }
    else {
        return [self challengesPresentationIndexForPageViewController:pageViewController];
    }
}


#pragma mark - MyClass/Explore UIPageViewControllerDataSource/Delegate Methods -
- (void)myClassPageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        if ([[[pageViewController viewControllers] firstObject] isKindOfClass:[MTMyClassTableViewController class]]) {
            [self myFeedButtonAction:self.myFeedButton];
        }
        else {
            [self exploreButtonAction:self.exploreButton];
        }
    }
}

- (UIViewController *)myClassPageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    
    index--;
    return self.viewControllers[index];
}

- (UIViewController *)myClassPageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSUInteger index = [self.viewControllers indexOfObject:viewController];
    
    if (index == NSNotFound) {
        return nil;
    }
    
    index++;
    if (index == [self.viewControllers count]) {
        return nil;
    }
    
    return self.viewControllers[index];
}


#pragma mark - Challenges UIPageViewControllerDataSource/Delegate Methods -
- (void)challengesPageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    self.challengesPendingIndex = ((MTChallengeContentViewController *)[pendingViewControllers firstObject]).pageIndex;
}

- (void)challengesPageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed) {
        self.challengesPageIndex = self.challengesPendingIndex;
        if ((self.challengesPageIndex == 0) || (self.challengesPageIndex >= self.challenges.count)) {
            self.challengeContentViewControllerBefore = nil;
        } else {
            self.challengeContentViewControllerBefore = [self viewControllerAtIndex:(self.challengesPageIndex - 1)];
        }
        
        if (self.challengesPageIndex >= (self.challenges.count - 1)) {
            self.challengeContentViewControllerAfter = nil;
        } else {
            self.challengeContentViewControllerAfter = [self viewControllerAtIndex:(self.challengesPageIndex + 1)];
        }
        
        if ([self.challenges count] > self.challengesPageIndex) {
            [self closeChallengeList];
            self.currentChallenge = [self.challenges objectAtIndex:self.challengesPageIndex];
            [self updateViews];
        }
    }
}

- (UIViewController *)challengesPageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    return self.challengeContentViewControllerBefore;
}

- (UIViewController *)challengesPageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    return self.challengeContentViewControllerAfter;
}

- (NSInteger)challengesPresentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.challenges count];
}

- (NSInteger)challengesPresentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    if (self.challengesPageIndex == 0) {
        self.challengeContentViewControllerBefore = nil;
        self.challengeContentViewControllerAfter = [self viewControllerAtIndex:1];
    }
    else if (self.challengesPageIndex == [self.challenges count]-1) {
        self.challengeContentViewControllerBefore = [self viewControllerAtIndex:self.challengesPageIndex-1];
        self.challengeContentViewControllerAfter = nil;
    }
    else {
        self.challengeContentViewControllerBefore = [self viewControllerAtIndex:self.challengesPageIndex-1];
        self.challengeContentViewControllerAfter = [self viewControllerAtIndex:self.challengesPageIndex+1];
    }
    
    return self.challengesPageIndex;
}


#pragma mark - MTChallengeContentViewControllerDelegate Methods -
- (void)leftButtonTapped
{
    [self closeChallengeList];
    self.challengesPageIndex--;
    
    MTChallengeContentViewController *newViewController = [self viewControllerAtIndex:self.challengesPageIndex];
    NSArray *viewControllers = @[newViewController];
    [self.challengesPageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:nil];
    
    self.currentChallenge = [self.challenges objectAtIndex:self.challengesPageIndex];
    [self updateViews];
}

- (void)rightButtonTapped
{
    [self closeChallengeList];
    self.challengesPageIndex++;
    
    MTChallengeContentViewController *newViewController = [self viewControllerAtIndex:self.challengesPageIndex];
    NSArray *viewControllers = @[newViewController];
    [self.challengesPageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    
    self.currentChallenge = [self.challenges objectAtIndex:self.challengesPageIndex];
    [self updateViews];
}

- (void)didSelectChallenge:(PFChallenges *)challenge withIndex:(NSInteger)index
{
    [self loadChallenge:challenge withIndex:index toggleChallengeList:YES];
}

- (void)closeChallengeList
{
    if (self.challengeListView.view.frame.origin.y > 0.0f) {
        [self didTapChallengeList];
    }
}

- (void)didTapChallengeList
{
    if (self.challengeListView.view.frame.origin.y > 0.0f) {
        // Hide
        self.challengeListView.tableView.scrollsToTop = NO;
        if (!self.myFeedButton.selected) {
            self.myClassTableView.tableView.scrollsToTop = NO;
            self.exploreCollectionView.collectionView.scrollsToTop = YES;
        }
        else {
            self.exploreCollectionView.collectionView.scrollsToTop = NO;
            self.myClassTableView.tableView.scrollsToTop = YES;
        }
        [UIView animateWithDuration:0.3f animations:^{
            self.challengeListView.view.frame = ({
                CGRect newFrame = self.challengeListView.view.frame;
                newFrame.origin.y = -self.challengeListView.view.frame.size.height;
                newFrame;
            });
        } completion:^(BOOL finished) {
            [self.view bringSubviewToFront:self.myClassView];
            [self.view bringSubviewToFront:self.feedExploreToggleView];
        }];
    }
    else {
        // Show
        self.myClassTableView.tableView.scrollsToTop = NO;
        self.exploreCollectionView.collectionView.scrollsToTop = NO;
        self.challengeListView.tableView.scrollsToTop = YES;

        [self.view sendSubviewToBack:self.myClassView];
        [self.view sendSubviewToBack:self.feedExploreToggleView];
        self.challengeListView.challenges = self.challenges;
        self.challengeListView.currentChallenge = self.currentChallenge;

        [UIView animateWithDuration:0.3f animations:^{
            self.challengeListView.view.frame = ({
                CGRect newFrame = self.challengeListView.view.frame;
                newFrame.origin.y = self.challengesView.frame.size.height;
                newFrame;
            });
        }];
    }
}


#pragma mark - Notifications -
- (void)userDidChangeClass:(NSNotification *)notif
{
    self.userChangedClass = YES;
    self.challenges = nil;
}


#pragma mark - Navigation -
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueID = [segue identifier];
    
    if ([segueID isEqualToString:@"commentSegue"]) {
        MTCommentViewController *destinationVC = (MTCommentViewController *)[segue destinationViewController];
        destinationVC.challenge = self.currentChallenge;
        destinationVC.delegate = self;
    }
}


@end
