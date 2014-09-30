//
//  MTPostViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MICheckBox.h"
#import "MTCommentViewController.h"

@interface MTPostViewController : UIViewController <MTCommentViewProtocol, UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) PFChallenges *challenge;
@property (strong, nonatomic) PFChallengePost *challengePost;

@end
