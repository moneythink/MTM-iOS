//
//  MTNoKeyboardAlertView.m
//  moneythink-ios
//
//  Created by Colin Young on 12/28/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import "MTNoKeyboardAlertView.h"

@implementation MTNoKeyboardAlertView

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return NO;
}

@end
