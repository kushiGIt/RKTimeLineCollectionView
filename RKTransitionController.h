//
//  RKTransitionController.h
//  RKtimeLineCollectionView
//
//  Created by RyousukeKushihata on 2014/10/25.
//  Copyright (c) 2014年 RyousukeKushihata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol RKTransitionControllerDelegate <NSObject>

- (void)interactionBeganAtPoint:(CGPoint)point;

@end

@interface RKTransitionController : NSObject  <UIViewControllerAnimatedTransitioning, UIViewControllerInteractiveTransitioning, UIGestureRecognizerDelegate>

@property (nonatomic) id <RKTransitionControllerDelegate> delegate;
@property (nonatomic) BOOL hasActiveInteraction;
@property (nonatomic) UINavigationControllerOperation navigationOperation;
@property (nonatomic) UICollectionView *collectionView;

- (instancetype)initWithCollectionView:(UICollectionView*)collectionView;


@end
