//
//  UITableViewController+ScrollLoad.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "UIViewController+ScrollLoad.h"

@implementation UIViewController (ScrollLoad)

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    if (scrollView == nil) {
        return;
    }
    
    if (![scrollView.delegate conformsToProtocol:NSProtocolFromString(@"ScrollLoading")] == YES) {
        return;
    }
    
    if ([scrollView.delegate respondsToSelector:@selector(dz_scrollViewDidScroll:)] == YES) {
        [scrollView.delegate performSelector:@selector(dz_scrollViewDidScroll:)];
    }
    
    CGFloat scrollPositionY = (scrollView.contentOffset.y + scrollView.frame.size.height) + 300.f;
    
    CGFloat contentHeight = scrollView.contentSize.height - (scrollView.adjustedContentInset.top + scrollView.adjustedContentInset.bottom) ;
    
//    NSLogDebug(@"Pos Y: %@ -- Content Height: %@", @(scrollPositionY), @(contentHeight));
    
    if (scrollPositionY >= contentHeight) {
        
        id delegate = scrollView.delegate;
        
        if (delegate && [scrollView.delegate respondsToSelector:@selector(loadNextPage)]) {
            
            if ([delegate isLoading] == NO && [delegate canLoadNext]) {
                
                NSLog(@"Loading next page for: %@", self);
                
                [delegate loadNextPage];
                
            }
            
        }
        
    }

}

@end
