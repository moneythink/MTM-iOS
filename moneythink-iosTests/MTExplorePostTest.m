//
//  MTClassTest.m
//  moneythink-ios
//
//  Created by Colin Young on 12/23/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestHelper.h"

@class MTExplorePost;

@interface MTExplorePostTest : XCTestCase

@property (nonatomic) MTExplorePost *object;

@end

@implementation MTExplorePostTest

- (void)setUp {
    [super setUp];
    
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.inMemoryIdentifier = self.name;
    [RLMRealmConfiguration setDefaultConfiguration:config];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [MTExplorePost createOrUpdateInRealm:realm withJSONDictionary:[self sampleExplorePostDictionary]];
    [realm commitWriteTransaction];
    
    self.object = [MTExplorePost objectForPrimaryKey:[self sampleExplorePostDictionary][@"post_id"]];
    XCTAssertNotNil(self.object);
}

- (void)testObjectHasDate {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    XCTAssertNotNil(self.object.createdAt);
}

- (void)testObjectHasUserId {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    XCTAssertNotNil(self.object.userId);
}

- (void)testObjectHasPostId {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    XCTAssertNotNil(self.object.postId);
}

- (NSDictionary *)sampleExplorePostDictionary {
    return @{
              @"post_id": @17976,
              @"post_content": @"My example content",
              @"post_picture": @"http://api.moneythink.org/posts/17976/picture",
              @"challenge_id": @5,
              @"user_id": @4468,
              @"user_avatar": @"http://api.moneythink.org/users/4468/avatar",
              @"user_name": @"Faizan Anarwala",
              @"post_created_at": @"2015-11-04T09:59:42Z"
    };
}

@end
