//
//  MTExploreCollectionViewCell.h
//  moneythink-ios
//
//  Created by jdburgie on 8/10/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTExploreCollectionViewCell : UICollectionViewCell

@property (strong, nonatomic) IBOutlet UILabel *postText;
@property (strong, nonatomic) IBOutlet UILabel *postUser;

@property (strong, nonatomic) IBOutlet PFImageView *postImage;
@property (strong, nonatomic) IBOutlet PFImageView *postUserImage;

@end
