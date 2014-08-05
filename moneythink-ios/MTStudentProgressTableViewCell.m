//
//  MTStudentProgressTableViewCell.m
//  moneythink-ios
//
//  Created by jdburgie on 8/3/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentProgressTableViewCell.h"

@implementation MTStudentProgressTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code

    self.bankCheckbox =[[MICheckBox alloc]initWithFrame:self.bankSwitch.frame];
	[self.bankCheckbox setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self.bankCheckbox setTitle:@"" forState:UIControlStateNormal];
	[self addSubview:self.bankCheckbox];
    
    self.bankSwitch.hidden = YES;

    self.resumeCheckbox =[[MICheckBox alloc]initWithFrame:self.resumeSwitch.frame];
	[self.resumeCheckbox setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self.resumeCheckbox setTitle:@"" forState:UIControlStateNormal];
	[self addSubview:self.resumeCheckbox];
    
    [self.resumeCheckbox addTarget:self action:@selector(checkedResumeBox) forControlEvents:UIControlEventTouchUpInside];
    [self.bankCheckbox addTarget:self action:@selector(checkedBankBox) forControlEvents:UIControlEventTouchUpInside];
    
    self.resumeSwitch.hidden = YES;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)checkedResumeBox {
    self.user[@"resume"] = [NSNumber numberWithBool:self.resumeCheckbox.isChecked];
    
    [self.user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"check point no error");
        } else {
            NSLog(@"check point error - %@", error);
        }
    }];
}

- (void)checkedBankBox {
    self.user[@"bank_account"] = [NSNumber numberWithBool:self.bankCheckbox.isChecked];
    
    [self.user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            NSLog(@"check point no error");
        } else {
            NSLog(@"check point error - %@", error);
        }
    }];
}

@end
