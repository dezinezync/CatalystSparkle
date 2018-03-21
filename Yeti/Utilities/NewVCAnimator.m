//
//  NewVCAnimator.m
//  Yeti
//
//  Created by Nikhil Nigade on 21/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "NewVCAnimator.h"

@implementation NewVCTransitionDelegate

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [NewVCAnimator new];
}

- (id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    NewVCAnimator *animator = [[NewVCAnimator alloc] init];
    animator.dismissing = YES;
    
    return animator;
}

@end

@implementation NewVCAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    return 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    UIView *from = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIView *to = [transitionContext viewForKey:UITransitionContextToViewKey];
    
    UIView *container = [transitionContext containerView];
    
    if (self.isDismissing) {
        [UIView animateWithDuration:duration animations:^{
            from.alpha = 0;
        } completion:^(BOOL finished) {
            [from removeFromSuperview];
            [transitionContext completeTransition:finished];
        }];
    }
    else {
        to.alpha = 0;
        to.frame = container.bounds;
        
        [container addSubview:to];
        
        [UIView animateWithDuration:duration animations:^{
            to.alpha = 1;
        } completion:^(BOOL finished) {
            [transitionContext completeTransition:finished];
        }];
    }
}

@end
