//
//  UITableViewController+ScrollLoad.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "UIViewController+ScrollLoad.h"

@implementation UIViewController (ScrollLoad)

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    
    @try {
        if ([self valueForKeyPath:@"scrollView"] == nil) {
            return;
        }
    }
    @catch (NSException *exc) {
        // not supported
        return;
    }
    
    if (![scrollView.delegate conformsToProtocol:NSProtocolFromString(@"ScrollLoading")])
        return;
    
    CGFloat actualPosition = scrollView.contentOffset.y + (scrollView.adjustedContentInset.top);
    CGFloat contentHeight = scrollView.contentSize.height;
    
    CGFloat diff = contentHeight - actualPosition - scrollView.adjustedContentInset.top;
    CGFloat const threshold = scrollView.bounds.size.height - 120.f;
    
    BOOL percentage = (diff/threshold) > 0.70f;
    CGFloat bottomOffset = (scrollView.bounds.size.height - scrollView.frame.origin.y - (scrollView.adjustedContentInset.top + scrollView.adjustedContentInset.bottom)) - scrollView.contentOffset.y;
    
    BOOL isAtBottom = bottomOffset <= 120.f;
    
    BOOL contentSmallerThanContentSize = contentHeight < scrollView.bounds.size.height;
    
    NSLog(@"Diff:%@\nThreshold:%@\nPercent:%@\nisAtBottom:%@", @(diff), @(threshold), @(diff/threshold), @(isAtBottom));
    
    if (percentage || isAtBottom || contentSmallerThanContentSize) {
        id delegate = scrollView.delegate;
        
        if (delegate && [scrollView.delegate respondsToSelector:@selector(loadNextPage)]) {
            
            if (![delegate isLoadingNext] && ![delegate cantLoadNext]) {
                NSLog(@"Loading next page for: %@", self);
                
                [delegate loadNextPage];
            }
        }
    }
}

@end
