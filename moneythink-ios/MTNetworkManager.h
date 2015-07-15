//
//  MTNetworkManager.h
//  moneythink-ios
//
//  Created by David Sica on 7/9/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "AFOAuth2Manager.h"

typedef void (^MTNetworkSuccessBlock)(id responseData);
typedef void (^MTNetworkOAuthSuccessBlock)(AFOAuthCredential *credential);
typedef void (^MTNetworkFailureBlock)(NSError *error);

@interface MTNetworkManager : AFHTTPSessionManager
{
}

+ (MTNetworkManager *)sharedMTNetworkManager;

// Authentication
- (void)authenticateForUsername:(NSString *)username withPassword:(NSString *)password success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (MTUser *)getMeUser;

- (void)getOrganizationsWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

@end