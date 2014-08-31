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
#import "MBProgressHUD.h"

@interface MTStudentMainViewController ()

@property (strong, nonatomic) IBOutlet UINavigationItem *studentMainNavItem;

@property (strong, nonatomic) IBOutlet UIButton *buttonMoneyMaker;
@property (strong, nonatomic) IBOutlet UIButton *buttonMoneyManager;

@property (strong, nonatomic) IBOutlet UIButton *buttonUserProfile;
@property (nonatomic, strong) UIImage *profileImage;
@property (strong, nonatomic) PFImageView *profileImageView;

@property (strong, nonatomic) IBOutlet UILabel *myPoints;

@property (strong, nonatomic) IBOutlet UIImageView *managerProgress;
@property (strong, nonatomic) IBOutlet UIImageView *makerProgress;

@property (strong, nonatomic) IBOutlet UIScrollView *challengesContainer;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollFields;
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [[UINavigationBar appearance] setBarTintColor:[UIColor primaryOrange]];
    [[UINavigationBar appearance] setTintColor:[UIColor white]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor white], NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:17.0f]}];

    self.parentViewController.navigationItem.title = @"Challenges";
    [[PFUser currentUser] refresh];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    [self loadUserProfile:[PFUser currentUser]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark -

- (void)loadUserProfile:(PFUser *)user
{
    self.buttonUserProfile.imageView.layer.cornerRadius = self.buttonUserProfile.frame.size.width / 2;
    self.buttonUserProfile.imageView.layer.masksToBounds = YES;
    
    NSString *myPoints = user[@"points"] ? user[@"points"] : @"0";
    self.myPoints.text = [NSString stringWithFormat:@"%@ pts", myPoints];
    
    PFFile *profileImageFile = [PFUser currentUser][@"profile_picture"];
    
    self.profileImageView = [[PFImageView alloc] init];
    [self.profileImageView setFile:profileImageFile];
    [self.profileImageView loadInBackground:^(UIImage *image, NSError *error) {
        if (!error) {
            if (image) {
                [self.buttonUserProfile setImage:image forState:UIControlStateNormal];
            } else {
                UIImage *defaultProfile = [UIImage imageNamed:@"profile_image"];
                [self.buttonUserProfile setImage:defaultProfile forState:UIControlStateNormal];
            }
        } else {
            UIImage *defaultProfile = [UIImage imageNamed:@"profile_image"];
            [self.buttonUserProfile setImage:defaultProfile forState:UIControlStateNormal];
        }
    }];
    
    NSInteger managerProgressValue = [user[@"money_manager"] intValue];
    NSInteger makerProgressValue = [user[@"money_maker"] intValue];
    
    if (makerProgressValue == 100) {
        self.makerProgress.hidden = NO;
        self.makerProgress.image = [UIImage imageNamed:@"bg_money_maker_2"];
    } else if (makerProgressValue >= 50) {
        self.makerProgress.hidden = NO;
        self.makerProgress.image = [UIImage imageNamed:@"bg_money_maker_1"];
    }
    
    if (managerProgressValue == 100) {
        self.managerProgress.hidden = NO;
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_7"];
    } else if (managerProgressValue >= 86) {
        self.managerProgress.hidden = NO;
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_6"];
    } else if (managerProgressValue >= 72) {
        self.managerProgress.hidden = NO;
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_5"];
    } else if (managerProgressValue >= 58) {
        self.managerProgress.hidden = NO;
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_4"];
    } else if (managerProgressValue >= 44) {
        self.managerProgress.hidden = NO;
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_3"];
    } else if (managerProgressValue >= 30) {
        self.managerProgress.hidden = NO;
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_2"];
    } else if (managerProgressValue >= 16) {
        self.managerProgress.hidden = NO;
        self.managerProgress.image = [UIImage imageNamed:@"bg_money_mananger_1"];
    }

    CGRect frame= self.scrollFields.frame;
    CGSize size = self.scrollFields.contentSize;
    size = CGSizeMake(frame.size.width, frame.origin.y + frame.size.height + 60.0f);
    self.scrollFields.contentSize = size;
    
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

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueID = [segue identifier];
    
    if ([segueID isEqualToString:@"pushEditStudentProfile"]) {

    }
}

- (IBAction)unwindToStudentMain:(UIStoryboardSegue *)sender
{
}


- (void)editProfileViewControllerDidSave:(MTEditProfileViewController *)editProfileViewController
{
    [self dismissViewControllerAnimated:NO completion:nil];
}


@end
