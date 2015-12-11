//
//  MTMentorStudentProfileViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMentorStudentProfileViewController.h"
#import "MTPostDetailViewController.h"
#import "MTStudentProfileTableViewCell.h"
#import "MTMentorStudentProfileTableViewController.h"

@interface MTMentorStudentProfileViewController ()

@property (strong, nonatomic) IBOutlet UILabel *userPoints;
@property (strong, nonatomic) IBOutlet UIImageView *profileImage;

@end

@implementation MTMentorStudentProfileViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSString *points = [NSString stringWithFormat:@"%lu", (long)self.studentUser.points];
    self.userPoints.text = [points stringByAppendingString:@" pts"];
    self.title = [NSString stringWithFormat:@"%@ %@", self.studentUser.firstName, self.studentUser.lastName];
    
    __block UIImageView *weakImageView = self.profileImage;
    self.profileImage.layer.cornerRadius = round(self.profileImage.frame.size.width / 2.0f);
    self.profileImage.layer.masksToBounds = YES;
    self.profileImage.contentMode = UIViewContentModeScaleAspectFill;
    self.profileImage.image = [self.studentUser loadAvatarImageWithSuccess:^(id responseData) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakImageView.image = responseData;
        });
    } failure:^(NSError *error) {
        NSLog(@"Unable to load user avatar");
    }];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [MTUtil GATrackScreen:@"Student Profile View: Mentor"];
}

#pragma mark - Navigation
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueId = [segue identifier];
    
    if ([segueId isEqualToString:@"tableViewController"]) {
        MTMentorStudentProfileTableViewController *controller = (MTMentorStudentProfileTableViewController *)[segue destinationViewController];
        controller.studentUser = self.studentUser;
    }
    
    if ([segueId isEqualToString:@"pushProfileToPost"]) {
        MTPostDetailViewController *destinationVC = (MTPostDetailViewController *)[segue destinationViewController];
        MTStudentProfileTableViewCell *cell = (MTStudentProfileTableViewCell *)sender;
        MTChallengePost *rowObject = cell.rowPost;
        destinationVC.challengePostId = rowObject.id;
    }
}

- (void)setStudentUser:(MTUser *)studentUser
{
    _studentUser = studentUser;
    self.title = studentUser.firstName;
}

@end
