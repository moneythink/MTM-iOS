//
//  MTNewClassCodeViewController.m
//  moneythink-ios
//
//  Created by Colin Young on 1/4/16.
//  Copyright © 2016 Moneythink. All rights reserved.
//

#import "MTNewClassCodeViewController.h"
@interface MTNewClassCodeViewController ()

@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UITextField *signupCodeTextField;
@property (weak, nonatomic) IBOutlet UILabel *errorMessage;

@end

@implementation MTNewClassCodeViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.errorMessage.hidden = YES;
    [self.signupCodeTextField becomeFirstResponder];
}

- (IBAction)continueButtonTapped:(UIButton *)sender {
    self.errorMessage.hidden = YES;
    
    NSString *signupCode = self.signupCodeTextField.text;
    if (IsEmpty(signupCode)) {
        return;
    }
    
    NSUInteger organizationId = [MTUser currentUser].organization.id;
    NSLog(@"%@ %ul", signupCode, (unsigned long)organizationId);
    
    [[MTNetworkManager sharedMTNetworkManager] getClassesWithSignupCode:signupCode organizationId:organizationId success:^(id responseData) {
        //
    } failure:^(NSError *error) {
        self.errorMessage.hidden = NO;
    }];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    self.errorMessage.hidden = YES;
    
    NSString *finalString = [textField.text stringByAppendingString:string];
    self.continueButton.enabled = ([finalString length] > 3);
    
    return YES;
}

@end
