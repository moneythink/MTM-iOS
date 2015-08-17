//
//  MTChallengeContentViewController.h
//  moneythink-ios
//
//  Created by David Sica on 5/28/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const kDidDeleteChallengePostNotification;
extern NSString *const kDidTapChallengeButtonNotification;

@protocol MTChallengeContentViewControllerDelegate <NSObject>

- (void)leftButtonTapped;
- (void)rightButtonTapped;
- (void)didSelectChallenge:(MTChallenge *)challenge withIndex:(NSInteger)index;
- (void)didTapChallengeList;

@end


@interface MTChallengeContentViewController : UIViewController

@property (nonatomic, weak) id<MTChallengeContentViewControllerDelegate> delegate;

@property (nonatomic, strong) IBOutlet UIButton *leftButton;
@property (nonatomic, strong) IBOutlet UIButton *rightButton;

@property (nonatomic, strong) NSString *challengeTitleText;
@property (nonatomic, strong) MTChallenge *challenge;
@property (nonatomic, strong) RLMResults *challenges;
@property (nonatomic) NSUInteger pageIndex;


@end
