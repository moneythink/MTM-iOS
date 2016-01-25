//
//  MTExplorePostCollectionView.h
//  moneythink-ios
//
//  Created by jdburgie on 8/7/14.
//  Copyright (c) 2014 Moneythink. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MTExplorePostCollectionView : UICollectionViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, nonatomic) MTChallenge *challenge;
@property (assign) BOOL isVisible;

@end
