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

#import "UIImage+Sizing.h"
#import "YetiConstants.h"

@interface Image () <UIContextMenuInteractionDelegate>

@property (nonatomic, assign, getter=isAnimatable, readwrite) BOOL animatable;
@property (nonatomic, weak) UITapGestureRecognizer *tap;

- (void)addContextMenus API_AVAILABLE(ios(13.0));

- (UIMenu *)makeMenuForPoint:(CGPoint)location suggestions:suggestedActions API_AVAILABLE(ios(13.0));

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location API_AVAILABLE(ios(13.0));

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
    imageView.cacheImage = YES;
    imageView.cachedSuffix = @"-sized";
    
    if ([self.URL isKindOfClass:NSURL.class]) {
        imageView.baseURL = self.URL.absoluteString;
    }
    else if ([self.URL isKindOfClass:NSString.class]) {
        imageView.baseURL = (NSString *)[self URL];
    }
    
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

- (void)il_setImageWithURL:(id)url imageLoader:(ImageLoader *)imageLoader
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
            
            [self _setupImage];
            
            CGFloat width = self.imageView.bounds.size.width;
            
            [self.imageView il_setImageWithURL:url mutate:^UIImage * _Nonnull(UIImage * _Nonnull image) {
              
                image = [image fastScale:width quality:1.f imageData:nil];
                
                return image;
                
            } success:^(UIImage * _Nonnull image, NSURL * _Nonnull URL) {
                
                self.imageView.backgroundColor = [(YetiTheme *)[YTThemeKit theme] articleBackgroundColor];
                
                if (@available(iOS 13, *)) {
                    [self addContextMenus];
                }
                
            } error:nil imageLoader:imageLoader];
            
        });
    }
}

- (void)il_cancelImageLoading {
    [self.imageView il_cancelImageLoading];
}

#pragma mark -

- (void)setLink:(NSURL *)link {
    _link = link;
    
    if (link == nil && self.tap != nil) {
        [self removeGestureRecognizer:self.tap];
        self.tap = nil;
    }
    else if (link != nil && self.tap == nil) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapLink:)];
        tap.delaysTouchesBegan = YES;
        tap.numberOfTapsRequired = 1;
        
        [self addGestureRecognizer:tap];
        self.tap = tap;
    }
}

#pragma mark -

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
    
    // ensure it's always called on the Main Thread
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setupAnimationControls) withObject:nil waitUntilDone:NO];
        return;
    }
    
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

#pragma mark -

- (void)didTapGIF:(UIButton *)sender {
    
    if (!self.URL)
        return;
    
    if ([sender isKindOfClass:UIButton.class]) {
        [sender setEnabled:NO];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        NSError *error = nil;
        
        NSData *data = [[NSData alloc] initWithContentsOfURL:self.URL options:kNilOptions error:&error];
        
        if (error != nil || data == nil || data.length == 0) {
            
            DDLogError(@"Error loading GIF from: %@\n%@", self.URL, error);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setTitle:@"  Failed. Tap to retry." forState:UIControlStateNormal];
            });
            
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [sender removeFromSuperview];
        });
        
        FLAnimatedImage *image = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
        
        [(SizedAnimatedImage *)[self imageView] setAnimatedImage:image];
        
        [self setupAnimationControls];
        
    });
    
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

- (void)didTapLink:(UITapGestureRecognizer *)tap {
    
    NSURL *external = formattedURL(@"yeti://external?link=%@", self.link.absoluteString);
    
    [[UIApplication sharedApplication] openURL:external options:@{} completionHandler:nil];
    
}

#pragma mark - Context Menus

- (void)addContextMenus {
    
    UIContextMenuInteraction *interaction = [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [self addInteraction:interaction];
    
}

- (NSURL *)sanitizedImageURL {
    
    if (self.URL) {
        
        NSURLComponents *components = [NSURLComponents componentsWithURL:self.URL resolvingAgainstBaseURL:nil];
        
        NSArray *queryItems = components.queryItems;
        
        NSURL *url = nil;
        
        for (NSURLQueryItem *item in queryItems) {
            if ([item.name isEqualToString:@"url"]) {
                url = [NSURL URLWithString:item.value];
                break;
            }
        }
        
        return url;
        
    }
    
    return self.URL;
    
}

- (UIMenu *)makeMenuForPoint:(CGPoint)location suggestions:(NSArray <UIMenuElement *> *)suggestedActions {
    
    NSMutableArray <UIMenuElement *> *actions = [NSMutableArray new];
    
    [actions addObject:[UIAction actionWithTitle:@"Copy Image" image:[UIImage systemImageNamed:@"doc.on.doc"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
        [[UIPasteboard generalPasteboard] setImage:self.imageView.image];
        
    }]];
    
    [actions addObject:[UIAction actionWithTitle:@"Copy Image URL" image:[UIImage systemImageNamed:@"link"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
        [[UIPasteboard generalPasteboard] setURL:[self sanitizedImageURL]];
        
    }]];
    
    [actions addObject:[UIAction actionWithTitle:@"Share Image" image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
        UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[self.imageView.image] applicationActivities:nil];
        
        id delegate = [self.superview.superview valueForKeyPath:@"delegate"];
        
        if (delegate && [delegate isKindOfClass:UIViewController.class]) {
            [(UIViewController *)delegate presentViewController:avc animated:YES completion:nil];
        }
        
    }]];
    
    [actions addObject:[UIAction actionWithTitle:@"Share Image URL" image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
        UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[[self sanitizedImageURL]] applicationActivities:nil];
        
        id delegate = [self.superview.superview valueForKeyPath:@"delegate"];
        
        if (delegate && [delegate isKindOfClass:UIViewController.class]) {
            [(UIViewController *)delegate presentViewController:avc animated:YES completion:nil];
        }
        
    }]];
    
    [actions addObject:[UIAction actionWithTitle:@"Save Image" image:[UIImage systemImageNamed:@"square.and.arrow.down"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImageWriteToSavedPhotosAlbum(self.imageView.image, nil, nil, nil);
        });
        
    }]];
    
    NSString *menuTitle = @"Image Actions";
    
    UIMenu *menu = [UIMenu menuWithTitle:menuTitle children:actions];
    
    return menu;
    
}

#pragma mark - <UIContextMenuInteractionDelegate>

- (UIContextMenuConfiguration *)contextMenuInteraction:(UIContextMenuInteraction *)interaction configurationForMenuAtLocation:(CGPoint)location {
    
    UIContextMenuConfiguration *configuration = [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
       
        return [self makeMenuForPoint:location suggestions:suggestedActions];
        
    }];
    
    return configuration;
    
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
        if (image == nil) {
            [super setImage:image];
        }
        else {
            // we have an image. Check the base URL to see if it's a (super?)retina image
            if (self.baseURL != nil) {
                if ([self.baseURL containsString:@"-2x"] || [self.baseURL containsString:@"@2x"]
                    || [self.baseURL containsString:@"-3x"] || [self.baseURL containsString:@"@3x"]) {
                    UIImage *scaledImage = [UIImage imageWithCGImage:[image CGImage] scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
                    image = scaledImage;
                }
            }
            
            if (image.size.width < self.bounds.size.width) {
                self.contentMode = UIViewContentModeCenter;
            }
            
            if (self.cacheImage == NO) {
                [super setImage:image];
            }
            else {
                CGSize size = [self scaledSizeForImage:image];
                
                weakify(self);
                
                dispatch_async(SharedImageLoader.ioQueue, ^{
                    
                    strongify(self);
                    
                    UIImage * scaled = self.settingCached ? image : [image fastScale:size.width quality:1 imageData:nil];
                    
                    // cache the scaled image
                    if (self.baseURL != nil && self.settingCached == NO) {
                        NSString *key = [self.baseURL stringByAppendingString:(self.cachedSuffix ?: @"-sized")];
                        NSString *extension = [[self.baseURL pathExtension] lowercaseString];
                        NSData *data = nil;
                        
                        if ([extension isEqualToString:@"jpg"] || [extension isEqualToString:@"jpeg"]) {
                            data = UIImageJPEGRepresentation(scaled, 0.9);
                        }
                        else if ([extension isEqualToString:@"png"]) {
                            data = UIImagePNGRepresentation(image);
                        }
                        
                        [SharedImageLoader.cache setObject:scaled data:data forKey:key];
                    }
                    
                    if (self.settingCached == YES) {
                        self.settingCached = NO;
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [super setImage:scaled];
                    });
                    
                });
            }
        }
    }
    
    if ([self isKindOfClass:NSClassFromString(@"GalleryImage")])
        return;
    
    weakify(self);
    
    asyncMain(^{
        
        if (self == nil) {
            return;
        }
        
        strongify(self);
        [self invalidateIntrinsicContentSize];
        
        if (self.contentMode == UIViewContentModeScaleAspectFit) {
            [self updateAspectRatioWithImage:self.image];
        }
    });
    
}

- (void)updateAspectRatioWithImage:(UIImage *)image {
    if (!image)
        return;
    
    if (self.superview == nil || [self.superview respondsToSelector:@selector(aspectRatio)] == NO) {
        return;
    }
    
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
        size = [self scaledSizeForImage:self.image];
    }
    else {
        // resolve with the cached constraints to prevent the content
        // from jumping when the user scrolls the content
        CGRect frame = [[self layoutMarginsGuide] layoutFrame];
        size = frame.size;
        size.width += frame.origin.x * 2.f;
        size.height += frame.origin.y * 2.f;
    }
    
    return size;
}

- (CGSize)scaledSizeForImage:(UIImage *)image {
    CGSize size = image.size;
    if (size.width < self.bounds.size.width) {
        return size;
    }
    
    size.width = MIN(self.bounds.size.width, image.size.width);
    size.height = ceilf(image.size.height / (image.size.width / size.width));
    
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
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setAnimatedImage:) withObject:animatedImage waitUntilDone:NO];
        return;
    }
    
    [super setAnimatedImage:animatedImage];
    self.animationRepeatCount = 0;
}

@end

