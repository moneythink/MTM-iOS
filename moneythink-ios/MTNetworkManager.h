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

// Authentication/Login/Signup Methods
- (void)authenticateForUsername:(NSString *)username withPassword:(NSString *)password success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)studentSignupForEmail:(NSString *)email
                        password:(NSString *)password
                      signupCode:(NSString *)signupCode
                       firstName:(NSString *)firstName
                        lastName:(NSString *)lastName
                         zipCode:(NSString *)zipCode
                     phoneNumber:(NSString *)phoneNumber
                       birthdate:(NSDate *)birthdate
                       ethnicity:(NSDictionary *)ethnicity
                    moneyOptions:(NSArray *)moneyOptions
                         success:(MTNetworkSuccessBlock)success
                         failure:(MTNetworkFailureBlock)failure;
- (void)mentorSignupForEmail:(NSString *)email
                    password:(NSString *)password
                  signupCode:(NSString *)signupCode
                   firstName:(NSString *)firstName
                    lastName:(NSString *)lastName
                 phoneNumber:(NSString *)phoneNumber
                     classId:(NSNumber *)classId
                     success:(MTNetworkSuccessBlock)success
                     failure:(MTNetworkFailureBlock)failure;
- (void)getClassesWithSignupCode:(NSString *)signupCode success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)getEthnicitiesWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)getMoneyOptionsWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

// Misc
- (void)setAvatarForUserId:(NSInteger)userId withImageData:(NSData *)imageData success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)updateCurrentUserWithFirstName:(NSString *)firstName lastName:(NSString *)lastName email:(NSString *)email phoneNumber:(NSString *)phoneNumber password:(NSString *)password success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)refreshCurrentUserDataWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)requestPasswordResetEmailForEmail:(NSString *)email success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)sendNewPassword:(NSString *)newPassword withToken:(NSString *)token success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

// Challenges related
- (void)loadChallengesWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

@end