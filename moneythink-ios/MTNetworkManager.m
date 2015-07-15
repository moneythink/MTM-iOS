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
static NSString * const MTNetworkAPIKey = @"123456";
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
                                                                       secret:nil];
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
                                                                       secret:nil];
    
    MTMakeWeakSelf();
    [OAuth2Manager authenticateUsingOAuthWithURLString:@"oauth" parameters:parameters success:^(AFOAuthCredential *credential) {
        NSLog(@"New AFOAuthCredential: %@", [credential description]);
        [AFOAuthCredential storeCredential:credential withIdentifier:MTNetworkServiceOAuthCredentialKey];
        [weakSelf.requestSerializer setAuthorizationHeaderFieldWithCredential:credential];
        [weakSelf GET:@"users/me" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
            NSLog(@"Found me user: %@", responseObject);
            if (success) {
                success(responseObject);
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

- (void)getOrganizationsWithSuccess:(MTNetworkSuccessBlock)success failure:(MTNetworkFailureBlock)failure
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
        NSLog(@"Failed to get users with error: %@", [error localizedDescription]);
    }];
}


@end
