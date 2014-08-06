//
//  MTStudentProfileTableViewCell.h
//  moneythink-ios
//
//  Created by jdburgie on 8/5/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTStudentProfileTableViewCell : PFTableViewCell

@property (strong, nonatomic) PFChallengePost *rowPost;

@property (strong, nonatomic) IBOutlet PFImageView *postProfileImage;
@property (strong, nonatomic) IBOutlet UILabel *timeSince;
@property (strong, nonatomic) IBOutlet UILabel *postText;
@property (strong, nonatomic) IBOutlet UISwitch *verified;
@property (strong, nonatomic) IBOutlet UIImageView *comment;
@property (strong, nonatomic) IBOutlet UILabel *commentCount;
@property (strong, nonatomic) IBOutlet UIImageView *likes;
@property (strong, nonatomic) IBOutlet UILabel *likeCount;

@end
