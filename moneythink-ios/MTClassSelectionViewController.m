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
#define kActiveClassesSection 0
#define kArchivedClassesSection 1
#define kMentorCodeKey @"kMentorCodeKey"
#define kShowArchivedClassesText @"Show Archived Classes"

#define kAlertViewTag_MentorCode 1
#define kAlertViewTag_ConfirmSelect 2

#import "MTNoKeyboardAlertView.h"

@interface MTClassSelectionViewController ()

@property (strong, nonatomic) RLMResults *archivedResults;

@property (strong, nonatomic) MTClass *temporaryClassSelection; // Only used while we support UIAlertView.

- (MTClass *)selectedClass;
- (void)setSelectedClass:(MTClass *)selectedClass;
- (void)confirmSelectClass:(MTClass *)class atIndexPath:(NSIndexPath *)indexPath;

- (MTOrganization *)selectedOrganization;
- (NSString *)mentorCode;

- (void)promptForMentorCode;

- (void)handleError:(NSError *)error;

- (void)save:(void (^)(BOOL success))blockName;

- (NSIndexPath *)resultIndexPath:(RLMObject *)object;
- (MTClass *)classAtIndexPath:(NSIndexPath *)indexPath;
- (void)loadArchivedResults;

@end

@implementation MTClassSelectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.loadingResourceName = @"classes";    
    self.pageSize = 50;    
    
    self.navigationItem.hidesBackButton = YES;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellIdentifier];
    self.incrementalLoadingControllerDelegate = self;
    
    self.navigationItem.prompt = self.selectedOrganization.name;
    
    if ([self.selectedClass isArchived]) {
        [self showArchivedClasses:nil];
    }
    
    [self loadLocalResults];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.currentPage = 1; // Reset current page on load
    
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
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
    if ([MTUser currentUser] == nil) return;
    
    RLMResults *results = [[MTClass objectsWhere:@"organization.id = %d AND archivedAt == nil", self.selectedOrganization.id] sortedResultsUsingProperty:@"name" ascending:YES];
    
    [self didLoadLocalResults:results withCallback:nil];
}

- (void)loadRemoteResultsForCurrentPage {
    [self willLoadRemoteResultsForCurrentPage];
    
    MTMakeWeakSelf();
    if (self.selectedOrganization.id != [MTUser currentUser].organization.id) {
        [[MTNetworkManager sharedMTNetworkManager] getClassesWithSignupCode:self.mentorCode organizationId:self.selectedOrganization.id page:self.currentPage success:^(BOOL lastPage, NSUInteger numPages, NSUInteger totalCount) {
            [weakSelf loadLocalResults];
            [weakSelf didLoadRemoteResultsSuccessfullyWithLastPage:lastPage numPages:numPages totalCount:totalCount];
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf handleError:error];
            });
        }];
    }
    else {
        // Clear classes in case some have been removed.
        [MTClass markAllDeletedExcept:self.selectedClass];
        [MTClass removeAllDeleted];
        
        [[MTNetworkManager sharedMTNetworkManager] getClassesWithPage:self.currentPage success:^(BOOL lastPage, NSUInteger numPages, NSUInteger totalCount) {
            [weakSelf loadLocalResults];
            [weakSelf didLoadRemoteResultsSuccessfullyWithLastPage:lastPage numPages:numPages totalCount:totalCount];
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
    if (section == kActiveClassesSection) {
        return @"Active Classes";
    } else {
        return @"Archived Classes";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == kArchivedClassesSection) {
        if (IsEmpty(self.archivedResults)) {
            return 1;
        } else {
            return self.archivedResults.count;
        }
    } else {
        return self.results.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier];
    
    if (indexPath.section == kArchivedClassesSection) {
        if (self.archivedResults == nil) {
            NSAttributedString *title = [[NSAttributedString alloc] initWithString:kShowArchivedClassesText attributes:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0f]}];
            cell.textLabel.attributedText = title;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selected = false;
            return cell;
        } else {
            if (self.archivedResults.count == 0) {
                cell.textLabel.text = @"No archived classes.";
                cell.selected = false;
                return cell;
            }
        }
    }
    
    MTClass *class;
    if (indexPath.section == kArchivedClassesSection) {
        if (indexPath.row > 0) {
            [self loadArchivedResults];
        }
        class = self.archivedResults[indexPath.row];
    } else {
        class = self.results[indexPath.row];
    }
    cell.textLabel.text = class.name;
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    if ([class isEqual:self.selectedClass]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    cell.textLabel.textColor = [UIColor blackColor];
    if (indexPath.section == kArchivedClassesSection) {
        cell.textLabel.textColor = [UIColor darkGrayColor];
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Needs to reload the new row and reload the currently selected row(s) of the previously selected class
    
    if (indexPath.section == kArchivedClassesSection) {
        UITableViewCell *firstCell = [tableView cellForRowAtIndexPath:indexPath];
        if (firstCell != nil) {
            if ([firstCell.textLabel.text isEqualToString:kShowArchivedClassesText]) {
            [self showArchivedClasses:nil];
            return nil;
            }
        }
    }
    
    MTClass *class = [self classAtIndexPath:indexPath];
    if (![class isEqual:self.selectedClass]) {
        [self confirmSelectClass:class atIndexPath:indexPath];
    }

    return nil;
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

- (void)setMentorCode:(NSString *)mentorCode {
    [[NSUserDefaults standardUserDefaults] setObject:mentorCode forKey:kMentorCodeKey];
    ((MTClassSelectionNavigationController *)self.navigationController).mentorCode = mentorCode;
}

#pragma mark - private methods
- (void)handleError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Unable to load classes. Please check your Internet connection. If this issue happens more than once, please contact us!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    [self didLoadRemoteResultsWithError:error];
}

- (void)promptForMentorCode {
    
    NSString *mentorCodeFromUserDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:kMentorCodeKey];
    if (!IsEmpty(mentorCodeFromUserDefaults) && IsEmpty(self.mentorCode)) {
        // Assume user default code is correct
        self.mentorCode = mentorCodeFromUserDefaults;
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    
    NSString *message = @"Enter your mentor code to change organizations.";
    NSString *title = @"Mentor Code";
    if (NSClassFromString(@"UIAlertController")) {
        UIAlertController *controller = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [controller addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = title;
        }];
        [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [[controller.textFields firstObject] resignFirstResponder];
        }]];
        [controller addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[controller.textFields firstObject] resignFirstResponder];
            NSString *mentorCode = [[controller textFields] firstObject].text;
            [self selectOrganizationIfCorrectWithCode:mentorCode];
        }]];
        [self presentViewController:controller animated:YES completion:nil];
    } else {
        UIAlertView *alertViewChangeName = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Continue", nil];
        alertViewChangeName.alertViewStyle = UIAlertViewStylePlainTextInput;
        alertViewChangeName.tag = kAlertViewTag_MentorCode;
        [alertViewChangeName show];
    }
}

- (void)loadArchivedResults {
    RLMResults *archivedResults = [[MTClass objectsWhere:@"organization.id = %d AND archivedAt != nil", self.selectedOrganization.id] sortedResultsUsingProperty:@"name" ascending:YES];
    self.archivedResults = archivedResults;
}

- (void)selectOrganizationIfCorrectWithCode:(NSString *)mentorCode {
    MTMakeWeakSelf();
    MBProgressHUD *hud = [[MBProgressHUD alloc] init];
    if (IsEmpty([[NSUserDefaults standardUserDefaults] objectForKey:kMentorCodeKey])) {
        hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        hud.labelText = @"Validating code...";
        hud.dimBackground = YES;
    }
    
    [[MTNetworkManager sharedMTNetworkManager] getOrganizationsWithSignupCode:mentorCode page:1 success:^(BOOL lastPage, NSUInteger numPages, NSUInteger totalCount) {
        [hud hide:YES];
        [self setMentorCode:mentorCode];
        self.currentPage = 1;
        [weakSelf.navigationController popViewControllerAnimated:YES];
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud hide:YES];
            [[[MTNoKeyboardAlertView alloc] initWithTitle:@"Invalid code." message:@"Please check your code. You can always contact Moneythink for help from the Talk to Moneythink menu." delegate:nil cancelButtonTitle:@"Try Again" otherButtonTitles:nil] show];
        });
    }];
}

- (NSIndexPath *)resultIndexPath:(RLMObject *)object {
    if (object == nil) return nil;
    
    NSInteger resultIndex = [self.results indexOfObject:object];
    if (resultIndex != NSNotFound) {
        return [NSIndexPath indexPathForRow:resultIndex inSection:kActiveClassesSection];
    }
    
    NSInteger otherResultIndex = [self.archivedResults indexOfObject:object];
    if (self.archivedResults == nil) {
        otherResultIndex = NSNotFound;
    }
    if (otherResultIndex != NSNotFound) {
        return [NSIndexPath indexPathForRow:otherResultIndex inSection:kArchivedClassesSection];
    }
    
    return nil;
}

- (MTClass *)classAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == kActiveClassesSection) {
        if (self.results == nil || self.results.count == 0) return nil;
        return [self.results objectAtIndex:indexPath.row];
    }
    
    if (indexPath.section == kArchivedClassesSection) {
        if (self.archivedResults == nil || self.archivedResults.count == 0) return nil;
        return [self.archivedResults objectAtIndex:indexPath.row];
    }
    
    return nil;
}


#pragma mark - IBActions
- (IBAction)showArchivedClasses:(id)sender {
    [self loadArchivedResults];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kArchivedClassesSection] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - MTIncrementalLoading configuration
- (BOOL)shouldConfigureRefreshController {
    return NO;
}

- (NSUInteger)incrementallyLoadedSectionIndex {
    return 0;
}

#pragma mark - Handle Saves
- (void)save:(void (^)(BOOL success))blockName {
    MTUser *user = [MTUser currentUser];
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    // Write to server
    MBProgressHUD *hud = [[MBProgressHUD alloc] init];
    
    hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    hud.labelText = @"Saving...";
    hud.dimBackground = YES;
    
    NSDictionary *dictionary = @{
         @"organization" : @{ @"id" : [NSNumber numberWithInteger:self.selectedOrganization.id] },
         @"class" : @{ @"id" : [NSNumber numberWithInteger:self.selectedClass.id] }
    };
    
    [[MTNetworkManager sharedMTNetworkManager] updateCurrentUserWithDictionary:dictionary success:^(id responseData) {
        [hud hide:YES];
        
        // Write locally
        [realm beginWriteTransaction];
        user.organization = self.selectedOrganization;
        user.userClass = self.selectedClass;
        [realm commitWriteTransaction];
        
        blockName(YES);
        
    } failure:^(NSError *error) {
        [hud hide:YES];
        
        [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Continue" otherButtonTitles:nil] show];
        
        blockName(NO);
    }];
}

- (IBAction)changeSchoolOrOrganizationButtonTapped:(id)sender {
    if (!IsEmpty(self.mentorCode)) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self promptForMentorCode];
    }
}

- (void)confirmSelectClass:(MTClass *)class atIndexPath:(NSIndexPath *)indexPath {
    
    NSString *title = @"Confirm Change";
    NSString *message = [NSString stringWithFormat:@"Are you sure you'd like to move to %@?", class.name, nil];
    
    // Success
    if (NSClassFromString(@"UIAlertController")) {
        MTMakeWeakSelf();
        UIAlertController *alert = [[UIAlertController alloc] init];
        alert.title = title;
        alert.message = message;
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf classSelectionWasConfirmed:class atIndexPath:indexPath];
        }]];
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"Confirm", nil];
        self.temporaryClassSelection = class;
        av.tag = kAlertViewTag_ConfirmSelect;
        [av show];
    }
}

- (void)classSelectionWasConfirmed:(MTClass *)class atIndexPath:(NSIndexPath *)indexPath {
    
    // Update the mentor's class
    NSIndexPath * currentCheckedIndexPath = [self resultIndexPath:self.selectedClass];
    
    NSMutableArray *rows = [NSMutableArray arrayWithArray:self.tableView.indexPathsForSelectedRows];
    [rows addObject:indexPath];
    
    if (currentCheckedIndexPath != nil) {
        [rows addObject:currentCheckedIndexPath];
    }
    
    self.selectedClass = class;
    
    MTMakeWeakSelf();
    [self save:^(BOOL success) {
        if (success) {
            [self.tableView reloadRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationNone];
            
            // Select the row to confirm the save and give them a sense of finality.
            if (currentCheckedIndexPath != nil) {
                [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            }
            
            // Dismiss after a second.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf performSegueWithIdentifier:@"dismiss" sender:nil];
            });
        }
    }];
}

#pragma mark - MTIncrementalLoadingTableViewControllerDelegate
- (void)didReloadResults {
    NSIndexPath *indexPath = [self resultIndexPath:self.selectedClass];
    if (indexPath != nil && !self.tableView.isDragging && !self.tableView.isDecelerating) {
        NSLog(@"%lu %lu", indexPath.section, indexPath.row);
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    UITextField *textField = [alertView textFieldAtIndex:0];
    NSString *mentorCode; // compiler won't allow this to be inside the block...
    
    switch (alertView.tag) {
        case kAlertViewTag_MentorCode:
            // pass
            mentorCode = textField.text;
            [textField resignFirstResponder];
            [self.view endEditing:YES];
            if (!IsEmpty(mentorCode) && buttonIndex != alertView.cancelButtonIndex) {
                [self selectOrganizationIfCorrectWithCode:mentorCode];
            }
            
            break;
            
        case kAlertViewTag_ConfirmSelect:
            if (buttonIndex != alertView.cancelButtonIndex) {
                MTClass *class = self.temporaryClassSelection;
                NSIndexPath *indexPath = [self resultIndexPath:class];
                [self classSelectionWasConfirmed:class atIndexPath:indexPath];
                self.temporaryClassSelection = nil;
            }
            break;
    }
}

#pragma mark -
- (IBAction)unwindToSelectClassScene:(UIStoryboardSegue *)segue {
}

@end
