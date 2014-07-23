    //
    //  PFSignupCodes.m
    //  moneythink-ios
    //
    //  Created by jdburgie on 7/16/14.
    //  Copyright (c) 2014 Moneythink. All rights reserved.
    //

#import "PFSignupCodes.h"
#import <Parse/PFObject+Subclass.h>

@interface PFSignupCodes ()

@end


@implementation PFSignupCodes

+ (NSString *)parseClassName {
    return @"SignupCodes";
}

+ (PFSignupCodes *)validSignUpCode:(NSString *)code type:(NSString *)type{
    
    NSPredicate *codePredicate = [NSPredicate predicateWithFormat:@"code = %@ AND type = %@", code, type];
    PFQuery *findCode = [PFQuery queryWithClassName:[self parseClassName] predicate:codePredicate];
    
    NSArray *codes = [findCode findObjects];
    
    if ([codes count] == 1) {
        return [codes firstObject];
    } else {
        return nil;
    }
}

+ (PFSignupCodes *)newStudentSignUpCodeForClass:(PFClasses *)class;
{
    return [self newSignUpCodeForClass:class forUserType:@"student"];
}

+ (PFSignupCodes *)newMentorSignUpCodeForClass:(PFClasses *)class;
{
    return [self newSignUpCodeForClass:class forUserType:@"mentor"];
}

+ (PFSignupCodes *)newSignUpCodeForClass:(PFClasses *)class forUserType:(NSString *)userType
{
    PFSignupCodes *newCode = [PFSignupCodes objectWithClassName:@"SignupCodes"];
    
    NSInteger len = 8;
    NSString *letters = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSString *randomString = @"";
    
    for (int i = 0; i < len; i++) {
        NSInteger pos = arc4random_uniform([letters length]) % [letters length];
        NSString *randomChar = [letters substringWithRange:NSMakeRange(pos, 1)];
        randomString = [randomString stringByAppendingString:randomChar];
    }
    
    NSPredicate *matchNewCode = [NSPredicate predicateWithFormat:@"code = %@", randomString];
    PFQuery *findCode = [PFQuery queryWithClassName:@"SignupCodes" predicate:matchNewCode];
    NSArray *foundCodes = [findCode findObjects];
    
    if ([foundCodes count] > 0) {
        newCode = [self newSignUpCodeForClass:class forUserType:userType];
    }
    
    newCode[@"code"] = randomString;
    newCode[@"school"] = class[@"school"];
    newCode[@"class"] = class[@"name"];
    newCode[@"type"] = userType;
    
    [newCode save];

    return newCode;
}


@end
