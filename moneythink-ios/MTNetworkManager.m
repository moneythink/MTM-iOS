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
        self.responseSerializer = [self getJSONResponseSerializer];
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
                    
                    MTUser *meUser = [MTUser objectForPrimaryKey:[NSNumber numberWithInteger:userId]];
                    MTUserAvatar *userAvatar = [[MTUserAvatar alloc] init];
                    userAvatar.avatarData = responseObject;
                    meUser.userAvatar = userAvatar;
                    
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
        NSLog(@"Failed to Auth to get user avatar with error: %@", [error mtErrorDescription]);
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
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    
    // Create and assign my class (organization created also)
    MTOrganization *myOrganization = [MTOrganization createOrUpdateInRealm:realm withJSONDictionary:[embeddedDict objectForKey:@"organization"]];
    MTClass *myClass = [MTClass createOrUpdateInRealm:realm withJSONDictionary:[embeddedDict objectForKey:@"class"]];
    myClass.organization = myOrganization;

    // Create new ME User and send back
    MTUser *meUser = [MTUser createOrUpdateInRealm:realm withJSONDictionary:responseDict];
    meUser.currentUser = YES;
    meUser.organization = myOrganization;
    meUser.userClass = myClass;
    
    [realm commitWriteTransaction];
    
    return meUser;
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


#pragma mark - Public Methods -
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
            
            MTUser *meUser = [weakSelf processMeUserRequestWithResponseObject:responseObject];
            if (meUser) {
                NSLog(@"Parsed meUser object: %@", meUser);
                
                // TODO: If Avatar, retrieve and store it
                if (YES) {
                    [self getAvatarForUserId:meUser.id success:^(id responseData) {
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

- (void)getClassesWithSignupCode:(NSString *)signupCode success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
{
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    parameters[@"maxdepth"] = @"0";

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

- (void)setAvatarForUserId:(NSInteger)userId withImageData:(NSData *)imageData success:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
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
                            MTUserAvatar *userAvatar = [[MTUserAvatar alloc] init];
                            userAvatar.avatarData = imageData;
                            meUser.userAvatar = userAvatar;
                        }
                        else {
                            meUser.userAvatar.avatarData = imageData;
                        }
                    }
                    else {
                        meUser.userAvatar = nil;
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

- (void)refreshCurrentUserData
{
    MTMakeWeakSelf();
    [self checkforOAuthTokenWithSuccess:^(id responseData) {
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:responseData];
        [weakSelf GET:@"users/me" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"Found me user");
            MTUser *meUser = [weakSelf processMeUserRequestWithResponseObject:responseObject];
            if (meUser) {
                NSLog(@"Parsed meUser object: %@", meUser);
                
                // TODO: If Avatar, retrieve and store it
                if (YES) {
                    [weakSelf getAvatarForUserId:meUser.id success:^(id responseData) {
                        NSLog(@"Retrieved user avatar");
                    } failure:^(NSError *error) {
                        NSLog(@"Failed to retrieve user avatar, probably no avatar assigned");
                    }];
                }
            }
            
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            NSLog(@"authenticateForUsername error: %@", [error mtErrorDescription]);
        }];
    } failure:^(NSError *error) {
        NSLog(@"Failed refreshCurrentUserData with error: %@", [error mtErrorDescription]);
    }];
}

// TODO: Need to handle pagination

@end
