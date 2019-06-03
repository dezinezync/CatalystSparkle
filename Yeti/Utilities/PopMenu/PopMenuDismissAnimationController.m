//
//  PopMenuDismissAnimationController.m
//  Yeti
//
//  Created by Nikhil Nigade on 24/05/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "PopMenuDismissAnimationController.h"
#import "PopMenuViewController.h"

@implementation PopMenuDismissAnimationController

- (instancetype)initWithSourceFrame:(CGRect)sourceFrame {
    
    if (self = [super init]) {
        self.sourceFrame = sourceFrame;
    }
    
    return self;
    
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    return 0.0982;
    
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    PopMenuViewController *menuViewController = (PopMenuViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    if (menuViewController == nil) {
        return;
    }
    
    UIView *containerView = transitionContext.containerView;
    UIView *view = menuViewController.view;
    
    view.frame = containerView.frame;
    [containerView addSubview:view];
    
    NSTimeInterval animationDuration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [self animate:menuViewController];
        
    } completion:^(BOOL finished) {
        
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        
    }];
    
}

- (void)animate:(PopMenuViewController *)viewController {
    
    viewController.containerView.alpha = 0.f;
    viewController.backgroundView.alpha = 0.f;
    
    viewController.containerView.transform = CGAffineTransformMakeScale(0.55f, 0.55f);
}

@end
