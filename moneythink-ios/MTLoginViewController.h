//
//  MTLoginViewController.h
//  moneythink-ios
//
//  Created by dsica on 5/27/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MTSignUpViewController.h"
#import <MessageUI/MessageUI.h>

@interface MTLoginViewController : UIViewController <UINavigationControllerDelegate, UITextFieldDelegate, UIActionSheetDelegate>

- (void)shouldUpdateView;

+ (NSArray *)helpActionSheetButtons;

@end
