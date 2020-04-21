//
//  UIRefreshControl+Manual.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/03/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "UIRefreshControl+Manual.h"

@implementation UIRefreshControl (Manual)

- (void)beginRefreshingManually:(BOOL)animated {
    
    if ([NSThread isMainThread] == NO) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            [self beginRefreshingManually:animated];
            
        });
        
        return;
        
    }
    
    if (self.isRefreshing == YES) {
        return;
    }
    
    UIScrollView *scrollView = [self valueForKeyPath:@"scrollView"];
    
    if (scrollView != nil && [scrollView isKindOfClass:UIScrollView.class] == YES) {
        
        CGPoint contentOffset = scrollView.contentOffset;
        contentOffset.y -= self.frame.size.height;
        
        [scrollView setContentOffset:contentOffset animated:animated];
        
    }
    
    [self beginRefreshing];
    
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    
}

@end
