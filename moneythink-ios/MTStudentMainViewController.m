//
//  MTStudentMainViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTStudentMainViewController.h"
#import "MTUserInformationViewController.h"
#import "UIViewController+MJPopupViewController.h"
#import "MTEditProfileViewController.h"

@interface MTStudentMainViewController ()

@property (strong, nonatomic) IBOutlet UINavigationItem *studentMainNavItem;

@property (strong, nonatomic) IBOutlet UIButton *buttonMoneyMaker;
@property (strong, nonatomic) IBOutlet UIButton *buttonUserProfile;
@property (strong, nonatomic) IBOutlet UIButton *buttonMoneyManager;

//@property (strong, nonatomic) UIImageView *profileImageView;
@property (nonatomic, strong) UIImage *profileImage;
@property (strong, nonatomic) PFImageView *profileImageView;

@property (strong, nonatomic) IBOutlet UILabel *myPoints;

@end

@implementation MTStudentMainViewController

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

    self.navigationItem.backBarButtonItem = nil;;
    self.navigationItem.hidesBackButton = YES;

    PFUser *user = [PFUser currentUser];
    
    NSString *myPoints = user[@"points"] ? user[@"points"] : @"0";
    self.myPoints.text = [NSString stringWithFormat:@"%@ pts", myPoints];
    
    if (NO) {
//        PFFile *profileImageFile = [PFUser currentUser][@"profile_picture"];
//        
//        NSString *requestURL = profileImageFile.url; // Save copy of url locally (will not change in block)
//        NSString *profileImageFileURL = profileImageFile.url; // Save copy of url on the instance
//        
//        [profileImageFile getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
//            if (!error) {
//                UIImage *image = [UIImage imageWithData:data];
//                if ([requestURL isEqualToString:profileImageFileURL]) {
//                    
//                    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
//                    self.profileImageView = imageView;
//                    
//                    self.buttonUserProfile.imageView.image = imageView.image;
//                    self.buttonUserProfile.imageView.layer.cornerRadius = round(self.buttonUserProfile.imageView.frame.size.width / 2.0f);
//                    self.buttonUserProfile.imageView.layer.masksToBounds = YES;
//                    
//                    [self.buttonUserProfile setImage:self.profileImageView.image forState:UIControlStateNormal];
//                    
//                    [self.view setNeedsDisplay];
//                }
//            } else {
//                NSLog(@"Error on fetching file");
//                self.buttonUserProfile.imageView.image = [UIImage imageNamed:@"bg_profile_avatar_small.png"];
//            }
//        }];
    } else {
        PFFile *profileImageFile = [PFUser currentUser][@"profile_picture"];

        self.profileImageView = [[PFImageView alloc] init];
        [self.profileImageView setFile:profileImageFile];
        [self.profileImageView loadInBackground:^(UIImage *image, NSError *error) {
            self.profileImage = image;
            self.buttonUserProfile.imageView.image = self.profileImage;
            self.buttonUserProfile.imageView.layer.cornerRadius = round(self.buttonUserProfile.imageView.frame.size.width / 2.0f);
            self.buttonUserProfile.imageView.layer.masksToBounds = YES;
            
            [self.buttonUserProfile setImage:self.profileImageView.image forState:UIControlStateNormal];
            
            [self.view setNeedsDisplay];
            [self.view setNeedsLayout];

        }];

    }
    
}

- (void)viewWillAppear:(BOOL)animated
{
//    if (self.profileImageView.image) {
//        self.buttonUserProfile.imageView.image = self.profileImageView.image;
//        self.buttonUserProfile.imageView.layer.cornerRadius = round(self.buttonUserProfile.imageView.frame.size.width / 2.0f);
//        self.buttonUserProfile.imageView.layer.masksToBounds = YES;
//    } else {
//        self.buttonUserProfile.imageView.image = [UIImage imageNamed:@"bg_profile_avatar_small.png"];
//    }
//        
//        [self.view setNeedsDisplay];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (self.profileImageView.image) {
        self.buttonUserProfile.imageView.image = self.profileImageView.image;
        self.buttonUserProfile.imageView.layer.cornerRadius = round(self.buttonUserProfile.imageView.frame.size.width / 2.0f);
        self.buttonUserProfile.imageView.layer.masksToBounds = YES;
        
        [self.buttonUserProfile setImage:self.self.profileImageView.image forState:UIControlStateNormal];
        
        [self.view setNeedsDisplay];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.profileImageView.image) {
        NSLog(@"got image");
    }
}


- (IBAction)buttonUserInfo:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton* userInfo = sender;
        
        if (userInfo.tag == 1) {
            MTUserInformationViewController *userInfoModal = [self.storyboard instantiateViewControllerWithIdentifier:@"infoModal"];
            userInfoModal.delegate = self;
            
            userInfoModal.labelInfoTitleText = @"Money Maker";
            userInfoModal.textInfoText = @"Making money is one of the two pillars for financial success. Some of the challenges that you will complete relate to this pillar, and will put you on the path to becoming a talented money maker. As you complete these \"Money Maker\" challenges, you will see your progress here.";
            
            [[[UIAlertView alloc] initWithTitle:@"Money Maker" message:@"Making money is one of the two pillars for financial success. Some of the challenges that you will complete relate to this pillar, and will put you on the path to becoming a talented money maker. As you complete these \"Money Maker\" challenges, you will see your progress here." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            
        } else if(userInfo.tag == 2) {
            MTUserInformationViewController *userInfoModal = [self.storyboard instantiateViewControllerWithIdentifier:@"infoModal"];
            userInfoModal.delegate = self;
            
            userInfoModal.labelInfoTitleText = @"Money Manager";
            userInfoModal.textInfoText = @"Managing money is one of the two pillars for financial success. Some of the challenges that you will complete relate to this pillar, and will put you on the path to becoming a expert money manager. As you complete these \"Money Manager\" challenges, you will see your progress here.";
            [[[UIAlertView alloc] initWithTitle:@"Money Manager" message:@"Managing money is one of the two pillars for financial success. Some of the challenges that you will complete relate to this pillar, and will put you on the path to becoming a expert money manager. As you complete these \"Money Manager\" challenges, you will see your progress here." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            
        } else if([userInfo.titleLabel.text isEqualToString:@"Profile"]) {
            
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
// Get the new view controller using [segue destinationViewController].
// Pass the selected object to the new view controller.

    NSString *segueID = [segue identifier];
    
    MTUserInformationViewController *userInfoModal = (MTUserInformationViewController *)segue.destinationViewController;
    
    if ([segueID isEqualToString:@"moneyMaker"]) {
        userInfoModal.labelInfoTitleText = @"Money Maker";
        userInfoModal.textInfoText = @"Making money is one of the two pillars for financial success. Some of the challenges that you will complete relate to this pillar, and will put you on the path to becoming a talented money maker. As you complete these \"Money Maker\" challenges, you will see your progress here.";
        
    } else if ([segueID isEqualToString:@"moneyManager"]) {
        userInfoModal.labelInfoTitleText = @"Money Manager";
        userInfoModal.textInfoText = @"Managin money is one of the two pillars for financial success. Some of the challenges that you will complete relate to this pillar, and will put you on the path to becoming a expert money manager. As you complete these \"Money Manager\" challenges, you will see your progress here.";
        
    } else if ([segue.identifier isEqualToString:@"pushEditStudentProfile"]) {
        MTEditProfileViewController *editProfileViewController = segue.destinationViewController;
        editProfileViewController.delegate = self;
    }
}

- (IBAction)unwindToStudentMain:(UIStoryboardSegue *)sender
{
    
}


- (void)editProfileViewControllerDidSave:(MTEditProfileViewController *)editProfileViewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
