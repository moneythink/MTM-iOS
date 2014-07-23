//
//  MTUserInformationViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTUserInformationViewController : UIViewController

@property (nonatomic, strong) IBOutlet UILabel *labelInfoTitle;
@property (nonatomic, strong) IBOutlet UITextView *textInfo;
@property (nonatomic, strong) IBOutlet UIButton *buttonInfoDone;

@property (nonatomic, strong) NSString *labelInfoTitleText;
@property (nonatomic, strong) NSString *textInfoText;

@end
