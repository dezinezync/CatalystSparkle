//
//  Gallery.m
//  Yeti
//
//  Created by Nikhil Nigade on 22/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "Gallery.h"
#import "Image.h"
#import <DZNetworking/UIImageView+ImageLoading.h>
#import "LayoutConstants.h"

@interface GalleryImage : Image

@property (nonatomic, assign) CGFloat height;

@end

@implementation GalleryImage

- (UIViewContentMode)contentMode
{
    return UIViewContentModeScaleAspectFit|UIViewContentModeCenter;
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];
    
//    if (self.image) {
        size.width = floor(self.superview.bounds.size.width);//self.image.size.width / (self.image.size.height / self.height);
        size.height = self.height;
//    }
    
    return size;
}

@end

@interface Gallery () <UIScrollViewDelegate>

@property (nonatomic, assign) CGFloat maxHeight;

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@property (nonatomic, strong) NSPointerArray *imageRefs;

@end

@implementation Gallery

- (instancetype)initWithNib
{
    if (self = [super initWithNib]) {
        self.scrollView.backgroundColor = UIColor.whiteColor;
        self.scrollView.delegate = self;
//        self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        
        self.backgroundColor = UIColor.whiteColor;
        self.imageRefs = [NSPointerArray weakObjectsPointerArray];
        
        [self.pageControl addTarget:self action:@selector(didChangePage:) forControlEvents:UIControlEventValueChanged];
    }
    
    return self;
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    if (self.superview) {
        [self.leadingAnchor constraintEqualToAnchor:self.superview.leadingAnchor constant:LayoutImageMargin].active = YES;
        [self.trailingAnchor constraintEqualToAnchor:self.superview.trailingAnchor].active = YES;
    }
}

- (void)updateConstraints
{
    [super updateConstraints];

    [self.scrollView setNeedsUpdateConstraints];
    [self.scrollView layoutIfNeeded];
    
    CGFloat width = ceil(self.scrollView.bounds.size.width);
    
    [self.scrollView.subviews enumerateObjectsUsingBlock:^(__kindof GalleryImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
       
        CGFloat leadingConstant = idx * width; // toward's leading edge
        
        if (image.leading) {
            [image removeConstraint:image.leading];
        }
        
        image.leading = [image.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:leadingConstant];
        image.leading.priority = UILayoutPriorityRequired;
        image.leading.identifier = @"GalleryImage:Leading";
        image.leading.active = YES;
        
    }];
}

#pragma mark -

- (void)setLoading:(BOOL)loading
{
    // once loading is enabled, it shouldn't be disabled.
    // the class further manages loading states of it's own child nodes
    // and it may interfere with that.
    if (_loading)
        return;
    
    _loading = loading;
    
    if (_loading) {
        
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            [self setNeedsLayout];
        })
        
        // we use a smaller timeout here since this can be the first item or comes in later.
        // it get's it initial message from it's VC.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            strongify(self);
            [self scrollViewDidScroll:self.scrollView];
        });
    }
}

- (void)setImages:(NSArray<Content *> *)images
{
    _images = images;
    
    if (!_images)
        return;
    
    CGFloat suggestedMaxHeight = 0.f;
    CGFloat width = floor(self.bounds.size.width);
    
    // calculate the max height that fits the tallest image. The other images will use aspect-fit.
    for (Content *content in images) { @autoreleasepool {
        
        CGSize size = content.size;
        if ([content.attributes valueForKey:@"data-orig-size"]) {
            NSArray <NSString *> *comps = [content.attributes[@"data-orig-size"] componentsSeparatedByString:@","];
            size = CGSizeMake(comps[0].floatValue, comps[1].floatValue);
        }
        
        CGFloat height = width * (size.height / size.width);
        suggestedMaxHeight = ceil(MAX(suggestedMaxHeight, height));
    } }
    
    self.maxHeight = suggestedMaxHeight;
    [self.heightAnchor constraintEqualToConstant:self.maxHeight + self.pageControl.bounds.size.height + LayoutPadding].active = YES;
    
    weakify(self);
    
    [images enumerateObjectsUsingBlock:^(Content * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        strongify(self);
        
        CGSize size = obj.size;
        if ([obj.attributes valueForKey:@"data-orig-size"]) {
            NSArray <NSString *> *comps = [obj.attributes[@"data-orig-size"] componentsSeparatedByString:@","];
            size = CGSizeMake(comps[0].floatValue, comps[1].floatValue);
        }
        
        // find the height for this image
        CGFloat imageHeight = ceil(size.height * (self.scrollView.bounds.size.width / size.width));
        CGFloat y = floor((suggestedMaxHeight - imageHeight) / 2.f);
        
        GalleryImage *image = [[GalleryImage alloc] initWithFrame:CGRectIntegral(CGRectMake(idx * width, y, width, imageHeight))];
        image.autoUpdateFrameOrConstraints = NO;
//        image.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        NSString *url = obj.url;
        
        if ([obj.attributes valueForKey:@"data-large-file"]) {
            url = [obj.attributes valueForKey:@"data-large-file"];
        }
        
        image.URL = [NSURL URLWithString:url];
        image.height = self.maxHeight;
        image.idx = idx;
        
        [self.scrollView addSubview:image];
        
        [image.centerYAnchor constraintEqualToAnchor:self.scrollView.centerYAnchor].active = YES;
        
        CGFloat leadingConstant = idx * width; // toward's leading edge
        image.leading = [image.leadingAnchor constraintEqualToAnchor:self.scrollView.leadingAnchor constant:leadingConstant];
        image.leading.priority = UILayoutPriorityRequired;
        image.leading.identifier = @"GalleryImage:Leading";
        image.leading.active = YES;
        
        [self.imageRefs addPointer:(__bridge void * _Nullable)(image)];
        
    }];
    
    self.scrollView.contentSize = CGSizeMake(self.images.count * width, self.maxHeight);
    
    self.pageControl.numberOfPages = images.count;
    
    [self setNeedsUpdateConstraints];
    [self layoutIfNeeded];
}

#pragma mark - Events

- (void)didChangePage:(UIPageControl *)sender {
    [self.scrollView setContentOffset:CGPointMake(sender.currentPage * self.scrollView.bounds.size.width, 0.f) animated:YES];
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint point = scrollView.contentOffset;
    
    // update page control
    self.pageControl.currentPage = ceil(point.x / scrollView.bounds.size.width);
    
    // adding the scrollView's width here triggers loading of the image as soon as it's about to appear on screen.
    point.x += scrollView.bounds.size.width;
    
    CGRect visibleRect;
    visibleRect.origin = scrollView.contentOffset;
    visibleRect.size = scrollView.frame.size;
    
    for (GalleryImage *imageview in self.imageRefs) { @autoreleasepool {
        
        CGRect frame = imageview.frame;
        frame.size.height = scrollView.bounds.size.height;
        frame.origin.y = 0.f;
        
        if (frame.size.width <= 0)
            frame.size.width = self.scrollView.bounds.size.width;
        
        BOOL contains = CGRectContainsPoint(frame, point);
        // the first image may be out of bounds of the scrollView when it's loaded.
        // check if it's frame is contained within the frame of the scrollView.
        if (imageview.idx == 0) {
            contains = contains || CGRectContainsRect(visibleRect, frame);
        }
        
//        DDLogDebug(@"Frame:%@, contains: %@", NSStringFromCGRect(imageview.frame), @(contains));
        
        if (!imageview.image && contains && !imageview.isLoading) {
            DDLogDebug(@"Point: %@ Loading image: %@", NSStringFromCGPoint(point), imageview.URL);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                imageview.loading = YES;
                [imageview il_setImageWithURL:imageview.URL];
            });
        }
    } }
    
}


@end
