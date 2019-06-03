//
//  PopMenuDismissAnimationController.h
//  Yeti
//
//  Created by Nikhil Nigade on 24/05/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PopMenuDismissAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, assign) CGRect sourceFrame;

- (instancetype)initWithSourceFrame:(CGRect)sourceFrame;

@end

NS_ASSUME_NONNULL_END
