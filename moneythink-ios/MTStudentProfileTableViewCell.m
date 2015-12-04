//
//  MTStudentProfileTableViewCell.m
//  moneythink-ios
//
//  Created by jdburgie on 8/5/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentProfileTableViewCell.h"

@implementation MTStudentProfileTableViewCell


- (void)layoutIfNeeded {
    [super layoutIfNeeded];
    
    [self overrideVerificationCheckbox];

    [self.verifiedCheckbox setHidden:YES];
    [self.verifiedLabel setHidden:YES];
    if (!self.challengeIsAutoVerified) {
        [self.verifiedCheckbox setHidden:NO];
        [self.verifiedLabel setHidden:NO];
    }
    
    self.postText.textColor = [UIColor blackColor];
    if (self.postText.text.length == 0) {
        self.postText.text = @"This post has no text.";
        self.postText.textColor = [UIColor lightGrayColor];
    }
    
    self.challengeNameLabel.text = @"";
    if (self.rowPost.challenge) {
        self.challengeNameLabel.text = self.rowPost.challenge.title;
    }
}

- (void)checkedVerifiedBox {
    BOOL isVerified = self.rowPost.isVerified;
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
    if (isVerified) {
        hud.labelText = @"Removing Verification...";
    }
    else {
        hud.labelText = @"Verifying...";
    }
    
    hud.dimBackground = YES;
    self.verifiedCheckbox.enabled = NO;
    
    MTMakeWeakSelf();
    if (isVerified) {
        [[MTNetworkManager sharedMTNetworkManager] unVerifyPostId:self.rowPost.id success:^(AFOAuthCredential *credential) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.verifiedCheckbox.enabled = YES;
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            });
            
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                weakSelf.verifiedCheckbox.isChecked = weakSelf.rowPost.isVerified;
                weakSelf.verifiedCheckbox.enabled = YES;
                [weakSelf setNeedsLayout];
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            });
        }];
    }
    else {
        [[MTNetworkManager sharedMTNetworkManager] verifyPostId:self.rowPost.id success:^(AFOAuthCredential *credential) {
            dispatch_async(dispatch_get_main_queue(), ^{
                weakSelf.verifiedCheckbox.enabled = YES;
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            });
            
        } failure:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                weakSelf.verifiedCheckbox.isChecked = weakSelf.rowPost.isVerified;
                weakSelf.verifiedCheckbox.enabled = YES;
                [weakSelf setNeedsLayout];
                [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
            });
        }];
    }
}

- (void)overrideVerificationCheckbox {
    if (self.verifiedCheckbox != nil) return;
    
    CGRect frame = self.verified.frame;
    frame.origin.x += (frame.size.width / 2) - 10.0f;
    frame.origin.y += (frame.size.height / 2) - 10.0f;
    frame.size.width = 20.0f;
    frame.size.height = 20.0f;
    
    self.verifiedCheckbox =[[MICheckBox alloc]initWithFrame:frame];
    [self.verifiedCheckbox setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.verifiedCheckbox setTitle:@"" forState:UIControlStateNormal];
    [self addSubview:self.verifiedCheckbox];
    
    [self.verifiedCheckbox addTarget:self action:@selector(checkedVerifiedBox) forControlEvents:UIControlEventTouchUpInside];
    self.verified.hidden = YES;
}


@end
