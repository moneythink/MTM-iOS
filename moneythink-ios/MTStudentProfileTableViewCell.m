//
//  MTStudentProfileTableViewCell.m
//  moneythink-ios
//
//  Created by jdburgie on 8/5/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentProfileTableViewCell.h"

@implementation MTStudentProfileTableViewCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
    
    CGRect frame = self.verified.frame;
    frame.origin.x += (frame.size.width / 2) - 10.0f;
    frame.origin.y += (frame.size.height / 2) - 10.0f;
    frame.size.width = 20.0f;
    frame.size.height = 20.0f;
    
    self.verifiedCheckbox =[[MICheckBox alloc]initWithFrame:frame];
	[self.verifiedCheckbox setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self.verifiedCheckbox setTitle:@"" forState:UIControlStateNormal];
	[self addSubview:self.verifiedCheckbox];
    
    [self.verifiedCheckbox addTarget:self action:@selector(checkedVerifiedBox) forControlEvents:UIControlEventTouchUpInside];
    
    self.verified.hidden = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)checkedVerifiedBox {
    PFUser *mentor = [PFUser currentUser];
    NSString *userID = [mentor objectId];
    NSString *postID = [self.rowPost objectId];
    
    if (!self.verifiedCheckbox.isChecked) {
        userID = @"";
    }
    
    NSDictionary *verifiedDict = @{@"post_id": postID, @"verified_by": userID};
    
    [PFCloud callFunctionInBackground:@"updatePostVerification" withParameters:verifiedDict block:^(id object, NSError *error) {
        if (!error) {
            
        } else {
            self.verifiedCheckbox.isChecked = !self.verifiedCheckbox.isChecked;
            [self setNeedsLayout];
            NSLog(@"error - %@", error);
            [UIAlertView bk_showAlertViewWithTitle:@"Unable to Update" message:[error localizedDescription] cancelButtonTitle:@"OK" otherButtonTitles:nil handler:nil];
        }
    }];
}

@end
