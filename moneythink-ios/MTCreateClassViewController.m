//
//  MTCreateClassViewController.m
//  moneythink-ios
//
//  Created by Colin Young on 1/13/16.
//  Copyright © 2016 Moneythink. All rights reserved.
//

#import "MTCreateClassViewController.h"
#import "MTClassSelectionNavigationController.h"

@interface MTCreateClassViewController ()

@property (nonatomic, retain) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *doneButton;
@property (nonatomic, retain) IBOutlet UITextField *classNameTextField;
@property (weak, nonatomic) IBOutlet UILabel *errorMessageLabel;

- (MTOrganization *)selectedOrganization;

@end

@implementation MTCreateClassViewController

#pragma mark - View
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.classNameTextField becomeFirstResponder];
    self.classNameTextField.delegate = self;
    if (IsEmpty(self.classNameTextField.text)) {
        self.doneButton.enabled = NO;
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (string.length == 0 && textField.text.length < 2) {
        self.doneButton.enabled = NO;
    } else {
        self.doneButton.enabled = YES;
    }
    
    [self.errorMessageLabel setHidden:YES];
    return YES;
}

- (IBAction)doneButtonTapped:(UIBarButtonItem *)sender {
    NSString *className = [self.classNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    MTMakeWeakSelf();
    sender.enabled = NO;
    self.classNameTextField.enabled = NO;
    self.classNameTextField.text = @"";
    self.classNameTextField.placeholder = @"Saving...";
    [[MTNetworkManager sharedMTNetworkManager] createClassObjectWithName:className organizationId:self.selectedOrganization.id success:^(id responseData, RLMObject *object) {
        // save it locally
        weakSelf.classNameTextField.enabled = NO;
        weakSelf.classNameTextField.text = @"";
        weakSelf.classNameTextField.placeholder = @"Saved!";
        
        // set the newly created class
        MTClass *newClass = (MTClass*)object;
        if (newClass != nil) {
            [weakSelf setSelectedClass:newClass];
            [weakSelf setCurrentUserNeedsSave];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
           [weakSelf performSegueWithIdentifier:@"dismiss" sender:nil];
        });
    } failure:^(NSError *error) {
        [self.errorMessageLabel setHidden:NO];
        if (error) {
            self.errorMessageLabel.text = error.detailMessage;
        } else {
            self.errorMessageLabel.text = @"An unknown error has occurred.";
        }
        self.classNameTextField.enabled = YES;
        self.classNameTextField.placeholder = @"Class Name";
        sender.enabled = YES;
    }];
}

#pragma mark - Private methods
- (MTOrganization *)selectedOrganization {
    MTClassSelectionNavigationController *controller = (MTClassSelectionNavigationController *)self.presentingViewController;
    return controller.selectedOrganization;
}

- (void)setSelectedClass:(MTClass *)class {
    MTClassSelectionNavigationController *controller = (MTClassSelectionNavigationController *)self.presentingViewController;
    controller.selectedClass = class;
}

- (void)setCurrentUserNeedsSave {
    MTClassSelectionNavigationController *controller = (MTClassSelectionNavigationController *)self.presentingViewController;
    controller.currentUserNeedsSave = YES;
}

@end
