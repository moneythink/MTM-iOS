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

#ifdef STAGE
static NSString * const MTNetworkURLString = @"http://moneythink-api.staging.causelabs.com/";
#else
static NSString * const MTNetworkURLString = @"https://api.moneythink.org/";
#endif

static NSString * const MTNetworkAPIKey = @"cE4.G0_$";
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
        [self.requestSerializer setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
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
    [contentTypes addObject:@"text/html"];
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
                [weakSelf checkForInternetAndReAuthWithError:nil cannotConnectMessage:NO];
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
        [AFOAuthCredential storeCredential:credential withIdentifier:MTNetworkServiceOAuthCredentialKey];
        weakSelf.refreshingOAuthToken = NO;

        if (success) {
            success(credential);
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Failed to refresh AFOAuthCredential error: %@", [error mtErrorDescription]);
        weakSelf.refreshingOAuthToken = NO;
        [weakSelf checkForInternetAndReAuthWithError:error cannotConnectMessage:NO];

        if (failure) {
            failure(error);
        }
    }];
}

- (void)checkForInternetAndReAuthWithError:(NSError *)error cannotConnectMessage:(BOOL)cannotConnectMessage
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

        NSString *title = @"Authentication Error";
        NSString *message = @"Moneythink authentication token has expired or is invalid. Please Logout/Login again to continue accessing Moneythink services.";
        if (cannotConnectMessage) {
            title = @"Connection Error";
            message = @"Moneythink cannot connect to network services. Try again later or if problem persists, logout/login again.";
        }
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
    if (IsEmpty([embeddedDict objectForKey:@"organization"])) {
        return nil;
    }
    MTOrganization *userOrganization = [MTOrganization createOrUpdateInRealm:realm withJSONDictionary:[embeddedDict objectForKey:@"organization"]];
    userOrganization.isDeleted = NO;
    
    if (IsEmpty([embeddedDict objectForKey:@"class"])) {
        return nil;
    }
    MTClass *userClass = [MTClass createOrUpdateInRealm:realm withJSONDictionary:[embeddedDict objectForKey:@"class"]];
    userClass.isDeleted = NO;
    userClass.organization = userOrganization;

    // Create new ME User and send back
    MTUser *user = [MTUser createOrUpdateInRealm:realm withJSONDictionary:responseDict];
    user.isDeleted = NO;
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

- (NSDictionary *)processOrganizationsRequestWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No organizations response data");
        return nil;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No organizations response data");
        return nil;
    }
    
    NSDictionary *embeddedDict = (NSDictionary *)[responseDict objectForKey:@"_embedded"];
    if (![[embeddedDict objectForKey:@"organizations"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No organizations response data");
        return nil;
    }
    
    NSArray *responseArray = (NSArray *)[embeddedDict objectForKey:@"organizations"];
    NSMutableDictionary *organizationsDict = [NSMutableDictionary dictionary];
    
    for (NSDictionary *thisOrganization in responseArray) {
        NSString *organizationName = [thisOrganization objectForKey:@"name"];
        NSNumber *organizationId = [thisOrganization objectForKey:@"id"];
        
        if (!IsEmpty(organizationName) && [organizationId integerValue] > 0) {
            [organizationsDict setValue:organizationId forKey:organizationName];
        }
    }
    
    return organizationsDict;
}

- (NSDictionary *)processClassesRequestWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No classes response data");
        return nil;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No classes response data");
        return nil;
    }
    
    NSDictionary *embeddedDict = (NSDictionary *)[responseDict objectForKey:@"_embedded"];
    if (![[embeddedDict objectForKey:@"classes"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No classes response data");
        return nil;
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

- (NSDictionary *)processCreateClassRequestWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No classes response data");
        return nil;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    NSMutableDictionary *classesDict = [NSMutableDictionary dictionary];
    NSString *className = [responseDict objectForKey:@"name"];
    NSNumber *classId = [responseDict objectForKey:@"id"];
    
    if (!IsEmpty(className) && [classId integerValue] > 0) {
        [classesDict setValue:classId forKey:className];
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

- (void)processChallengePlaylistWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No user response data");
        return;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No embedded challenges data");
        return;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"playlist"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No playlist data");
        return;
    }
    
    NSArray *playlistArray = [embeddedDict objectForKey:@"playlist"];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    // Mark existing challenges deleted to filter out deleted challenges
    [MTChallenge markAllDeleted];
    [realm beginWriteTransaction];
    
    for (id playlistEntry in playlistArray) {
        if ([playlistEntry isKindOfClass:[NSDictionary class]]) {
            
            NSDictionary *playlistEntryDict = (NSDictionary *)playlistEntry;
            if ([[playlistEntryDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                
                NSInteger thisRanking = [[playlistEntryDict valueForKey:@"ranking"] integerValue];
                NSDictionary *innerEmbeddedDict = [playlistEntryDict objectForKey:@"_embedded"];
                
                if ([[innerEmbeddedDict objectForKey:@"challenge"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *challengeDict = [innerEmbeddedDict objectForKey:@"challenge"];
                    if (IsEmpty(challengeDict)) {
                        continue;
                    }
                    
                    // Now create/update challenge
                    MTChallenge *challenge = [MTChallenge createOrUpdateInRealm:realm withJSONDictionary:challengeDict];
                    challenge.ranking = thisRanking;
                    challenge.isPlaylistChallenge = YES;
                    challenge.isDeleted = NO;
                    
                    if ([[challengeDict objectForKey:@"postExtraFieldDefinitions"] isKindOfClass:[NSDictionary class]]) {
                        NSError *error;
                        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[challengeDict objectForKey:@"postExtraFieldDefinitions"] options:0 error:&error];
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
    
    // Mark existing posts deleted to filter out deleted posts
    RLMResults *existingPosts = [MTChallengePost objectsWhere:@"challenge.id = %lu", challengeId];
    for (MTChallengePost *thisPost in existingPosts) {
        thisPost.isDeleted = YES;
    }
    
    MTClass *myClass = [MTUser currentUser].userClass;
    MTOrganization *myOrganization = myClass.organization;

    for (id post in postsArray) {
        if ([post isKindOfClass:[NSDictionary class]]) {
            
            if (IsEmpty(post)) {
                continue;
            }
            MTChallengePost *challengePost = [MTChallengePost createOrUpdateInRealm:realm withJSONDictionary:post];
            challengePost.isDeleted = NO;
            
            NSDictionary *postDict = (NSDictionary *)post;
            if ([[postDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *innerEmbeddedDict = [postDict objectForKey:@"_embedded"];
                
                // Get user
                if ([[innerEmbeddedDict objectForKey:@"user"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *classDict = [innerEmbeddedDict objectForKey:@"class"];
                    
                    if (IsEmpty(classDict)) {
                        continue;
                    }
                    MTClass *thisClass = [MTClass createOrUpdateInRealm:realm withJSONDictionary:classDict];
                    thisClass.isDeleted = NO;
                    challengePost.challengeClass = thisClass;
                    
                    NSDictionary *userDict = [innerEmbeddedDict objectForKey:@"user"];
                    
                    if (IsEmpty(userDict)) {
                        challengePost.isDeleted = YES;
                        continue;
                    }
                    MTUser *thisUser = [MTUser createOrUpdateInRealm:realm withJSONDictionary:userDict];
                    thisUser.isDeleted = NO;
                    
                    if ([[userDict objectForKey:@"_links"] isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *linksDict = [userDict objectForKey:@"_links"];
                        if ([linksDict objectForKey:@"avatar"]) {
                            thisUser.hasAvatar = YES;
                        }
                        else {
                            thisUser.hasAvatar = NO;
                        }
                    }
                    
                    // Make sure my ID is not overwritten with missing data (class/org) from feed
                    if ([MTUser isUserMe:thisUser]) {
                        thisUser.userClass = myClass;
                        thisUser.organization = myOrganization;
                    }
                    else if (thisClass) {
                        thisUser.userClass = thisClass;
                    }
                    
                    challengePost.user = thisUser;

                    NSDictionary *challengeDict = [innerEmbeddedDict objectForKey:@"challenge"];
                    
                    if (IsEmpty(challengeDict)) {
                        challengePost.isDeleted = YES;
                        continue;
                    }
                    
                    NSNumber *challengeId = [challengeDict objectForKey:@"id"];
                    if (challengeId && [MTChallenge objectForPrimaryKey:challengeId]) {
                        MTChallenge *thisChallenge = [MTChallenge objectForPrimaryKey:challengeId];
                        challengePost.challenge = thisChallenge;
                    }
                    else {
                        challengePost.isDeleted = YES;
                        continue;
                    }
                    
                    id extraFieldsArray = [innerEmbeddedDict objectForKey:@"extraFieldValues"];
                    if ([extraFieldsArray isKindOfClass:[NSArray class]] && !IsEmpty(extraFieldsArray)) {
                        NSMutableDictionary *extraFieldsDict = [NSMutableDictionary dictionary];
                        for (NSDictionary *thisData in extraFieldsArray) {
                            NSString *name = [thisData valueForKey:@"name"];
                            NSString *value = [thisData valueForKey:@"value"];
                            if (!IsEmpty(name) && !IsEmpty(value)) {
                                [extraFieldsDict setObject:value forKey:name];
                            }
                        }
                        if (!IsEmpty(extraFieldsDict)) {
                            NSError *error;
                            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extraFieldsDict options:0 error:&error];
                            if (!error) {
                                NSString *extraFieldsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                                challengePost.extraFields = extraFieldsString;
                            }
                        }
                        else {
                            challengePost.extraFields = @"";
                        }
                    }
                    else {
                        challengePost.extraFields = @"";
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

- (void)processExplorePostsWithResponseObject:(id)responseObject challengeId:(NSInteger)challengeId
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No explore posts response data");
        return;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No embedded explore posts data");
        return;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"posts"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No explore posts data");
        return;
    }
    
    NSArray *postsArray = [embeddedDict objectForKey:@"posts"];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    // Mark existing posts (not in user class) deleted to filter out deleted explore posts
    RLMResults *existingPosts = [MTChallengePost objectsWhere:@"challenge.id = %lu AND challengeClass.id != %lu", challengeId, [MTUser currentUser].userClass.id];
    for (MTChallengePost *thisPost in existingPosts) {
        thisPost.isDeleted = YES;
    }
    
    MTClass *myClass = [MTUser currentUser].userClass;
    MTOrganization *myOrganization = myClass.organization;
    
    for (id post in postsArray) {
        if ([post isKindOfClass:[NSDictionary class]]) {
            
            if (IsEmpty(post)) {
                continue;
            }
            MTChallengePost *challengePost = [MTChallengePost createOrUpdateInRealm:realm withJSONDictionary:post];
            challengePost.isDeleted = NO;
            
            NSDictionary *postDict = (NSDictionary *)post;
            if ([[postDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *innerEmbeddedDict = [postDict objectForKey:@"_embedded"];
                
                // Get user
                if ([[innerEmbeddedDict objectForKey:@"user"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *classDict = [innerEmbeddedDict objectForKey:@"class"];
                    
                    if (IsEmpty(classDict)) {
                        continue;
                    }
                    MTClass *thisClass = [MTClass createOrUpdateInRealm:realm withJSONDictionary:classDict];
                    thisClass.isDeleted = NO;
                    challengePost.challengeClass = thisClass;
                    
                    NSDictionary *userDict = [innerEmbeddedDict objectForKey:@"user"];
                    
                    if (IsEmpty(userDict)) {
                        continue;
                    }
                    MTUser *thisUser = [MTUser createOrUpdateInRealm:realm withJSONDictionary:userDict];
                    thisUser.isDeleted = NO;
                    
                    if ([[userDict objectForKey:@"_links"] isKindOfClass:[NSDictionary class]]) {
                        NSDictionary *linksDict = [userDict objectForKey:@"_links"];
                        if ([linksDict objectForKey:@"avatar"]) {
                            thisUser.hasAvatar = YES;
                        }
                        else {
                            thisUser.hasAvatar = NO;
                        }
                    }
                    
                    // Make sure my ID is not overwritten with missing data (class/org) from feed
                    if ([MTUser isUserMe:thisUser]) {
                        thisUser.userClass = myClass;
                        thisUser.organization = myOrganization;
                    }
                    else if (thisClass) {
                        thisUser.userClass = thisClass;
                    }
                    
                    challengePost.user = thisUser;
                    
                    NSDictionary *challengeDict = [innerEmbeddedDict objectForKey:@"challenge"];
                    
                    if (IsEmpty(challengeDict)) {
                        challengePost.isDeleted = YES;
                        continue;
                    }
                    
                    NSNumber *challengeId = [challengeDict objectForKey:@"id"];
                    if (challengeId && [MTChallenge objectForPrimaryKey:challengeId]) {
                        MTChallenge *thisChallenge = [MTChallenge objectForPrimaryKey:challengeId];
                        challengePost.challenge = thisChallenge;
                    }
                    else {
                        challengePost.isDeleted = YES;
                        continue;
                    }
                    
                    id extraFieldsArray = [innerEmbeddedDict objectForKey:@"extraFieldValues"];
                    if ([extraFieldsArray isKindOfClass:[NSArray class]] && !IsEmpty(extraFieldsArray)) {
                        NSMutableDictionary *extraFieldsDict = [NSMutableDictionary dictionary];
                        for (NSDictionary *thisData in extraFieldsArray) {
                            NSString *name = [thisData valueForKey:@"name"];
                            NSString *value = [thisData valueForKey:@"value"];
                            if (!IsEmpty(name) && !IsEmpty(value)) {
                                [extraFieldsDict setObject:value forKey:name];
                            }
                        }
                        if (!IsEmpty(extraFieldsDict)) {
                            NSError *error;
                            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extraFieldsDict options:0 error:&error];
                            if (!error) {
                                NSString *extraFieldsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                                challengePost.extraFields = extraFieldsString;
                            }
                        }
                        else {
                            challengePost.extraFields = @"";
                        }
                    }
                    else {
                        challengePost.extraFields = @"";
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

- (void)processPostWithResponseObject:(id)responseObject
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
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    MTClass *myClass = [MTUser currentUser].userClass;
    MTOrganization *myOrganization = myClass.organization;
    
    MTChallengePost *challengePost = [MTChallengePost createOrUpdateInRealm:realm withJSONDictionary:responseDict];
    challengePost.isDeleted = NO;
    
    if ([[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        
        NSDictionary *innerEmbeddedDict = [responseDict objectForKey:@"_embedded"];
        
        // Get user
        if ([[innerEmbeddedDict objectForKey:@"user"] isKindOfClass:[NSDictionary class]]) {
            NSDictionary *classDict = [innerEmbeddedDict objectForKey:@"class"];
            MTClass *thisClass = nil;
            
            if (!IsEmpty(classDict)) {
                MTClass *thisClass = [MTClass createOrUpdateInRealm:realm withJSONDictionary:classDict];
                thisClass.isDeleted = NO;
                challengePost.challengeClass = thisClass;
            }
            
            NSDictionary *userDict = [innerEmbeddedDict objectForKey:@"user"];
            
            if (!IsEmpty(userDict)) {
                MTUser *thisUser = [MTUser createOrUpdateInRealm:realm withJSONDictionary:userDict];
                thisUser.isDeleted = NO;
                
                if ([[userDict objectForKey:@"_links"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *linksDict = [userDict objectForKey:@"_links"];
                    if ([linksDict objectForKey:@"avatar"]) {
                        thisUser.hasAvatar = YES;
                    }
                    else {
                        thisUser.hasAvatar = NO;
                    }
                }
                
                // Make sure my ID is not overwritten with missing data (class/org) from feed
                if ([MTUser isUserMe:thisUser]) {
                    thisUser.userClass = myClass;
                    thisUser.organization = myOrganization;
                }
                else if (thisClass) {
                    thisUser.userClass = thisClass;
                }
                
                challengePost.user = thisUser;
            }
            
            NSDictionary *challengeDict = [innerEmbeddedDict objectForKey:@"challenge"];
            
            if (IsEmpty(challengeDict)) {
                challengePost.isDeleted = YES;
            }
            
            NSNumber *challengeId = [challengeDict objectForKey:@"id"];
            if (challengeId && [MTChallenge objectForPrimaryKey:challengeId]) {
                MTChallenge *thisChallenge = [MTChallenge objectForPrimaryKey:challengeId];
                challengePost.challenge = thisChallenge;
            }
            else {
                challengePost.isDeleted = YES;
            }

            id extraFieldsArray = [innerEmbeddedDict objectForKey:@"extraFieldValues"];
            if ([extraFieldsArray isKindOfClass:[NSArray class]] && !IsEmpty(extraFieldsArray)) {
                NSMutableDictionary *extraFieldsDict = [NSMutableDictionary dictionary];
                for (NSDictionary *thisData in extraFieldsArray) {
                    NSString *name = [thisData valueForKey:@"name"];
                    NSString *value = [thisData valueForKey:@"value"];
                    if (!IsEmpty(name) && !IsEmpty(value)) {
                        [extraFieldsDict setObject:value forKey:name];
                    }
                }
                if (!IsEmpty(extraFieldsDict)) {
                    NSError *error;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extraFieldsDict options:0 error:&error];
                    if (!error) {
                        NSString *extraFieldsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        challengePost.extraFields = extraFieldsString;
                    }
                }
                else {
                    challengePost.extraFields = @"";
                }
            }
            else {
                challengePost.extraFields = @"";
            }
        }
        
        // Get Image
        NSDictionary *linksDict = [responseDict objectForKey:@"_links"];
        if ([linksDict objectForKey:@"picture"]) {
            challengePost.hasPostImage = YES;
        }
        else {
            challengePost.hasPostImage = NO;
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
            
            if (IsEmpty(comment)) {
                continue;
            }
            MTChallengePostComment *challengePostComment = [MTChallengePostComment createOrUpdateInRealm:realm withJSONDictionary:comment];
            challengePostComment.isDeleted = NO;
            
            NSDictionary *commentDict = (NSDictionary *)comment;
            if ([[commentDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *innerEmbeddedDict = [commentDict objectForKey:@"_embedded"];
                
                // Get user
                if ([[innerEmbeddedDict objectForKey:@"user"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *userDict = [innerEmbeddedDict objectForKey:@"user"];
                    
                    if (!IsEmpty(userDict)) {
                        MTUser *thisUser = [MTUser createOrUpdateInRealm:realm withJSONDictionary:userDict];
                        thisUser.isDeleted = NO;
                        
                        if ([[userDict objectForKey:@"_links"] isKindOfClass:[NSDictionary class]]) {
                            NSDictionary *linksDict = [userDict objectForKey:@"_links"];
                            if ([linksDict objectForKey:@"avatar"]) {
                                thisUser.hasAvatar = YES;
                            }
                            else {
                                thisUser.hasAvatar = NO;
                            }
                        }
                        
                        challengePostComment.user = thisUser;
                    }
                    
                    NSDictionary *challengePostDict = [innerEmbeddedDict objectForKey:@"post"];
                    
                    if (!IsEmpty(challengePostDict)) {
                        MTChallengePost *thisChallengePost = [MTChallengePost createOrUpdateInRealm:realm withJSONDictionary:challengePostDict];
                        thisChallengePost.isDeleted = NO;
                        challengePostComment.challengePost = thisChallengePost;
                    }
                }
            }
        }
    }
    [realm commitWriteTransaction];
}

- (void)processEmojisWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No emojis response data");
        return;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No embedded emojis data");
        return;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"emojis"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No emojis data");
        return;
    }
    
    NSMutableArray *emojiCodesToFetch = [NSMutableArray array];
    NSArray *emojisArray = [embeddedDict objectForKey:@"emojis"];
    
    // Mark existing emojis deleted to filter out deleted emojis
    [MTEmoji markAllDeleted];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    for (id emoji in emojisArray) {
        if ([emoji isKindOfClass:[NSDictionary class]]) {
            BOOL shouldFetchEmojiImage = NO;

            // See if we have existing Emoji and check updated timestamp to see if we need to
            //  refresh the image.
            NSString *emojiCode = [emoji objectForKey:@"code"];
            NSDate *oldUpdatedAt = nil;
            if (!IsEmpty(emojiCode)) {
                MTEmoji *oldEmojiObject = [MTEmoji objectForPrimaryKey:emojiCode];
                if (oldEmojiObject) {
                    oldUpdatedAt = oldEmojiObject.updatedAt;
                }
            }
            
            if (IsEmpty(emoji)) {
                continue;
            }
            MTEmoji *emojiObject = [MTEmoji createOrUpdateInRealm:realm withJSONDictionary:emoji];
            emojiObject.isDeleted = NO;
            
            if (!emojiObject.emojiImage) {
                shouldFetchEmojiImage = YES;
            }
            else if (oldUpdatedAt && emojiObject.updatedAt) {
                if ([emojiObject.updatedAt timeIntervalSince1970] > [oldUpdatedAt timeIntervalSince1970]) {
                    shouldFetchEmojiImage = YES;
                }
            }
            
            if (shouldFetchEmojiImage) {
                [emojiCodesToFetch addObject:emojiObject.code];
            }
        }
    }
    [realm commitWriteTransaction];
    
    for (NSString *emojiCode in emojiCodesToFetch) {
        [self getEmojiImageForEmojiCode:emojiCode success:nil failure:nil];
    }
}

- (void)processLikesWithResponseObject:(id)responseObject challengeId:(NSInteger)challengeId postId:(NSInteger)postId
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No likes response data");
        return;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No likes comments data");
        return;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"likes"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No likes data");
        return;
    }
    
    NSArray *likesArray = [embeddedDict objectForKey:@"likes"];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    // Mark existing likes deleted to filter out deleted likes
    if (challengeId > 0) {
        // for challenge
        RLMResults *existingLikes = [MTChallengePostLike objectsWhere:@"challengePost.challenge.id = %lu", challengeId];
        for (MTChallengePostLike *thisLike in existingLikes) {
            thisLike.isDeleted = YES;
        }
    }
    else {
        // for post
        RLMResults *existingLikes = [MTChallengePostLike objectsWhere:@"challengePost.id = %lu", postId];
        for (MTChallengePostLike *thisLike in existingLikes) {
            thisLike.isDeleted = YES;
        }
    }
    
    for (id like in likesArray) {
        if ([like isKindOfClass:[NSDictionary class]]) {
            
            if (IsEmpty(like)) {
                continue;
            }
            MTChallengePostLike *challengePostLike = [MTChallengePostLike createOrUpdateInRealm:realm withJSONDictionary:like];
            challengePostLike.isDeleted = NO;
            
            NSDictionary *likeDict = (NSDictionary *)like;
            if ([[likeDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *innerEmbeddedDict = [likeDict objectForKey:@"_embedded"];
                
                // Get embedded data
                if ([[innerEmbeddedDict objectForKey:@"user"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *userDict = [innerEmbeddedDict objectForKey:@"user"];
                    
                    if (!IsEmpty(userDict)) {
                        MTUser *thisUser = [MTUser createOrUpdateInRealm:realm withJSONDictionary:userDict];
                        
                        if ([[userDict objectForKey:@"_links"] isKindOfClass:[NSDictionary class]]) {
                            NSDictionary *linksDict = [userDict objectForKey:@"_links"];
                            if ([linksDict objectForKey:@"avatar"]) {
                                thisUser.hasAvatar = YES;
                            }
                            else {
                                thisUser.hasAvatar = NO;
                            }
                        }
                        
                        thisUser.isDeleted = NO;
                        challengePostLike.user = thisUser;
                    }
                }
                
                if ([[innerEmbeddedDict objectForKey:@"post"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *challengePostDict = [innerEmbeddedDict objectForKey:@"post"];
                    if (!IsEmpty(challengePostDict)) {
                        MTChallengePost *thisChallengePost = [MTChallengePost createOrUpdateInRealm:realm withJSONDictionary:challengePostDict];
                        thisChallengePost.isDeleted = NO;
                        challengePostLike.challengePost = thisChallengePost;
                    }
                }

                if ([[innerEmbeddedDict objectForKey:@"emoji"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *emojiDict = [innerEmbeddedDict objectForKey:@"emoji"];
                    if (!IsEmpty(emojiDict)) {
                        MTEmoji *thisEmoji = [MTEmoji createOrUpdateInRealm:realm withJSONDictionary:emojiDict];
                        thisEmoji.isDeleted = NO;
                        challengePostLike.emoji = thisEmoji;
                    }
                }
            }
        }
    }
    [realm commitWriteTransaction];
}

- (void)processButtonsWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No buttons response data");
        return;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No buttons comments data");
        return;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"buttons"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No buttons data");
        return;
    }
    
    NSArray *buttonsArray = [embeddedDict objectForKey:@"buttons"];
    
    // Mark existing buttons deleted to filter out deleted comments
    [MTChallengeButton markAllDeleted];

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    for (id button in buttonsArray) {
        if ([button isKindOfClass:[NSDictionary class]]) {
            
            if (IsEmpty(button)) {
                continue;
            }
            MTChallengeButton *challengeButton = [MTChallengeButton createOrUpdateInRealm:realm withJSONDictionary:button];
            challengeButton.isDeleted = NO;
            
            NSDictionary *buttonDict = (NSDictionary *)button;
            if ([[buttonDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *innerEmbeddedDict = [buttonDict objectForKey:@"_embedded"];
                
                // Get embedded data
                if ([[innerEmbeddedDict objectForKey:@"buttonType"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *buttonTypeDict = [innerEmbeddedDict objectForKey:@"buttonType"];
                    if ([buttonTypeDict objectForKey:@"code"]) {
                        challengeButton.buttonTypeCode = [buttonTypeDict objectForKey:@"code"];
                    }
                }
                
                if ([[innerEmbeddedDict objectForKey:@"challenge"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *challengeDict = [innerEmbeddedDict objectForKey:@"challenge"];
                    if (!IsEmpty(challengeDict)) {
                        
                        NSNumber *challengeId = [challengeDict objectForKey:@"id"];
                        if (challengeId && [MTChallenge objectForPrimaryKey:challengeId]) {
                            MTChallenge *thisChallenge = [MTChallenge objectForPrimaryKey:challengeId];
                            challengeButton.challenge = thisChallenge;
                        }
                        else {
                            challengeButton.isDeleted = YES;
                            continue;
                        }
                    }
                    else {
                        challengeButton.isDeleted = YES;
                        continue;
                    }
                }
            }
        }
    }
    [realm commitWriteTransaction];
}

- (void)processButtonClicksWithResponseObject:(id)responseObject challengeId:(NSInteger)challengeId postId:(NSInteger)postId
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No button-clicks response data");
        return;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No button-clicks comments data");
        return;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"buttonClicks"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No button-clicks data");
        return;
    }
    
    NSArray *buttonClicksArray = [embeddedDict objectForKey:@"buttonClicks"];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    if (challengeId > 0) {
        // for challenge
        RLMResults *existingButtons = [MTChallengeButtonClick objectsWhere:@"challengePost.challenge.id = %lu", challengeId];
        for (MTChallengeButton *thisButton in existingButtons) {
            thisButton.isDeleted = YES;
        }
    }
    else {
        // for post
        RLMResults *existingButtons = [MTChallengeButtonClick objectsWhere:@"challengePost.id = %lu", postId];
        for (MTChallengeButton *thisButton in existingButtons) {
            thisButton.isDeleted = YES;
        }
    }
    
    for (id buttonClick in buttonClicksArray) {
        if ([buttonClick isKindOfClass:[NSDictionary class]]) {
            
            if (IsEmpty(buttonClick)) {
                continue;
            }
            MTChallengeButtonClick *challengeButtonClick = [MTChallengeButtonClick createOrUpdateInRealm:realm withJSONDictionary:buttonClick];
            challengeButtonClick.isDeleted = NO;
            
            NSDictionary *buttonDict = (NSDictionary *)buttonClick;
            if ([[buttonDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *innerEmbeddedDict = [buttonDict objectForKey:@"_embedded"];
                
                // Get embedded data
                if ([[innerEmbeddedDict objectForKey:@"user"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *userDict = [innerEmbeddedDict objectForKey:@"user"];
                    if (!IsEmpty(userDict)) {
                        MTUser *thisUser = [MTUser createOrUpdateInRealm:realm withJSONDictionary:userDict];
                        thisUser.isDeleted = NO;
                        challengeButtonClick.user = thisUser;
                    }
                }
                
                if ([[innerEmbeddedDict objectForKey:@"post"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *challengePostDict = [innerEmbeddedDict objectForKey:@"post"];
                    if (!IsEmpty(challengePostDict)) {
                        MTChallengePost *thisChallengePost = [MTChallengePost createOrUpdateInRealm:realm withJSONDictionary:challengePostDict];
                        thisChallengePost.isDeleted = NO;
                        challengeButtonClick.challengePost = thisChallengePost;
                    }
                }
                
                if ([[innerEmbeddedDict objectForKey:@"button"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *buttonDict = [innerEmbeddedDict objectForKey:@"button"];
                    if (!IsEmpty(buttonDict)) {
                        MTChallengeButton *thisButton = [MTChallengeButton createOrUpdateInRealm:realm withJSONDictionary:buttonDict];
                        thisButton.isDeleted = NO;
                        challengeButtonClick.challengeButton = thisButton;
                    }
                }
            }
        }
    }
    [realm commitWriteTransaction];
}

- (void)processChallengeProgressWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No challenge-progress response data");
        return;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No challenge-progress data");
        return;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"studentChallenges"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No challenge-progress data");
        return;
    }
    
    NSArray *studentChallengesArray = [embeddedDict objectForKey:@"studentChallenges"];
    
    [MTChallengeProgress markAllDeleted];

    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    for (id progress in studentChallengesArray) {
        if ([progress isKindOfClass:[NSDictionary class]]) {
            
            if (IsEmpty(progress)) {
                continue;
            }
            MTChallengeProgress *challengeProgress = [MTChallengeProgress createOrUpdateInRealm:realm withJSONDictionary:progress];
            challengeProgress.isDeleted = NO;
            challengeProgress.user = [MTUser currentUser];
            
            NSDictionary *challengeProgressDict = (NSDictionary *)progress;
            if ([[challengeProgressDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *innerEmbeddedDict = [challengeProgressDict objectForKey:@"_embedded"];
                
                // Get embedded data
                if ([[innerEmbeddedDict objectForKey:@"challenge"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *challengeDict = [innerEmbeddedDict objectForKey:@"challenge"];
                    if (!IsEmpty(challengeDict)) {
                        NSNumber *challengeId = [challengeDict objectForKey:@"id"];
                        if (challengeId && [MTChallenge objectForPrimaryKey:challengeId]) {
                            MTChallenge *thisChallenge = [MTChallenge objectForPrimaryKey:challengeId];
                            challengeProgress.challenge = thisChallenge;
                        }
                        else {
                            challengeProgress.isDeleted = YES;
                            continue;
                        }
                    }
                    else {
                        challengeProgress.isDeleted = YES;
                        continue;
                    }
                }
            }
        }
    }
    [realm commitWriteTransaction];
}

- (void)processNotificationsWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No notifications response data");
        return;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No notifications data");
        return;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"notifications"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No notifications data");
        return;
    }
    
    NSArray *notificationsArray = [embeddedDict objectForKey:@"notifications"];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    for (id notification in notificationsArray) {
        if ([notification isKindOfClass:[NSDictionary class]] && !IsEmpty(notification)) {
            MTNotification *thisNotification = [MTNotification createOrUpdateInRealm:realm withJSONDictionary:notification];
            thisNotification.isDeleted = NO;
            
            NSDictionary *notificationDict = (NSDictionary *)notification;
            
            // Related Comment
            if ([[notificationDict objectForKey:@"relatedComment"] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *relatedCommentDict = [notificationDict objectForKey:@"relatedComment"];
                if (!IsEmpty(relatedCommentDict)) {
                    MTChallengePostComment *relatedComment = [MTChallengePostComment createOrUpdateInRealm:realm withJSONDictionary:relatedCommentDict];
                    relatedComment.isDeleted = NO;
                    thisNotification.relatedComment = relatedComment;
                }
            }

            if ([[notificationDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *innerEmbeddedDict = [notificationDict objectForKey:@"_embedded"];
                
                // Get embedded data, related data
                if ([[innerEmbeddedDict objectForKey:@"relatedChallenge"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *challengeDict = [innerEmbeddedDict objectForKey:@"relatedChallenge"];
                    if (!IsEmpty(challengeDict)) {
                        NSNumber *challengeId = [challengeDict objectForKey:@"id"];
                        if (challengeId && [MTChallenge objectForPrimaryKey:challengeId]) {
                            MTChallenge *thisChallenge = [MTChallenge objectForPrimaryKey:challengeId];
                            thisNotification.relatedChallenge = thisChallenge;
                        }
                        else {
                            thisNotification.isDeleted = YES;
                            continue;
                        }
                    }
                }
                
                if ([[innerEmbeddedDict objectForKey:@"relatedPost"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *postDict = [innerEmbeddedDict objectForKey:@"relatedPost"];
                    if (!IsEmpty(postDict)) {
                        MTChallengePost *thisPost = [MTChallengePost createOrUpdateInRealm:realm withJSONDictionary:postDict];
                        thisPost.isDeleted = NO;
                        thisNotification.relatedPost = thisPost;
                    }
                }
                
                if ([[innerEmbeddedDict objectForKey:@"relatedUser"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *userDict = [innerEmbeddedDict objectForKey:@"relatedUser"];
                    if (!IsEmpty(userDict)) {
                        MTUser *thisUser = [MTUser createOrUpdateInRealm:realm withJSONDictionary:userDict];
                        
                        if ([[userDict objectForKey:@"_links"] isKindOfClass:[NSDictionary class]]) {
                            NSDictionary *linksDict = [userDict objectForKey:@"_links"];
                            if ([linksDict objectForKey:@"avatar"]) {
                                thisUser.hasAvatar = YES;
                            }
                            else {
                                thisUser.hasAvatar = NO;
                            }
                        }
                        
                        thisUser.isDeleted = NO;
                        thisNotification.relatedUser = thisUser;
                    }
                }
            }
        }
    }
    [realm commitWriteTransaction];
}

- (void)processDashboardUsersWithResponseObject:(id)responseObject
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No dashboard users response data");
        return;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No dashboard users data");
        return;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"users"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No dashboard users members data");
        return;
    }
    
    NSArray *usersArray = [embeddedDict objectForKey:@"users"];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    for (id user in usersArray) {
        if ([user isKindOfClass:[NSDictionary class]]) {
            
            NSDictionary *userDict = (NSDictionary *)user;
            
            if (IsEmpty(userDict)) {
                continue;
            }
            MTUser *thisUser = [MTUser createOrUpdateInRealm:realm withJSONDictionary:userDict];
            thisUser.isDeleted = NO;
            thisUser.organization = [MTUser currentUser].organization;
            thisUser.userClass = [MTUser currentUser].userClass;

            if ([[userDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                
                NSDictionary *innerEmbeddedDict = [userDict objectForKey:@"_embedded"];
                
                if ([[innerEmbeddedDict objectForKey:@"student"] isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *student = [innerEmbeddedDict objectForKey:@"student"];
                    if (!IsEmpty(student)) {
                        thisUser.hasBankAccount = [[student objectForKey:@"hasBankAccount"] boolValue];
                        thisUser.hasResume = [[student objectForKey:@"hasResume"] boolValue];
                        thisUser.points = [[student objectForKey:@"points"] integerValue];
                    }
                }
            }
            
            if ([[userDict objectForKey:@"_links"] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *linksDict = [userDict objectForKey:@"_links"];
                if ([linksDict objectForKey:@"avatar"]) {
                    thisUser.hasAvatar = YES;
                }
                else {
                    thisUser.hasAvatar = NO;
                }
            }
        }
    }
    [realm commitWriteTransaction];
}

- (void)processUserPostsWithResponseObject:(id)responseObject userId:(NSInteger)userId
{
    if (![responseObject isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No user posts response data");
        return;
    }
    
    NSDictionary *responseDict = (NSDictionary *)responseObject;
    
    if (![[responseDict objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No user posts data");
        return;
    }
    
    NSDictionary *embeddedDict = [responseDict objectForKey:@"_embedded"];
    
    if (![[embeddedDict objectForKey:@"posts"] isKindOfClass:[NSArray class]]) {
        NSLog(@"No user posts data");
        return;
    }
    
    NSArray *postsArray = [embeddedDict objectForKey:@"posts"];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    MTUser *thisUser = [MTUser objectForPrimaryKey:[NSNumber numberWithInteger:userId]];

    for (id post in postsArray) {
        if ([post isKindOfClass:[NSDictionary class]]) {
            NSDictionary *postDict = (NSDictionary *)post;
            if (IsEmpty(postDict)) {
                continue;
            }
            MTChallengePost *thisPost = [MTChallengePost createOrUpdateInRealm:realm withJSONDictionary:postDict];
            thisPost.isDeleted = NO;
            thisPost.user = thisUser;
            thisPost.challengeClass = thisUser.userClass;
            
            if ([[post objectForKey:@"_links"] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *innerLinksDict = (NSDictionary *)[post objectForKey:@"_links"];
                if (innerLinksDict[@"picture"]) {
                    thisPost.hasPostImage = YES;
                }
            }
            
            if ([[post objectForKey:@"_embedded"] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *innerEmbeddedDict = (NSDictionary *)[post objectForKey:@"_embedded"];
                
                NSInteger likesCount = 0;
                NSInteger commentCount = 0;
                
                if ([[innerEmbeddedDict objectForKey:@"likes"] isKindOfClass:[NSArray class]]) {
                    NSArray *likesArray = [innerEmbeddedDict objectForKey:@"likes"];
                    likesCount = [likesArray count];
                }
                
                if ([[innerEmbeddedDict objectForKey:@"comments"] isKindOfClass:[NSArray class]]) {
                    NSArray *commentsArray = [innerEmbeddedDict objectForKey:@"comments"];
                    commentCount = [commentsArray count];
                }
                
                if ([innerEmbeddedDict objectForKey:@"feedFromPost"]) {
                    thisPost.isCrossPost = YES;
                }
                
                NSDictionary *challengeDict = [innerEmbeddedDict objectForKey:@"challenge"];
                NSNumber *challengeId = [challengeDict objectForKey:@"id"];
                if (challengeId && [MTChallenge objectForPrimaryKey:challengeId]) {
                    MTChallenge *thisChallenge = [MTChallenge objectForPrimaryKey:challengeId];
                    thisPost.challenge = thisChallenge;
                    thisPost.challengeRanking = thisChallenge.ranking;
                }
                
                NSString *complexId = [NSString stringWithFormat:@"%lu-%lu", (long)thisUser.id, (long)thisPost.id];
                MTUserPostPropertyCount *existing = [MTUserPostPropertyCount objectForPrimaryKey:complexId];
                if (!existing) {
                    existing = [[MTUserPostPropertyCount alloc] init];
                    existing.complexId = complexId;
                }
                
                existing.isDeleted = NO;
                existing.user = thisUser;
                existing.post = thisPost;
                existing.likeCount = likesCount;
                existing.commentCount = commentCount;
                
                [realm addOrUpdateObject:existing];
            }
        }
    }
    [realm commitWriteTransaction];
}


#pragma mark - Public Methods -
- (void)cancelExistingOperations
{
    [self.oauthRefreshQueue cancelAllOperations];
}


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
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";

        [AFOAuthCredential storeCredential:credential withIdentifier:MTNetworkServiceOAuthCredentialKey];
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:credential];
        [weakSelf GET:@"users/me" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
//            NSLog(@"Found me user");
            MTUser *meUser = [weakSelf processUserRequestWithResponseObject:responseObject];
            if (meUser) {
//                NSLog(@"Parsed meUser object: %@", meUser);
                BOOL shouldFetchAvatar = NO;
                
                if (meUser.hasAvatar && !meUser.userAvatar) {
                    shouldFetchAvatar = YES;
                }
                else if (meUser.hasAvatar && meUser.userAvatar) {
                    if ([meUser.updatedAt timeIntervalSince1970] > [meUser.userAvatar.updatedAt timeIntervalSince1970]) {
                        shouldFetchAvatar = YES;
                    }
                }
                
                if (shouldFetchAvatar) {
                    [weakSelf getAvatarForUserId:meUser.id success:^(id responseData) {
//                        NSLog(@"Retrieved new or updated user avatar");
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
                    NSLog(@"Already have latest user avatar");
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
              organizationId:(NSNumber *)organizationId
                     classId:(NSNumber *)classId
                newClassName:(NSString *)newClassName success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
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

    NSDictionary *organizationDict = [NSDictionary dictionaryWithObject:organizationId forKey:@"id"];
    parameters[@"organization"] = organizationDict;

    if (!IsEmpty(newClassName)) {
        NSDictionary *classDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:0], @"id", newClassName, @"name", nil];
        parameters[@"class"] = classDict;
    }
    else {
        NSDictionary *classDict = [NSDictionary dictionaryWithObject:classId forKey:@"id"];
        parameters[@"class"] = classDict;
    }
    
    NSString *signupCodeString = [NSString stringWithFormat:@"SignupCode %@", signupCode];
    [self.requestSerializer setValue:signupCodeString forHTTPHeaderField:@"Authorization"];

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
    
    if (ethnicity != nil) {
        NSDictionary *ethnicityDict = [NSDictionary dictionaryWithObject:[ethnicity valueForKey:@"code"] forKey:@"code"];
        parameters[@"ethnicity"] = ethnicityDict;
    }
    
    NSMutableArray *moneyOptionsArray = [NSMutableArray array];
    for (NSDictionary *moneyOption in moneyOptions) {
        NSDictionary *moneyOptionDict = [NSDictionary dictionaryWithObjectsAndKeys:[moneyOption valueForKey:@"code"], @"code", nil];
        [moneyOptionsArray addObject:moneyOptionDict];
    }
    parameters[@"moneyOptions"] = moneyOptionsArray;
    
    NSString *signupCodeString = [NSString stringWithFormat:@"SignupCode %@", signupCode];
    [self.requestSerializer setValue:signupCodeString forHTTPHeaderField:@"Authorization"];

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

- (void)getOrganizationsWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"0";
        parameters[@"page_size"] = @"9990";
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        
        [self GET:@"organizations" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"Success getOrganizationsWithSuccess response");
            NSDictionary *organizationsDict = [self processOrganizationsRequestWithResponseObject:responseObject];
            
            if ([organizationsDict count] > 0) {
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        success(organizationsDict);
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
            NSLog(@"Failed getOrganizationsWithSuccess with error: %@", [error mtErrorDescription]);
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error);
                });
            }
        }];

    } failure:^(NSError *error) {
        NSLog(@"Failed getOrganizationsWithSuccess with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
    
}

- (void)getOrganizationsWithSignupCode:(NSString *)signupCode success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    if (IsEmpty(signupCode)) {
        [self getOrganizationsWithSuccess:success failure:failure];
        return;
    }
    
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"maxdepth"] = @"0";
    parameters[@"page_size"] = @"999";
    
    NSString *signupCodeString = [NSString stringWithFormat:@"SignupCode %@", signupCode];
    [self.requestSerializer setValue:signupCodeString forHTTPHeaderField:@"Authorization"];
    
    [self GET:@"mentor-organizations" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"Success getting Organizations response");
        NSDictionary *organizationsDict = [self processOrganizationsRequestWithResponseObject:responseObject];
        
        if ([organizationsDict count] > 0) {
            if (success) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    success(organizationsDict);
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
        NSLog(@"Failed to get organizations with error: %@", [error mtErrorDescription]);
        if (failure) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failure(error);
            });
        }
    }];
}

- (void)getClassesWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = @"9990";
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        
        [self GET:@"classes" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"Success getClassesWithSuccess response");
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
            NSLog(@"Failed getClassesWithSuccess with error: %@", [error mtErrorDescription]);
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error);
                });
            }
        }];
        
    } failure:^(NSError *error) {
        NSLog(@"Failed getClassesWithSuccess with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
    
}

- (void)createClassWithName:(NSString *)name organizationId:(NSInteger)organizationId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = @"9990";
        parameters[@"name"] = name;
        parameters[@"organization"] = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:organizationId] forKey:@"id"];

        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        
        [self POST:@"classes" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"Success createClassWithName response");
            NSDictionary *classesDict = [self processCreateClassRequestWithResponseObject:responseObject];
            
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
            NSLog(@"Failed createClassWithName with error: %@", [error mtErrorDescription]);
            if (failure) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    failure(error);
                });
            }
        }];
        
    } failure:^(NSError *error) {
        NSLog(@"Failed createClassWithName with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
    
}

- (void)getClassesWithSignupCode:(NSString *)signupCode organizationId:(NSInteger)organizationId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"maxdepth"] = @"0";
    parameters[@"page_size"] = @"999";
    
    NSString *urlString = [NSString stringWithFormat:@"organizations/%ld/classes", (long)organizationId];

    NSString *signupCodeString = [NSString stringWithFormat:@"SignupCode %@", signupCode];
    [self.requestSerializer setValue:signupCodeString forHTTPHeaderField:@"Authorization"];
    
    [self GET:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
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
        [contentTypes addObject:@"image/png"];
        responseSerializer.acceptableContentTypes = [NSSet setWithSet:contentTypes];
        manager.responseSerializer = responseSerializer;
        
        NSError *requestError = nil;
        NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:urlString parameters:nil error:&requestError];
        
        if (!requestError) {
            AFHTTPRequestOperation *requestOperation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
//                NSLog(@"getAvatarForUserId success response");
                
                if (responseObject) {
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    
                    MTUser *thisUser = [MTUser objectForPrimaryKey:[NSNumber numberWithInteger:userId]];
                    
                    MTOptionalImage *optionalImage = thisUser.userAvatar;
                    if (!optionalImage) {
                        optionalImage = [[MTOptionalImage alloc] init];
                    }
                    
                    optionalImage.isDeleted = NO;
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
                        organizationId:(NSInteger)organizationId
                               classId:(NSInteger)classId
                               success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        MTUser *currentUser = [MTUser currentUser];
        NSString *urlString = [NSString stringWithFormat:@"users/%ld?maxdepth=1", (long)currentUser.id];

        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        
        if (!IsEmpty(firstName)) {
            parameters[@"firstName"] = firstName;
        }
        
        if (!IsEmpty(lastName)) {
            parameters[@"lastName"] = lastName;
        }
        
        if (!IsEmpty(phoneNumber)) {
            parameters[@"phoneNumber"] = phoneNumber;
        }
        
        if (!IsEmpty(email)) {
            parameters[@"email"] = email;
            parameters[@"username"] = email;
        }

        if (!IsEmpty(password)) {
            parameters[@"password"] = password;
        }
        
        if (organizationId > 0) {
            parameters[@"organization"] = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:organizationId] forKey:@"id"];
        }
        
        if (classId > 0) {
            parameters[@"class"] = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:classId] forKey:@"id"];
        }
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf PUT:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"updateCurrentUser success response");
            
            if (responseObject) {
                MTUser *meUser = [weakSelf processUserRequestWithResponseObject:responseObject];
                NSLog(@"updated User: %@", meUser);
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

- (void)setOnboardingCompleteForCurrentUserWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        MTUser *currentUser = [MTUser currentUser];
        NSString *urlString = [NSString stringWithFormat:@"users/%ld", (long)currentUser.id];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"onboardingComplete"] = [NSNumber numberWithBool:YES];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf PUT:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"setOnboardingCompleteForCurrentUserWithSuccess success response");
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            [MTUser currentUser].onboardingComplete = YES;
            [realm commitWriteTransaction];
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed setOnboardingCompleteForCurrentUserWithSuccess with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed setOnboardingCompleteForCurrentUserWithSuccess with error: %@", [error mtErrorDescription]);
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
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";

        [weakSelf GET:@"users/me" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"refreshCurrentUserDataWithSuccess");
            MTUser *meUser = [weakSelf processUserRequestWithResponseObject:responseObject];
            if (meUser) {
                //                NSLog(@"Parsed meUser object: %@", meUser);
                BOOL shouldFetchAvatar = NO;
                
                if (meUser.hasAvatar && !meUser.userAvatar) {
                    shouldFetchAvatar = YES;
                }
                else if (meUser.hasAvatar && meUser.userAvatar) {
                    if ([meUser.updatedAt timeIntervalSince1970] > [meUser.userAvatar.updatedAt timeIntervalSince1970]) {
                        shouldFetchAvatar = YES;
                    }
                }
                
                if (shouldFetchAvatar) {
                    [weakSelf getAvatarForUserId:meUser.id success:^(id responseData) {
//                        NSLog(@"Retrieved new or updated user avatar");
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
//                    NSLog(@"Already have latest user avatar");
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
            // Silently fail on network connection errors
            NSInteger code = [error code];
            if (code == NSURLErrorTimedOut || code == NSURLErrorCancelled || code == NSURLErrorCannotFindHost ||
                code == NSURLErrorCannotConnectToHost || code == NSURLErrorNetworkConnectionLost || code == NSURLErrorDNSLookupFailed ||
                code == NSURLErrorResourceUnavailable || code == NSURLErrorNotConnectedToInternet) {
                
                if (failure) {
                    failure(error);
                }
            }
            else {
                [weakSelf checkForInternetAndReAuthWithError:error cannotConnectMessage:YES];
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
        

        NSString *path = nil;
        if ([MTUser currentUser] != nil && [[MTUser currentUser] userClass] != nil) {
            NSUInteger currentClassId = [[[MTUser currentUser] userClass] id];
            path = [NSString stringWithFormat:@"classes/%lu/playlist", (unsigned long)currentClassId, nil];
        }
        
        if (path == nil) {
            NSError * error = [NSError errorWithDomain:@"No valid class id" code:1 userInfo:nil];
            return failure(error);
        }

        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:path parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"loadChallengesWithSuccess success response");
            
            if (responseObject) {
                [self processChallengePlaylistWithResponseObject:responseObject];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadChallengesWithSuccess with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadChallengesWithSuccess with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)getChallengeBannerImageForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
        NSString *urlString = [NSString stringWithFormat:@"%@challenges/%ld/banner", self.baseURL, (long)challengeId];
        
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
                //                NSLog(@"getChallengeBannerImageForChallengeId success response");
                
                if (responseObject) {
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    
                    MTChallenge *thisChallenge = [MTChallenge objectForPrimaryKey:[NSNumber numberWithInteger:challengeId]];
                    
                    MTOptionalImage *optionalImage = thisChallenge.banner;
                    if (!optionalImage) {
                        optionalImage = [[MTOptionalImage alloc] init];
                    }
                    
                    optionalImage.isDeleted = NO;
                    optionalImage.imageData = responseObject;
                    optionalImage.updatedAt = [NSDate date];
                    thisChallenge.banner = optionalImage;
                    
                    [realm commitWriteTransaction];
                }
                
                if (success) {
                    success([UIImage imageWithData:responseObject]);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed getChallengeBannerImageForChallengeId with error: %@", [error mtErrorDescription]);
                if (failure) {
                    failure(error);
                }
            }];
            
            [requestOperation start];
        }
        else {
            NSLog(@"Failed getChallengeBannerImageForChallengeId with error: %@", [requestError mtErrorDescription]);
            if (failure) {
                failure(requestError);
            }
        }
        
    } failure:^(NSError *error) {
        NSLog(@"Failed getChallengeBannerImageForChallengeId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)loadChallengeProgressWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = @"999";
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"student-challenges" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"loadChallengeProgressWithSuccess success response");
            
            if (responseObject) {
                [self processChallengeProgressWithResponseObject:responseObject];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadChallengeProgressWithSuccess with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadChallengeProgressWithSuccess with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - Post Methods -
- (void)loadPostsForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
//    __block NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];
    
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        __block NSTimeInterval finishWaitTime = [[NSDate date] timeIntervalSince1970];
//        NSLog(@"loadPostsForChallengeId success response; wait time: %f", finishWaitTime-startTime);

        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"2";
        parameters[@"page_size"] = @"999";
        parameters[@"challenge_id"] = [NSNumber numberWithInteger:challengeId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"posts" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSTimeInterval finishTime = [[NSDate date] timeIntervalSince1970];
            NSLog(@"loadPostsForChallengeId success response; load time: %f", finishTime-finishWaitTime);
            
            if (responseObject) {
                [self processPostsWithResponseObject:responseObject challengeId:challengeId];
            }
            
//            NSLog(@"loadPostsForChallengeId process time: %f seconds", [[NSDate date] timeIntervalSince1970]-finishTime);
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadPostsForChallengeId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadPostsForChallengeId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)loadPostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"2";
        parameters[@"page_size"] = @"999";
        
        NSString *urlString = [NSString stringWithFormat:@"posts/%ld", (long)postId];

        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"loadPostId success response");
            
            if (responseObject) {
                [self processPostWithResponseObject:responseObject];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadPostId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadPostId with error: %@", [error mtErrorDescription]);
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
        [contentTypes addObject:@"image/png"];
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
                    thisPost.isDeleted = NO;
                    
                    MTOptionalImage *optionalImage = thisPost.postImage;
                    if (!optionalImage) {
                        optionalImage = [[MTOptionalImage alloc] init];
                    }
                    
                    optionalImage.isDeleted = NO;
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

- (void)updatePostImageForPostId:(NSInteger)postId withImageData:(NSData *)imageData success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
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
        NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:method URLString:urlString parameters:nil error:&requestError];
        
        if (!requestError) {
            request.HTTPBody = imageData;
            AFHTTPRequestOperation *requestOperation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"updatePostImageForPostId success response");
                
                if (responseObject) {
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    
                    MTChallengePost *challengePost = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postId]];
                    challengePost.isDeleted = NO;
                    
                    if (imageData) {
                        MTOptionalImage *postImage = challengePost.postImage;
                        if (!postImage) {
                            postImage = [[MTOptionalImage alloc] init];
                        }
                        
                        postImage.isDeleted = NO;
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

- (void)createPostForChallengeId:(NSInteger)challengeId content:(NSString *)content postImageData:(NSData *)postImageData extraFields:(NSDictionary *)extraFields success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSString *urlString = [NSString stringWithFormat:@"posts"];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"content"] = content;
        parameters[@"challenge"] = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:challengeId] forKey:@"id"];
        parameters[@"class"] = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:[MTUser currentUser].userClass.id] forKey:@"id"];
        
        if (!IsEmpty(extraFields)) {
            parameters[@"extraFieldValues"] = extraFields;
        }
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf POST:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"createPostForChallengeId success response");
            
            if (!IsEmpty(responseObject)) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                MTChallengePost *newPost = [MTChallengePost createOrUpdateInRealm:realm withJSONDictionary:responseObject];
                newPost.isDeleted = NO;
                
                MTChallenge *challenge = [MTChallenge objectForPrimaryKey:[NSNumber numberWithInteger:challengeId]];
                challenge.isDeleted = NO;
                
                if (challenge) {
                    newPost.challenge = challenge;
                }
                
                MTClass *thisClass = [MTUser currentUser].userClass;
                if (thisClass) {
                    newPost.challengeClass = thisClass;
                }
                
                newPost.user = [MTUser currentUser];
                
                if (!IsEmpty(extraFields)) {
                    NSError *error;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extraFields options:0 error:&error];
                    if (!error) {
                        NSString *extraFieldsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        newPost.extraFields = extraFieldsString;
                    }
                }

                [realm commitWriteTransaction];
                
                // Now POST image
                if (postImageData) {
                    [weakSelf updatePostImageForPostId:newPost.id withImageData:postImageData success:^(id responseData) {
                        RLMRealm *realm = [RLMRealm defaultRealm];
                        [realm beginWriteTransaction];
                        
                        MTChallengePost *updatedPost = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:newPost.id]];
                        MTOptionalImage *postImage = updatedPost.postImage;
                        if (!postImage) {
                            postImage = [[MTOptionalImage alloc] init];
                        }
                        
                        postImage.isDeleted = NO;
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

- (void)updatePostId:(NSInteger)postId content:(NSString *)content postImageData:(NSData *)postImageData hadImage:(BOOL)hadImage extraFields:(NSDictionary *)extraFields success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure;
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSString *urlString = [NSString stringWithFormat:@"posts/%ld", (long)postId];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"content"] = content;
        
        if (!IsEmpty(extraFields)) {
            parameters[@"extraFieldValues"] = extraFields;
        }
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf PUT:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"updatePostId success response");
            
            if (responseObject) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                
                MTChallengePost *updatedPost = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postId]];
                updatedPost.content = content;
                
                if (!IsEmpty(extraFields)) {
                    NSError *error;
                    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:extraFields options:0 error:&error];
                    if (!error) {
                        NSString *extraFieldsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                        updatedPost.extraFields = extraFieldsString;
                    }
                }
                else {
                    updatedPost.extraFields = @"";
                }

                [realm commitWriteTransaction];

                // Now update image
                if (postImageData) {
                    [weakSelf updatePostImageForPostId:postId withImageData:postImageData success:^(id responseData) {
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
                else if (hadImage) {
                    [weakSelf updatePostImageForPostId:postId withImageData:nil success:^(id responseData) {
                        [realm beginWriteTransaction];
                        MTChallengePost *updatedPost = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postId]];
                        updatedPost.isDeleted = NO;
                        updatedPost.hasPostImage = NO;
                        updatedPost.postImage = nil;
                        [realm commitWriteTransaction];

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

- (void)deletePostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
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

- (void)verifyPostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"post"] = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:postId] forKey:@"id"];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf POST:@"posts/verify" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"verifyPostId success response");
            
            if (responseObject) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                
                MTChallengePost *updatedPost = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postId]];
                updatedPost.isDeleted = NO;
                updatedPost.isVerified = YES;
                
                [realm commitWriteTransaction];
                
                if (success) {
                    success(nil);
                }
            }
            else {
                NSLog(@"Unable to update post, no responseObject");
                if (failure) {
                    failure(nil);
                }
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed verifyPostId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed verifyPostId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)unVerifyPostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"post"] = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:postId] forKey:@"id"];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf POST:@"posts/unverify" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"unVerifyPostId success response");
            
            if (responseObject) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                
                MTChallengePost *updatedPost = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postId]];
                updatedPost.isDeleted = NO;
                updatedPost.isVerified = NO;
                
                [realm commitWriteTransaction];
                
                if (success) {
                    success(nil);
                }
            }
            else {
                NSLog(@"Unable to update post, no responseObject");
                if (failure) {
                    failure(nil);
                }
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed unVerifyPostId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed verifyPostId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)loadPostsForUserId:(NSInteger)userId success:(MTNetworkPaginatedSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    [self loadPostsForUserId:userId page:1 success:success failure:failure];
}

- (void)loadPostsForUserId:(NSInteger)userId page:(NSUInteger)page success:(MTNetworkPaginatedSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    [self loadPostsForUserId:userId page:page params:@{} success:success failure:failure];
}

- (void)loadPostsForUserId:(NSInteger)userId page:(NSUInteger)page params:(NSDictionary*)params success:(MTNetworkPaginatedSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithDictionary:params];
        NSUInteger pageSize = 10;
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = [NSString stringWithFormat:@"%lu", (unsigned long)pageSize];
        parameters[@"page"] = [NSString stringWithFormat:@"%lu", (unsigned long)page];
        parameters[@"user_id"] = [NSString stringWithFormat:@"%ld", (long)userId];
        
        NSLog(@"Querying page %lu", (unsigned long)page);
        
        NSString *urlString = @"posts";

        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"loadPostsForUserId success response");
            
            if (responseObject) {
                [self processUserPostsWithResponseObject:responseObject userId:userId];
            }
            
            if (success) {
                NSUInteger numPages = (NSUInteger)[[responseObject objectForKey:@"page_count"] integerValue];
                NSUInteger totalItems = (NSUInteger)[[responseObject objectForKey:@"total_items"] integerValue];
                BOOL lastPage = page >= numPages;
                success(lastPage, numPages, totalItems);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadPostsForUserId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadPostsForUserId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - Comment Methods -
- (void)loadCommentsForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
//    __block NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];

    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        __block NSTimeInterval finishWaitTime = [[NSDate date] timeIntervalSince1970];
//        NSLog(@"loadCommentsForChallengeId success response; wait time: %f", finishWaitTime-startTime);

        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = @"999";
        parameters[@"challenge_id"] = [NSNumber numberWithInteger:challengeId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"comments" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSTimeInterval finishTime = [[NSDate date] timeIntervalSince1970];
            NSLog(@"loadCommentsForChallengeId success response; load time: %f", finishTime-finishWaitTime);
            
            if (responseObject) {
                [self processCommentsWithResponseObject:responseObject challengeId:challengeId postId:0];
            }
            
//            NSLog(@"loadCommentsForChallengeId process time: %f seconds", [[NSDate date] timeIntervalSince1970]-finishTime);

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
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = @"999";
        parameters[@"post_id"] = [NSNumber numberWithInteger:postId];

        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"comments" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
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
            
            if (!IsEmpty(responseObject)) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                MTChallengePostComment *newComment = [MTChallengePostComment createOrUpdateInRealm:realm withJSONDictionary:responseObject];
                newComment.isDeleted = NO;
                
                MTUser *meUser = [MTUser currentUser];
                newComment.user = meUser;
                
                MTChallengePost *post = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postId]];
                post.isDeleted = NO;
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
                MTChallengePostComment *updatedPostComment = [MTChallengePostComment objectForPrimaryKey:[NSNumber numberWithInteger:commentId]];
                updatedPostComment.isDeleted = NO;
                updatedPostComment.content = content;
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


#pragma mark - Liking/Emoji Methods -
- (void)loadEmojiWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = @"999";
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"emojis" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"loadEmojiWithSuccess success response");
            
            if (responseObject) {
                [self processEmojisWithResponseObject:responseObject];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadEmojiWithSuccess with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadEmojiWithSuccess with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)getEmojiImageForEmojiCode:(NSString *)emojiCode success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        AFHTTPRequestOperationManager *manager = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:self.baseURL];
        NSString *urlString = [NSString stringWithFormat:@"%@emojis/%@/icon", self.baseURL, emojiCode];
        
        [manager.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [manager.requestSerializer setValue:@"image/png" forHTTPHeaderField:@"Accept"];
        [manager.requestSerializer setValue:@"image/png" forHTTPHeaderField:@"Content-Type"];
        
        AFHTTPResponseSerializer *responseSerializer = [AFHTTPResponseSerializer serializer];
        NSMutableSet *contentTypes = [NSMutableSet setWithSet:[responseSerializer acceptableContentTypes]];
        [contentTypes addObject:@"image/png"];
        responseSerializer.acceptableContentTypes = [NSSet setWithSet:contentTypes];
        manager.responseSerializer = responseSerializer;
        
        NSError *requestError = nil;
        NSMutableURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:urlString parameters:nil error:&requestError];
        
        if (!requestError) {
            AFHTTPRequestOperation *requestOperation = [manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
//                NSLog(@"getEmojiImageForEmojiName success response");
                
                if (responseObject) {
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    
                    MTEmoji *thisEmoji = [MTEmoji objectForPrimaryKey:emojiCode];
                    thisEmoji.isDeleted = NO;
                    
                    if (thisEmoji) {
                        MTOptionalImage *optionalImage = thisEmoji.emojiImage;
                        if (!optionalImage) {
                            optionalImage = [[MTOptionalImage alloc] init];
                        }
    
                        optionalImage.isDeleted = NO;
                        optionalImage.imageData = responseObject;
                        optionalImage.updatedAt = [NSDate date];
                        thisEmoji.emojiImage = optionalImage;
                    }
                    
                    [realm commitWriteTransaction];
                }
                
                if (success) {
                    success([UIImage imageWithData:responseObject]);
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed getEmojiImageForEmojiName with error: %@", [error mtErrorDescription]);
                
                if ([error mtErrorCode] == 404) {
                    RLMRealm *realm = [RLMRealm defaultRealm];
                    [realm beginWriteTransaction];
                    
                    MTEmoji *thisEmoji = [MTEmoji objectForPrimaryKey:emojiCode];
                    thisEmoji.isDeleted = NO;
                    
                    if (thisEmoji) {
                        thisEmoji.emojiImage = nil;
                    }
                    
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
        NSLog(@"Failed to Auth to get emoji with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)loadLikesForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
//    __block NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];

    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        __block NSTimeInterval finishWaitTime = [[NSDate date] timeIntervalSince1970];
//        NSLog(@"loadLikesForChallengeId success response; wait time: %f", finishWaitTime-startTime);

        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = @"999";
        parameters[@"challenge_id"] = [NSNumber numberWithInteger:challengeId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"likes" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSTimeInterval finishTime = [[NSDate date] timeIntervalSince1970];
            NSLog(@"loadLikesForChallengeId success response; load time: %f", finishTime-finishWaitTime);
            
            if (responseObject) {
                [self processLikesWithResponseObject:responseObject challengeId:challengeId postId:0];
            }
            
//            NSLog(@"loadLikesForChallengeId process time: %f seconds", [[NSDate date] timeIntervalSince1970]-finishTime);

            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadLikesForChallengeId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadLikesForChallengeId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)loadLikesForPostId:(NSInteger)postId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = @"999";
        parameters[@"post_id"] = [NSNumber numberWithInteger:postId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"likes" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"loadLikesForPostId success response");
            
            if (responseObject) {
                [self processLikesWithResponseObject:responseObject challengeId:0 postId:postId];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadLikesForPostId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadLikesForPostId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)addLikeForPostId:(NSInteger)postId emojiCode:(NSString *)emojiCode success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSString *urlString = [NSString stringWithFormat:@"likes"];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"emoji"] = [NSDictionary dictionaryWithObject:emojiCode forKey:@"code"];
        parameters[@"post"] = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:postId] forKey:@"id"];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf POST:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"addLikeForPostId success response");
            
            if (!IsEmpty(responseObject)) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                MTChallengePostLike *newLike = [MTChallengePostLike createOrUpdateInRealm:realm withJSONDictionary:responseObject];
                newLike.isDeleted = NO;
                
                MTUser *meUser = [MTUser currentUser];
                newLike.user = meUser;
                
                MTChallengePost *post = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postId]];
                post.isDeleted = NO;
                newLike.challengePost = post;
                
                MTEmoji *emoji = [MTEmoji objectForPrimaryKey:emojiCode];
                emoji.isDeleted = NO;
                newLike.emoji = emoji;
                
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
            NSLog(@"Failed addLikeForPostId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed addLikeForPostId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)updateLikeId:(NSInteger)likeId emojiCode:(NSString *)emojiCode success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSString *urlString = [NSString stringWithFormat:@"likes/%ld", (long)likeId];

        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"emoji"] = [NSDictionary dictionaryWithObject:emojiCode forKey:@"code"];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf PUT:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"updateLikeId success response");
            
            if (!IsEmpty(responseObject)) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                MTChallengePostLike *updatedLike = [MTChallengePostLike createOrUpdateInRealm:realm withJSONDictionary:responseObject];
                updatedLike.isDeleted = NO;
                
                MTEmoji *emoji = [MTEmoji objectForPrimaryKey:emojiCode];
                emoji.isDeleted = NO;
                updatedLike.emoji = emoji;
                
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
            NSLog(@"Failed updateLikeId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed updateLikeId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - Buttons -
- (void)loadButtonsWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = @"999";
        parameters[@"class_id"] = [NSNumber numberWithInteger:[MTUser currentUser].userClass.id];

        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"buttons" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"loadButtonsWithSuccess success response");
            
            if (responseObject) {
                [self processButtonsWithResponseObject:responseObject];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadButtonsWithSuccess with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadButtonsWithSuccess with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)loadButtonClicksForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = @"999";
        parameters[@"challenge_id"] = [NSNumber numberWithInteger:challengeId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"button-clicks" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"loadButtonClicksForChallengeId success response");
            
            if (responseObject) {
                [self processButtonClicksWithResponseObject:responseObject challengeId:challengeId postId:0];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadButtonClicksForChallengeId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadButtonClicksForChallengeId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)addButtonClickForPostId:(NSInteger)postId buttonId:(NSInteger)buttonId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSString *urlString = [NSString stringWithFormat:@"button-clicks"];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"post"] = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:postId] forKey:@"id"];
        parameters[@"button"] = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:buttonId] forKey:@"id"];

        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf POST:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"addButtonClickForPostId success response");
            
            if (!IsEmpty(responseObject)) {
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                MTChallengeButtonClick *newButtonClick = [MTChallengeButtonClick createOrUpdateInRealm:realm withJSONDictionary:responseObject];
                newButtonClick.isDeleted = NO;
                
                MTUser *meUser = [MTUser currentUser];
                newButtonClick.user = meUser;
                
                MTChallengePost *post = [MTChallengePost objectForPrimaryKey:[NSNumber numberWithInteger:postId]];
                post.isDeleted = NO;
                newButtonClick.challengePost = post;
                
                MTChallengeButton *button = [MTChallengeButton objectForPrimaryKey:[NSNumber numberWithInteger:buttonId]];
                button.isDeleted = NO;
                newButtonClick.challengeButton = button;
                
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
            NSLog(@"Failed addButtonClickForPostId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed addButtonClickForPostId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)deleteButtonClickId:(NSInteger)buttonClickId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSString *urlString = [NSString stringWithFormat:@"button-clicks/%ld", (long)buttonClickId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf DELETE:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"deleteButtonClickId success response");
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            MTChallengeButtonClick *buttonClickToDelete = [MTChallengeButtonClick objectForPrimaryKey:[NSNumber numberWithInteger:buttonClickId]];
            if (buttonClickToDelete) {
                buttonClickToDelete.isDeleted = YES;
            }
            [realm commitWriteTransaction];
            
            if (success) {
                success(nil);
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed deleteButtonClickId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed deleteButtonClickId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - Notifications -
- (void)loadNotificationsWithSinceDate:(NSDate *)sinceDate includeRead:(BOOL)includeRead success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = @"999";
        
        if (!includeRead) {
            parameters[@"filter"] = @"unread";
        }
        
        if (sinceDate) {
            parameters[@"since"] = sinceDate;
        }
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"notifications" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"loadNotificationsWithSinceDate success response");
            
            if (responseObject) {
                [self processNotificationsWithResponseObject:responseObject];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadNotificationsWithSinceDate with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadNotificationsWithSinceDate with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)loadNotificationId:(NSInteger)notificationId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"2";
        parameters[@"page_size"] = @"999";
        
        NSString *urlString = [NSString stringWithFormat:@"notifications/%ld", (long)notificationId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"loadNotificationId success response");
            
            if (responseObject) {
                [self processNotificationsWithResponseObject:responseObject];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadNotificationId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadNotificationId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)markReadForNotificationId:(NSInteger)notificationId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSString *urlString = [NSString stringWithFormat:@"notifications/%lu/read", (long)notificationId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf POST:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"markReadForNotificationId success response");
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            MTNotification *thisNotification = [MTNotification objectForPrimaryKey:[NSNumber numberWithInteger:notificationId]];
            if (thisNotification) {
                thisNotification.read = YES;
            }
            [realm commitWriteTransaction];
            
            if (success) {
                success(nil);
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed markReadForNotificationId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed markReadForNotificationId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)markAllNotificationsReadWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf POST:@"notifications/read-all" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"markAllNotificationsReadWithSuccess success response");
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            RLMResults *allNotifications = [MTNotification allObjects];
            for (MTNotification *notif in allNotifications) {
                notif.read = YES;
            }
            [realm commitWriteTransaction];
            
            if (success) {
                success(nil);
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed markAllNotificationsReadWithSuccess with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed markAllNotificationsReadWithSuccess with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)createPushMessagingRegistrationWithDeviceToken:(NSString *)deviceToken success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        NSString *urlString = [NSString stringWithFormat:@"push-messaging-registrations"];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"deviceType"] = @"ios";
        parameters[@"registrationId"] = deviceToken;
        parameters[@"deviceId"] = deviceToken;

        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf POST:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"createPushMessagingRegistrationWithDeviceToken success response");
            
            if (responseObject) {
                if ([responseObject objectForKey:@"id"]) {
                    [MTUtil setPushMessagingRegistrationId:[[responseObject objectForKey:@"id"] integerValue]];
                }
                
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
            NSLog(@"Failed createPushMessagingRegistrationWithDeviceToken with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed createPushMessagingRegistrationWithDeviceToken with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)updatePushMessagingRegistrationId:(NSInteger)pushMessagingRegistrationId withDeviceToken:(NSString *)deviceToken success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSString *urlString = [NSString stringWithFormat:@"push-messaging-registrations/%lu", (long)pushMessagingRegistrationId];
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"deviceType"] = @"ios";
        parameters[@"registrationId"] = deviceToken;
        parameters[@"deviceId"] = deviceToken;
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf PUT:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"updatePushMessagingRegistrationId success response");
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed updatePushMessagingRegistrationId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed updatePushMessagingRegistrationId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)deletePushMessagingRegistrationId:(NSInteger)pushMessagingRegistrationId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSString *urlString = [NSString stringWithFormat:@"push-messaging-registrations/%lu", (long)pushMessagingRegistrationId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf DELETE:urlString parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"deletePushMessagingRegistrationId success response");
            [MTUtil setPushMessagingRegistrationId:0];
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed deletePushMessagingRegistrationId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed deletePushMessagingRegistrationId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - Explore -
- (void)loadExplorePostsForChallengeId:(NSInteger)challengeId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
//    __block NSTimeInterval startTime = [[NSDate date] timeIntervalSince1970];

    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        __block NSTimeInterval finishWaitTime = [[NSDate date] timeIntervalSince1970];
//        NSLog(@"loadExplorePostsForChallengeId success response; wait time: %f", finishWaitTime-startTime);

        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"2";
        parameters[@"page_size"] = @"20";
        
        NSString *urlString = [NSString stringWithFormat:@"challenges/%lu/explore", (long)challengeId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSTimeInterval finishTime = [[NSDate date] timeIntervalSince1970];
            NSLog(@"loadExplorePostsForChallengeId success response; load time: %f", finishTime-finishWaitTime);
            
            if (responseObject) {
                [self processExplorePostsWithResponseObject:responseObject challengeId:challengeId];
            }
//            NSLog(@"loadExplorePostsForChallengeId process time: %f seconds", [[NSDate date] timeIntervalSince1970]-finishTime);
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadExplorePostsForChallengeId with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadExplorePostsForChallengeId with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - Dashboard -
- (void)loadDashboardUsersWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"maxdepth"] = @"1";
        parameters[@"page_size"] = @"999";
        
        NSString *urlString = [NSString stringWithFormat:@"classes/%lu/students", (long)[MTUser currentUser].userClass.id];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"loadDashboardUsersWithSuccess success response");
            
            if (responseObject) {
                [self processDashboardUsersWithResponseObject:responseObject];
            }
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed loadDashboardUsersWithSuccess with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed loadDashboardUsersWithSuccess with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)setBankValue:(BOOL)bankValue forUserId:(NSInteger)userId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"hasBankAccount"] = [NSNumber numberWithBool:bankValue];
        
        NSString *urlString = [NSString stringWithFormat:@"students/%lu", (long)userId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf PUT:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"setBankValue success response");
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            MTUser *user = [MTUser objectForPrimaryKey:[NSNumber numberWithInteger:userId]];
            user.hasBankAccount = bankValue;
            [realm commitWriteTransaction];
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed setBankValue with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed setBankValue with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}

- (void)setResumeValue:(BOOL)resumeValue forUserId:(NSInteger)userId success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
        parameters[@"hasResume"] = [NSNumber numberWithBool:resumeValue];
        
        NSString *urlString = [NSString stringWithFormat:@"students/%lu", (long)userId];
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf PUT:urlString parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"setResumeValue success response");
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            MTUser *user = [MTUser objectForPrimaryKey:[NSNumber numberWithInteger:userId]];
            user.hasResume = resumeValue;
            [realm commitWriteTransaction];
            
            if (success) {
                success(nil);
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed setResumeValue with error: %@", [error mtErrorDescription]);
            if (failure) {
                failure(error);
            }
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed setResumeValue with error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}



@end
