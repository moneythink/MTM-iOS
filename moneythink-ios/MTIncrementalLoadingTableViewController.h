//
//  MTIncrementalLoadingTableViewController.h
//  moneythink-ios
//
//  Created by Colin Young on 12/9/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

struct MTIncrementalLoadingResponse {
    BOOL lastPage;
    NSUInteger numPages;
    NSUInteger totalCount;
};

@interface MTIncrementalLoadingTableViewController : UITableViewController <UIScrollViewDelegate>

@property (strong, nonatomic) RLMResults *results;
@property (assign, nonatomic) NSUInteger currentPage;
@property (assign, nonatomic) NSUInteger pageSize;

@property (assign, nonatomic) NSString   *loadingMessage;

- (void)loadLocalResults:(MTSuccessBlock)callback;
- (void)loadLocalResults;
- (void)loadRemoteResultsForCurrentPage;

- (void)willLoadRemoteResultsForCurrentPage;
- (void)didLoadRemoteResultsWithSuccessfulResponse:(struct MTIncrementalLoadingResponse)response;
- (void)didLoadRemoteResultsSuccessfullyWithLastPage:(BOOL)lastPage numPages:(NSUInteger)numPages totalCount:(NSUInteger)totalCount;
- (void)didLoadRemoteResultsWithError:(NSError *)error;
- (void)didLoadLocalResults:(RLMResults *)results withCallback:(MTSuccessBlock)callback;

- (void)handlePullToRefresh;
- (void)handlePullToLoadMore;

- (void)resetResults;

- (BOOL)shouldConfigureRefreshController;
- (BOOL)shouldConfigureLoadMoreController;
- (NSUInteger)incrementallyLoadedSectionIndex;

@end
