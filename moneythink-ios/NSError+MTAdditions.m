//
//  NSError+MTAdditions.m
//  moneythink-ios
//
//  Created by David Sica on 8/6/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "NSError+MTAdditions.h"

NSString *const MTErrorDomain = @"com.moneythink.errorDomain";

@implementation NSError (MTAdditions)

- (NSString *)mtErrorDescription
{
    NSData *errorData = self.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    
    if (errorData) {
        NSDictionary *serializedData = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
        return [NSString stringWithFormat:@"Localized:%@\nAFNetworking:%@", [self localizedDescription], [serializedData description]];
    }
    else {
        return [self localizedDescription];
    }
}

- (NSInteger)mtErrorCode
{
    NSData *errorData = self.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    if (errorData) {
        NSDictionary *serializedData = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
        return [[serializedData valueForKey:@"status"] integerValue];
    }
    else {
        return 0;
    }
}

- (NSString *)mtErrorDetail
{
    NSData *errorData = self.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    if (errorData) {
        NSDictionary *serializedData = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
        return [serializedData valueForKey:@"detail"];
    }
    else {
        return 0;
    }
}

- (NSString *)firstValidationMessage
{
    NSData *errorData = self.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    
    if (errorData) {
        NSDictionary *serializedData = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
        if (serializedData && !IsEmpty([serializedData objectForKey:@"validation_messages"])) {
            NSDictionary *validationMessages = [serializedData objectForKey:@"validation_messages"];
            NSString *firstKey = [[validationMessages allKeys] firstObject];
            NSString *firstValueString;
            
            id firstValue = [validationMessages objectForKey:firstKey];
            if ([firstValue isKindOfClass:[NSArray class]]) {
                firstValueString = [firstValue firstObject];
            }
            else {
                firstValueString = firstValue;
            }
            
            return [NSString stringWithFormat:@"%@: %@", [firstKey capitalizedString], firstValueString];
        }
        else {
            return nil;
        }
    }
    else {
        return nil;
    }
}

- (NSString *)detailMessage
{
    NSData *errorData = self.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
    
    if (errorData) {
        NSDictionary *serializedData = [NSJSONSerialization JSONObjectWithData: errorData options:kNilOptions error:nil];
        if (serializedData && !IsEmpty([serializedData objectForKey:@"detail"])) {
            return [serializedData objectForKey:@"detail"];
        }
        else {
            return nil;
        }
    }
    else {
        return nil;
    }
}


@end
