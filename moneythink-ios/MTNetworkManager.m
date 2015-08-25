//
//  MTNetworkManager.m
//  moneythink-ios
//
//  Created by David Sica on 7/9/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTNetworkManager.h"
#import "AFHTTPRequestSerializer+OAuth2.h"
#import "RLMObject+JSON.h"
#import "AFURLRequestSerialization.h"
#import "AFURLResponseSerialization.h"
#import "MTOAuthRefreshOperation.h"

// TODO: Create dev and prod keys/urls
#ifdef STAGE
static NSString * const MTNetworkAPIKey = @"123456";
static NSString * const MTNetworkURLString = @"http://moneythink-api.staging.causelabs.com/";
#else
static NSString * const MTNetworkAPIKey = @"123456";
static NSString * const MTNetworkURLString = @"http://moneythink-api.staging.causelabs.com/";
#endif

static NSString * const MTNetworkClientID = @"ios";
static NSString * const MTRefreshingErrorCode = @"701";

@interface MTNetworkManager (Private)

@end


@implementation MTNetworkManager

+ (MTNetworkManager *)sharedMTNetworkManager
{
    static MTNetworkManager *_sharedMTNetworkManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedMTNetworkManager = [[self alloc] initWithBaseURL:[NSURL URLWithString:MTNetworkURLString]];
    });
    
    return _sharedMTNetworkManager;
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    
    if (self) {
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        self.responseSerializer = [self getJSONResponseSerializer];
        self.oauthRefreshQueue = [[NSOperationQueue alloc] init];
        self.oauthRefreshQueue.maxConcurrentOperationCount = 1;
    }
    
    return self;
}


#pragma mark - Private Methods -
- (AFHTTPResponseSerializer *)getJSONResponseSerializer
{
    AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
    NSMutableSet *contentTypes = [NSMutableSet setWithSet:[responseSerializer acceptableContentTypes]];
    [contentTypes addObject:@"application/hal+json"];
    [contentTypes addObject:@"application/api-problem+json"];
    [contentTypes addObject:@"application/problem+json"];
    responseSerializer.acceptableContentTypes = [NSSet setWithSet:contentTypes];
    return responseSerializer;
}

- (void)checkforOAuthTokenWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTOAuthRefreshOperation *refreshOperation = [[MTOAuthRefreshOperation alloc] init];
    
    MTMakeWeakSelf();
    refreshOperation.completionBlock = ^{
//        NSLog(@"MTOAuthRefreshOperation completionBlock");
        AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:MTNetworkServiceOAuthCredentialKey];
        
        if (credential) {
//            NSLog(@"MTOAuthRefreshOperation completionBlock: have credential");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    success(credential);
                }
            });
        }
        else {
            NSLog(@"MTOAuthRefreshOperation completionBlock: NO credential");
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.oauthRefreshQueue cancelAllOperations];
                [weakSelf checkForInternetAndReAuthWithError:nil];
                if (failure) {
                    failure(nil);
                }
            });
        }
    };
    
    [self.oauthRefreshQueue addOperation:refreshOperation];
}

- (void)refreshOAuthTokenForCredential:(AFOAuthCredential *)credential success:(MTNetworkOAuthSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"refresh_token"] = credential.refreshToken;
    parameters[@"grant_type"] = @"refresh_token";
    
    NSURL *baseURL = [NSURL URLWithString:MTNetworkURLString];
    AFOAuth2Manager *OAuth2Manager = [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                                                     clientID:MTNetworkClientID
                                                                       secret:MTNetworkAPIKey];
    
    MTMakeWeakSelf();
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"oauth" parameters:parameters success:^(AFOAuthCredential *credential) {
        NSLog(@"Successfully refreshed AFOAuthCredential");
//        [credential setExpiration:[NSDate dateWithTimeIntervalSinceNow:10]];
        [AFOAuthCredential storeCredential:credential withIdentifier:MTNetworkServiceOAuthCredentialKey];
        weakSelf.refreshingOAuthToken = NO;

        if (success) {
            success(credential);
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Failed to refresh AFOAuthCredential error: %@", [error mtErrorDescription]);
        weakSelf.refreshingOAuthToken = NO;
        [weakSelf checkForInternetAndReAuthWithError:error];

        if (failure) {
            failure(error);
        }
    }];
}

- (void)checkForInternetAndReAuthWithError:(NSError *)error
{
    if (![MTUtil internetReachable]) {
        [UIAlertView showNoInternetAlert];
    }
    else {
        if (self.displayingInternetAndReAuthAlert) {
            return;
        }
        self.displayingInternetAndReAuthAlert = YES;

        [MBProgressHUD hideAllHUDsForView:[UIApplication sharedApplication].keyWindow animated:YES];

        NSString *title = @"Moneythink Network Error";
        NSString *message = @"Unable to connect to Moneythink services, please try again. If the problem persists, Logout and Login again.";
        if ([UIAlertController class]) {
            UIAlertController *alertController = [UIAlertController
                                                  alertControllerWithTitle:title
                                                  message:message
                                                  preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *okAction = [UIAlertAction
                                       actionWithTitle:@"OK"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction *action) {
                                           self.displayingInternetAndReAuthAlert = NO;
                                       }];
            [alertController addAction:okAction];
            
            [((AppDelegate *)[MTUtil getAppDelegate]).window.rootViewController presentViewController:alertController animated:YES completion:nil];
        } else {
            [[[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
        }
    }
}

#pragma mark - UIAlertViewDelegate methods -
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    self.displayingInternetAndReAuthAlert = NO;
}


#pragma mark - JSON Data Parser Methods -
- (MTUser *)processUserRequestWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No user response data");
        return nil;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No embedded organization/class data");
        return nil;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"organization"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No organization data");
        return nil;
    }
    
    if (![[embeddedDict objectForKey:@"class"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No class data");
        return nil;
    }
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    // Create and assign my class (organization created also)
    MTOrganization *userOrganization = [MTOrganization createOrUpdateInRealm:realm withJSONDictionary:[embeddedDict objectForKey:@"organization"]];
    MTClass *userClass = [MTClass createOrUpdateInRealm:realm withJSONDictionary:[embeddedDict objectForKey:@"class"]];
    userClass.organization = userOrganization;

    // Create new ME User and send back
    MTUser *user = [MTUser createOrUpdateInRealm:realm withJSONDictionary:responseDict];
    user.currentUser = YES;
    user.organization = userOrganization;
    user.userClass = userClass;
    
    NSDictionary *linksDict = [responseDict objectForKey:@"_links"];
    if ([linksDict objectForKey:@"avatar"]) {
        user.hasAvatar = YES;
    }
    else {
        user.hasAvatar = NO;
    }
    
    if (![MTUser isUserMentor:user]) {
        if ([[embeddedDict objectForKey:@"student"] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *studentDict = [embeddedDict objectForKey:@"student"];
            NSNumber *points = [studentDict valueForKey:@"points"];
            if (points) {
                user.points = [points integerValue];
            }
            user.hasBankAccount = [[studentDict objectForKey:@"hasBankAccount"] boolValue];
            user.hasResume = [[studentDict objectForKey:@"hasResume"] boolValue];
        }
    }
    
    [realm commitWriteTransaction];
    
    return user;
}

- (NSDictionary *)processClassesRequestWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No classes response data");
        return 0;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No classes response data");
        return 0;
    }
    
    NSDictionary *embeddedDict = (NSDictionary *)[responseDict objectForKey:@"_embedded"];
    if (![[embeddedDict objectForKey:@"classes"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No classes response data");
        return 0;
    }
    
    NSArray *responseArray = (NSArray *)[embeddedDict objectForKey:@"classes"];
    NSMutableDictionary *classesDict = [NSMutableDictionary dictionary];
    
    for (NSDictionary *thisClass in responseArray) {
        NSString *className = [thisClass objectForKey:@"name"];
        NSNumber *classId = [thisClass objectForKey:@"id"];
        
        if (!IsEmpty(className) && [classId integerValue] > 0) {
            [classesDict setValue:classId forKey:className];
        }
    }
    
    return classesDict;
}

- (NSArray *)processEthnicitiesRequestWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No ethnicities response data");
        return 0;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No ethnicities response data");
        return 0;
    }
    
    NSDictionary *embeddedDict = (NSDictionary *)[responseDict objectForKey:@"_embedded"];
    if (![[embeddedDict objectForKey:@"ethnicities"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No ethnicities response data");
        return 0;
    }
    
    NSArray *responseArray = (NSArray *)[embeddedDict objectForKey:@"ethnicities"];
    NSMutableDictionary *ethnicitiesDict = [NSMutableDictionary dictionary];
    
    for (NSDictionary *thisEthnicity in responseArray) {
        NSString *ethnicityRank = [[thisEthnicity objectForKey:@"ranking"] stringValue];
        
        if (!IsEmpty(ethnicityRank)) {
            [ethnicitiesDict setValue:thisEthnicity forKey:ethnicityRank];
        }
    }
    
    NSMutableArray *sortedArray = [NSMutableArray array];
    for (NSString *thisKey in [[ethnicitiesDict allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
        [sortedArray addObject:[ethnicitiesDict objectForKey:thisKey]];
    }
    
    return sortedArray;
}

- (NSArray *)processMoneyOptionsRequestWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No moneyOptions response data");
        return 0;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No moneyOptions response data");
        return 0;
    }
    
    NSDictionary *embeddedDict = (NSDictionary *)[responseDict objectForKey:@"_embedded"];
    if (![[embeddedDict objectForKey:@"moneyOptions"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No moneyOptions response data");
        return 0;
    }
    
    NSArray *responseArray = (NSArray *)[embeddedDict objectForKey:@"moneyOptions"];
    NSMutableDictionary *moneyOptionsDict = [NSMutableDictionary dictionary];
    
    for (NSDictionary *thisMoneyOption in responseArray) {
        NSString *moneyOptionRank = [[thisMoneyOption objectForKey:@"ranking"] stringValue];
        
        if (!IsEmpty(moneyOptionRank)) {
            [moneyOptionsDict setValue:thisMoneyOption forKey:moneyOptionRank];
        }
    }
    
    NSMutableArray *sortedArray = [NSMutableArray array];
    for (NSString *thisKey in [[moneyOptionsDict allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]) {
        [sortedArray addObject:[moneyOptionsDict objectForKey:thisKey]];
    }
    
    return sortedArray;
}

- (void)processClassChallengesWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No user response data");
        return;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No embedded class-challenges data");
        return;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"classChallenges"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No classChallenges data");
        return;
    }
    
    NSArray *classChallengesArray = [embeddedDict objectForKey:@"classChallenges"];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    // Mark existing challenges deleted to filter out deleted challenges
    RLMResults *existingChallenges = [MTChallenge allObjects];
    for (MTChallenge *thisChallenge in existingChallenges) {
        thisChallenge.isDeleted = YES;
    }

    for (id classChallenge in classChallengesArray) {
        if ([classChallenge isKindOfClass:[NSDictionary class]]) {
            
            NSDictionary *classChallengeDict = (NSDictionary *)classChallenge;
            if ([[classChallengeDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                
                NSInteger thisRanking = [[classChallengeDict valueForKey:@"ranking"] integerValue];
                NSDictionary *innerEmbeddedDict = [classChallengeDict objectForKey:@"_embedded"];
                
                if ([[innerEmbeddedDict objectForKey:@"challenge"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *challengeDict = [innerEmbeddedDict objectForKey:@"challenge"];
                    
                    // Now create/update challenge
                    MTChallenge *challenge = [MTChallenge createOrUpdateInRealm:realm withJSONDictionary:challengeDict];
                    challenge.ranking = thisRanking;
                    challenge.isDeleted = NO;
                    
                    if ([[challengeDict objectForKey:@"postExtraFields"] isKindOfClass:[NSDictionary class]]) {
                        NSError *error;
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[challengeDict objectForKey:@"postExtraFields"] options:0 error:&error];
                        if (!error) {
                            NSString *postExtraFieldsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                            challenge.postExtraFields = postExtraFieldsString;
                        }
                    }
                }
            }
        }
    }
    [realm commitWriteTransaction];
}

- (void)processPostsWithResponseObject:(id)responseObject challengeId:(NSInteger)challengeId
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No posts response data");
        return;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No embedded posts data");
        return;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"posts"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No posts data");
        return;
    }
    
    NSArray *postsArray = [embeddedDict objectForKey:@"posts"];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    // Mark existing comments deleted to filter out deleted comments
    RLMResults *existingPosts = [MTChallengePost objectsWhere:@"challenge.id = %lu", challengeId];
    for (MTChallengePost *thisPost in existingPosts) {
        thisPost.isDeleted = YES;
    }

    for (id post in postsArray) {
        if ([post isKindOfClass:[NSDictionary class]]) {
            
            MTChallengePost *challengePost = [MTChallengePost createOrUpdateInRealm:realm withJSONDictionary:post];
            challengePost.isDeleted = NO;
            
            NSDictionary *postDict = (NSDictionary *)post;
            if ([[postDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *innerEmbeddedDict = [postDict objectForKey:@"_embedded"];
                
                // Get user
                if ([[innerEmbeddedDict objectForKey:@"user"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *classDict = [innerEmbeddedDict objectForKey:@"class"];
                    MTClass *thisClass = [MTClass createOrUpdateInRealm:realm withJSONDictionary:classDict];
                    challengePost.challengeClass = thisClass;
                    
                    NSDictionary *userDict = [innerEmbeddedDict objectForKey:@"user"];
                    MTUser *thisUser = [MTUser createOrUpdateInRealm:realm withJSONDictionary:userDict];
                    thisUser.userClass = thisClass;
                    thisUser.organization = thisClass.organization;
                    challengePost.user = thisUser;

                    NSDictionary *challengeDict = [innerEmbeddedDict objectForKey:@"challenge"];
                    MTChallenge *thisChallenge = [MTChallenge createOrUpdateInRealm:realm withJSONDictionary:challengeDict];
                    challengePost.challenge = thisChallenge;
                    
                    id challengeDataArray = [innerEmbeddedDict objectForKey:@"challengeData"];
                    if ([challengeDataArray isKindOfClass:[NSArray class]] && !IsEmpty(challengeDataArray)) {
                        NSMutableDictionary *challengeDataDict = [NSMutableDictionary dictionary];
                        for (NSDictionary *thisData in challengeDataArray) {
                            NSString *name = [thisData valueForKey:@"name"];
                            NSString *value = [thisData valueForKey:@"value"];
                            [challengeDataDict setObject:value forKey:name];
                        }
                        if (!IsEmpty(challengeDataDict)) {
                            NSError *error;
                            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:challengeDataDict options:0 error:&error];
                            if (!error) {
                                NSString *challangeDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                                challengePost.challengeData = challangeDataString;
                            }
                        }
                        else {
                            challengePost.challengeData = @"";
                        }
                    }
                    else {
                        challengePost.challengeData = @"";
                    }
                }
                
                // Get Image
                NSDictionary *linksDict = [postDict objectForKey:@"_links"];
                if ([linksDict objectForKey:@"picture"]) {
                    challengePost.hasPostImage = YES;
                }
                else {
                    challengePost.hasPostImage = NO;
                }
            }
        }
    }
    [realm commitWriteTransaction];
}

- (void)processCommentsWithResponseObject:(id)responseObject challengeId:(NSInteger)challengeId postId:(NSInteger)postId
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No comments response data");
        return;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No embedded comments data");
        return;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"comments"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No comments data");
        return;
    }
    
    NSArray *commentsArray = [embeddedDict objectForKey:@"comments"];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    // Mark existing comments deleted to filter out deleted comments
    if (challengeId > 0) {
        // for challenge
        RLMResults *existingComments = [MTChallengePostComment objectsWhere:@"challengePost.challenge.id = %lu", challengeId];
        for (MTChallengePostComment *thisComment in existingComments) {
            thisComment.isDeleted = YES;
        }
    }
    else {
        // for post
        RLMResults *existingComments = [MTChallengePostComment objectsWhere:@"challengePost.id = %lu", postId];
        for (MTChallengePostComment *thisComment in existingComments) {
            thisComment.isDeleted = YES;
        }
    }
    
    for (id comment in commentsArray) {
        if ([comment isKindOfClass:[NSDictionary class]]) {
            
            MTChallengePostComment *challengePostComment = [MTChallengePostComment createOrUpdateInRealm:realm withJSONDictionary:comment];
            challengePostComment.isDeleted = NO;
            
            NSDictionary *commentDict = (NSDictionary *)comment;
            if ([[commentDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *innerEmbeddedDict = [commentDict objectForKey:@"_embedded"];
                
                // Get user
                if ([[innerEmbeddedDict objectForKey:@"user"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *userDict = [innerEmbeddedDict objectForKey:@"user"];
                    MTUser *thisUser = [MTUser createOrUpdateInRealm:realm withJSONDictionary:userDict];
                    challengePostComment.user = thisUser;
                    
                    NSDictionary *challengePostDict = [innerEmbeddedDict objectForKey:@"post"];
                    MTChallengePost *thisChallengePost = [MTChallengePost createOrUpdateInRealm:realm withJSONDictionary:challengePostDict];
                    challengePostComment.challengePost = thisChallengePost;
                    
                }
            }
        }
    }
    [realm commitWriteTransaction];
}


#pragma mark - Public Methods -

#pragma mark - Login/Registration Methods -
- (void)authenticateForUsername:(NSString *)username withPassword:(NSString *)password success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    parameters[@"username"] = username;
    parameters[@"password"] = password;
    parameters[@"grant_type"] = @"password";
    
    NSURL *baseURL = [NSURL URLWithString:MTNetworkURLString];
    AFOAuth2Manager *OAuth2Manager = [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                                                     clientID:MTNetworkClientID
                                                                       secret:MTNetworkAPIKey];
    
    MTMakeWeakSelf();
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"oauth" parameters:parameters success:^(AFOAuthCredential *credential) {
        NSLog(@"New AFOAuthCredential: %@", [credential description]);
        [credential setExpiration:[NSDate dateWithTimeIntervalSinceNow:10]];
        [AFOAuthCredential storeCredential:credential withIdentifier:MTNetworkServiceOAuthCredentialKey];
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:credential];
        [weakSelf GET:@"users/me" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
//            NSLog(@"Found me user");
            MTUser *meUser = [weakSelf processUserRequestWithResponseObject:responseObject];
            if (meUser) {
//                NSLog(@"Parsed meUser object: %@", meUser);
                if (meUser.hasAvatar) {
                    [weakSelf getAvatarForUserId:meUser.id success:^(id responseData) {
                        NSLog(@"Retrieved user avatar");
                        if (success) {
                            success(nil);
                        }
                    } failure:^(NSError *error) {
                        NSLog(@"Failed to retrieve user avatar, probably no avatar assigned");
                        if (success) {
                            success(nil);
                        }
                    }];
                }
                else {
                    if (success) {
                        success(nil);
                    }
                }
            }
            else {
                if (failure) {
                    failure(nil);
                }
            }

        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"authenticateForUsername error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
        
    } failure:^(NSError *error) {
        NSLog(@"authenticateForUsername error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)mentorSignupForEmail:(NSString *)email
                    password:(NSString *)password
                  signupCode:(NSString *)signupCode
                   firstName:(NSString *)firstName
                    lastName:(NSString *)lastName
                 phoneNumber:(NSString *)phoneNumber
                     classId:(NSNumber *)classId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    parameters[@"firstName"] = firstName;
    parameters[@"lastName"] = lastName;
    parameters[@"phoneNumber"] = phoneNumber;
    parameters[@"username"] = email;
    parameters[@"email"] = email;
    parameters[@"password"] = password;
    parameters[@"signupCode"] = signupCode;
    
    NSDictionary *codeDict = [NSDictionary dictionaryWithObject:@"MENTOR" forKey:@"code"];
    parameters[@"role"] = codeDict;

    NSDictionary *classDict = [NSDictionary dictionaryWithObject:classId forKey:@"id"];
    parameters[@"class"] = classDict;

    MTMakeWeakSelf();
    [self POST:@"users" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"Signup Success");
        
        // Now, need to authenticate to get OAuth access token
        [weakSelf authenticateForUsername:email withPassword:password success:^(id responseData) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(responseData);
                });
            }
        } failure:^(NSError *error) {
            NSLog(@"Failed authenticateForUsername after registering as mentor: %@", [error mtErrorDescription]);
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error);
                });
            }
        }];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Failed to register as mentor with error: %@", [error mtErrorDescription]);
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}

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
                      failure:(MTNetworkFailureBlock)failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    parameters[@"firstName"] = firstName;
    parameters[@"lastName"] = lastName;
    parameters[@"phoneNumber"] = phoneNumber;
    parameters[@"username"] = email;
    parameters[@"email"] = email;
    parameters[@"password"] = password;
    parameters[@"signupCode"] = signupCode;
    parameters[@"zipCode"] = zipCode;

    MCJSONDateTransformer *birthdateTransformer = [[MCJSONDateTransformer alloc] initWithDateStyle:MCJSONDateTransformerStyleDateOnly];
    NSString *birthdateString = [birthdateTransformer reverseTransformedValue:birthdate];
    parameters[@"birthDate"] = birthdateString;
    
    NSDictionary *codeDict = [NSDictionary dictionaryWithObject:@"STUDENT" forKey:@"code"];
    parameters[@"role"] = codeDict;
    
    NSDictionary *ethnicityDict = [NSDictionary dictionaryWithObject:[ethnicity valueForKey:@"code"] forKey:@"code"];
    parameters[@"ethnicity"] = ethnicityDict;
    
    NSMutableArray *moneyOptionsArray = [NSMutableArray array];
    for (NSDictionary *moneyOption in moneyOptions) {
        NSDictionary *moneyOptionDict = [NSDictionary dictionaryWithObjectsAndKeys:[moneyOption valueForKey:@"code"], @"code", nil];
        [moneyOptionsArray addObject:moneyOptionDict];
    }
    parameters[@"moneyOptions"] = moneyOptionsArray;

    MTMakeWeakSelf();
    [self POST:@"users" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"Signup Success");
        
        // Now, need to authenticate to get OAuth access token
        [weakSelf authenticateForUsername:email withPassword:password success:^(id responseData) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(responseData);
                });
            }
        } failure:^(NSError *error) {
            NSLog(@"Failed authenticateForUsername after registering as student: %@", [error mtErrorDescription]);
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error);
                });
            }
        }];
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Failed to register as student with error: %@", [error mtErrorDescription]);
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}

- (void)getClassesWithSignupCode:(NSString *)signupCode success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"maxdepth"] = @"0";
    parameters[@"page_size"] = @"999";

    NSString *signupCodeString = [NSString stringWithFormat:@"SignupCode %@", signupCode];
    [self.requestSerializer setValue:signupCodeString forHTTPHeaderField:@"Authorization"];
    
    [self GET:@"organizations/classes" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"Success getting Classes response");
        NSDictionary *classesDict = [self processClassesRequestWithResponseObject:responseObject];
        
        if ([classesDict count] > 0) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(classesDict);
                });
            }
        }
        else {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(nil);
                });
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Failed to get classes with error: %@", [error mtErrorDescription]);
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}

- (void)getEthnicitiesWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"maxdepth"] = @"0";
    parameters[@"page_size"] = @"999";

    [self GET:@"ethnicities" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"Success getting Ethnicities response");
        NSArray *ethnicitiesArray = [self processEthnicitiesRequestWithResponseObject:responseObject];
        
        if ([ethnicitiesArray count] > 0) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(ethnicitiesArray);
                });
            }
        }
        else {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(nil);
                });
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Failed to get Ethnicities with error: %@", [error mtErrorDescription]);
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}

- (void)getMoneyOptionsWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"maxdepth"] = @"0";
    parameters[@"page_size"] = @"999";

    [self GET:@"money-options" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"Success getting Money Options response");
        NSArray *moneyOptionsArray = [self processMoneyOptionsRequestWithResponseObject:responseObject];
        
        if ([moneyOptionsArray count] > 0) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(moneyOptionsArray);
                });
            }
        }
        else {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(nil);
                });
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Failed to get Money Options with error: %@", [error mtErrorDescription]);
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}

- (void)requestPasswordResetEmailForEmail:(NSString *)email success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"email"] = email;
    
    [self POST:@"users/reset-password" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"requestPasswordResetEmailForEmail Success");
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(nil);
            });
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"requestPasswordResetEmailForEmail Failed with error: %@", [error mtErrorDescription]);
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}

- (void)sendNewPassword:(NSString *)newPassword withToken:(NSString *)token success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"password"] = newPassword;
    
    NSString *authString = [NSString stringWithFormat:@"Token %@", token];
    [self.requestSerializer setValue:authString forHTTPHeaderField:@"Authorization"];
    [self POST:@"users/reset-password-confirm" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"sendNewPassword Success");
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(nil);
            });
        }
        
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"sendNewPassword Failed with error: %@", [error mtErrorDescription]);
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}


#pragma mark - User Methods -
- (void)getAvatarForUserId:(NSInteger)userId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
        NSString *urlString = [NSString stringWithFormat:@"%@users/%ld/avatar", self.baseURL, (long)userId];
        
        [manager.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [manager.requestSerializer setValue:@"image/jpeg" forHTTPHeaderField:@"Accept"];
        [manager.requestSerializer setValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
        
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        NSMutableSet *contentTypes = [NSMutableSet setWithSet:[responseSerializer acceptableContentTypes]];
        [contentTypes addObject:@"image/jpeg"];
        responseSerializer.acceptableContentTypes = [NSSet setWithSet:contentTypes];
        manager.responseSerializer = responseSerializer;
        
        NSError *requestError = nil;
        NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:urlString parameters:nil error:&requestError];
        
        if (!requestError) {
            AFHTTPRequestOperation *requestOperation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"getAvatarForUserId success response");
                
                if (responseObject) {
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    
                    MTUser *thisUser = [MTUser objectForPrimaryKey:[NSNumber numberWithInteger:userId]];
                    
                    MTOptionalImage *optionalImage = thisUser.userAvatar;
                    if (!optionalImage) {
                        optionalImage = [[MTOptionalImage alloc] init];
                    }
                    
                    optionalImage.imageData = responseObject;
                    optionalImage.updatedAt = [NSDate date];
                    thisUser.userAvatar = optionalImage;
                    thisUser.hasAvatar = YES;
                    
                    [realm commitWriteTransaction];
                }
                
                if (success) {
                    success([UIImage imageWithData:responseObject]);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to get user avatar with error: %@", [error mtErrorDescription]);
                
                if ([error mtErrorCode] == 404) {
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    
                    MTUser *thisUser = [MTUser objectForPrimaryKey:[NSNumber numberWithInteger:userId]];
                    thisUser.userAvatar = nil;
                    thisUser.hasAvatar = NO;
                    
                    [realm commitWriteTransaction];
                }
                if (failure) {
                    failure(error);
                }
            }];
            
            [requestOperation start];
        }
        else {
            NSLog(@"Unable to construct request: %@", [requestError mtErrorDescription]);
            if (failure) {
                failure(requestError);
            }
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Failed to Auth to get user avatar with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)setMyAvatarWithImageData:(NSData *)imageData success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
        NSString *urlString = [NSString stringWithFormat:@"%@users/%ld/avatar", self.baseURL, (long)[MTUser currentUser].id];
        
        [manager.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [manager.requestSerializer setValue:@"image/jpeg" forHTTPHeaderField:@"Accept"];
        [manager.requestSerializer setValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
        
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        NSMutableSet *contentTypes = [NSMutableSet setWithSet:[responseSerializer acceptableContentTypes]];
        [contentTypes addObject:@"image/jpeg"];
        responseSerializer.acceptableContentTypes = [NSSet setWithSet:contentTypes];
        manager.responseSerializer = responseSerializer;
        
        NSError *requestError = nil;
        NSString *method = imageData ? @"PUT" : @"DELETE";
        NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:method URLString:urlString parameters:nil error:&requestError];
        
        if (!requestError) {
            request.HTTPBody = imageData;
            AFHTTPRequestOperation *requestOperation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"setAvatarForUserId success response");
                
                if (responseObject) {
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    
                    MTUser *meUser = [MTUser currentUser];
                    
                    if (imageData) {
                        if (!meUser.userAvatar) {
                            MTOptionalImage *userAvatar = [[MTOptionalImage alloc] init];
                            userAvatar.imageData = imageData;
                            userAvatar.updatedAt = [NSDate date];
                            meUser.userAvatar = userAvatar;
                        }
                        else {
                            meUser.userAvatar.imageData = imageData;
                        }
                    }
                    else {
                        meUser.userAvatar = nil;
                        meUser.hasAvatar = NO;
                    }
                    
                    [realm commitWriteTransaction];
                }
                
                if (success) {
                    success(nil);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to set user avatar with error: %@", [error mtErrorDescription]);
                if (failure) {
                    failure(error);
                }
            }];
            
            [requestOperation start];
        }
        else {
            NSLog(@"Unable to construct request: %@", [requestError mtErrorDescription]);
            if (failure) {
                failure(requestError);
            }
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Failed to set user avatar with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)updateCurrentUserWithFirstName:(NSString *)firstName
                              lastName:(NSString *)lastName
                                 email:(NSString *)email
                           phoneNumber:(NSString *)phoneNumber
                              password:(NSString *)password
                               success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        MTUser *currentUser = [MTUser currentUser];
        NSString *urlString = [NSString stringWithFormat:@"users/%ld", (long)currentUser.id];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"firstName"] = firstName;
        parameters[@"lastName"] = lastName;
        parameters[@"phoneNumber"] = phoneNumber;
        //        parameters[@"username"] = email;
        //        parameters[@"email"] = email;
        parameters[@"password"] = password;
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf PUT:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"updateCurrentUser success response");
            
            if (responseObject) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                
                MTUser *meUser = [MTUser currentUser];
                meUser.firstName = firstName;
                meUser.lastName = lastName;
                //                meUser.email = email;
                meUser.phoneNumber = phoneNumber;
                
                [realm commitWriteTransaction];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed updateCurrentUser with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed updateCurrentUser with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)refreshCurrentUserDataWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:responseData];
        [weakSelf GET:@"users/me" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            //            NSLog(@"Found me user");
            MTUser *meUser = [weakSelf processUserRequestWithResponseObject:responseObject];
            if (meUser) {
                //                NSLog(@"Parsed meUser object: %@", meUser);
                if (meUser.hasAvatar) {
                    [weakSelf getAvatarForUserId:meUser.id success:^(id responseData) {
                        NSLog(@"Retrieved user avatar");
                        if (success) {
                            success(nil);
                        }
                        
                    } failure:^(NSError *error) {
                        NSLog(@"Failed to retrieve user avatar, probably no avatar assigned");
                        if (failure) {
                            failure(error);
                        }
                    }];
                }
                else {
                    if (success) {
                        success(nil);
                    }
                }
            }
            else {
                if (success) {
                    success(nil);
                }
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"refreshCurrentUserData error: %@", [error mtErrorDescription]);
            [weakSelf checkForInternetAndReAuthWithError:error];
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"refreshCurrentUserData error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - Challenge Methods -
- (void)loadChallengesWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = @"999";

        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"class-challenges" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"class-challenges success response");
            
            if (responseObject) {
                [self processClassChallengesWithResponseObject:responseObject];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed class-challenges with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed class-challenges with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - Post Methods -
- (void)loadPostsForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"2";
        parameters[@"page_size"] = @"9990";
        parameters[@"challenge_id"] = [NSNumber numberWithInteger:challengeId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"posts" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"posts success response");
            
            if (responseObject) {
                [self processPostsWithResponseObject:responseObject challengeId:challengeId];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed posts with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed posts with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)getImageForPostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
        NSString *urlString = [NSString stringWithFormat:@"%@posts/%ld/picture", self.baseURL, (long)postId];
        
        [manager.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [manager.requestSerializer setValue:@"image/jpeg" forHTTPHeaderField:@"Accept"];
        [manager.requestSerializer setValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
        
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        NSMutableSet *contentTypes = [NSMutableSet setWithSet:[responseSerializer acceptableContentTypes]];
        [contentTypes addObject:@"image/jpeg"];
        responseSerializer.acceptableContentTypes = [NSSet setWithSet:contentTypes];
        manager.responseSerializer = responseSerializer;
        
        NSError *requestError = nil;
        NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:urlString parameters:nil error:&requestError];
        
        if (!requestError) {
            AFHTTPRequestOperation *requestOperation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
//                NSLog(@"getImageForPostId success response");
                
                if (responseObject) {
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    
                    MTChallengePost *thisPost = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postId]];
                    
                    MTOptionalImage *optionalImage = thisPost.postImage;
                    if (!optionalImage) {
                        optionalImage = [[MTOptionalImage alloc] init];
                    }
                    
                    optionalImage.imageData = responseObject;
                    optionalImage.updatedAt = [NSDate date];
                    thisPost.postImage = optionalImage;
                    
                    [realm commitWriteTransaction];
                }
                
                if (success) {
                    success([UIImage imageWithData:responseObject]);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed to get post image with error: %@", [error mtErrorDescription]);
                if (failure) {
                    failure(error);
                }
            }];
            
            [requestOperation start];
        }
        else {
            NSLog(@"Unable to construct request: %@", [requestError mtErrorDescription]);
            if (failure) {
                failure(requestError);
            }
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Failed to Auth to get post image with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)updatePostImageForPostId:(NSInteger)postId withImageData:(NSData *)imageData create:(BOOL)create success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
        NSString *urlString = [NSString stringWithFormat:@"%@posts/%ld/picture", self.baseURL, (long)postId];
        
        [manager.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [manager.requestSerializer setValue:@"image/jpeg" forHTTPHeaderField:@"Accept"];
        [manager.requestSerializer setValue:@"image/jpeg" forHTTPHeaderField:@"Content-Type"];
        
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        NSMutableSet *contentTypes = [NSMutableSet setWithSet:[responseSerializer acceptableContentTypes]];
        [contentTypes addObject:@"image/jpeg"];
        responseSerializer.acceptableContentTypes = [NSSet setWithSet:contentTypes];
        manager.responseSerializer = responseSerializer;
        
        NSError *requestError = nil;
        NSString *method = imageData ? @"PUT" : @"DELETE";
        if (create) {
            method = @"POST";
        }
        NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:method URLString:urlString parameters:nil error:&requestError];
        
        if (!requestError) {
            request.HTTPBody = imageData;
            AFHTTPRequestOperation *requestOperation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"updatePostImageForPostId success response");
                
                if (responseObject) {
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    
                    MTChallengePost *challengePost = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postId]];
                    
                    if (imageData) {
                        MTOptionalImage *postImage = challengePost.postImage;
                        if (!postImage) {
                            postImage = [[MTOptionalImage alloc] init];
                        }
                        
                        postImage.imageData = imageData;
                        postImage.updatedAt = [NSDate date];
                        challengePost.postImage = postImage;
                        challengePost.hasPostImage = YES;
                    }
                    else {
                        challengePost.postImage = nil;
                        challengePost.hasPostImage = NO;
                    }
                    
                    [realm commitWriteTransaction];
                }
                
                if (success) {
                    success(nil);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed updatePostImageForPostId with error: %@", [error mtErrorDescription]);
                if (failure) {
                    failure(error);
                }
            }];
            
            [requestOperation start];
        }
        else {
            NSLog(@"Unable to construct request: %@", [requestError mtErrorDescription]);
            if (failure) {
                failure(requestError);
            }
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Failed updatePostImageForPostId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)createPostForChallengeId:(NSInteger)challengeId content:(NSString *)content postImageData:(NSData *)postImageData extraData:(NSDictionary *)extraData success:(MTNetworkOAuthSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSString *urlString = [NSString stringWithFormat:@"posts"];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"content"] = content;
        parameters[@"challenge"] = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:challengeId] forKey:@"id"];
        parameters[@"class"] = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:[MTUser currentUser].userClass.id] forKey:@"id"];
        
        if (!IsEmpty(extraData)) {
            parameters[@"challengeData"] = extraData;
        }
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf POST:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"createPostForChallengeId success response");
            
            if (responseObject) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                MTChallengePost *newPost = [MTChallengePost createOrUpdateInRealm:realm withJSONDictionary:responseObject];
                
                MTChallenge *challenge = [MTChallenge objectForPrimaryKey:[NSNumber numberWithInteger:challengeId]];
                if (challenge) {
                    newPost.challenge = challenge;
                }
                
                MTClass *thisClass = [MTUser currentUser].userClass;
                if (thisClass) {
                    newPost.challengeClass = thisClass;
                }
                
                newPost.user = [MTUser currentUser];
                
                if (!IsEmpty(extraData)) {
                    NSError *error;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extraData options:0 error:&error];
                    if (!error) {
                        NSString *challangeDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        newPost.challengeData = challangeDataString;
                    }
                }

                [realm commitWriteTransaction];
                
                // Now POST image
                if (postImageData) {
                    [weakSelf updatePostImageForPostId:newPost.id withImageData:postImageData create:YES success:^(id responseData) {
                        RLMRealm *realm = [RLMRealm defaultRealm];
                        [realm beginWriteTransaction];
                        
                        MTChallengePost *updatedPost = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:newPost.id]];
                        MTOptionalImage *postImage = updatedPost.postImage;
                        if (!postImage) {
                            postImage = [[MTOptionalImage alloc] init];
                        }
                        postImage.imageData = postImageData;
                        updatedPost.postImage = postImage;
                        updatedPost.hasPostImage = YES;
                        
                        [realm commitWriteTransaction];
                        
                        if (success) {
                            success(nil);
                        }
                    } failure:^(NSError *error) {
                        if (failure) {
                            failure(error);
                        }
                    }];
                }
                else {
                    if (success) {
                        success(nil);
                    }
                }
            }
            else {
                if (failure) {
                    failure(nil);
                }
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed createPostForChallengeId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed createPostForChallengeId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)updatePostId:(NSInteger)postId content:(NSString *)content postImageData:(NSData *)postImageData extraData:(NSDictionary *)extraData success:(MTNetworkOAuthSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSString *urlString = [NSString stringWithFormat:@"posts/%ld", (long)postId];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"content"] = content;
        
        if (!IsEmpty(extraData)) {
            parameters[@"challengeData"] = extraData;
        }
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf PUT:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"updatePostId success response");
            
            if (responseObject) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                
                MTChallengePost *updatedPost = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postId]];
                updatedPost.content = content;
                
                if (!IsEmpty(extraData)) {
                    NSError *error;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extraData options:0 error:&error];
                    if (!error) {
                        NSString *challangeDataString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        updatedPost.challengeData = challangeDataString;
                    }
                }
                else {
                    updatedPost.challengeData = @"";
                }

                [realm commitWriteTransaction];

                // Now update image
                if (postImageData) {
                    [weakSelf updatePostImageForPostId:postId withImageData:postImageData create:NO success:^(id responseData) {
                        if (success) {
                            success(nil);
                        }
                    } failure:^(NSError *error) {
                        NSLog(@"Unable to update post image");
                        if (failure) {
                            failure(error);
                        }
                    }];
                }
                else {
                    if (success) {
                        success(nil);
                    }
                }
            }
            else {
                NSLog(@"Unable to update post, no responseObject");
                if (failure) {
                    failure(nil);
                }
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed updatePostId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed updatePostId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)deletePostId:(NSInteger)postId success:(MTNetworkOAuthSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSString *urlString = [NSString stringWithFormat:@"posts/%ld", (long)postId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf DELETE:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"deletePostId success response");
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            MTChallengePost *postToDelete = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postId]];
            if (postToDelete) {
                [realm deleteObject:postToDelete];
            }
            [realm commitWriteTransaction];
            
            if (success) {
                success(nil);
            }
         
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed deletePostId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed deletePostId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - Comment Methods -
- (void)loadCommentsForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"2";
        parameters[@"page_size"] = @"9990";
        parameters[@"challenge_id"] = [NSNumber numberWithInteger:challengeId];
//        NSString *urlString = [NSString stringWithFormat:@"comments/challenge_id=%lu", challengeId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"comments" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"loadCommentsForChallengeId success response");
            
            if (responseObject) {
                [self processCommentsWithResponseObject:responseObject challengeId:challengeId postId:0];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadCommentsForChallengeId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadCommentsForChallengeId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)loadCommentsForPostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"2";
        parameters[@"page_size"] = @"9990";
        NSString *urlString = [NSString stringWithFormat:@"comments/post_id=%lu", postId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"loadCommentsForPostId success response");
            
            if (responseObject) {
                [self processCommentsWithResponseObject:responseObject challengeId:0 postId:postId];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadCommentsForPostId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadCommentsForPostId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)createCommentForPostId:(NSInteger)postId content:(NSString *)content success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSString *urlString = [NSString stringWithFormat:@"comments"];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"content"] = content;
        parameters[@"post"] = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:postId] forKey:@"id"];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf POST:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"createCommentForPostId success response");
            
            if (responseObject) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                MTChallengePostComment *newComment = [MTChallengePostComment createOrUpdateInRealm:realm withJSONDictionary:responseObject];
                
                MTUser *meUser = [MTUser currentUser];
                newComment.user = meUser;
                
                MTChallengePost *post = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postId]];
                newComment.challengePost = post;
                
                [realm commitWriteTransaction];
                
                if (success) {
                    success(nil);
                }
            }
            else {
                if (failure) {
                    failure(nil);
                }
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed createCommentForPostId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed createCommentForPostId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)updateCommentId:(NSInteger)commentId content:(NSString *)content success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSString *urlString = [NSString stringWithFormat:@"comments/%ld", (long)commentId];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"content"] = content;
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf PUT:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"updateCommentId success response");
            
            if (responseObject) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                MTChallengePostComment *updatedPost = [MTChallengePostComment objectForPrimaryKey:[NSNumber numberWithInteger:commentId]];
                updatedPost.content = content;
                [realm commitWriteTransaction];
                
                if (success) {
                    success(nil);
                }
            }
            else {
                NSLog(@"Unable to update comment, no responseObject");
                if (failure) {
                    failure(nil);
                }
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed updateCommentId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed updateCommentId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)deleteCommentId:(NSInteger)commentId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSString *urlString = [NSString stringWithFormat:@"comments/%ld", (long)commentId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf DELETE:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"deleteCommentId success response");
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            MTChallengePostComment *commentToDelete = [MTChallengePostComment objectForPrimaryKey:[NSNumber numberWithInteger:commentId]];
            if (commentToDelete) {
                [realm deleteObject:commentToDelete];
            }
            [realm commitWriteTransaction];
            
            if (success) {
                success(nil);
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed deleteCommentId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed deleteCommentId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}


// TODO: Need to handle pagination

@end
