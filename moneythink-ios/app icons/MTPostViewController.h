//
//  MTPostViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTPostViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) PFChallengePost *challengePost;

@end
