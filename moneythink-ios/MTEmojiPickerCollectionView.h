//
//  MTEmojiPickerCollectionView.h
//  moneythink-ios
//
//  Created by David Sica on 6/2/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MTEmojiPickerCollectionViewDelegate <NSObject>

- (void)didSelectEmoji:(PFEmoji *)emoji withPost:(MTChallengePost *)post;

@end

@interface MTEmojiPickerCollectionView : UICollectionViewController

@property (nonatomic, weak) id<MTEmojiPickerCollectionViewDelegate> delegate;

@property (nonatomic, strong) MTChallengePost *post;
@property (nonatomic, strong) NSArray *emojiObjects;

@end
