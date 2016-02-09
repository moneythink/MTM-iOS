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
    
    MTUser *currentUser = [MTUser currentUser];
    NSUInteger organizationId = currentUser.organization.id;
    NSLog(@"%@ %lu", signupCode, (unsigned long)organizationId);
    
    sender.enabled = NO;
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] userChangeClassWithSignupCode:signupCode success:^(id responseData) {
        // User already will have been updated
        [sender setTitle:@"Done!" forState:UIControlStateDisabled];
        [sender setTitleColor:[UIColor primaryGreenDark] forState:UIControlStateDisabled];
        sender.enabled = NO;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((1 * NSEC_PER_SEC))), dispatch_get_main_queue(), ^{
            [MTChallengePost markAllDeleted];
            [MTChallengePost removeAllDeleted];
            // Class was changed, so clear explore posts
            [MTExplorePost deleteAll];
            [self performSegueWithIdentifier:@"dismiss" sender:self];
        });
    } failure:^(NSError *error) {
        sender.enabled = YES;
        weakSelf.errorMessage.hidden = NO;
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
