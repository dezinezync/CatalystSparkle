//
//  Image.m
//  Yeti
//
//  Created by Nikhil Nigade on 25/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Image.h"
#import "LayoutConstants.h"

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

//- (void)didMoveToSuperview
//{
//    [super didMoveToSuperview];
//
//    if (self.superview && ![self isKindOfClass:NSClassFromString(@"GalleryImage")]) {
//
//        self.leading = [self.leadingAnchor constraintEqualToAnchor:self.superview.leadingAnchor constant:LayoutImageMargin];
//        self.leading.priority = UILayoutPriorityRequired;
//        self.leading.active = YES;
//
//        self.trailing = [self.trailingAnchor constraintEqualToAnchor:self.superview.trailingAnchor constant:0.f];
//        self.trailing.priority = UILayoutPriorityRequired;
//        self.trailing.active = YES;
//
//    }
//}

- (void)setImage:(UIImage *)image
{
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
        return;
    }
    
    [super setImage:image];
    
    self.backgroundColor = UIColor.whiteColor;
    
    if ([self isKindOfClass:NSClassFromString(@"GalleryImage")])
        return;
    
    weakify(self);
    
    // this no longer applies and we need to contraint the imageview to the maximum width of the image.
//    if (image.size.width < self.bounds.size.width) {
//        self.leading.active = NO;
//        self.trailing.active = NO;
//
//        self.leading = nil;
//        self.trailing = nil;
//
//        [self.widthAnchor constraintEqualToConstant:image.size.width];
//    }
    
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
    self.aspectRatio.priority = 999;
    
    [self addConstraint:self.aspectRatio];
    
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];

    if (self.image) {
        size.width = MIN(self.bounds.size.width, self.image.size.width);
        size.height = ceilf(self.image.size.height / (self.image.size.width / size.width));
    }

    return size;
}

@end
