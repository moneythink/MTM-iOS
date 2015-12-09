//
//  MTNetworkManager.h
//  moneythink-ios
//
//  Created by David Sica on 7/9/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "AFOAuth2Manager.h"

typedef void (^MTNetworkSuccessBlock)(id responseData);
typedef void (^MTNetworkPaginatedSuccessBlock)(BOOL lastPage, NSUInteger numPages, NSUInteger totalCount);
typedef void (^MTSuccessBlock)(NSError *error);
typedef void (^MTNetworkOAuthSuccessBlock)(AFOAuthCredential *credential);
typedef void (^MTNetworkFailureBlock)(NSError *error);

@interface MTNetworkManager : AFHTTPSessionManager

@property (nonatomic, strong) NSOperationQueue *oauthRefreshQueue;
@property BOOL refreshingOAuthToken;
@property BOOL displayingInternetAndReAuthAlert;
@property (nonatomic, strong) UIAlertView *reAuthAlertView;

+ (MTNetworkManager *)sharedMTNetworkManager;

- (void)cancelExistingOperations;

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
              organizationId:(NSNumber *)organizationId
                     classId:(NSNumber *)classId
                newClassName:(NSString *)newClassName
                     success:(MTNetworkSuccessBlock)success
                     failure:(MTNetworkFailureBlock)failure;
- (void)getOrganizationsWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)getOrganizationsWithSignupCode:(NSString *)signupCode success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)getClassesWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)createClassWithName:(NSString *)name organizationId:(NSInteger)organizationId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)getClassesWithSignupCode:(NSString *)signupCode organizationId:(NSInteger)organizationId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)getEthnicitiesWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)getMoneyOptionsWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)refreshOAuthTokenForCredential:(AFOAuthCredential *)credential success:(MTNetworkOAuthSuccessBlock)success failure:(MTNetworkFailureBlock)failure;


// Misc
- (void)getAvatarForUserId:(NSInteger)userId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)setMyAvatarWithImageData:(NSData *)imageData success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)updateCurrentUserWithFirstName:(NSString *)firstName lastName:(NSString *)lastName email:(NSString *)email phoneNumber:(NSString *)phoneNumber password:(NSString *)password organizationId:(NSInteger)organizationId classId:(NSInteger)classId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)setOnboardingCompleteForCurrentUserWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)refreshCurrentUserDataWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)requestPasswordResetEmailForEmail:(NSString *)email success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)sendNewPassword:(NSString *)newPassword withToken:(NSString *)token success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

// Challenges
- (void)loadChallengesWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)getChallengeBannerImageForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)loadChallengeProgressWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

// Posts
- (void)loadPostsForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)loadPostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)getImageForPostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)createPostForChallengeId:(NSInteger)challengeId content:(NSString *)content postImageData:(NSData *)postImageData extraFields:(NSDictionary *)extraFields success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)updatePostId:(NSInteger)postId content:(NSString *)content postImageData:(NSData *)postImageData hadImage:(BOOL)hadImage extraFields:(NSDictionary *)extraFields success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)deletePostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)verifyPostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)unVerifyPostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)loadPostsForUserId:(NSInteger)userId success:(MTNetworkPaginatedSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)loadPostsForUserId:(NSInteger)userId page:(NSUInteger)page success:(MTNetworkPaginatedSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)loadPostsForUserId:(NSInteger)userId page:(NSUInteger)page params:(NSDictionary *)params success:(MTNetworkPaginatedSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

// Comments
- (void)loadCommentsForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)loadCommentsForPostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)createCommentForPostId:(NSInteger)postId content:(NSString *)content success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)updateCommentId:(NSInteger)commentId content:(NSString *)content success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)deleteCommentId:(NSInteger)commentId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

// Liking/Emoji
- (void)loadEmojiWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)loadLikesForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)loadLikesForPostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)addLikeForPostId:(NSInteger)postId emojiCode:(NSString *)emojiCode success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)updateLikeId:(NSInteger)likeId emojiCode:(NSString *)emojiCode success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

// Buttons
- (void)loadButtonsWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)loadButtonClicksForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)addButtonClickForPostId:(NSInteger)postId buttonId:(NSInteger)buttonId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)deleteButtonClickId:(NSInteger)buttonClickId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

// Notifications
- (void)loadNotificationsWithSinceDate:(NSDate *)sinceDate includeRead:(BOOL)includeRead success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)loadNotificationId:(NSInteger)notificationId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)markReadForNotificationId:(NSInteger)notificationId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)markAllNotificationsReadWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)createPushMessagingRegistrationWithDeviceToken:(NSString *)deviceToken success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)updatePushMessagingRegistrationId:(NSInteger)pushMessagingRegistrationId withDeviceToken:(NSString *)deviceToken success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)deletePushMessagingRegistrationId:(NSInteger)pushMessagingRegistrationId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

// Explore
- (void)loadExplorePostsForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

// Dashboard
- (void)loadDashboardUsersWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)setBankValue:(BOOL)bankValue forUserId:(NSInteger)userId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
- (void)setResumeValue:(BOOL)bankValue forUserId:(NSInteger)userId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;

@end