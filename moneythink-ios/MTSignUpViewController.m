    //
    //  MTSignUpViewController.m
    //  LogInAndSignUpDemo
    //
    //  Created by Mattieu Gamache-Asselin on 6/15/12.
    //  Copyright (c) 2013 Parse. All rights reserved.
    //

#import "MTSignUpViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+Palette.h"

#ifdef DEBUG
static BOOL useStage = YES;
#else
static BOOL useStage = NO;
#endif

@interface MTSignUpViewController ()

@end

@implementation MTSignUpViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.view.backgroundColor = [UIColor white];
    
    if ([PFUser currentUser]) {
        [self performSegueWithIdentifier:@"signUpToChallenges" sender:self];
    } else {
        [self.firstName setDelegate:self];
        [self.lastName setDelegate:self];
        [self.email setDelegate:self];
        [self.password setDelegate:self];
        [self.registrationCode setDelegate:self];
    }

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = self.signUpTitle;
    [label sizeToFit];
    self.navigationItem.titleView = label;
    
	self.agreeCheckbox =[[MICheckBox alloc]initWithFrame:self.agreeButton.frame];
	[self.agreeCheckbox setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self.agreeCheckbox setTitle:@"" forState:UIControlStateNormal];
    self.agreeCheckbox.isChecked = NO;
	[self.viewFields addSubview:self.agreeCheckbox];
    
    self.agreeButton.hidden = YES;

    self.useStageCheckbox =[[MICheckBox alloc]initWithFrame:self.useStageButton.frame];
	[self.useStageCheckbox setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	[self.useStageCheckbox setTitle:@"" forState:UIControlStateNormal];
	[self.viewFields addSubview:self.useStageCheckbox];
    
    self.useStageCheckbox.isChecked = useStage;
    self.useStageButton.hidden = YES;
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasDismissed:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self dismissKeyboard];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    
}


#pragma mark - IBActions


- (IBAction)tappedAgreeButton:(id)sender { }

- (IBAction)tappedUseStageButton:(id)sender { }

- (IBAction)tappedSignUpButton:(id)sender {
    if ([self.useStageCheckbox isChecked]) {
        NSString *applicationID = @"OFZ4TDvgCYnu40A5bKIui53PwO43Z2x5CgUKJRWz";
        NSString *clientKey = @"2OBw9Ggbl5p0gJ0o6Y7n8rK7gxhFTGcRQAXH6AuM";
        
        [Parse setApplicationId:applicationID
                      clientKey:clientKey];
    }
    
    if ([self.agreeCheckbox isChecked]) {
        NSPredicate *codePredicate = [NSPredicate predicateWithFormat:@"code = %@ AND type = %@", self.registrationCode.text, self.signUpType];
        
        PFQuery *findCode = [PFQuery queryWithClassName:[PFSignupCodes parseClassName] predicate:codePredicate];
        
        [findCode findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                NSArray *codes = objects;
                
                if ([codes count] == 1) {
                    PFSignupCodes *code = [codes firstObject];
                    
                    PFUser *user = [PFUser user];
                    
                    user.username = self.email.text;
                    user.password = self.password.text;
                    user.email = self.email.text;
                    
                        // other fields can be set just like with PFObject
                    user[@"first_name"] = self.firstName.text;
                    user[@"last_name"] = self.lastName.text;
                    
                    user[@"type"] = self.signUpType;
                    
                    NSString *aString = (NSString *)[code valueForUndefinedKey:@"class"];
                    user[@"class"] = aString;
                    
                    aString = (NSString *)[code valueForUndefinedKey:@"school"];
                    user[@"school"] = aString;
                    
                    [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (!error) {
                                // Hooray! Let them use the app now.
                            
                            if ([[[PFUser currentUser] valueForKey:@"type"] isEqualToString:@"student"]) {
                                [self performSegueWithIdentifier:@"studentSignedUp" sender:self];
                            } else {
                                [self performSegueWithIdentifier:@"pushMentorSignedUp" sender:self];
                            }
                            
                        } else {
                            NSString *errorString = [error userInfo][@"error"];
                                // Show the errorString somewhere and let the user try again.
                            self.error.text = errorString;
                            [[[UIAlertView alloc] initWithTitle:@"Login Error" message:errorString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                        }
                    }];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"There was an error with the registration code." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
                }
            } else {
                [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:[error userInfo][@"error"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
            }
        }];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Signup Error" message:@"Please agree to Terms & Conditions before signing up." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil] show];
    }

    
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void) keyboardWasShown:(NSNotification *)nsNotification {
    CGRect viewFrame = self.view.frame;
    CGRect fieldsFrame = self.viewFields.frame;
    
    NSDictionary *userInfo = [nsNotification userInfo];
    CGRect kbRect = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGSize kbSize = kbRect.size;
    NSInteger kbTop = viewFrame.origin.y + viewFrame.size.height - kbSize.height;
    
    CGRect fieldFrameSize = CGRectMake(fieldsFrame.origin.x ,
                                       fieldsFrame.origin.y,
                                       fieldsFrame.size.width,
                                       fieldsFrame.size.height - kbSize.height + 40.0f);
    
    fieldFrameSize = CGRectMake(0.0f, 0.0f, viewFrame.size.width, kbTop);
    
//    self.viewFields.contentSize = viewFrame.size;
    self.viewFields.contentSize = CGSizeMake(viewFrame.size.width, kbTop + 60.0f);
    
    self.viewFields.frame = fieldFrameSize;
}

- (void)keyboardWasDismissed:(NSNotification *)notification
{
    self.viewFields.frame = self.view.frame;
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    NSInteger nextTag = textField.tag + 1;
        // Try to find next responder
    UIResponder* nextResponder = [textField.superview viewWithTag:nextTag];
    if (nextResponder) {
            // Found next responder, so set it.
        [nextResponder becomeFirstResponder];
    } else {
            // Not found, so remove keyboard.
        [textField resignFirstResponder];
    }
    return NO; // We do not want UITextField to insert line-breaks.
}


@end
