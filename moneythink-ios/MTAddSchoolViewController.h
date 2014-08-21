//
//  MTAddSchoolViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 8/15/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTAddSchoolViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *schoolNameText;
@property (strong, nonatomic) NSString *schoolName;

@end
