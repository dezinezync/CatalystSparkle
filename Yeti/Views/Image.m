//
//  Image.m
//  Yeti
//
//  Created by Nikhil Nigade on 25/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Image.h"
#import "LayoutConstants.h"
#import "Paragraph.h"
#import "FeedsManager.h"

#import "YetiThemeKit.h"
#import <DZNetworking/UIImageView+ImageLoading.h>

#import <DZKit/AlertManager.h>
#import <FLAnimatedImage/FLAnimatedImage.h>

@interface Image ()

@property (nonatomic, assign, getter=isAnimatable, readwrite) BOOL animatable;

@end

@implementation Image

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitImage;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        self.backgroundColor = theme.cellColor;
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.layoutMargins = UIEdgeInsetsZero;
    }
    
    return self;
}

#pragma mark - Image

- (void)_setupImage {
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    SizedImage *imageView = [[SizedImage alloc] initWithFrame:self.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.backgroundColor = theme.borderColor;
    
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
}

- (void)_setupAnimatedImage {
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    SizedAnimatedImage *imageView = [[SizedAnimatedImage alloc] initWithFrame:self.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.backgroundColor = theme.borderColor;
    
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
    
    _imageView = (SizedImage *)imageView;
}

#pragma mark -

- (BOOL)isAnimating {
    
    if (!self.isAnimatable)
        return NO;
    
    return [self.imageView isAnimating];
}

- (void)il_setImageWithURL:(id)url
{
    BOOL isGIF = NO;
    
    if ([url isKindOfClass:NSString.class]) {
        isGIF = [(NSString *)url containsString:@".gif"];
    }
    else if ([url isKindOfClass:NSURL.class]) {
        isGIF = [[(NSURL *)url absoluteString] containsString:@".gif"];
    }
    
    weakify(self);
    
    if (!url)
       return;
    
    if (isGIF) {
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            [self _setupAnimatedImage];
        });
        
        self.URL = url;
        [self setupGIFLoadingControl];
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            [self _setupImage];
            [self.imageView il_setImageWithURL:url];
        });
    }
}

- (CGSize)intrinsicContentSize
{
    return self.imageView.intrinsicContentSize;
}

- (void)setupGIFLoadingControl {
    
    if (!NSThread.isMainThread) {
        weakify(self);
        asyncMain(^{
            strongify(self);
            
            [self setupGIFLoadingControl];
        });
        
        return;
    }
    
    UIButton *gifButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    gifButton.translatesAutoresizingMaskIntoConstraints = NO;
    gifButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    gifButton.layer.cornerRadius = 3.f;
    [gifButton setTitle:@"  Tap to load" forState:UIControlStateNormal];
    [gifButton setTitle:@"  Loading..." forState:UIControlStateDisabled];
    gifButton.titleLabel.font = [UIFont systemFontOfSize:13.f];
    
    [gifButton setImage:[[UIImage imageNamed:@"gif"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [gifButton sizeToFit];
    
    [gifButton.widthAnchor constraintEqualToConstant:gifButton.bounds.size.width + 16.f].active = YES;
    [gifButton.heightAnchor constraintEqualToConstant:gifButton.bounds.size.height + 8.f].active = YES;
    
    [self addSubview:gifButton];
    [gifButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0.f].active = YES;
    
    if (UIApplication.sharedApplication.keyWindow.traitCollection.layoutDirection == UITraitEnvironmentLayoutDirectionRightToLeft) {
        [gifButton.leadingAnchor constraintEqualToAnchor:self.trailingAnchor constant:8.f].active = YES;
    }
    else {
        [gifButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.f].active = YES;
    }
    
    [gifButton addTarget:self action:@selector(didTapGIF:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupAnimationControls {
    // ensure this gets called only once.
    if (self.isAnimatable)
        return;
    
    self.animatable = YES;
    
    UIButton *startStopButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    startStopButton.translatesAutoresizingMaskIntoConstraints = NO;
    startStopButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    startStopButton.layer.cornerRadius = 3.f;
    
    [startStopButton setImage:[[UIImage imageNamed:@"gif_pause"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [startStopButton sizeToFit];
    
    [startStopButton.widthAnchor constraintEqualToConstant:startStopButton.bounds.size.width + 16.f].active = YES;
    [startStopButton.heightAnchor constraintEqualToConstant:startStopButton.bounds.size.height + 8.f].active = YES;
    
    [self addSubview:startStopButton];
    [startStopButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8.f].active = YES;
    
    if (UIApplication.sharedApplication.keyWindow.traitCollection.layoutDirection == UITraitEnvironmentLayoutDirectionRightToLeft) {
        [startStopButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:0.f].active = YES;
    }
    else {
        [startStopButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:0.f].active = YES;
    }
    
    [startStopButton addTarget:self action:@selector(didTapStartStop:) forControlEvents:UIControlEventTouchUpInside];
    
    _startStopButton = startStopButton;
    
}

- (void)didTapGIF:(UIButton *)sender {
    
    if (!self.URL)
        return;
    
    if ([sender isKindOfClass:UIButton.class]) {
        [sender setEnabled:NO];
    }
    
    [MyFeedsManager.gifSession GET:self.URL.absoluteString parameters:@{} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [sender removeFromSuperview];
        });

        FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:responseObject];
        
        [(SizedAnimatedImage *)[self imageView] setAnimatedImage:image];
        
        [self setupAnimationControls];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [sender setTitle:@"  Failed. Tap to retry." forState:UIControlStateNormal];
        });
        
    }];
    
}

- (void)didTapStartStop:(UIButton *)sender {
    
    if ([NSThread isMainThread] == NO) {
        weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            [self didTapStartStop:sender];
        });
    }
    
    if (self.isAnimating) {
        [self.imageView stopAnimating];
        [sender setImage:[[UIImage imageNamed:@"gif_play"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    }
    else {
        [self.imageView startAnimating];
        [sender setImage:[[UIImage imageNamed:@"gif_pause"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    }
    
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
    
    if (image.images && image.images.count && self.superview && [self.superview isKindOfClass:Image.class]) {
        super.image = image.images.lastObject;
        self.animationImages = image.images;
        self.animationDuration = [[image valueForKey:@"_duration"] doubleValue];
        self.animationRepeatCount = 0;
        
        [(Image *)self.superview setupAnimationControls];
    }
    else {
        [super setImage:image];
    }
    
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

@implementation SizedAnimatedImage

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

- (void)setAnimatedImage:(FLAnimatedImage *)animatedImage {
    [super setAnimatedImage:animatedImage];
    self.animationRepeatCount = 0;
}

@end

