//
//  MTClassTest.m
//  moneythink-ios
//
//  Created by Colin Young on 12/23/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestHelper.h"
@class MTClass;

@interface MTClassTest : XCTestCase

@end

@implementation MTClassTest

MTClass *classObject;

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    classObject = [MTClass new];
}

- (void)testIsArchived {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    classObject[@"archivedAt"] = [NSDate date];
    
    XCTAssert([classObject isArchived]);
    
    classObject[@"archivedAt"] = nil;
    
    XCTAssertFalse([classObject isArchived]);
}

@end
