//
//  MTMessagesViewController.h
//  moneythink-ios
//
//  Created by Colin Young on 2/11/16.
//  Copyright © 2016 Moneythink. All rights reserved.
//

#import <JSQMessagesViewController/JSQMessagesViewController.h>
#import "THContactPickerView.h"

@interface MTMessagesViewController : JSQMessagesViewController <
                                        UIActionSheetDelegate,
                                        JSQMessagesComposerTextViewPasteDelegate,
                                        THContactPickerDelegate
                                        >
@property (weak, nonatomic) IBOutlet THContactPickerView *contactPickerView;

@end
