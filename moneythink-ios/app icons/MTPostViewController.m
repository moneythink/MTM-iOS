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
    
    
    
    UIImage *postImage = [UIImage imageNamed:@"post"];
    UIBarButtonItem *postComment = [[UIBarButtonItem alloc]
                                    initWithImage:postImage
                                    style:UIBarButtonItemStyleBordered
                                    target:self
                                    action:@selector(postCommentSelector)];
    
    self.navigationItem.rightBarButtonItem = postComment;
    
    
    
    
//    NSPredicate *challengePredicate = [NSPredicate predicateWithFormat:@"asdf = %@", ];
//    PFQuery *queryChallenges = [PFQuery queryWithClassName:[PFChallenges parseClassName] predicate:challengePredicate];
    
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
        CGRect frame = self.postImage.frame;
        
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)postCommentSelector
{

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
