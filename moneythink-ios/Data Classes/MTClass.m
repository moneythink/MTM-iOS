//
//  MTClass.m
//  moneythink-ios
//
//  Created by David Sica on 7/13/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTClass.h"

@implementation MTClass

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues {
    return @{@"name" : @"", @"studentSignupCode": @""};
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

+ (NSString *)primaryKey {
    return @"classId";
}

@end
