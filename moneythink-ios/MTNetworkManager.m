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

// TODO: Create dev and prod keys
#ifdef STAGE
static NSString * const MTNetworkAPIKey = @"123456";
#else
static NSString * const MTNetworkAPIKey = @"123456";
#endif

static NSString * const MTNetworkURLString = @"http://moneythink-api.staging.causelabs.com/";
static NSString * const MTNetworkClientID = @"ios";

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
        
        AFJSONResponseSerializer *responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingAllowFragments];
        NSMutableSet *contentTypes = [NSMutableSet setWithSet:[responseSerializer acceptableContentTypes]];
        [contentTypes addObject:@"application/hal+json"];
        [contentTypes addObject:@"application/api-problem+json"];
        [contentTypes addObject:@"application/problem+json"];
        responseSerializer.acceptableContentTypes = [NSSet setWithSet:contentTypes];
        self.responseSerializer = responseSerializer;
    }
    
    return self;
}


#pragma mark - Private Methods -
- (void)checkforOAuthTokenWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    AFOAuthCredential *existingCredential = [AFOAuthCredential retrieveCredentialWithIdentifier:MTNetworkServiceOAuthCredentialKey];
    
    if (existingCredential && existingCredential.accessToken && !existingCredential.isExpired) {
        NSLog(@"Have existing AFOAuthCredential: %@", [existingCredential description]);
        if (success) {
            success(existingCredential);
        }
    }
    else {
        if (existingCredential && !IsEmpty(existingCredential.refreshToken)) {
            [self refreshOAuthTokenForCredential:existingCredential success:^(AFOAuthCredential *credential) {
                if (success) {
                    success(credential);
                }
            } failure:^(NSError *error) {
                NSLog(@"Failed to refresh OAuth token: %@", [error mtErrorDescription]);
                if (failure) {
                    failure(error);
                }
            }];
        }
        else {
            if (![MTUtil internetReachable]) {
                [[[UIAlertView alloc] initWithTitle:@"No Internet" message:@"Restore Internet connection and try again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }
            else {
                // TODO: Shouldn't get here but force user to login again.
            }
        }
    }
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
    
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"oauth" parameters:parameters success:^(AFOAuthCredential *credential) {
        NSLog(@"Refreshed AFOAuthCredential: %@", [credential description]);
        [AFOAuthCredential deleteCredentialWithIdentifier:MTNetworkServiceOAuthCredentialKey];
        [AFOAuthCredential storeCredential:credential withIdentifier:MTNetworkServiceOAuthCredentialKey];
        if (success) {
            success(credential);
        }
        
    } failure:^(NSError *error) {
        NSLog(@"refreshOAuthTokenForCredential error: %@", [error mtErrorDescription]);
        if (failure) {
            failure(error);
        }
    }];
}


#pragma mark - JSON Data Parser Methods -
- (MTUser *)processMeUserRequestWithResponseObject:(id)responseObject
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
    
    RLMRealm *realm = [RLMRealm defaultRealm]; // Create realm pointing to default file
    
    [realm beginWriteTransaction];
    
    // Create and assign my class (organization created also)
    MTClass *myClass = [MTClass createOrUpdateInRealm:realm withJSONDictionary:[embeddedDict objectForKey:@"class"]];

    // Create new ME User and send back
    MTUser *meUser = [MTUser createOrUpdateInRealm:realm withJSONDictionary:responseDict];
    meUser.currentUser = YES;
//    meUser.organization = myOrganization;
    meUser.userClass = myClass;

    [realm commitWriteTransaction];
    
    return meUser;
}

- (NSInteger)processClassesRequestWithResponseObject:(id)responseObject
{
    NSInteger classesCount = 0;
    
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
    
    RLMRealm *realm = [RLMRealm defaultRealm]; // Create realm pointing to default file
    
    [realm beginWriteTransaction];
    NSArray *classesArray = [MTClass createOrUpdateInRealm:realm withJSONArray:responseArray];
    classesCount = [classesArray count];
    [realm commitWriteTransaction];
    
    return classesCount;
}


#pragma mark - Public Methods- 
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
        [AFOAuthCredential storeCredential:credential withIdentifier:MTNetworkServiceOAuthCredentialKey];
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:credential];
        [weakSelf GET:@"users/me" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"Found me user");
            
            MTUser *meUser = [self processMeUserRequestWithResponseObject:responseObject];
            if (meUser) {
                NSLog(@"Parsed meUser object: %@", meUser);
                if (success) {
                    success(meUser);
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

- (void)getClassesWithSignupCode:(NSString *)signupCode success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    NSString *signupCodeString = [NSString stringWithFormat:@"SignupCode %@", signupCode];

    [self.requestSerializer setValue:signupCodeString forHTTPHeaderField:@"Authorization"];
    
    [self GET:@"organizations/classes" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"Success getting Classes response");
        NSInteger classesCount = [self processClassesRequestWithResponseObject:responseObject];
        
        if (classesCount > 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                // TODO: Get classes and return to success block
            });
        }
        else {
            if (success) {
                success(nil);
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"Failed to get classes with error: %@", [error mtErrorDescription]);
    }];
}

- (void)getClassesWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"classes" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"success response");
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"Failed to get classes with error: %@", [error mtErrorDescription]);
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed to get classes with error: %@", [error mtErrorDescription]);
    }];
}

// TODO: Need to handle pagination

@end
