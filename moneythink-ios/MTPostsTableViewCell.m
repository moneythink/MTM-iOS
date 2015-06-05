//
//  MTPostsTableViewCell.m
//  moneythink-ios
//
//  Created by jdburgie on 7/31/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import "MTPostsTableViewCell.h"

@implementation MTPostsTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.activityIndicator.hidden = YES;
    self.loadingView.alpha = 0.0f;
    [self.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateNormal];
    [self.likeButton setImage:[UIImage imageNamed:@"like_normal"] forState:UIControlStateDisabled];
    
    for (UIView *thisView in [self.emojiContainerView subviews]) {
        [thisView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
}

- (void)setEmojiArray:(NSArray *)emojiArray
{
    if (emojiArray != _emojiArray) {
        _emojiArray = emojiArray;
        
        [MTPostsTableViewCell layoutEmojiForContainerView:self.emojiContainerView withEmojiArray:self.emojiArray];
    }
}


#pragma mark - Public Methods -
+ (void)layoutEmojiForContainerView:(UIView *)containerView withEmojiArray:(NSArray *)emojiArray
{
    // Clear first
    for (UIView *thisView in [containerView subviews]) {
        [thisView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        thisView.clipsToBounds = YES;
    }

    NSMutableArray *uniqueEmojiArray = [NSMutableArray array];
    NSMutableArray *uniqueEmojiNameArray = [NSMutableArray array];
    for (PFEmoji *thisEmoji in emojiArray) {
        if (![uniqueEmojiNameArray containsObject:thisEmoji[@"name"]]) {
            [uniqueEmojiNameArray addObject:thisEmoji[@"name"]];
            [uniqueEmojiArray addObject:thisEmoji];
        }
    }
    
    // Sort by name, so consistent in presentation
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray *sortedUniqueEmojiArray = [uniqueEmojiArray sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    NSInteger otherCount = [emojiArray count]-[uniqueEmojiArray count];
    if ([uniqueEmojiArray count] >= 7 && [emojiArray count] >= [uniqueEmojiArray count]) {
        // Add extra count for removing optional 7th emoji
        otherCount = [emojiArray count] - 6;
    }
    
    NSInteger startIndex = 0;
    NSInteger finishIndex = 7;
    
    if (otherCount > 0) {
        // Show label first, then unique emoji
        UIView *counterView = [containerView viewWithTag:1];
        
        UIView *labelView = [[UIView alloc] initWithFrame:CGRectMake(0, 5.0f, counterView.frame.size.width, counterView.frame.size.height-10.0f)];
        labelView.layer.cornerRadius = 5.0f;
        labelView.backgroundColor = [UIColor colorWithHexString:@"#687377"];
        labelView.clipsToBounds = YES;
        
        UILabel *counterLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, labelView.frame.size.width, labelView.frame.size.height)];
        counterLabel.backgroundColor = [UIColor clearColor];
        counterLabel.font = [UIFont mtFontOfSize:11.0f];
        counterLabel.textColor = [UIColor whiteColor];
        counterLabel.textAlignment = NSTextAlignmentCenter;
        
        if (otherCount > 99) {
            otherCount = 99;
        }
        counterLabel.text = [NSString stringWithFormat:@"%lu+", otherCount];
        
        [labelView addSubview:counterLabel];
        [counterView addSubview:labelView];
        
        startIndex = 1;
    }
    
    if ([sortedUniqueEmojiArray count] < 7) {
        finishIndex = [sortedUniqueEmojiArray count];
    }
    
    for (NSInteger i = 0; i < finishIndex; i++) {
        PFEmoji *thisEmoji = [sortedUniqueEmojiArray objectAtIndex:i];
        PFFile *imageFile = nil;
        if (IS_RETINA) {
            imageFile = thisEmoji[@"image_2x"];
        }
        else {
            imageFile = thisEmoji[@"image"];
        }
        
        UIView *emojiView = [containerView viewWithTag:(i+startIndex+1)];
        emojiView.backgroundColor = [UIColor clearColor];
        PFImageView *emojiImageView = [[PFImageView alloc] initWithFrame:CGRectMake(0, 0, emojiView.frame.size.width, emojiView.frame.size.height)];
        emojiImageView.contentMode = UIViewContentModeScaleAspectFill;
        emojiImageView.file = imageFile;
        
        [emojiView addSubview:emojiImageView];
        
        [emojiImageView loadInBackground:^(UIImage *image, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!error) {
                    if (image) {
                        emojiImageView.image = image;
                        [containerView setNeedsDisplay];
                    }
                } else {
                    NSLog(@"error - %@", error);
                }
            });
        }];
    }
}


@end
