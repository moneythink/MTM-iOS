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

@interface MTIncrementalLoadingTableViewController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) RLMResults *results;

- (NSUInteger)currentPage;

- (void)loadLocalResults:(MTSuccessBlock)callback;
- (void)loadLocalResults;
- (void)loadRemoteResultsForCurrentPage;

- (void)didLoadRemoteResultsWithSuccessfulResponse:(struct MTIncrementalLoadingResponse)response;
- (void)didLoadRemoteResultsWithError:(NSError *)error;
- (void)didLoadLocalResults:(RLMResults *)results withCallback:(MTSuccessBlock)callback;

@end
