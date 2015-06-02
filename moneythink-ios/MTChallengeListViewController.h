//
//  MTChallengeListViewController.h
//  moneythink-ios
//
//  Created by David Sica on 5/29/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MTChallengeListViewControllerDelegate <NSObject>

- (void)didSelectChallenge:(PFChallenges *)challenge withIndex:(NSInteger)index;

@end

@interface MTChallengeListViewController : UIViewController

@property (nonatomic, weak) id<MTChallengeListViewControllerDelegate> delegate;

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *challenges;
@property (nonatomic, strong) PFChallenges *currentChallenge;

@end
