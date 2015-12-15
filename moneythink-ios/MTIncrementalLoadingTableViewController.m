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

NSInteger totalItems = -1;

#pragma mark - View Methods
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentPage = 0;
    self.pageSize = 10;

    if (self.loadingView == nil) {
        CGPoint origin = self.tableView.frame.origin;
        MTLoadingView *loadingView = [[MTLoadingView alloc] initWithFrame:CGRectMake(origin.x, origin.y, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
        loadingView.layer.zPosition++;
        [self.view addSubview:loadingView];
        self.loadingView = loadingView;
    }
    [self.loadingView setMessage:@"Loading latest posts..."];
    [self.loadingView startLoading];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.loadingView setHidden:self.results.count > 0];
    [self loadLocalResults:^(NSError *error) {
        if (error == nil) {
            [self.loadingView stopLoadingSuccessfully:YES];
        }
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self configureRefreshController];
    [self configureLoadMoreController];
}

- (void)resetResults {
    self.results = nil;
    self.currentPage = 0;
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
- (void)willLoadRemoteResultsForCurrentPage {
    if (IsEmpty(self.results) && self.refreshController.refreshState == JYRefreshStateStop) {
        [self.loadingView startLoading];
    }
}
- (void)didLoadRemoteResultsWithSuccessfulResponse:(struct MTIncrementalLoadingResponse)response
{
    MTMakeWeakSelf();
    totalItems = response.totalCount;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.loadingView stopLoadingSuccessfully:totalItems > 0];
        
        if (self.refreshController.refreshState == JYRefreshStateLoading) {
            BOOL shouldAnimate = self.results.count > 0; // Refreshing existing feed?
            [self.refreshController stopRefreshWithAnimated:shouldAnimate completion:nil];
        }
        if (self.loadMoreController.loadMoreState == JYLoadMoreStateLoading) {
            [self.loadMoreController stopLoadMoreCompletion:nil];
        }
        NSLog(@"Loaded page %lu of %lu", (unsigned long)self.currentPage, (unsigned long)response.numPages);
        if (!response.lastPage && response.numPages > 0) {
            self.currentPage++;
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
        [self.loadingView stopLoadingSuccessfully:weakSelf.results.count > 0];
    });
}

- (void)didLoadLocalResults:(RLMResults *)results withCallback:(MTSuccessBlock)callback {
    MTMakeWeakSelf();
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.results = results;
        
        if (weakSelf.currentPage == 0) {
            if (weakSelf.results.count == 0) {
                weakSelf.currentPage = 1;
            } else {
                weakSelf.currentPage = (weakSelf.results.count / weakSelf.pageSize) + 1;
                NSLog(@"%@: Starting page is %lu", NSStringFromClass([weakSelf class]), (unsigned long)weakSelf.currentPage);
            }
        }
        
        if (weakSelf.results.count > 0) {
            [weakSelf.loadingView setHidden:YES];
            if ([weakSelf.tableView numberOfRowsInSection:0] > 0) {
                [weakSelf.tableView beginUpdates];
                [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
                [weakSelf.tableView endUpdates];
            } else {
                [weakSelf.tableView reloadData];
            }
        } else {
            [weakSelf.loadingView setHidden:NO];
            [weakSelf.tableView reloadData]; // Empty it out
        }
        
        [weakSelf.refreshController stopRefreshWithAnimated:YES completion:nil];
        
        if (callback != nil) {
            callback(nil);
        }
    });
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
    if (self.refreshController || self.refreshControllerRefreshView) {
        return;
    }
    
    self.refreshController = [[JYPullToRefreshController alloc] initWithScrollView:self.tableView];
    
    MTRefreshView *refreshView = [[MTRefreshView alloc] initWithFrame:CGRectMake(0,0,self.tableView.frame.size.width, 44.0f)];
    [self.refreshController setCustomView:refreshView];
    self.refreshControllerRefreshView = refreshView;
    
    MTMakeWeakSelf();
    self.refreshController.pullToRefreshHandleAction = ^{
        [weakSelf handlePullToRefresh];
    };
}

- (void)configureLoadMoreController {
    if (self.loadMoreController || self.loadMoreControllerRefreshView) return;
    
    self.loadMoreController = [[JYPullToLoadMoreController alloc] initWithScrollView:self.tableView];
    self.loadMoreController.autoLoadMore = NO;
    
    MTRefreshView *refreshView = [[MTRefreshView alloc] initWithFrame:CGRectMake(0,0,self.tableView.frame.size.width, 44.0f)];
    [self.loadMoreController setCustomView:refreshView];
    self.loadMoreControllerRefreshView = refreshView;
    
    MTMakeWeakSelf();
    self.loadMoreController.pullToLoadMoreHandleAction = ^{
        [weakSelf handlePullToLoadMore];
    };
}

#pragma mark - Handlers
- (void)handlePullToRefresh {
    self.currentPage = 1;
    [self loadRemoteResultsForCurrentPage];
}

- (void)handlePullToLoadMore {
    if (self.results.count > 0) {
        [self loadRemoteResultsForCurrentPage];
    }
}

@end
