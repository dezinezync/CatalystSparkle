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

#import <DZKit/AlertManager.h>

#import "UIImage+Sizing.h"
#import "YetiConstants.h"

#import "NSString+ImageProxy.h"

#import <DZAppdelegate/UIApplication+KeyWindow.h>

#if TARGET_OS_MACCATALYST
#import "SceneDelegate.h"
#endif

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
        
        self.backgroundColor = UIColor.secondarySystemBackgroundColor;
        
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.layoutMargins = UIEdgeInsetsZero;
    }
    
    return self;
}

#pragma mark - Image

- (void)_setupImage {
    
    SizedImage *imageView = [[SizedImage alloc] initWithFrame:self.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.backgroundColor =  UIColor.secondarySystemBackgroundColor;
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
    
    SizedAnimatedImage *imageView = [[SizedAnimatedImage alloc] initWithFrame:self.bounds];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    imageView.backgroundColor = UIColor.secondarySystemBackgroundColor;
    
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

- (void)setImageWithURL:(id)url {
    
    BOOL isGIF = NO;
    
    if ([url isKindOfClass:NSString.class]) {
        
        isGIF = [(NSString *)url containsString:@".gif"];
        
        url = [NSURL URLWithString:url];
        
    }
    else if ([url isKindOfClass:NSURL.class]) {
        
        isGIF = [[(NSURL *)url absoluteString] containsString:@".gif"];
        
    }
    
    if (!url)
       return;
    
    weakify(self);
    
    if (isGIF) {
        
        runOnMainQueueWithoutDeadlocking(^{
            strongify(self);
            [self _setupAnimatedImage];
        });
        
        self.URL = url;
        [self setupGIFLoadingControl];
        
    }
    else {
        
        runOnMainQueueWithoutDeadlocking(^{
            
            [self _setupImage];
            
//            CGFloat width = self.imageView.bounds.size.width;
            
            [self.imageView sd_setImageWithURL:url placeholderImage:nil options:SDWebImageScaleDownLargeImages|SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                
                self.imageView.backgroundColor = UIColor.systemBackgroundColor;
                
                if (error == nil) {
                
                    [self addContextMenus];
                    
                }
                else if (SharedPrefs.imageProxy == YES) {
                    
                    NSURL * base = [[url absoluteString] urlFromProxyURI];
                    
                    if (base != nil) {
                        
                        // try the direct URL
                        [self.imageView sd_setImageWithURL:base placeholderImage:[UIImage systemImageNamed:@"rectangle.on.rectangle.angled"] options:SDWebImageScaleDownLargeImages|SDWebImageRetryFailed completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
                            
                            if (error != nil) {
                                
                                return;
                            }
                            
                        }];
                        
                    }
                    
                }
                
            }];
            
        });
        
    }
}

- (void)cancelImageLoading {
    
    [self.imageView sd_cancelCurrentImageLoad];
    
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
        
        runOnMainQueueWithoutDeadlocking(^{
            strongify(self);
            
            [self setupGIFLoadingControl];
        });
        
        return;
    }
    
    UIButton *gifButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    gifButton.translatesAutoresizingMaskIntoConstraints = NO;
    
#if !TARGET_OS_MACCATALYST
    gifButton.backgroundColor = UIColor.secondarySystemFillColor;
#endif
    
    gifButton.layer.cornerRadius = 3.f;
    
#if !TARGET_OS_MACCATALYST
    [gifButton setTitle:@"  Tap to load" forState:UIControlStateNormal];
    [gifButton setTitle:@"  Loading..." forState:UIControlStateDisabled];
#endif
    
#if TARGET_OS_MACCATALYST
    [gifButton setTitle:@"Tap to load" forState:UIControlStateNormal];
#endif
    
    gifButton.titleLabel.font = [UIFont systemFontOfSize:13.f];
    
    [gifButton setImage:[UIImage systemImageNamed:@"circle.dashed.inset.fill"] forState:UIControlStateNormal];
    [gifButton sizeToFit];
    
#if !TARGET_OS_MACCATALYST
    [gifButton.widthAnchor constraintEqualToConstant:gifButton.bounds.size.width + 16.f].active = YES;
    [gifButton.heightAnchor constraintEqualToConstant:gifButton.bounds.size.height + 8.f].active = YES;
#endif
    
    [self addSubview:gifButton];
    
    [gifButton.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0.f].active = YES;
    
    if (UIApplication.keyWindow.traitCollection.layoutDirection == UITraitEnvironmentLayoutDirectionRightToLeft) {
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
#if !TARGET_OS_MACCATALYST
    startStopButton.backgroundColor = UIColor.secondarySystemFillColor;
    startStopButton.layer.cornerRadius = 3.f;
#endif
    
    [startStopButton setImage:[UIImage systemImageNamed:@"pause.rectangle.fill"] forState:UIControlStateNormal];
    [startStopButton sizeToFit];
    
    [startStopButton.widthAnchor constraintEqualToConstant:startStopButton.bounds.size.width + 16.f].active = YES;
    [startStopButton.heightAnchor constraintEqualToConstant:startStopButton.bounds.size.height + 8.f].active = YES;
    
    [self addSubview:startStopButton];
    [startStopButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-8.f].active = YES;
    
    if (UIApplication.keyWindow.traitCollection.layoutDirection == UITraitEnvironmentLayoutDirectionRightToLeft) {
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
    
#if TARGET_OS_MACCATALYST
    [sender setTitle:@"Loading..." forState:UIControlStateNormal];
#endif
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        NSError *error = nil;
        
        NSData *data = [[NSData alloc] initWithContentsOfURL:self.URL options:kNilOptions error:&error];
        
        if (error != nil || data == nil || data.length == 0) {
            
            NSLog(@"Error: loading GIF from: %@\n%@", self.URL, error);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [sender setTitle:@"  Failed. Tap to retry." forState:UIControlStateNormal];
            });
            
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [sender removeFromSuperview];
            
            SDAnimatedImage *image = [[SDAnimatedImage alloc] initWithData:data];
            
            SizedAnimatedImage *imageView = (SizedAnimatedImage *)[self imageView];
            
            imageView.image = image;
            imageView.clearBufferWhenStopped = YES;
            imageView.autoPlayAnimatedImage = NO;
            
            [self setupAnimationControls];
            
        });
        
    });
    
}

- (void)didTapStartStop:(UIButton *)sender {
    
    runOnMainQueueWithoutDeadlocking(^{
        
        if (self.isAnimating) {
            [self.imageView stopAnimating];
            [sender setImage:[UIImage systemImageNamed:@"play.rectangle.fill"] forState:UIControlStateNormal];
        }
        else {
            [self.imageView startAnimating];
            [sender setImage:[UIImage systemImageNamed:@"pause.rectangle.fill"] forState:UIControlStateNormal];
        }
        
    });
    
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
        
#if TARGET_OS_MACCATALYST
        [self saveImageToDisk];
#else
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImageWriteToSavedPhotosAlbum(self.imageView.image, nil, nil, nil);
        });
#endif
        
    }]];
    
    NSString *menuTitle = @"Image Actions";
    
    UIMenu *menu = [UIMenu menuWithTitle:menuTitle children:actions];
    
    return menu;
    
}

#if TARGET_OS_MACCATALYST
#pragma mark - Mac Image Export

- (void)saveImageToDisk {
    
    UIImage *image = self.imageView.image;
    
    if (image == nil) {
        return;
    }
    
    NSURL *url = self.URL;
    
    if ([url.absoluteString containsString:@"weserv.nl"]) {
        url = [self.URL.absoluteString urlFromProxyURI];
    }
    
    NSString *filename = [url lastPathComponent];
    NSString *fileExtension = [[url pathExtension] lowercaseString];
    
    NSLog(@"Preparing image to store to disk: %@, of type: %@", filename, fileExtension);
    
    NSData *data = nil;
    
    if ([fileExtension isEqualToString:@"png"]) {
        
        data = UIImagePNGRepresentation(image);
        
    }
    else {
        
        data = UIImageJPEGRepresentation(image, 1.f);
        
    }
    
    if (data == nil || data.length == 0) {
        NSLog(@"No image data formed for image type: %@", fileExtension);
        return;
    }
    
    NSURL *tempURL = [[NSFileManager.defaultManager temporaryDirectory] URLByAppendingPathComponent:filename];
    
    [data writeToURL:tempURL atomically:YES];
    
    UIDocumentPickerViewController *controller = [[UIDocumentPickerViewController alloc] initForExportingURLs:@[tempURL]];
    controller.delegate = (id<UIDocumentPickerDelegate>)self;
    
    SceneDelegate *delegate = (SceneDelegate *)(UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate);
    
    [delegate.coordinator.splitViewController presentViewController:controller animated:YES completion:nil];
    
}

#pragma mark - <UIDocumentPickerViewController>

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    
    NSURL *url = self.URL;
    
    if ([url.absoluteString containsString:@"weserv.nl"]) {
        url = [self.URL.absoluteString urlFromProxyURI];
    }
    
    NSString *filename = [url lastPathComponent];
    NSURL *tempURL = [[NSFileManager.defaultManager temporaryDirectory] URLByAppendingPathComponent:filename];
    
    NSError *error = nil;
    
    if ([NSFileManager.defaultManager removeItemAtURL:tempURL error:&error] == NO) {
        
        NSLog(@"Error: Failed to remove temp image file: %@", error.localizedDescription);
        
    }
    
}

#endif

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
        
        [super setImage:image];
        
    }
    
    if ([self isKindOfClass:NSClassFromString(@"GalleryImage")])
        return;
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
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
    
    if (image.size.width < self.bounds.size.width) {
        return;
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

- (void)setAnimatedImage:(SDAnimatedImage *)animatedImage {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setAnimatedImage:) withObject:animatedImage waitUntilDone:NO];
        return;
    }
    
    [super setImage:animatedImage];
    self.animationRepeatCount = 0;
}

@end

