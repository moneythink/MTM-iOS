//
//  NSError+MTAdditions.h
//  moneythink-ios
//
//  Created by David Sica on 8/6/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const MTErrorDomain;

@interface NSError (MTAdditions)

- (NSString *)mtErrorDescription;
- (NSString *)firstValidationMessage;
- (NSString *)detailMessage;

@end
