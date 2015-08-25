//
//  MTChallenge.m
//  moneythink-ios
//
//  Created by David Sica on 8/17/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTChallenge.h"

@implementation MTChallenge

+ (NSDictionary *)defaultPropertyValues {
    return @{@"autoVerify" : @NO,
             @"challengeDescription": @"",
             @"difficulty": @"",
             @"goal": @"",
             @"isActive": @NO,
             @"isPrivate": @NO,
             @"maxPoints": @0,
             @"mentorInstructions": @"",
             @"outcome": @"",
             @"pointsPerPost": @0,
             @"ranking": @0,
             @"studentInstructions": @"",
             @"tagline": @"",
             @"postExtraFields": @"",
             @"title": @"",
             @"isDeleted": @NO};
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
             @"autoVerify": @"autoVerify",
             @"createdAt": @"createdAt",
             @"description": @"challengeDescription",
             @"difficulty": @"difficulty",
             @"goal": @"goal",
             @"isActive": @"isActive",
             @"isPrivate": @"isPrivate",
             @"maxPoints": @"maxPoints",
             @"mentorInstructions": @"mentorInstructions",
             @"outcome": @"outcome",
             @"pointsPerPost": @"pointsPerPost",
             @"studentInstructions": @"studentInstructions",
             @"tagline": @"tagline",
             @"title": @"title",
             @"updatedAt": @"updatedAt",
             };
}

+ (NSDictionary *)JSONOutboundMappingDictionary {
    return @{
             @"id": @"id",
             @"autoVerify": @"autoVerify",
             @"createdAt": @"createdAt",
             @"challengeDescription": @"description",
             @"difficulty": @"difficulty",
             @"goal": @"goal",
             @"isActive": @"isActive",
             @"isPrivate": @"isPrivate",
             @"maxPoints": @"maxPoints",
             @"mentorInstructions": @"mentorInstructions",
             @"outcome": @"outcome",
             @"studentInstructions": @"studentInstructions",
             @"tagline": @"tagline",
             @"title": @"title",
             @"updatedAt": @"updatedAt",
             };
}


@end
