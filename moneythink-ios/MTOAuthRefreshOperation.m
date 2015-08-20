//
//  MTOAuthRefreshOperation.m
//  moneythink-ios
//
//  Created by David Sica on 8/20/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTOAuthRefreshOperation.h"

@interface MTOAuthRefreshOperation ()

@end

@implementation MTOAuthRefreshOperation
- (id)init
{
    self = [super init];
    if (self) {
        executing = NO;
        finished = NO;
    }
    return self;
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting
{
    return executing;
}

- (BOOL)isFinished
{
    return finished;
}

- (void)start
{
    // Always check for cancellation before launching the task.
    if ([self isCancelled])
    {
        // Must move the operation to the finished state if it is canceled.
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }
    
    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)main
{
        // Do the main work of the operation here.
//    NSLog(@"Entering MTOAuthRefreshOperation.main");
    AFOAuthCredential *existingCredential = [AFOAuthCredential retrieveCredentialWithIdentifier:MTNetworkServiceOAuthCredentialKey];
    
    if (existingCredential && existingCredential.accessToken && !existingCredential.isExpired) {
//        NSLog(@"MTOAuthRefreshOperation.main: Have existing AFOAuthCredential with accessToken (NOT expired)");
        [self completeOperation];
    }
    else {
        if (existingCredential && !IsEmpty(existingCredential.refreshToken)) {
            NSLog(@"MTOAuthRefreshOperation.main: Have existing AFOAuthCredential but is expired, refresh");
            
            MTMakeWeakSelf();
            [[MTNetworkManager sharedMTNetworkManager] refreshOAuthTokenForCredential:existingCredential success:^(AFOAuthCredential *credential) {
                NSLog(@"MTOAuthRefreshOperation.main: refreshed token");
                [weakSelf completeOperation];
            } failure:^(NSError *error) {
                NSLog(@"MTOAuthRefreshOperation.main: Failed to refresh OAuth token: %@", [error mtErrorDescription]);
                [weakSelf completeOperation];
            }];
        }
        else {
            NSLog(@"MTOAuthRefreshOperation.main: Have NO existing AFOAuthCredential or NO refreshToken");
            [self completeOperation];
        }
    }
//    NSLog(@"Exiting MTOAuthRefreshOperation.main");
}

- (void)completeOperation
{
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    
    executing = NO;
    finished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}


@end
