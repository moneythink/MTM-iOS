//
//  MTCommentViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTCommentViewController.h"
#import "MTMyClassTableViewController.h"

@interface MTCommentViewController ()

@property (nonatomic, strong) IBOutlet UITextView *postText;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UIButton *doneButton;

@end

@implementation MTCommentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.cancelButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];

    if (self.editComment) {
        self.title = @"Edit Comment";
        [self.doneButton setTitle:@"Save" forState:UIControlStateNormal];
        self.postText.text = self.challengePostComment.content;
    }
    else {
        self.title = @"Comment on Post";
        [self.doneButton setTitle:@"Comment" forState:UIControlStateNormal];
        self.postText.text = @"";
    }
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(dismissKeyboard)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [MTUtil GATrackScreen:self.title];
    [self.postText becomeFirstResponder];
}


#pragma mark - Private Methods -
- (void)dismissKeyboard
{
    [self.view endEditing:YES];
}


#pragma mark - New Comment on Post Method -
- (IBAction)postCommentDone:(id)sender
{
    if (![self.postText.text isEqualToString:@""]) {
        if (![MTUtil internetReachable]) {
            [UIAlertView showNoInternetAlert];
            return;
        }

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:[UIApplication sharedApplication].keyWindow animated:YES];
        
        NSString *labelString = @"Posting Comment...";
        if (self.editComment) {
            labelString = @"Updating Comment...";
        }
        hud.labelText = labelString;
        hud.dimBackground = YES;
        
        if (self.editComment) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveEditPostCommentNotification object:nil];

            [[MTNetworkManager sharedMTNetworkManager] updateCommentId:self.challengePostComment.id content:self.postText.text success:^(id responseData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidSaveNewPostCommentNotification object:nil];
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
                
                [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
                    [MTUtil setRefreshedForKey:kRefreshForMeUser];
                } failure:nil];
            } failure:^(NSError *error) {
                NSLog(@"Edit comment error - %@", [error mtErrorDescription]);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kFailedMyClassChallengePostCommentEditNotification object:nil];
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
            }];
        }
        else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveNewPostCommentNotification object:nil];

            [[MTNetworkManager sharedMTNetworkManager] createCommentForPostId:self.post.id content:self.postText.text success:^(id responseData) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kDidSaveNewPostCommentNotification object:nil];
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
                
                [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:^(id responseData) {
                    [MTUtil setRefreshedForKey:kRefreshForMeUser];
                } failure:nil];
            } failure:^(NSError *error) {
                NSLog(@"Post text comment error - %@", [error mtErrorDescription]);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kFailedMyClassChallengePostCommentNotification object:nil];
                    [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
                });
            }];
        }
    }
    
    [self.postText endEditing:YES];
    [self.delegate dismissCommentView];
}

- (IBAction)postCommentCancel:(id)sender
{
    self.postText.text = @"";
    [self postCommentDone:nil];
}


@end
