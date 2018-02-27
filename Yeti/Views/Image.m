//
//  Image.m
//  Yeti
//
//  Created by Nikhil Nigade on 25/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Image.h"

@interface Image ()

@end

@implementation Image

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.f];
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.layoutMargins = UIEdgeInsetsZero;
    }
    
    return self;
}

- (void)setImage:(UIImage *)image
{
    [super setImage:image];
    
    self.backgroundColor = UIColor.blueColor;
    
    weakify(self);
    
    asyncMain(^{
        strongify(self);
        [self invalidateIntrinsicContentSize];
        
        if (self.contentMode == UIViewContentModeScaleAspectFit) {
            [self updateAspectRatioWithImage:self.image];
        }
    });

}

- (void)updateAspectRatioWithImage:(UIImage *)image
{
    if (self.aspectRatio) {
        [self removeConstraint:self.aspectRatio];
    }
    
    CGFloat aspectRatioValue = image.size.height / image.size.width;
    self.aspectRatio = [self.heightAnchor constraintEqualToConstant:aspectRatioValue * self.bounds.size.width];
    [self addConstraint:self.aspectRatio];
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];

    if (self.image) {
        size.width = self.superview.frame.size.width + self.superview.frame.origin.x;
        size.height = ceilf(self.image.size.height / (self.image.size.width / size.width));
    }

    return size;
}

@end
