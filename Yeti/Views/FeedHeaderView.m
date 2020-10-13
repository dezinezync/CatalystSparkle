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
        
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
    }
    
    return self;
}

- (void)setFrame:(CGRect)frame {
    
    if (self.superview != nil && self.superview.bounds.size.width > 0) {
        
        CGFloat width = self.superview.readableContentGuide.layoutFrame.size.width;
        
        self.titleLabel.preferredMaxLayoutWidth = width - CGRectGetMinX(self.titleLabel.frame) - 24.f;
        self.descriptionLabel.preferredMaxLayoutWidth = width - CGRectGetMinX(self.descriptionLabel.frame) - 24.f;
        
    }
    else {
        self.titleLabel.preferredMaxLayoutWidth = self.bounds.size.width - CGRectGetMinX(self.titleLabel.frame) - 24.f;
        self.descriptionLabel.preferredMaxLayoutWidth = self.bounds.size.width - CGRectGetMinX(self.descriptionLabel.frame) - 24.f;
    }
    
    [super setFrame:frame];
    
}

- (CGSize)intrinsicContentSize {
    
    CGSize size = [super intrinsicContentSize];
    
    if (self.superview) {
        size.width = self.superview.bounds.size.width;
    }
    
    CGSize stackViewSize = [self.mainStackView systemLayoutSizeFittingSize:UILayoutFittingExpandedSize];
    
    size.height = stackViewSize.height + 8.f;
    
    return size;
    
}

@end
