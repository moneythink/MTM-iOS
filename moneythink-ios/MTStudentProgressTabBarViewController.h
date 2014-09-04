//
//  MTStudentProgressTabBarViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTStudentProgressTabBarViewController : UITabBarController

@property (nonatomic, strong) PFClasses *userClass;
@property (nonatomic, strong) PFUser *mentor;
@property (nonatomic, strong) NSArray *studentsForMentor;

@end
