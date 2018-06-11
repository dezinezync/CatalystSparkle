//
//  UIViewController+Hairline.m
//  Yeti
//
//  Created by Nikhil Nigade on 11/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "UIViewController+Hairline.h"

@implementation UIViewController (Hairline)

- (UIImageView *)yt_findHairlineImageViewUnder:(UIView *)view {
    
    NSArray <UIImageView *> *imageViews = @[];
    
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    
    for (UIView *subview in view.subviews) {
        UIImageView *imageView = [self yt_findHairlineImageViewUnder:subview];
        if (imageView) {
            imageViews = [imageViews arrayByAddingObject:imageView];
        }
    }
    
    return [imageViews lastObject];
}

@end
