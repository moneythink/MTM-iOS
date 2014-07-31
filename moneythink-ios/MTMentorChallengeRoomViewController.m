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



//- (BOOL) startCameraControllerFromViewController: (UIViewController*) controller
//                                   usingDelegate: (id <UIImagePickerControllerDelegate,
//                                                   UINavigationControllerDelegate>) delegate {
//    
//    if (([UIImagePickerController isSourceTypeAvailable:
//          UIImagePickerControllerSourceTypeCamera] == NO)
//        || (delegate == nil)
//        || (controller == nil))
//        return NO;
//    
//    
//    UIImagePickerController *cameraUI = [[UIImagePickerController alloc] init];
//    cameraUI.sourceType = UIImagePickerControllerSourceTypeCamera;
//    cameraUI.mediaTypes = [NSArray arrayWithObject:(NSString *) kUTTypeImage];
//    cameraUI.allowsEditing = YES;
//    cameraUI.delegate = delegate;
//    
//    [controller presentViewController:cameraUI animated:YES completion:nil];
//    
//    return YES;
//}


#pragma mark - UIImagePickerControllerDelegate methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [[UIImage alloc] init];
    
    if ([info objectForKey:UIImagePickerControllerEditedImage]) {
        image = [info objectForKey:UIImagePickerControllerEditedImage];
    } else {
        image = [info objectForKey:UIImagePickerControllerOriginalImage];
    }
    
    self.anyImage.image = image;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    
}


@end
