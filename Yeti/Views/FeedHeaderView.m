//
//  FeedHeaderView.m
//  Elytra
//
//  Created by Nikhil Nigade on 09/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedHeaderView.h"

@implementation FeedHeaderView

- (instancetype)initWithNib {
    
    if (self = [super initWithNib]) {
        
//        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.faviconView.layer.cornerRadius = 3.f;
        self.faviconView.layer.cornerCurve = kCACornerCurveContinuous;
        self.faviconView.clipsToBounds = YES;
        
    }
    
    return self;
}

- (CGSize)intrinsicContentSize {
    
    CGSize size = [super intrinsicContentSize];
    
    if (self.superview) {
        size.width = self.superview.bounds.size.width;
    }
    
    CGSize stackViewSize = [self.mainStackView systemLayoutSizeFittingSize:UILayoutFittingExpandedSize];
    
    size.height = stackViewSize.height + 16.f;
    
    return size;
    
}

@end
