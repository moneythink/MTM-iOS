//
//  MTUserInformationViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MTUserInfoDelegate;

@interface MTUserInformationViewController : UIViewController

@property (assign, nonatomic) id <MTUserInfoDelegate>delegate;

@property (strong, nonatomic) IBOutlet UIView *fieldsView;
@property (nonatomic, strong) IBOutlet UILabel *labelInfoTitle;
@property (nonatomic, strong) IBOutlet UITextView *textInfo;

@property (nonatomic, strong) NSString *labelInfoTitleText;
@property (nonatomic, strong) NSString *textInfoText;

@end


@protocol MTUserInfoDelegate<NSObject>

@optional

- (void)cancelButtonClicked:(MTUserInformationViewController*)userInfoViewController;

@end