//
//  MTStudentProgressTableViewCell.m
//  moneythink-ios
//
//  Created by jdburgie on 8/3/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentProgressTableViewCell.h"

@implementation MTStudentProgressTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (IBAction)checkedResumeBox
{
    // TODO: Implement resume
//    BOOL resume = self.resumeCheckbox.isChecked;
//    self.user[@"resume"] = [NSNumber numberWithBool:resume];
//    id userID = [self.user objectId];
//    self.resumeCheckbox.enabled = NO;
//    
//    NSDictionary *resumeDict = @{@"user_id": userID, @"key": @"resume", @"value" : [NSNumber numberWithBool:resume]};
//
//    MTMakeWeakSelf();
//    [PFCloud callFunctionInBackground:@"setOtherStudentData" withParameters:resumeDict block:^(id object, NSError *error) {
//        weakSelf.resumeCheckbox.enabled = YES;
//        if (!error) {
//            
//        } else {
//            weakSelf.resumeCheckbox.isChecked = !weakSelf.resumeCheckbox.isChecked;
//            [weakSelf setNeedsLayout];
//            NSLog(@"error - %@", error);
//            [UIAlertView bk_showAlertViewWithTitle:@"Unable to Resume" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
//        }
//    }];
}

- (IBAction)checkedBankBox
{
    // TODO: Support this
//    BOOL bank = self.bankCheckbox.isChecked;
//    self.user[@"bank_account"] = [NSNumber numberWithBool:bank];
//    id userID = [self.user objectId];
//    self.bankCheckbox.enabled = NO;
//    
//    NSDictionary *bankDict = @{@"user_id": userID, @"key": @"bank_account", @"value" : [NSNumber numberWithBool:bank]};
//    
//    MTMakeWeakSelf();
//    [PFCloud callFunctionInBackground:@"setOtherStudentData" withParameters:bankDict block:^(id object, NSError *error) {
//        weakSelf.bankCheckbox.enabled = YES;
//        if (!error) {
//            //
//        } else {
//            weakSelf.bankCheckbox.isChecked = !weakSelf.bankCheckbox.isChecked;
//            [weakSelf setNeedsLayout];
//            NSLog(@"error - %@", error);
//            [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
//        }
//    }];
}


@end
