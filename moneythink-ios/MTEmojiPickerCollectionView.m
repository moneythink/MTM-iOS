//
//  MTEmojiPickerCollectionView.m
//  moneythink-ios
//
//  Created by David Sica on 6/2/15.
//  Copyright (c) 2015 Moneythink. All rights reserved.
//

#import "MTEmojiPickerCollectionView.h"
#import "MTEmojiPickerCollectionViewCell.h"

@interface MTEmojiPickerCollectionView ()

@end

@implementation MTEmojiPickerCollectionView

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[MTEmojiPickerCollectionViewCell class] forCellWithReuseIdentifier:@"EmojiPickerCollectionViewCell"];
}


#pragma mark <UICollectionViewDataSource> -
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.emojiObjects count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MTEmojiPickerCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"EmojiPickerCollectionViewCell" forIndexPath:indexPath];
    
    MTEmoji *emojiObject = [self.emojiObjects objectAtIndex:indexPath.item];

    [[cell viewWithTag:99] removeFromSuperview];
    cell.emojiImage = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 48.0f, 48.0f)];
    cell.emojiImage.tag = 99;
    cell.emojiImage.contentMode = UIViewContentModeScaleAspectFill;
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.emojiImage.layer.borderColor = [UIColor primaryOrange].CGColor;
    cell.emojiImage.layer.cornerRadius = 4.0f;
    cell.emojiImage.image = [UIImage imageWithData:emojiObject.emojiImage.imageData];
    
    [cell.contentView addSubview:cell.emojiImage];
    
    return cell;
}


#pragma mark <UICollectionViewDelegate> -
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    MTEmoji *emojiObject = [self.emojiObjects objectAtIndex:indexPath.item];
    if ([self.delegate respondsToSelector:@selector(didSelectEmoji:withPost:)]) {
        [self.delegate didSelectEmoji:emojiObject withPost:self.post];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    MTEmojiPickerCollectionViewCell *cell = (MTEmojiPickerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.emojiImage.layer.borderWidth = 1.0f;
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
    MTEmojiPickerCollectionViewCell *cell = (MTEmojiPickerCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    cell.emojiImage.layer.borderWidth = 0.0f;
}


@end
