//
//  ViewController.h
//  moneythink-ios
//
//  Created by jdburgie on 7/10/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate>

//@property (strong, nonatomic) IBOutlet UILabel *labelStatus;
//@property (strong, nonatomic) IBOutlet UILabel *labelUsername;
//@property (strong, nonatomic) IBOutlet UILabel *labelVersion;


@property (strong, nonatomic) IBOutlet UIButton *buttonSignupStudent;
@property (strong, nonatomic) IBOutlet UIButton *buttonSignupMentor;
@property (strong, nonatomic) IBOutlet UIButton *buttonLogin;
@property (strong, nonatomic) IBOutlet UIButton *buttonLogout;


- (IBAction)tapStudentSignupButton:(id)sender;
- (IBAction)tapMentorSignupButton:(id)sender;
- (IBAction)tapLoginButton:(id)sender;
- (IBAction)tapLogoutButton:(id)sender;

@end
