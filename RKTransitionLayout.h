//
//  RKTransitionLayout.h
//  RKtimeLineCollectionView
//
//  Created by RyousukeKushihata on 2014/10/25.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RKTransitionLayout : UICollectionViewTransitionLayout

@property (nonatomic) UIOffset offset;
@property (nonatomic) CGFloat progress;
@property (nonatomic) CGSize itemSize;


@end
