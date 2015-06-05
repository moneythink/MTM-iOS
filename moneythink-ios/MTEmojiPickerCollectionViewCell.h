//
//  MTEmojiPickerCollectionViewCell.h
//  moneythink-ios
//
//  Created by David Sica on 6/2/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTEmojiPickerCollectionViewCell : UICollectionViewCell

@property (nonatomic, strong) IBOutlet UIImageView *emojiImageView;
@property (nonatomic, strong) PFImageView *emojiImage;

@end
