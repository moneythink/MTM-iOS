//
//  MTMentorStudentProfileViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMentorStudentProfileViewController.h"

@interface MTMentorStudentProfileViewController ()

@property (strong, nonatomic) IBOutlet PFImageView *profileImage;
@property (strong, nonatomic) IBOutlet UILabel *userPoints;

@end

@implementation MTMentorStudentProfileViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSString *points = self.student[@"points"];
    self.userPoints.text = [points stringByAppendingString:@" pts"];
    
    
    
    
    
/*
 cell.profileImage.file = user[@"profile_picture"];
 
 [cell.profileImage loadInBackground:^(UIImage *image, NSError *error) {
 CGRect frame = cell.contentView.frame;
 
 if (image.size.width > frame.size.width) {
 CGFloat scale = frame.size.width / image.size.width;
 CGFloat heightNew = scale * image.size.height;
 CGSize sizeNew = CGSizeMake(frame.size.width, heightNew);
 UIGraphicsBeginImageContext(sizeNew);
 [image drawInRect:CGRectMake(0.0f, 0.0f, sizeNew.width, sizeNew.height)];
 image = UIGraphicsGetImageFromCurrentImageContext();
 UIGraphicsEndImageContext();
 }
 }];
*/
    
    
    
    
    
    PFFile *profileFile = self.student[@"profile_picture"];
    
    self.profileImage = [[PFImageView alloc] init];
    self.profileImage.file = profileFile;
    
    [self.profileImage loadInBackground:^(UIImage *image, NSError *error) {
        if (!error) {
            NSLog(@"not error");
            CGRect frame = self.profileImage.frame;
            
            if (image.size.width > frame.size.width) {
                CGFloat scale = frame.size.width / image.size.width;
                CGFloat heightNew = scale * image.size.height;
                CGSize sizeNew = CGSizeMake(frame.size.width, heightNew);
                UIGraphicsBeginImageContext(sizeNew);
                [image drawInRect:CGRectMake(0.0f, 0.0f, sizeNew.width, sizeNew.height)];
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
            
            self.profileImage.image = image;
            
//            [self.profileImage setNeedsLayout];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
