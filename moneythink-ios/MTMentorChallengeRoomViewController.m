//
//  MTMentorChallengeRoomViewController.m
//  moneythink-ios
//
//  Created by jdburgie on 7/28/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTMentorChallengeRoomViewController.h"

@interface MTMentorChallengeRoomViewController ()

@end

@implementation MTMentorChallengeRoomViewController

- (id)init
{
    self = [super init];
//    NSLog(@"MTMentorChallengeRoomViewController init");
    
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    NSLog(@"MTMentorChallengeRoomViewController initWithNibName");
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

- (void)viewWillAppear:(BOOL)animated
{
    self.parentViewController.navigationItem.title = @"Challenges";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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


- (IBAction)buttonImagePickerTouchUp:(id)sender {
//    [self startCameraControllerFromViewController: self
//                                    usingDelegate: self];
    
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
}

- (IBAction)buttonImagePicker2:(id)sender {
    
    [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
}


- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType
{
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    
    imagePickerController.allowsEditing = YES;
        
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}


#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [[UIImage alloc] init];
    
    if ([info objectForKey:UIImagePickerControllerEditedImage]) {
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    } else {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    if (image.size.width > 480.0f) {
        CGFloat scale = 480.0f / image.size.width;
        CGFloat heightNew = scale * image.size.height;
        CGSize sizeNew = CGSizeMake(480.0f, heightNew);
        UIGraphicsBeginImageContext(sizeNew);
        [image drawInRect:CGRectMake(0,0,sizeNew.width,sizeNew.height)];
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    self.anyImage.image = image;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    
}


@end
