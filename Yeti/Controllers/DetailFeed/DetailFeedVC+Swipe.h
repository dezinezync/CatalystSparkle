//
//  DetailFeedVC+Swipe.h
//  Yeti
//
//  Created by Nikhil Nigade on 02/05/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "DetailFeedVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface DetailFeedVC (Swipe) <UIGestureRecognizerDelegate>

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

#pragma mark -

- (void)didPanForSwipe:(UIPanGestureRecognizer * _Nonnull)sender;

- (void)resetSwipedCell;

@end

NS_ASSUME_NONNULL_END
