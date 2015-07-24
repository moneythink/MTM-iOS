//
//  MTUser.h
//  moneythink-ios
//
//  Created by David Sica on 7/13/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Realm/Realm.h>

@class MTOrganization;
@class MTClass;

@interface MTUser : RLMObject

@property NSInteger userId;
@property NSString *username;
@property NSString *email;
@property NSString *firstName;
@property NSString *lastName;
@property NSString *phoneNumber;
@property NSString *roleCode;
@property NSString *avatar;
@property BOOL currentUser;

@property MTOrganization *organization;
@property MTClass *userClass;

+ (void)logout;
+ (BOOL)isCurrentUserMentor;
+ (BOOL)isUserMe:(MTUser *)user;
+ (BOOL)isUserLoggedIn;
+ (MTUser *)getMeUser;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTUser>
RLM_ARRAY_TYPE(MTUser)
