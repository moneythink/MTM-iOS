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
@class MTOptionalImage;

@interface MTUser : RLMObject

@property NSInteger id;
@property NSString *username;
@property NSString *email;
@property NSString *firstName;
@property NSString *lastName;
@property NSString *phoneNumber;
@property NSString *roleCode;
@property MTOptionalImage *userAvatar;
@property NSInteger points;
@property BOOL currentUser;
@property NSDate *updatedAt;
@property NSDate *createdAt;
@property BOOL hasResume;
@property BOOL hasBankAccount;

@property MTOrganization *organization;
@property MTClass *userClass;

+ (void)logout;
+ (BOOL)isCurrentUserMentor;
+ (BOOL)isUserMentor:(MTUser *)user;
+ (BOOL)isUserMe:(MTUser *)user;
+ (BOOL)isUserLoggedIn;
+ (MTUser *)currentUser;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<MTUser>
RLM_ARRAY_TYPE(MTUser)
