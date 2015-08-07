//
//  MTOrganization.m
//  moneythink-ios
//
//  Created by David Sica on 7/13/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTOrganization.h"

@implementation MTOrganization

// Specify default values for properties

+ (NSDictionary *)defaultPropertyValues {
    return @{@"name" : @"",
             @"mentorSignupCode": @"",
             @"isActive": @YES};
}

// Specify properties to ignore (Realm won't persist these)

//+ (NSArray *)ignoredProperties
//{
//    return @[];
//}

+ (NSString *)primaryKey {
    return @"id";
}


#pragma mark - Realm+JSON Methods -
+ (NSDictionary *)JSONInboundMappingDictionary {
    return @{
             @"id": @"id",
             @"name": @"name",
             @"mentorSignupCode": @"mentorSignupCode",
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"id": @"id",
             @"name": @"name",
             @"mentorSignupCode": @"mentorSignupCode",
             };
}


@end
