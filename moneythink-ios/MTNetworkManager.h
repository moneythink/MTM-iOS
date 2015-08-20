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

@property (nonatomic, strong) NSOperationQueue *oauthRefreshQueue;
@property (nonatomic) BOOL showingReAuthAlert;
@property BOOL refreshingOAuthToken;
@property (nonatomic, strong) UIAlertView *reAuthAlertView;

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
- (void)refreshOAuthTokenForCredential:(AFOAuthCredential *)credential success:(MTNetworkOAuthSuccessBlock)success failure:(MTNetworkFailureBlock)failure;


// Misc
- (void)getAvatarForUserId:(NSInteger)userId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)setMyAvatarWithImageData:(NSData *)imageData success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)updateCurrentUserWithFirstName:(NSString *)firstName lastName:(NSString *)lastName email:(NSString *)email phoneNumber:(NSString *)phoneNumber password:(NSString *)password success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)refreshCurrentUserDataWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)requestPasswordResetEmailForEmail:(NSString *)email success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)sendNewPassword:(NSString *)newPassword withToken:(NSString *)token success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

// Challenges related
- (void)loadChallengesWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

// Posts related
- (void)loadPostsForChallenge:(MTChallenge *)challenge success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)getImageForPostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)createPostForChallengeId:(NSInteger)challengeId content:(NSString *)content postImageData:(NSData *)postImageData extraData:(NSString *)extraData success:(MTNetworkOAuthSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)updatePostId:(NSInteger)postId content:(NSString *)content postImageData:(NSData *)postImageData extraData:(NSString *)extraData success:(MTNetworkOAuthSuccessBlock)success failure:(MTNetworkFailureBlock)failure;


@end