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

- (void)loadLocalResults:(MTSuccessBlock)callback;
- (void)loadLocalResults;
- (void)loadRemoteResultsForCurrentPage;

- (void)willLoadRemoteResultsForCurrentPage;
- (void)didLoadRemoteResultsWithSuccessfulResponse:(struct MTIncrementalLoadingResponse)response;
- (void)didLoadRemoteResultsWithError:(NSError *)error;
- (void)didLoadLocalResults:(RLMResults *)results withCallback:(MTSuccessBlock)callback;

- (void)handlePullToRefresh;
- (void)handlePullToLoadMore;

@end
