//
//  MTOnboardingController.m
//  moneythink-ios
//
//  Created by David Sica on 6/15/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTOnboardingController.h"
#import "OnboardingViewController.h"
#import "OnboardingContentViewController.h"

static NSString * const kUserHasOnboardedKey = @"user_has_onboarded";

@interface MTOnboardingController ()

@property (nonatomic, strong) OnboardingViewController *onboardingVC;

@end

@implementation MTOnboardingController

#pragma mark - Onboarding -
- (BOOL)checkForOnboarding
{
    BOOL userHasOnboarded = [[NSUserDefaults standardUserDefaults] boolForKey:kUserHasOnboardedKey];
    
    // if the user has already onboarded, just set up the normal root view controller
    // for the application, but don't animate it because there's no transition in this case
    if (userHasOnboarded) {
        return NO;
    }
    
    SWRevealViewController *revealViewController = (SWRevealViewController *)((AppDelegate *)[MTUtil getAppDelegate]).window.rootViewController;
    [revealViewController setFrontViewController:[self generateWelcomeVC] animated:YES];
    
    return YES;
}

- (void)handleOnboardingCompletion {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kUserHasOnboardedKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    SWRevealViewController *rootVC = (SWRevealViewController *)((AppDelegate *)[MTUtil getAppDelegate]).window.rootViewController;
    id challengesVC = [rootVC.storyboard instantiateViewControllerWithIdentifier:@"challengesViewControllerNav"];
    [rootVC setFrontViewController:challengesVC animated:YES];
}

- (OnboardingViewController *)generateWelcomeVC {
    MTMakeWeakSelf();
    
    OnboardingContentViewController *welcomePage = [OnboardingContentViewController contentWithTitle:nil body:nil image:[UIImage imageNamed:@"onboarding_1"] buttonText:@"Take A Tour" action:^{
    }];
    welcomePage.movesToNextViewController = YES;
    welcomePage.buttonFontName = @"HelveticaNeue-Bold";
    welcomePage.underPageControlPadding = 64.0f;
    welcomePage.buttonFontSize = 20.0f;
    welcomePage.viewWillAppearBlock = ^{
    };

    OnboardingContentViewController *secondPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:[UIImage imageNamed:@"onboarding_2"] buttonText:nil action:^{
    }];
    
    OnboardingContentViewController *thirdPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:[UIImage imageNamed:@"onboarding_3"] buttonText:nil action:^{
    }];
    
    OnboardingContentViewController *fourthPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:[UIImage imageNamed:@"onboarding_4"] buttonText:nil action:^{
    }];

    OnboardingContentViewController *fifthPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:[UIImage imageNamed:@"onboarding_5"] buttonText:nil action:^{
    }];

    OnboardingContentViewController *sixthPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:[UIImage imageNamed:@"onboarding_6"] buttonText:nil action:^{
    }];

    OnboardingContentViewController *seventhPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:[UIImage imageNamed:@"onboarding_7"] buttonText:nil action:^{
    }];

    OnboardingContentViewController *photoUploadPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:[UIImage imageNamed:@"onboarding_8"] buttonText:nil action:^{
        [self handleOnboardingCompletion];
    }];
    photoUploadPage.hasProfileImagePickerButton = YES;
    photoUploadPage.hasDoLaterButton = YES;
    photoUploadPage.movesToNextViewController = YES;
    
    if (IS_IPHONE_4) {
        photoUploadPage.underProfileImagePickerPadding = 80.0f;
    }
    else {
        photoUploadPage.underProfileImagePickerPadding = 120.0f;
    }
    
    __block OnboardingContentViewController *weakPhotoUploadPage = photoUploadPage;

    photoUploadPage.viewDidAppearBlock = ^{
        weakSelf.onboardingVC.swipingEnabled = NO;
        PFFile *profileImageFile = [PFUser currentUser][@"profile_picture"];
        if (profileImageFile) {
            [weakPhotoUploadPage setProfileImageFile:profileImageFile];
        }
    };
    
    OnboardingContentViewController *lastPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:[UIImage imageNamed:@"onboarding_9"] buttonText:@"Let's Do This!" action:^{
        [self handleOnboardingCompletion];
    }];
    lastPage.hasProfileImagePickerButton = YES;
    lastPage.buttonFontName = @"HelveticaNeue-Bold";
    lastPage.underPageControlPadding = 10.0f;
    lastPage.buttonFontSize = 20.0f;

    if (IS_IPHONE_4) {
        lastPage.bottomPadding = -10.0f;
        lastPage.underProfileImagePickerPadding = 100.0f;
    }
    else {
        lastPage.underProfileImagePickerPadding = 160.0f;
    }

    __block OnboardingContentViewController *weakLastPage = lastPage;
    lastPage.viewDidAppearBlock = ^{
        weakSelf.onboardingVC.swipingEnabled = NO;
        if (weakLastPage.profileFile) {
            [weakLastPage setProfileImageFile:weakLastPage.profileFile];
        }
        else {
            PFFile *profileImageFile = [PFUser currentUser][@"profile_picture"];
            if (profileImageFile) {
                [weakLastPage setProfileImageFile:profileImageFile];
            }
        }
    };

    self.onboardingVC = nil;
    if ([PFUser currentUser][@"profile_picture"]) {
        self.onboardingVC = [OnboardingViewController onboardWithBackgroundImage:nil contents:@[welcomePage, secondPage, thirdPage, fourthPage, fifthPage, sixthPage, seventhPage, lastPage]];
        self.onboardingVC.fadePageControlOnLastPage = YES;
    }
    else {
        self.onboardingVC = [OnboardingViewController onboardWithBackgroundImage:nil contents:@[welcomePage, secondPage, thirdPage, fourthPage, fifthPage, sixthPage, seventhPage, photoUploadPage, lastPage]];
        self.onboardingVC.fadePageControlOnLastTwoPages = YES;
    }
    
    self.onboardingVC.shouldMaskBackground = NO;
    self.onboardingVC.shouldFadeTransitions = YES;
    self.onboardingVC.pageControl.alpha = 0.0f;
    self.onboardingVC.fadePageControlOnFirstPage = YES;
    
    // If you want to allow skipping the onboarding process, enable skipping and set a block to be executed
    // when the user hits the skip button.
    self.onboardingVC.allowSkipping = NO;
//    self.onboardingVC.skipHandler = ^{
//        [weakSelf handleOnboardingCompletion];
//    };
    
    return self.onboardingVC;
}


@end
