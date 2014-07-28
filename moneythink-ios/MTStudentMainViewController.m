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

@interface MTStudentMainViewController ()

@end

@implementation MTStudentMainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
            // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        // Do any additional setup after loading the view.
}


- (IBAction)buttonUserInfo:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton* userInfo = sender;
        
        if (userInfo.tag == 1) {
//        if ([userInfo.titleLabel.text isEqualToString:@"Maker"]) {
        
            MTUserInformationViewController *userInfoModal = [self.storyboard instantiateViewControllerWithIdentifier:@"infoModal"];
            userInfoModal.delegate = self;
            
            userInfoModal.labelInfoTitleText = @"Money Maker";
            userInfoModal.textInfoText = @"Making money is one of the two pillars for financial success. Some of the challenges that you will complete relate to this pillar, and will put you on the path to becoming a talented money maker. As you complete these \"Money Maker\" challenges, you will see your progress here.";
            
            [[[UIAlertView alloc] initWithTitle:@"Money Maker" message:@"Making money is one of the two pillars for financial success. Some of the challenges that you will complete relate to this pillar, and will put you on the path to becoming a talented money maker. As you complete these \"Money Maker\" challenges, you will see your progress here." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            
            
//            [self presentPopupViewController:userInfoModal animationType:MJPopupViewAnimationFade];

        } else if(userInfo.tag == 2) {
//        } else if([userInfo.titleLabel.text isEqualToString:@"Manager"]) {
            MTUserInformationViewController *userInfoModal = [self.storyboard instantiateViewControllerWithIdentifier:@"infoModal"];
            userInfoModal.delegate = self;

            userInfoModal.labelInfoTitleText = @"Money Manager";
            userInfoModal.textInfoText = @"Managing money is one of the two pillars for financial success. Some of the challenges that you will complete relate to this pillar, and will put you on the path to becoming a expert money manager. As you complete these \"Money Manager\" challenges, you will see your progress here.";
            [[[UIAlertView alloc] initWithTitle:@"Money Manager" message:@"Managing money is one of the two pillars for financial success. Some of the challenges that you will complete relate to this pillar, and will put you on the path to becoming a expert money manager. As you complete these \"Money Manager\" challenges, you will see your progress here." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            
//            [self presentPopupViewController:userInfoModal animationType:MJPopupViewAnimationFade];
            
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

     } else {
         
     }
 
 }



@end
