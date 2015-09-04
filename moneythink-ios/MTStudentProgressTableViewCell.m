//
//  MTStudentProgressTableViewCell.m
//  moneythink-ios
//
//  Created by jdburgie on 8/3/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentProgressTableViewCell.h"

@implementation MTStudentProgressTableViewCell

- (IBAction)checkedResumeBox
{
    BOOL resume = self.resumeCheckbox.isChecked;
    self.resumeCheckbox.enabled = NO;
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] setResumeValue:resume forUserId:self.user.id success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.resumeCheckbox.enabled = YES;
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to update resume value: %@", [error mtErrorDescription]);
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.resumeCheckbox.enabled = YES;
            weakSelf.resumeCheckbox.isChecked = !weakSelf.resumeCheckbox.isChecked;
            [weakSelf setNeedsLayout];
            [UIAlertView bk_showAlertViewWithTitle:@"Unable to Resume" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
        });
    }];
}

- (IBAction)checkedBankBox
{
    BOOL bank = self.bankCheckbox.isChecked;
    self.bankCheckbox.enabled = NO;
    
    MTMakeWeakSelf();
    [[MTNetworkManager sharedMTNetworkManager] setBankValue:bank forUserId:self.user.id success:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.bankCheckbox.enabled = YES;
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to update resume value: %@", [error mtErrorDescription]);
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.bankCheckbox.enabled = YES;
            weakSelf.bankCheckbox.isChecked = !weakSelf.bankCheckbox.isChecked;
            [weakSelf setNeedsLayout];
            [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
        });
    }];
}


@end
