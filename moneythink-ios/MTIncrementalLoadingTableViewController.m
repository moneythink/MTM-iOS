//
//  MTIncrementalLoadingTableViewController.m
//  moneythink-ios
//
//  Created by Colin Young on 12/9/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import "MTIncrementalLoadingTableViewController.h"
#import "MTLoadingView.h"
#import "JYPullToRefreshController.h"
#import "JYPullToLoadMoreController.h"
#import "MTRefreshView.h"

@interface MTIncrementalLoadingTableViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) IBOutlet MTLoadingView *loadingView;

@property (strong, nonatomic) JYPullToRefreshController *refreshController;
@property (strong, nonatomic) JYPullToLoadMoreController *loadMoreController;
@property (strong, nonatomic) MTRefreshView *refreshControllerRefreshView;
@property (strong, nonatomic) MTRefreshView *loadMoreControllerRefreshView;

- (void)configureRefreshController;
- (void)configureLoadMoreController;

@end

@implementation MTIncrementalLoadingTableViewController

NSUInteger currentPage = 1;
NSInteger totalItems = -1;

#pragma mark - View Methods
- (void)viewDidLoad {
    [super viewDidLoad];

    [self.loadingView setMessage:@"Loading latest posts..."];
    [self.loadingView setHidden:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // TODO: May want to release old results
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.loadingView setHidden:YES];
    [self loadLocalResults:^(NSError *error) {
        if (error == nil) {
            [self.loadingView setHidden:self.results.count > 0];
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self configureRefreshController];
    [self configureLoadMoreController];
}

#pragma mark - UITableViewController delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView // Default is 1 if not implemented
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.results == nil) return 0;
    NSInteger rows = [self.results count];
    return rows;
}

#pragma mark - UITableViewController datasource methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @throw @"Not implemented";
}

#pragma mark - Navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // TODO: Stop requests
}

#pragma mark - Loading
- (void)loadLocalResults {
    [self loadLocalResults:nil];
}

- (void)loadLocalResults:(MTSuccessBlock)callback {
    @throw @"Not implemented in subclass";
}

- (void)loadRemoteResultsForCurrentPage {
    @throw @"Not implemented in subclass";
}

#pragma mark - Clients should call these methods
- (void)didLoadRemoteResultsWithSuccessfulResponse:(struct MTIncrementalLoadingResponse)response
{
    MTMakeWeakSelf();
    totalItems = response.totalCount;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.loadingView setHidden:YES];
        
        if (self.refreshController.refreshState == JYRefreshStateLoading) {
            [self.refreshController stopRefreshWithAnimated:YES completion:nil];
        }
        if (self.loadMoreController.loadMoreState == JYLoadMoreStateLoading) {
            [self.loadMoreController stopLoadMoreCompletion:nil];
        }
        NSLog(@"Loaded page %lu of %lu", (unsigned long)currentPage, (unsigned long)response.numPages);
        if (!response.lastPage) {
            currentPage++;
        }
        [weakSelf loadLocalResults];
    });
}

- (void)didLoadRemoteResultsWithError:(NSError *)error {
    MTMakeWeakSelf();
    NSLog(@"%@: Unable to load results", NSStringFromClass([self class]));
    [self.refreshController stopRefreshWithAnimated:YES completion:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf loadLocalResults];
        [self.loadingView setIsLoading:NO];
        if (weakSelf.results.count == 0) {
            [self.loadingView setHidden:NO];
            [self.loadingView setMessage:@"No posts yet by this student."];
        } else {
            [self.loadingView setHidden:YES];
        }
    });
}

- (void)didLoadLocalResults:(RLMResults *)results withCallback:(MTSuccessBlock)callback {
    MTMakeWeakSelf();
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.results = results;
        [weakSelf.tableView beginUpdates];
        [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
        [weakSelf.tableView endUpdates];
        
        [weakSelf.refreshController stopRefreshWithAnimated:YES completion:nil];
        
        if (callback != nil) {
            callback(nil);
        }
    });
}

- (NSUInteger)currentPage {
    return currentPage;
}

#pragma mark - UIScrollViewDelegate
// MARK: UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y < 0) {
        [self.refreshControllerRefreshView scrollView:scrollView contentOffsetDidUpdate:scrollView.contentOffset];
    } else {
        [self.loadMoreControllerRefreshView scrollView:scrollView contentOffsetDidUpdate:scrollView.contentOffset];
    }
}

#pragma mark - Private Methods
- (void)configureRefreshController {
    if (self.refreshController || self.refreshControllerRefreshView) return;
    
    MTMakeWeakSelf();
    self.refreshController = [[JYPullToRefreshController alloc] initWithScrollView:self.tableView];
    
    MTRefreshView *refreshView = [[MTRefreshView alloc] initWithFrame:CGRectMake(0,0,self.tableView.frame.size.width, 44.0f)];
    [self.refreshController setCustomView:refreshView];
    self.refreshControllerRefreshView = refreshView;
    
    self.refreshController.pullToRefreshHandleAction = ^{
        currentPage = 1;
        [weakSelf loadRemoteResultsForCurrentPage];
    };
}

- (void)configureLoadMoreController {
    if (self.loadMoreController || self.loadMoreControllerRefreshView) return;
    
    MTMakeWeakSelf();
    self.loadMoreController = [[JYPullToLoadMoreController alloc] initWithScrollView:self.tableView];
    self.loadMoreController.autoLoadMore = NO;
    
    MTRefreshView *refreshView = [[MTRefreshView alloc] initWithFrame:CGRectMake(0,0,self.tableView.frame.size.width, 44.0f)];
    [self.loadMoreController setCustomView:refreshView];
    self.loadMoreControllerRefreshView = refreshView;
    
    self.loadMoreController.pullToLoadMoreHandleAction = ^{
        [weakSelf loadRemoteResultsForCurrentPage];
    };
}

@end
