//
//  PFChallengePost.m
//  moneythink-ios
//
//  Created by jdburgie on 7/16/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "PFChallengePost.h"
#import <Parse/PFObject+Subclass.h>

@implementation PFChallengePost

/*
- (id) init
{
    NSLog(@"hello");
    
    self = [[PFChallengePost objectWithClassName:@"PFChallengePost"] init];
    
    PFQuery *getAllPosts = [PFQuery queryWithClassName:self.parseClassName];
    
    NSArray *allPosts = [getAllPosts findObjects];
    
    
    BOOL isDataAvailable = [self isDataAvailable];
    
    NSArray *allKeys = [self allKeys];
    
    if (isDataAvailable) {
    }
    
    return self;
}
*/

+ (NSString *)parseClassName {
    return @"PFChallengePost";
}


@end
