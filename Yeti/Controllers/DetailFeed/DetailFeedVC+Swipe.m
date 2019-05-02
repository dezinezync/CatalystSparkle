//
//  DetailFeedVC+Swipe.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/05/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "DetailFeedVC+Swipe.h"
#import "ArticleCellB.h"

@implementation DetailFeedVC (Swipe)

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return (gestureRecognizer == self.swipePanGesture || otherGestureRecognizer == self.swipePanGesture);
    
}

#pragma mark - Actions

- (void)didPanForSwipe:(UIPanGestureRecognizer *)sender {
    
    CGFloat const minimumVelocity = 250.f;
    
    CGPoint velocity = [sender velocityInView:self.collectionView];
    
    // reject the translation if the velocity is less
    // than the minimum threshold to avoid accidental
    // swipes when scrolling the collection view.
    if (ABS(velocity.x) < minimumVelocity) {
        return;
    }

    if (sender.state == UIGestureRecognizerStateBegan) {
        CGPoint location = [sender locationInView:self.collectionView];
        
        NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:location];
        
        DDLogDebug(@"Swiping indexPath: %@", indexPath);
        
        [self resetSwipedCell];
        
        self.swipingIndexPath = indexPath;
    }
    else if (sender.state == UIGestureRecognizerStateChanged) {
        
        if (self.swipingIndexPath == nil) {
            return;
        }
        
        ArticleCellB *cell = (ArticleCellB *)[self.collectionView cellForItemAtIndexPath:self.swipingIndexPath];
        
        CGPoint translation = [sender translationInView:cell];
        
        // compute the final frame
        CGRect frame = cell.swipeStackView.frame;
        CGAffineTransform transform = CGAffineTransformTranslate(cell.swipeStackView.transform, translation.x, 0.f);
        
        CGRect finalFrame = CGRectApplyAffineTransform(frame, transform);
        
        if (CGRectGetMinX(finalFrame) < 0.f) {
            // set the transform to be minimum of 0.f
            transform = CGAffineTransformIdentity;
        }
        
        // if the user is very close to opening
        // open it completely when swiping left
        if ((finalFrame.origin.x < 120.f) && (velocity.x < 0.f)) {
            transform = CGAffineTransformIdentity;
        }
        
        // or optionally close it completely
        // if the user closes it up to 80% when swiping right
        if ((finalFrame.origin.x > (frame.size.width * 0.8f)) && (velocity.x > 0.f)) {
            // close the menu
            [self resetSwipedCell];
            return;
        }
        
        CGFloat alpha = transform.tx / frame.size.width;
        if (alpha < 0.2f) {
            alpha = 0.f;
        }
        else if (alpha > 0.9f) {
            alpha = 1.f;
        }
        
        [UIView animateWithDuration:0.025 animations:^{
            cell.swipeStackView.transform = transform;
            cell.mainStackView.alpha = alpha;
        }];
        
    }
    else if (sender.state == UIGestureRecognizerStateFailed || sender.state == UIGestureRecognizerStateCancelled) {
        
        [self resetSwipedCell];
        
    }
    
}

- (void)resetSwipedCell {
    
    if (self.swipingIndexPath == nil) {
        return;
    }
    
    DDLogDebug(@"Resetting existing swiped indexPath: %@", self.swipingIndexPath);
    
    ArticleCellB *cell = (ArticleCellB *)[self.collectionView cellForItemAtIndexPath:self.swipingIndexPath];
    
    [UIView animateWithDuration:0.2 animations:^{
        cell.mainStackView.alpha = 1.f;
        [cell setupInitialSwipeState];
    }];
}

@end
