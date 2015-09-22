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

@interface MTOnboardingController ()

@property (nonatomic, strong) OnboardingViewController *onboardingVC;

@end

@implementation MTOnboardingController

#pragma mark - Onboarding -
- (BOOL)checkForOnboarding
{
    BOOL userHasOnboarded = [MTUser currentUser].onboardingComplete;
    
    // if the user has already onboarded, just set up the normal root view controller
    // for the application, but don't animate it because there's no transition in this case
    if (userHasOnboarded) {
        return NO;
    }
    
    [self initiateOnboarding];
    
    return YES;
}

- (void)initiateOnboarding
{
    SWRevealViewController *revealViewController = (SWRevealViewController *)((AppDelegate *)[MTUtil getAppDelegate]).window.rootViewController;
    [revealViewController setFrontViewController:[self generateWelcomeVC] animated:YES];
    
    // GA Track - 'Onboarding: Student'
    // GA Track - 'Onboarding: Mentor'
    NSString *screenName = [NSString stringWithFormat:@"Onboarding: %@", [MTUtil currentUserTypeCapitalized]];
    [MTUtil GATrackScreen:screenName];
}

- (void)handleOnboardingCompletion {
    [[MTNetworkManager sharedMTNetworkManager] setOnboardingCompleteForCurrentUserWithSuccess:nil failure:nil];
    
    SWRevealViewController *rootVC = (SWRevealViewController *)((AppDelegate *)[MTUtil getAppDelegate]).window.rootViewController;
    id challengesVC = [rootVC.storyboard instantiateViewControllerWithIdentifier:@"challengesViewControllerNav"];
    [rootVC setFrontViewController:challengesVC animated:YES];
}

- (OnboardingViewController *)generateWelcomeVC {
    MTMakeWeakSelf();
    
    UIImage *onboarding1 = [MTUser isCurrentUserMentor] ? [UIImage imageNamed:@"onboarding_1_mentor"] : [UIImage imageNamed:@"onboarding_1_student"];
    OnboardingContentViewController *welcomePage = [OnboardingContentViewController contentWithTitle:nil body:nil image:onboarding1 buttonText:@"Take A Tour" action:^{
    }];
    welcomePage.movesToNextViewController = YES;
    welcomePage.buttonFontName = @"HelveticaNeue-Bold";
    welcomePage.underPageControlPadding = 64.0f;
    welcomePage.buttonFontSize = 20.0f;
    welcomePage.viewWillAppearBlock = ^{
    };

    UIImage *onboarding2 = [MTUser isCurrentUserMentor] ? [UIImage imageNamed:@"onboarding_2_mentor"] : [UIImage imageNamed:@"onboarding_2_student"];
    OnboardingContentViewController *secondPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:onboarding2 buttonText:nil action:^{
    }];
    
    UIImage *onboarding3 = [MTUser isCurrentUserMentor] ? [UIImage imageNamed:@"onboarding_3_mentor"] :[UIImage imageNamed:@"onboarding_3_student"];
    OnboardingContentViewController *thirdPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:onboarding3 buttonText:nil action:^{
    }];
    
    UIImage *onboarding4 = [MTUser isCurrentUserMentor] ? [UIImage imageNamed:@"onboarding_4_mentor"] : [UIImage imageNamed:@"onboarding_4_student"];
    OnboardingContentViewController *fourthPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:onboarding4 buttonText:nil action:^{
    }];

    // Skipping this until progress bar is complete
    UIImage *onboarding5 = [MTUser isCurrentUserMentor] ? [UIImage imageNamed:@"onboarding_5_mentor"] : [UIImage imageNamed:@"onboarding_5_student"];
    OnboardingContentViewController *fifthPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:onboarding5 buttonText:nil action:^{
    }];

    UIImage *onboarding6 = [MTUser isCurrentUserMentor] ? [UIImage imageNamed:@"onboarding_6_mentor"] : [UIImage imageNamed:@"onboarding_6_student"];
    OnboardingContentViewController *sixthPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:onboarding6 buttonText:nil action:^{
    }];

    UIImage *onboarding7 = [MTUser isCurrentUserMentor] ? [UIImage imageNamed:@"onboarding_7_mentor"] : [UIImage imageNamed:@"onboarding_7_student"];
    OnboardingContentViewController *seventhPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:onboarding7 buttonText:nil action:^{
    }];

    UIImage *onboarding8 = [MTUser isCurrentUserMentor] ? [UIImage imageNamed:@"onboarding_8_mentor"] : [UIImage imageNamed:@"onboarding_8_student"];
    OnboardingContentViewController *photoUploadPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:onboarding8 buttonText:nil action:^{
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
        MTUser *currentUser = [MTUser currentUser];
        if (currentUser.userAvatar && !weakPhotoUploadPage.changedProfileImage) {
            [weakPhotoUploadPage setProfileImage:[UIImage imageWithData:currentUser.userAvatar.imageData]];
        }
    };
    
    UIImage *onboarding9 = [MTUser isCurrentUserMentor] ? [UIImage imageNamed:@"onboarding_9_mentor"] : [UIImage imageNamed:@"onboarding_9_student"];
    OnboardingContentViewController *lastPage = [OnboardingContentViewController contentWithTitle:nil body:nil image:onboarding9 buttonText:@"Let's Do This!" action:^{
        [self handleOnboardingCompletion];
    }];
    lastPage.hasProfileImagePickerButton = YES;
    lastPage.buttonFontName = @"HelveticaNeue-Bold";
    lastPage.underPageControlPadding = 10.0f;
    lastPage.buttonFontSize = 20.0f;

    if (IS_IPHONE_4) {
        lastPage.bottomPadding = -35.0f;
        lastPage.underProfileImagePickerPadding = 71.0f;
    }
    else {
        lastPage.underProfileImagePickerPadding = 112.0f;
    }


    self.onboardingVC = nil;
    if ([MTUser currentUser].userAvatar) {
        self.onboardingVC = [OnboardingViewController onboardWithBackgroundImage:nil contents:@[welcomePage, secondPage, thirdPage, fourthPage, fifthPage, sixthPage, seventhPage, lastPage]];
        self.onboardingVC.fadePageControlOnLastPage = YES;
    }
    else {
        self.onboardingVC = [OnboardingViewController onboardWithBackgroundImage:nil contents:@[welcomePage, secondPage, thirdPage, fourthPage, fifthPage, sixthPage, seventhPage, photoUploadPage, lastPage]];
        self.onboardingVC.fadePageControlOnLastTwoPages = YES;
    }
    
    __block OnboardingContentViewController *weakLastPage = lastPage;
    __block OnboardingViewController *weakOnboaringVC = self.onboardingVC;

    lastPage.viewDidAppearBlock = ^{
        weakSelf.onboardingVC.swipingEnabled = YES;
        if (weakLastPage.profileImage) {
            if (!weakLastPage.changedProfileImage) {
                [weakLastPage.profileImageButton setImage:weakLastPage.profileImage forState:UIControlStateNormal];
                [weakLastPage.profileImageButton setImage:nil forState:UIControlStateHighlighted];
            }
        }
        else {
            MTUser *currentUser = [MTUser currentUser];
            if (currentUser.userAvatar) {
                [weakLastPage setProfileImage:[UIImage imageWithData:currentUser.userAvatar.imageData]];
            }
        }
        
        // Remove photoUploadPage if it exists
        NSMutableArray *newArray = [NSMutableArray arrayWithArray:[weakOnboaringVC viewControllers]];
        for (UIViewController *thisVC in [self.onboardingVC viewControllers]) {
            if (thisVC == weakPhotoUploadPage) {
                [newArray removeObject:thisVC];
            }
        }
        
        if ([newArray count] != [[weakOnboaringVC viewControllers] count]) {
            weakOnboaringVC.viewControllers = [NSArray arrayWithArray:newArray];
            weakOnboaringVC.fadePageControlOnLastTwoPages = NO;
            weakOnboaringVC.fadePageControlOnLastPage = YES;
            weakOnboaringVC.pageControl.numberOfPages = [newArray count];
        }
    };
    
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
