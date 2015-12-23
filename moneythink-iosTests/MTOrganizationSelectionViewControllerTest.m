//
//  MTOrganizationSelectionViewControllerTest.m
//  moneythink-ios
//
//  Created by Colin Young on 12/23/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "TestHelper.h"

@interface MTOrganizationSelectionViewControllerTest : XCTestCase

@end

@implementation MTOrganizationSelectionViewControllerTest

MTClassSelectionNavigationController *navController;
MTOrganizationSelectionViewController *controller;

MTClass *mockClass;
MTOrganization *mockOrganization;

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    mockClass = [MTClass new];
    mockOrganization = [MTOrganization new];
    
    controller = [[self storyboard] instantiateViewControllerWithIdentifier:@"MTOrganizationSelectionViewController"];
    navController = [[MTClassSelectionNavigationController alloc] initWithRootViewController:controller];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNavControllerStoresCurrentSelections {
    XCTAssertNil(navController.selectedOrganization);
    
    navController.selectedOrganization = mockOrganization;
    
    XCTAssertEqual([controller performSelector:@selector(selectedOrganization)], mockOrganization);
}

- (void)testNavControllerStoresCurrentMentorCode {
    XCTAssertNil(navController.mentorCode);
    
    navController.mentorCode = @"asdf";
    
    XCTAssertEqual([controller performSelector:@selector(mentorCode)], @"asdf");
}
                     
- (UIStoryboard *)storyboard {
    return [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
}

@end
