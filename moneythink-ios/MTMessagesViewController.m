//
//  MTMessagesViewController.m
//  moneythink-ios
//
//  Created by Colin Young on 2/11/16.
//  Copyright © 2016 Moneythink. All rights reserved.
//

#import "MTMessagesViewController.h"

@interface MTMessagesViewController ()

@end

@implementation MTMessagesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.contactPickerView setPromptLabelText:@"To:"];
    [self.contactPickerView setPlaceholderLabelText:@"Mentor name"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - JSQMessagesComposerTextViewPasteDelegate methods


//- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender
//{
//    if ([UIPasteboard generalPasteboard].image) {
//        // If there's an image in the pasteboard, construct a media item with that image and `send` it.
//        JSQPhotoMediaItem *item = [[JSQPhotoMediaItem alloc] initWithImage:[UIPasteboard generalPasteboard].image];
//        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:self.senderId
//                                                 senderDisplayName:self.senderDisplayName
//                                                              date:[NSDate date]
//                                                             media:item];
//        [self.demoData.messages addObject:message];
//        [self finishSendingMessage];
//        return NO;
//    }
//    return YES;
//}

#pragma mark - THContactPickerDelegate
- (void)contactPicker:(THContactPickerView *)contactPicker didSelectContact:(id)contact {
    NSLog(@"%@", contact);
}

- (void)contactPicker:(THContactPickerView *)contactPicker didRemoveContact:(id)contact {
    NSLog(@"%@", contact);
}

@end
