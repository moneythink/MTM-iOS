//
//  MTPostViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/20/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTPostViewController.h"

@interface MTPostViewController ()

@property (strong, nonatomic) IBOutlet UILabel *postUsername;
@property (strong, nonatomic) IBOutlet PFImageView *postUserImage;
@property (strong, nonatomic) IBOutlet UIButton *postUserButton;
@property (strong, nonatomic) IBOutlet UILabel *whenPosted;

@property (strong, nonatomic) IBOutlet PFImageView *postImage;
@property (strong, nonatomic) IBOutlet UITextView *postText;

@property (strong, nonatomic) IBOutlet UIButton *commentPost;
@property (strong, nonatomic) IBOutlet UITextField *postComment;

@property (strong, nonatomic) IBOutlet UIButton *likePost;
@property (strong, nonatomic) IBOutlet UILabel *postLikes;

@property (strong, nonatomic) IBOutlet UITableView *commentsLikesTableView;

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
        }
    }];
    
    self.postText.text = self.challengePost[@"post_text"];
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
    }];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITextFieldDelegate delegate methods


//- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
//    return YES;
//}

//- (void)textFieldDidBeginEditing:(UITextField *)textField {
//
//}

//- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
//    return YES;
//}

- (void)textFieldDidEndEditing:(UITextField *)textField {

}

//- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
//    return YES;
//}

//- (BOOL)textFieldShouldClear:(UITextField *)textField {
//    return YES;
//}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    return YES;
}


#pragma mark - UITextInputDelegate methods

- (void)selectionWillChange:(id<UITextInput>)textInput
{
    
}

- (void)selectionDidChange:(id<UITextInput>)textInput
{
    
}

- (void)textWillChange:(id <UITextInput>)textInput
{
    
}

- (void)textDidChange:(id <UITextInput>)textInput
{
    
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

- (IBAction)unwindToPostView:(UIStoryboardSegue *)sender
{
    
}

@end
