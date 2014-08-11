//
//  MTPostViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTPostViewController.h"
#import "MTMentorStudentProfileViewController.h"

@interface MTPostViewController ()

@property (strong, nonatomic) IBOutlet UILabel *postUsername;
@property (strong, nonatomic) IBOutlet PFImageView *postUserImage;
@property (strong, nonatomic) IBOutlet UIButton *postUserButton;
@property (strong, nonatomic) IBOutlet UILabel *whenPosted;

@property (strong, nonatomic) IBOutlet PFImageView *postImage;
@property (strong, nonatomic) IBOutlet UILabel *postText;

@property (strong, nonatomic) IBOutlet UIButton *commentPost;
@property (strong, nonatomic) IBOutlet UITextField *postComment;

@property (strong, nonatomic) IBOutlet UIButton *likePost;
@property (strong, nonatomic) IBOutlet UILabel *postLikes;

@property (strong, nonatomic) IBOutlet UIButton *comment;
@property (strong, nonatomic) IBOutlet UILabel *commentCount;
@property (assign, nonatomic) NSInteger commentsCount;

@property (strong, nonatomic) IBOutlet UIButton *button1;
@property (strong, nonatomic) IBOutlet UIButton *button2;

@property (strong, nonatomic) IBOutlet MICheckBox *verifiedCheckBox;
@end

@implementation MTPostViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
    
    self.postComment.delegate = self;
    
    PFQuery *queryPostComments = [PFQuery queryWithClassName:[PFChallengePostComment parseClassName]];
    [queryPostComments whereKey:@"challenge_post" equalTo:self.challengePost];
    [queryPostComments includeKey:@"user"];
    [queryPostComments countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
        if (!error) {
            self.commentsCount = number;
        }
    }];
    
    __block PFUser *user = self.challengePost[@"user"];
    
    NSPredicate *posterWithID = [NSPredicate predicateWithFormat:@"objectId = %@", [user objectId]];
    PFQuery *findPoster = [PFQuery queryWithClassName:[PFUser parseClassName] predicate:posterWithID];
    [findPoster findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            user = [objects firstObject];
            self.postUsername.text = [user username];
            self.postUserImage.file = user[@"profile_picture"];

            [self.postUserImage loadInBackground:^(UIImage *image, NSError *error) {
                CGRect frame = self.postUserButton.frame;
                
                if (image.size.width > frame.size.width) {
                    CGFloat scale = frame.size.width / image.size.width;
                    CGFloat heightNew = scale * image.size.height;
                    CGSize sizeNew = CGSizeMake(frame.size.width, heightNew);
                    UIGraphicsBeginImageContext(sizeNew);
                    [image drawInRect:CGRectMake(0.0f, 0.0f, sizeNew.width, sizeNew.height)];
                    image = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                }
                
                [self.postUserButton setImage:image forState:UIControlStateNormal];
            }];
        } else {
            NSLog(@"error - %@", error);
        }
    }];
    
    
    
    // >>>>> Attributed hashtag
    self.postText.text = self.challengePost[@"post_text"];
    
    NSRegularExpression *hashtags = [[NSRegularExpression alloc] initWithPattern:@"\\#\\w+" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRange rangeAll = NSMakeRange(0, self.postText.text.length);
    
    [hashtags enumerateMatchesInString:self.postText.text options:NSMatchingWithoutAnchoringBounds range:rangeAll usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        
        NSMutableAttributedString *hashtag = [[NSMutableAttributedString alloc]initWithString:self.postText.text];
        [hashtag addAttribute:NSForegroundColorAttributeName value:[UIColor primaryOrange] range:result.range];
        
        self.postText.attributedText = hashtag;
    }];
    // Attributed hashtag

    
    
    self.postImage.file = self.challengePost[@"picture"];
    
    [self.postImage loadInBackground:^(UIImage *image, NSError *error) {
//        NSLog(@"post image frame size width - %f", self.postImage.frame.size.width);
//        NSLog(@"post image frame size height - %f", self.postImage.frame.size.height);
//        NSLog(@"post image frame origin x - %f", self.postImage.frame.origin.x);
//        NSLog(@"post image frame origin y - %f", self.postImage.frame.origin.y);
        if (!error) {
            CGRect frame = self.postImage.frame;
            
            if (image) {
                if (image.size.width > frame.size.width) {
                    CGFloat scale = frame.size.width / image.size.width;
                    CGFloat heightNew = scale * image.size.height;
                    CGSize sizeNew = CGSizeMake(frame.size.width, heightNew);
                    UIGraphicsBeginImageContext(sizeNew);
                    [image drawInRect:CGRectMake(0.0f, 0.0f, sizeNew.width, sizeNew.height)];
                    image = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                }
                
                self.postImage.image = image;
            } else {
                self.postImage.frame = CGRectZero;
            }

//            NSLog(@"post image frame size width - %f", self.postImage.frame.size.width);
//            NSLog(@"post image frame size height - %f", self.postImage.frame.size.height);
//            NSLog(@"post image frame origin x - %f", self.postImage.frame.origin.x);
//            NSLog(@"post image frame origin y - %f", self.postImage.frame.origin.y);

//            [self.postImage updateConstraintsIfNeeded];
//            [self.postImage layoutIfNeeded];
            
        } else {
            NSLog(@"error - %@", error);
        }
    }];
    
    [[self.button1 layer] setBorderWidth:2.0f];
    [[self.button1 layer] setCornerRadius:5.0f];
    [[self.button1 layer] setBorderColor:[UIColor greenColor].CGColor];
    [self.button1 setTintColor:[UIColor greenColor]];
    
    [[self.button2 layer] setCornerRadius:5.0f];
    [[self.button2 layer] setBackgroundColor:[UIColor redColor].CGColor];
    [self.button2 setTintColor:[UIColor white]];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.title = @"Post";

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasDismissed:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self dismissKeyboard];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


-(void)dismissKeyboard {
    [self.view endEditing:YES];
}



//- (void)viewWillLayoutSubviews {
//    NSLog(@"post image frame size height - %f", self.postImage.frame.size.height);
//
//    CGRect frame = self.postImage.frame;
//    frame.size.height = 0.0f;
//    
//    self.postImage.frame = frame;
//    
//    NSLog(@"post image frame size height - %f", self.postImage.frame.size.height);
//
//    [self updateViewConstraints];
//    [self.view layoutIfNeeded];
//}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) keyboardWasShown:(NSNotification *)nsNotification {
//    CGRect viewFrame = self.view.frame;
//    CGRect fieldsFrame = self.viewFields.frame;
//    
//    NSDictionary *userInfo = [nsNotification userInfo];
//    CGRect kbRect = [[userInfo objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
//    CGSize kbSize = kbRect.size;
//    NSInteger kbTop = viewFrame.origin.y + viewFrame.size.height - kbSize.height;
//    
//    CGRect fieldFrameSize = CGRectMake(fieldsFrame.origin.x ,
//                                       fieldsFrame.origin.y,
//                                       fieldsFrame.size.width,
//                                       fieldsFrame.size.height - kbSize.height + 40.0f);
//    
//    fieldFrameSize = CGRectMake(0.0f, 0.0f, viewFrame.size.width, kbTop);
//    
//    self.viewFields.contentSize = CGSizeMake(viewFrame.size.width, kbTop + 160.0f);
//    
//    self.viewFields.frame = fieldFrameSize;
}

- (void)keyboardWasDismissed:(NSNotification *)notification
{
//    self.viewFields.frame = self.view.frame;
}



#pragma mark - UITextFieldDelegate delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *segueID = [segue identifier];
    if ([segueID isEqualToString:@"pushStudentProfileFromPost"]) {
        MTMentorStudentProfileViewController *destinationVC = (MTMentorStudentProfileViewController *)[segue destinationViewController];
        destinationVC.student = self.challengePost[@"user"];
    }
}

- (IBAction)unwindToPostView:(UIStoryboardSegue *)sender
{
    
}

@end
