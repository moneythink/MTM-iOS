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

@interface MTSignUpViewController ()

@end

@implementation MTSignUpViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.view.backgroundColor = [UIColor white];
    
    UIFont *fontRoboto = [UIFont fontWithName:@"Roboto-Thin" size:17.0f];
    
    if ([PFUser currentUser]) {
        self.error.text = @"You are already logged in.";
        [self performSegueWithIdentifier:@"signUpToChallenges" sender:self];
    } else {
        self.firstName.font = fontRoboto;
        self.lastName.font = fontRoboto;
        self.email.font = fontRoboto;
        self.password.font = fontRoboto;
        self.registrationCode.font = fontRoboto;
        
        [self.firstName setDelegate:self];
        [self.lastName setDelegate:self];
        [self.email setDelegate:self];
        [self.password setDelegate:self];
        [self.registrationCode setDelegate:self];
    }
    
    
    
    
    fontRoboto = [UIFont fontWithName:@"Roboto-black" size:18.0f];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.font = fontRoboto;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor whiteColor];
    label.text = self.signUpTitle;
    [label sizeToFit];
    self.navigationItem.titleView = label;
    
    
    
    
    
    fontRoboto = [UIFont fontWithName:@"Roboto-Thin" size:11.0f];
    self.error.textColor = [UIColor redColor];
    self.error.font = fontRoboto;
    
    self.cancelButton.hidden = YES;
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
                
                NSString *aString = (NSString *)[code valueForUndefinedKey:@"class"];
                user[@"class"] = aString;
                
                aString = (NSString *)[code valueForUndefinedKey:@"school"];
                user[@"school"] = aString;
                
                [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    if (!error) {
                            // Hooray! Let them use the app now.
                        NSLog(@"errorString - nil");
                        [self.cancelButton sendActionsForControlEvents:UIControlEventTouchUpInside];
//                        [self dismissViewControllerAnimated:YES completion:nil];
                    } else {
                        NSString *errorString = [error userInfo][@"error"];
                        NSLog(@"errorString - %@", errorString);
                            // Show the errorString somewhere and let the user try again.
                        self.error.text = errorString;
                    }
                }];
            } else {
                
            }
        } else {
            NSLog(@"error");
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    
}

-(void)dismissKeyboard {
    [self.view endEditing:YES];
}


- (IBAction)tappedCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UITextFieldDelegate methods

- (void) keyboardWasShown:(NSNotification *)nsNotification {
    CGRect viewFrame = self.view.frame;
    CGRect fieldsFrame = self.viewFields.frame;
    
    NSDictionary *userInfo = [nsNotification userInfo];
    CGRect kbRect = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGSize kbSize = kbRect.size;
    NSInteger kbTop = viewFrame.origin.y + viewFrame.size.height - kbSize.height;
    
    CGRect fieldContentSize = CGRectMake(viewFrame.origin.x ,
                                            viewFrame.origin.y,
                                            viewFrame.size.width,
                                            fieldsFrame.size.height - kbSize.height);
    
    self.viewFields.contentSize = viewFrame.size;
    self.viewFields.frame = fieldContentSize;
    
}

- (void)keyboardWasDismissed:(NSNotification *)notification
{
    self.viewFields.frame = self.view.frame;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    NSLog(@"foo");
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSLog(@"foo");
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

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


#pragma mark - UITextInputDelegate methods

- (void)selectionWillChange:(id <UITextInput>)textInput
{
    NSLog(@"foo");
}

- (void)selectionDidChange:(id <UITextInput>)textInput
{
    NSLog(@"foo");
}

- (void)textWillChange:(id <UITextInput>)textInput
{
    NSLog(@"foo");
}

- (void)textDidChange:(id <UITextInput>)textInput
{
    NSLog(@"foo");
}


@end
