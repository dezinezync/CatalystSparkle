//
//  UITableViewController+ScrollLoad.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "UITableViewController+ScrollLoad.h"

@implementation UITableViewController (ScrollLoad)

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if ([self respondsToSelector:@selector(yt_scrollViewDidScroll:)]) {
        [self yt_scrollViewDidScroll:scrollView];
    }
    
    if (![scrollView.delegate conformsToProtocol:NSProtocolFromString(@"ScrollLoading")])
        return;
    
    CGFloat actualPosition = scrollView.contentOffset.y + (scrollView.adjustedContentInset.top);
    CGFloat contentHeight = scrollView.contentSize.height;
    
    CGFloat diff = contentHeight - actualPosition;
    CGFloat const threshold = scrollView.bounds.size.height - 120.f;
    
//    DDLogDebug(@"%@ %@", @(diff), @(actualPosition));
    if (diff <= threshold) {
        if ([scrollView.delegate respondsToSelector:@selector(loadNextPage)]) {
            id del = scrollView.delegate;
            if (![del isLoadingNext] && ![del cantLoadNext])
                [del loadNextPage];
        }
    }
}

- (void)yt_scrollViewDidScroll:(UIScrollView *)scrollView {}

@end
