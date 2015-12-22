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
#define kAllSchoolsSection 0
#define kClassesSection 1

@interface MTClassSelectionViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *saveButton;

- (MTClass *)selectedClass;
- (void)setSelectedClass:(MTClass *)selectedClass;

- (MTOrganization *)selectedOrganization;
- (NSString *)mentorCode;

- (void)handleError:(NSError *)error;

- (void)saveAndDismiss;

@end

@implementation MTClassSelectionViewController

- (void)viewDidLoad {
    self.loadingMessage = @"Loading classes...";
    [super viewDidLoad];
    
    self.title = @"Change Class";
    self.navigationItem.hidesBackButton = YES;
    
    self.tableView.sectionIndexColor = [UIColor lightGrey];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    
    [self loadLocalResults];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Scroll the table view to selected class
    
    [self loadRemoteResultsForCurrentPage];
    
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
    
    RLMResults *results = [[MTClass objectsWhere:@"organization.id = %d", self.selectedOrganization.id] sortedResultsUsingProperty:@"name" ascending:YES];
    
    [self didLoadLocalResults:results withCallback:nil];
}

- (void)loadRemoteResultsForCurrentPage {
    [self willLoadRemoteResultsForCurrentPage];
    
    MTMakeWeakSelf();
    if (self.selectedOrganization.id != [MTUser currentUser].organization.id) {
        [[MTNetworkManager sharedMTNetworkManager] getClassesWithSignupCode:self.mentorCode organizationId:self.selectedOrganization.id page:self.currentPage success:^(BOOL lastPage, NSUInteger numPages, NSUInteger totalCount) {
            [weakSelf loadLocalResults];
            [self didLoadRemoteResultsSuccessfullyWithLastPage:lastPage numPages:numPages totalCount:totalCount];
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf handleError:error];
            });
        }];
    }
    else {
        [[MTNetworkManager sharedMTNetworkManager] getClassesWithPage:self.currentPage success:^(BOOL lastPage, NSUInteger numPages, NSUInteger totalCount) {
            [weakSelf loadLocalResults];
            [self didLoadRemoteResultsSuccessfullyWithLastPage:lastPage numPages:numPages totalCount:totalCount];
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf handleError:error];
            });
        }];
    }
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == kAllSchoolsSection) {
        return nil;
    } else {
        return [NSString stringWithFormat:@"Classes in %@", self.selectedOrganization.name];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kAllSchoolsSection) {
        return 1;
    } else {
        return self.results.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    if (indexPath.section == kAllSchoolsSection) {
        NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"← All Schools" attributes:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0f]}];
        cell.textLabel.attributedText = title;
        cell.selected = false;
        return cell;
    }
    
    MTClass *class = [self.results objectAtIndex:indexPath.row];
    cell.textLabel.text = class.name;
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([class isEqual:self.selectedClass]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kAllSchoolsSection) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        // Update the mentor's class
        
        NSUInteger row = [self.results indexOfObject:self.selectedClass];
        
        MTClass *class = (MTClass *)self.results[indexPath.row];
        self.selectedClass = class;
        self.saveButton.enabled = YES;
        
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:kClassesSection]] withRowAnimation:UITableViewRowAnimationNone];
        
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [MTUtil englishAlphabet];
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
- (void)handleError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Unable to load classes. Please check your Internet connection. If this issue happens more than once, please contact us!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    [self didLoadRemoteResultsWithError:error];
}

#pragma mark - MTIncrementalLoading configuration
- (BOOL)shouldConfigureRefreshController {
    return NO;
}

- (NSUInteger)incrementallyLoadedSectionIndex {
    return 1;
}

#pragma mark - Handle Saves
- (void)saveAndDismiss {
    MTUser *user = [MTUser currentUser];
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    [realm beginWriteTransaction];
    user.userClass = self.selectedClass;
    [realm commitWriteTransaction];
    
    [self performSegueWithIdentifier:@"dismiss" sender:self];
}

- (IBAction)saveAction:(UIBarButtonItem *)sender {
    [self saveAndDismiss];
}

@end
