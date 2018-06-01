//
//  Image.m
//  Yeti
//
//  Created by Nikhil Nigade on 25/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Image.h"
#import "LayoutConstants.h"

#import "YetiThemeKit.h"

@interface Image ()

@end

@implementation Image

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        self.backgroundColor = theme.backgroundColor;
        
        SizedImage *imageView = [[SizedImage alloc] initWithFrame:self.bounds];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.translatesAutoresizingMaskIntoConstraints = NO;
        imageView.backgroundColor = theme.cellColor;
        
        [self addSubview:imageView];
        
        [imageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0].active = YES;
        [imageView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0].active = YES;
        [imageView setContentCompressionResistancePriority:1000 forAxis:UILayoutConstraintAxisVertical];
        
        if (![self isKindOfClass:NSClassFromString(@"GalleryImage")]) {
            [imageView.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:LayoutImageMargin*2].active = YES;
            [imageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:-LayoutPadding-2.f].active = YES;
        }
        else {
            [imageView.widthAnchor constraintEqualToAnchor:self.widthAnchor constant:0.f].active = YES;
        }
        
        _imageView = imageView;
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.layoutMargins = UIEdgeInsetsZero;
    }
    
    return self;
}

#pragma mark -

- (void)il_setImageWithURL:(id)url
{
    [self.imageView performSelector:@selector(il_setImageWithURL:) withObject:url];
}

- (CGSize)intrinsicContentSize
{
    return self.imageView.intrinsicContentSize;
}

@end

@implementation SizedImage

- (void)setImage:(UIImage *)image
{
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
        return;
    }
    
    if ([image isKindOfClass:NSData.class]) {
        image = [UIImage imageWithData:(NSData *)image];
    }
    
    [super setImage:image];
    
    if ([self isKindOfClass:NSClassFromString(@"GalleryImage")])
        return;
    
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
    if (!image)
        return;
    
    NSLayoutConstraint *aspectRatio = [(Image *)[self superview] aspectRatio];
    
    if (aspectRatio) {
        [self removeConstraint:aspectRatio];
    }
    
    CGFloat aspectRatioValue = image.size.height / image.size.width;
    aspectRatio = [self.heightAnchor constraintEqualToConstant:aspectRatioValue * self.bounds.size.width];
    aspectRatio.priority = 999;
    
    [(Image *)[self superview] setAspectRatio:aspectRatio];
    
    [self.superview addConstraint:aspectRatio];
    
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

