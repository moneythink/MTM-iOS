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

//@property (nonatomic, strong) PFChallengePost *challengePost;

@end

@implementation MTCommentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.cancelButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor primaryOrange] forState:UIControlStateNormal];

    self.title = @"Comment on Post";
    self.postText.text = @"";
            
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
        hud.labelText = @"Posting Comment...";
        hud.dimBackground = YES;

        MTUser *currentUser = [MTUser currentUser];
        self.challengePostComment = [[PFChallengePostComment alloc] initWithClassName:[PFChallengePostComment parseClassName]];
        self.challengePostComment[@"challenge_post"] = self.post;
        self.challengePostComment[@"comment_text"] = self.postText.text;
        self.challengePostComment[@"school"] = currentUser.organization.name;
        self.challengePostComment[@"class"] = currentUser.userClass.name;
        self.challengePostComment[@"user"] = [MTUser currentUser];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kWillSaveNewPostCommentNotification object:nil];
        
        MTMakeWeakSelf();
        [self.challengePostComment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kDidSaveNewPostCommentNotification object:nil];
                [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];
            });

            if (!error) {
                [[MTNetworkManager sharedMTNetworkManager] refreshCurrentUserDataWithSuccess:nil failure:nil];
            }
            else {
                NSLog(@"Post text comment error - %@", error);
                [weakSelf.challengePostComment saveEventually];
            }
        }];
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
