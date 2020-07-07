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
    
    CGFloat scrollPositionY = (scrollView.contentOffset.y + scrollView.frame.size.height) + 300.f;
    
    CGFloat contentHeight = scrollView.contentSize.height - (scrollView.adjustedContentInset.top + scrollView.adjustedContentInset.bottom) ;
    
    NSLogDebug(@"Pos Y: %@ -- Content Height: %@", @(scrollPositionY), @(contentHeight));
    
    if (scrollPositionY >= contentHeight) {
        
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
