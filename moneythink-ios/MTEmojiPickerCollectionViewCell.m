//
//  MTEmojiPickerCollectionViewCell.m
//  moneythink-ios
//
//  Created by David Sica on 6/2/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTEmojiPickerCollectionViewCell.h"

@implementation MTEmojiPickerCollectionViewCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    self.emojiImage.image = nil;
    self.emojiImageView.image = nil;
}


@end
