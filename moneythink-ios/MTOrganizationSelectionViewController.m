//
//  MTOrganizationSelectionViewController.m
//  moneythink-ios
//
//  Created by Colin Young on 12/18/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import "MTOrganizationSelectionViewController.h"
#import "MTClassSelectionViewController.h"
#import "MTClassSelectionNavigationController.h"

#define kCellIdentifier @"Organization Name Cell"
#define kOrganizationSelectedIdentifier @"organizationSelected"

@interface MTOrganizationSelectionViewController ()

- (NSIndexPath *)resultIndexPath:(RLMObject *)object;

@end

@implementation MTOrganizationSelectionViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.pageSize = 50;
    self.loadingResourceName = @"organizations";    
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.prompt = self.selectedOrganization.name;

    // Immediately push to class selection so that this nav controller opens in the second view
    UIStoryboard *sb = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    MTClassSelectionViewController *selectClassController = [sb instantiateViewControllerWithIdentifier:@"MTClassSelectionViewController"];
    
    [self.navigationController pushViewController:selectClassController animated:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.currentPage = 0;
    
    [self loadLocalResults];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self loadRemoteResultsForCurrentPage];
    
    [MTUtil GATrackScreen:@"Edit Profile: Select Organization"];
}

- (void)loadLocalResults:(MTSuccessBlock)callback {
    if ([MTUser currentUser] == nil) return;
    
    RLMResults *results;
//    if (!IsEmpty(self.currentSearchText)) {
//        results = [[MTOrganization objectsWhere:@"name CONTAINS %@", self.currentSearchText] sortedResultsUsingProperty:@"name" ascending:YES];
//    } else {
        results = [[MTOrganization allObjects] sortedResultsUsingProperty:@"name" ascending:YES];
//    }

    [self didLoadLocalResults:results withCallback:^(NSError *error) {
        if (!IsEmpty(self.results)) {
            NSIndexPath *selectedPath = [self resultIndexPath:self.selectedOrganization];
            if (selectedPath != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView scrollToRowAtIndexPath:selectedPath atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
                });
            }
        }
    }];
}

- (void)loadRemoteResultsForCurrentPage {
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] getOrganizationsWithSignupCode:self.mentorCode page:self.currentPage success:^(BOOL lastPage, NSUInteger numPages, NSUInteger totalCount) {
        [weakSelf loadLocalResults];
        [weakSelf didLoadRemoteResultsSuccessfullyWithLastPage:lastPage numPages:numPages totalCount:totalCount];
        
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf handleError:error];
        });
    }];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    MTClass *organization = self.results[indexPath.row];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    if ([organization isEqual:self.selectedOrganization]) {
        NSAttributedString *boldName = [[NSAttributedString alloc] initWithString:organization.name attributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0f]}];
        cell.textLabel.attributedText = boldName;
    } else {
        NSAttributedString *name = [[NSAttributedString alloc] initWithString:organization.name attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:16.0f]}];
        cell.textLabel.attributedText = name;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MTOrganization *organization = (MTOrganization *)self.results[indexPath.row];
    self.navigationItem.prompt = organization.name;
    
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
        // Update the mentor's class
    MTOrganization *organization = (MTOrganization *)self.results[indexPath.row];
    [self setSelectedOrganization:organization];
    [self performSegueWithIdentifier:kOrganizationSelectedIdentifier sender:self];
}

#pragma mark - Accessors of changes to be made
 - (MTOrganization *)selectedOrganization {
     return ((MTClassSelectionNavigationController *)self.navigationController).selectedOrganization;
 }

- (void)setSelectedOrganization:(MTOrganization *)selectedSelection {
    ((MTClassSelectionNavigationController *)self.navigationController).selectedOrganization = selectedSelection;
}

- (NSString *)mentorCode {
    return ((MTClassSelectionNavigationController *)self.navigationController).mentorCode;
}

#pragma mark - private methods
- (void)handleError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Unable to load organizations. Please check your Internet connection. If this issue happens more than once, please contact us!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    [self didLoadRemoteResultsWithError:error];
}

#pragma mark - MTIncrementalLoading configuration
- (BOOL)shouldConfigureRefreshController {
    return NO;
}

- (BOOL)shouldAutomaticallyLoadMore {
    return YES;
}

#pragma mark - PRivate methods
- (NSIndexPath *)resultIndexPath:(RLMObject *)object {
    NSInteger resultIndex = [self.results indexOfObject:object];
    if (resultIndex != NSNotFound) {
        return [NSIndexPath indexPathForRow:resultIndex inSection:0];
    }
    return nil;
}

@end
