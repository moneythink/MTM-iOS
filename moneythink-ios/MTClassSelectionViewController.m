//
//  MTClassSelectionViewController.m
//  moneythink-ios
//
//  Created by Colin Young on 12/18/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import "MTClassSelectionViewController.h"
#import "MTClassSelectionNavigationController.h"

#define kCellIdentifier @"Class Name Cell"

@interface MTClassSelectionViewController ()

- (MTClass *)selectedClass;
- (void)setSelectedClass:(MTClass *)selectedClass;

- (MTOrganization *)selectedOrganization;
- (NSString *)mentorCode;

- (void)handleError;

@end

@implementation MTClassSelectionViewController

- (void)viewDidLoad {
    self.loadingMessage = @"Loading classes...";
    [super viewDidLoad];
    
    self.title = self.selectedClass.name;
    self.navigationItem.hidesBackButton = YES;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    
    [self loadLocalResults];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [MTUtil GATrackScreen:@"Edit Profile: Select Class"];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - MTIncrementalLoading
- (void)loadLocalResults:(MTSuccessBlock)callback {
    
    RLMResults *results = [[MTClass objectsWhere:@"organization.id = %d AND isDeleted = NO", self.selectedOrganization.id] sortedResultsUsingProperty:@"name" ascending:YES];
    
    [self didLoadLocalResults:results withCallback:nil];
}

- (void)loadRemoteResultsForCurrentPage {
    [self willLoadRemoteResultsForCurrentPage];
    
    MTMakeWeakSelf();
    if (self.selectedOrganization.id != [MTUser currentUser].organization.id) {
        [[MTNetworkManager sharedMTNetworkManager] getClassesWithSignupCode:self.mentorCode organizationId:self.selectedOrganization.id page:self.currentPage success:^(BOOL lastPage, NSUInteger numPages, NSUInteger totalCount) {
            [weakSelf loadLocalResults];
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf handleError];
            });
        }];
    }
    else {
        [[MTNetworkManager sharedMTNetworkManager] getClassesWithPage:self.currentPage success:^(BOOL lastPage, NSUInteger numPages, NSUInteger totalCount) {
            [weakSelf loadLocalResults];
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf handleError];
            });
        }];
    }
    
    [self didLoadRemoteResultsWithError:nil];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    MTClass *class = [self.results objectAtIndex:indexPath.row];
    cell.textLabel.text = class.name;
    cell.selected = [class isEqual:self.selectedClass];
    
    return cell;
}

#pragma mark - Accessors of changes to be made
- (MTClass *)selectedClass {
    return ((MTClassSelectionNavigationController *)self.navigationController).selectedClass;
}

- (void)setSelectedClass:(MTClass *)selectedClass {
    ((MTClassSelectionNavigationController *)self.navigationController).selectedClass = selectedClass;
}

- (MTOrganization *)selectedOrganization {
    return ((MTClassSelectionNavigationController *)self.navigationController).selectedOrganization;
}

- (NSString *)mentorCode {
    return ((MTClassSelectionNavigationController *)self.navigationController).mentorCode;
}

#pragma mark - private methods
- (void)handleError {
    [[[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Unable to load classes. Please check your Internet connection. If this issue happens more than once, please contact us!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

@end
