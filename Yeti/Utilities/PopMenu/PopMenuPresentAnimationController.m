//
//  PopMenuPresentAnimationController.m
//  Yeti
//
//  Created by Nikhil Nigade on 24/05/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "PopMenuPresentAnimationController.h"
#import "PopMenuViewController.h"

#import "UIView+Anchoring.h"

@implementation PopMenuPresentAnimationController

- (instancetype)initWithSourceFrame:(CGRect)sourceFrame {
    
    if (self = [super init]) {
        self.sourceFrame = sourceFrame;
    }
    
    return self;
    
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    return 0.138;
    
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    PopMenuViewController *menuViewController = (PopMenuViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if (menuViewController == nil) {
        return;
    }
    
    UIView *containerView = transitionContext.containerView;
    UIView *view = menuViewController.view;
    
    view.frame = containerView.frame;
    [containerView addSubview:view];
    
    [self prepareAnimtion:menuViewController];
    
    NSTimeInterval animationDuration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        
        [self animate:menuViewController];
        
    } completion:^(BOOL finished) {
       
        [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
        
    }];
    
}

- (void)prepareAnimtion:(PopMenuViewController *)viewController {
 
    viewController.containerView.alpha = 0.f;
    viewController.backgroundView.alpha = 0.f;
    
    viewController.contentLeftConstraint.constant = self.sourceFrame.origin.x;
    viewController.contentTopConstraint.constant = self.sourceFrame.origin.y;
    viewController.contentWidthConstraint.constant = self.sourceFrame.size.width;
    viewController.contentHeightConstraint.constant = self.sourceFrame.size.height;
    
}

- (void)animate:(PopMenuViewController *)viewController {
    
    viewController.containerView.alpha = 1.f;
    viewController.backgroundView.alpha = 1.f;
    
    viewController.contentLeftConstraint.constant = viewController.contentFrame.origin.x;
    viewController.contentTopConstraint.constant = viewController.contentFrame.origin.y;
    viewController.contentWidthConstraint.constant = viewController.contentFrame.size.width;
    viewController.contentHeightConstraint.constant = viewController.contentFrame.size.height;
    
    [viewController.containerView layoutIfNeeded];
}

@end
