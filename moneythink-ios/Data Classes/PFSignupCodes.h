//
//  PFSignupCodes.h
//  moneythink-ios
//
//  Created by jdburgie on 7/16/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PFClasses.h"

@interface PFSignupCodes : PFObject <PFSubclassing>

+ (NSString *)parseClassName;

+ (PFSignupCodes *)validSignUpCode:(NSString *)code type:(NSString *)type;
+ (PFSignupCodes *)newSignUpCodeForClass:(PFClasses *)class forUserType:(NSString *)userType;
+ (PFSignupCodes *)newStudentSignUpCodeForClass:(PFClasses *)class;
+ (PFSignupCodes *)newMentorSignUpCodeForClass:(PFClasses *)class;

@end
