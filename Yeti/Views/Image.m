//
//  Image.m
//  Yeti
//
//  Created by Nikhil Nigade on 25/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Image.h"

@implementation Image

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.contentMode = UIViewContentModeScaleAspectFit;
        self.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.f];
    }
    
    return self;
}

- (void)setImage:(UIImage *)image
{
    [super setImage:image];
    
    [self invalidateIntrinsicContentSize];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (self.superview) {
        [self invalidateIntrinsicContentSize];
    }
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];
    
    if (self.image) {
        size.width = self.bounds.size.width;
        size.height = self.image.size.height / (self.image.size.width / size.width);
    }
    
    return size;
}

@end
