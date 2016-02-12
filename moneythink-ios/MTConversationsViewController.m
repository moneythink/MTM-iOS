//
//  MTConversationsViewController.m
//  moneythink-ios
//
//  Created by Colin Young on 2/4/16.
//  Copyright © 2016 Moneythink. All rights reserved.
//

#import "MTConversationsViewController.h"

@interface MTConversationsViewController () <LYRQueryControllerDelegate>

- (LYRClient *)client;
- (void)refresh:(id)sender;

@end

@implementation MTConversationsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self refresh:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (LYRClient *)client {
    return [[MTUtil getAppDelegate] layerClient];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Actions
- (void)refresh:(UIRefreshControl *)sender {
    LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRConversation class]];
    query.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:YES]];
    query.limit = 20;
    query.offset = 0;
    
    NSError *error;
    LYRQueryController *queryController = [self.client queryControllerWithQuery:query error:&error];
    queryController.delegate = self;
    
    MTMakeWeakSelf();
    [queryController executeWithCompletion:^(BOOL success, NSError *error) {
        [weakSelf.refreshControl endRefreshing];        
        if (success) {
            NSUInteger count = [queryController numberOfObjectsInSection:0];
            NSLog(@"LYR: %tu conversations", count);
        } else {
            NSLog(@"LYR: Query failed with error %@", error);
        }
    }];
}

#pragma mark - Storyboard
- (IBAction)unwindToConversations:(UIStoryboardSegue *)sender {
    
}

#pragma mark - LYRQueryControllerDelegate
- (void)queryController:(nonnull LYRQueryController *)controller didChangeObject:(nonnull id)object atIndexPath:(nullable NSIndexPath *)indexPath forChangeType:(LYRQueryControllerChangeType)type newIndexPath:(nullable NSIndexPath *)newIndexPath {
    
}

- (void)queryControllerWillChangeContent:(nonnull LYRQueryController *)queryController
{
    
}

- (void)queryControllerDidChangeContent:(nonnull LYRQueryController *)queryController {
    
}

@end
