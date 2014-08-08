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
    
    self.buttonUserProfile.imageView.layer.cornerRadius = self.buttonUserProfile.frame.size.width / 2;
    self.buttonUserProfile.imageView.layer.masksToBounds = YES;
    
    PFUser *user = [PFUser currentUser];
    
    NSString *myPoints = user[@"points"] ? user[@"points"] : @"0";
    self.myPoints.text = [NSString stringWithFormat:@"%@ pts", myPoints];
    
    PFFile *profileImageFile = [PFUser currentUser][@"profile_picture"];
    
    self.profileImageView = [[PFImageView alloc] init];
    [self.profileImageView setFile:profileImageFile];
    [self.profileImageView loadInBackground:^(UIImage *image, NSError *error) {
        if (!error) {
            [self.buttonUserProfile setImage:image forState:UIControlStateNormal];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{

}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.profileImageView.image) {

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
