//
//  MTPostsTabBarViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/27/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTPostsTabBarViewController : UITabBarController

@property (nonatomic, strong) NSArray *challenges;
@property (nonatomic, assign) NSInteger challengeNumber;
@property (nonatomic, strong) NSString *class;

@end
