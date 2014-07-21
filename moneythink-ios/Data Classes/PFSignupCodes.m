    //
    //  PFSignupCodes.m
    //  moneythink-ios
    //
    //  Created by jdburgie on 7/16/14.
    //  Copyright (c) 2014 Moneythink. All rights reserved.
    //

#import "PFSignupCodes.h"
#import <Parse/PFObject+Subclass.h>

@implementation PFSignupCodes

+ (NSString *)parseClassName {
    return @"SignupCodes";
}

+ (PFSignupCodes *)validSignUpCode:(NSString *)code type:(NSString *)type{
    
    NSPredicate *codePredicate = [NSPredicate predicateWithFormat:@"code = %@ AND type = %@", code, type];
    PFQuery *findCode = [PFQuery queryWithClassName:[self parseClassName] predicate:codePredicate];
    
    NSArray *codes = [findCode findObjects];
    
    
    
        //    [findCode findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        //    }];
    
    
    
    if ([codes count] == 1) {
        return [codes firstObject];
    } else {
        return nil;
    }
    
    
    
}

@end
