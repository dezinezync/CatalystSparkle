//
//  Gallery.h
//  Yeti
//
//  Created by Nikhil Nigade on 22/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DZKit/NibView.h>
#import "Content.h"

@interface Gallery : NibView

@property (nonatomic, weak) NSArray <Content *> *images;

@property (nonatomic, strong) NSLayoutConstraint *heightC;

/**
 This is the maximum height available on screen to display the images and the controls without underflowing the navigation bar and bottom bar.
 */
@property (nonatomic, assign) CGFloat maxScreenHeight;

@property (nonatomic, assign, getter=isLoading) BOOL loading;
@property (nonatomic, assign) NSInteger idx;

@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end
