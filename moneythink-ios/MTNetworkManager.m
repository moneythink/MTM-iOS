//
//  MTNetworkManager.m
//  moneythink-ios
//
//  Created by David Sica on 7/9/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTNetworkManager.h"
#import "AFHTTPRequestSerializer+OAuth2.h"

// TODO: Create dev and prod keys
#ifdef STAGE
static NSString * const MTNetworkAPIKey = @"123456";
#else
static NSString * const MTNetworkAPIKey = @"123456";
#endif

static NSString * const MTNetworkURLString = @"http://moneythink-api.staging.causelabs.com/";

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
                NSLog(@"Failed to refresh OAuth token");
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
    parameters[@"client_id"] = @"web";
    parameters[@"client_secret"] = MTNetworkAPIKey;
    
    NSURL *baseURL = [NSURL URLWithString:MTNetworkURLString];
    AFOAuth2Manager *OAuth2Manager = [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                                                     clientID:@"web"
                                                                       secret:MTNetworkAPIKey];
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"oauth" parameters:parameters success:^(AFOAuthCredential *credential) {
        NSLog(@"Refreshed AFOAuthCredential: %@", [credential description]);
        [AFOAuthCredential deleteCredentialWithIdentifier:MTNetworkServiceOAuthCredentialKey];
        [AFOAuthCredential storeCredential:credential withIdentifier:MTNetworkServiceOAuthCredentialKey];
        if (success) {
            success(credential);
        }
        
    } failure:^(NSError *error) {
        NSLog(@"refreshOAuthTokenForCredential error: %@", error);
        if (failure) {
            failure(error);
        }
    }];
}

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
    
    if (![[embeddedDict objectForKey:@"role"] isKindOfClass:[NSDictionary class]]) {
        NSLog(@"No role data");
        return nil;
    }
    
    NSDictionary *organizationDict = [embeddedDict objectForKey:@"organization"];
    NSDictionary *classDict = [embeddedDict objectForKey:@"class"];
    NSDictionary *roleDict = [embeddedDict objectForKey:@"role"];
    
    // Create and assign my organization
    MTOrganization *myOrganization = [[MTOrganization alloc] init];
    myOrganization.name = [organizationDict safeValueForKey:@"name"];
    myOrganization.organizationId = [[organizationDict safeValueForKey:@"id"] integerValue];
    myOrganization.mentorSignupCode = [organizationDict safeValueForKey:@"mentorSignupCode"];
    
    // Create and assign my class
    MTClass *myClass = [[MTClass alloc] init];
    myClass.classId = [[classDict safeValueForKey:@"id"] integerValue];
    myClass.name = [classDict safeValueForKey:@"name"];
    myClass.studentSignupCode = [classDict safeValueForKey:@"studentSignupCode"];
    myClass.organization = myOrganization;
    
    // Create new ME User and send back
    MTUser *meUser = [[MTUser alloc] init];
    meUser.userId = [[responseDict safeValueForKey:@"id"] integerValue];
    meUser.username = [responseDict safeValueForKey:@"username"];
    meUser.firstName = [responseDict safeValueForKey:@"firstName"];
    meUser.lastName = [responseDict safeValueForKey:@"lastName"];
    meUser.email = [responseDict safeValueForKey:@"email"];
    meUser.avatar = [responseDict safeValueForKey:@"avatar"];
    meUser.phoneNumber = [responseDict safeValueForKey:@"phoneNumber"];
    meUser.roleCode = [roleDict safeValueForKey:@"code"];
    meUser.currentUser = YES;
    meUser.organization = myOrganization;
    meUser.userClass = myClass;
    
    // Realms are used to group data together
    RLMRealm *realm = [RLMRealm defaultRealm]; // Create realm pointing to default file
    
    // Save your object
    [realm beginWriteTransaction];
    [realm addObject:myOrganization];
    [realm addObject:myClass];
    [realm addObject:meUser];
    [realm commitWriteTransaction];
    
    return meUser;
}


#pragma mark - Public Methods- 
- (void)authenticateForUsername:(NSString *)username withPassword:(NSString *)password success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    parameters[@"username"] = username;
    parameters[@"password"] = password;
    parameters[@"grant_type"] = @"password";
    parameters[@"client_id"] = @"web";
    parameters[@"client_secret"] = MTNetworkAPIKey;
    
    NSURL *baseURL = [NSURL URLWithString:MTNetworkURLString];
    AFOAuth2Manager *OAuth2Manager = [[AFOAuth2Manager alloc] initWithBaseURL:baseURL
                                                                     clientID:@"web"
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
            NSLog(@"authenticateForUsername error: %@", error);
            if (failure) {
                failure(error);
            }
        }];
        
    } failure:^(NSError *error) {
        NSLog(@"authenticateForUsername error: %@", error);
        if (failure) {
            failure(error);
        }
    }];
}

- (NSArray *)getClassesWithSignupCode:(NSString *)signupCode success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    NSArray *classes = [NSArray array];
    
//    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
//    parameters[@"grant_type"] = @"password";
//    parameters[@"client_id"] = @"web";
//    parameters[@"client_secret"] = MTNetworkAPIKey;

    [self.requestSerializer setValue:signupCode forHTTPHeaderField:@"Authorization"];
    [self GET:@"organizations/classes" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        NSLog(@"success response");
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        NSLog(@"failure response, error: %@", [error localizedDescription]);
    }];

    return classes;
}

- (void)getClassesWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:(AFOAuthCredential *)responseData];
        [weakSelf GET:@"classes" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"success response");
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"failure response, error: %@", [error localizedDescription]);
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed to get classes with error: %@", [error localizedDescription]);
    }];
}


@end
