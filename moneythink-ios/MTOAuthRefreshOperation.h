//
//  MTOAuthRefreshOperation.h
//  moneythink-ios
//
//  Created by David Sica on 8/20/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MTOAuthRefreshOperation : NSOperation {
    BOOL        executing;
    BOOL        finished;
}

- (void)completeOperation;

@end
