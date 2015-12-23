//
//  MTClassSelectionNavigationController.h
//  moneythink-ios
//
//  Created by Colin Young on 12/18/15.
//  Copyright © 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MTClass;
@class MTOrganization;

@interface MTClassSelectionNavigationController : UINavigationController

@property (nonatomic, retain) MTClass *selectedClass;
@property (nonatomic, retain) MTOrganization *selectedOrganization;
@property (nonatomic, retain) NSString *mentorCode;

@end
