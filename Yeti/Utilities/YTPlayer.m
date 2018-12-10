//
//  YTPlayer.m
//  Yeti
//
//  Created by Nikhil Nigade on 06/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YTPlayer.h"

@implementation YTPlayer

- (void)setRate:(float)rate {
    [super setRate:rate];
    
    if (rate > 0.f && self.playerViewController != nil) {
        
        // check if the cover is being shown.
        if ([self.playerViewController.contentOverlayView subviews].count > 0) {
            
            for (UIView *subview in self.playerViewController.contentOverlayView.subviews) {
                if ([subview isKindOfClass:UIImageView.class]) {
                
                    [UIView animateWithDuration:0.25 animations:^{
                    
                        subview.alpha = 0.f;
                        
                    } completion:^(BOOL finished) {
                        
                        if (finished) {
                            [subview removeFromSuperview];
                        }
                        
                    }];
                    
                }
            }
            
        }
        // ensure this does not run again
        self.playerViewController = nil;
        
    }
    
}

@end
