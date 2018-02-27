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

@interface GalleryImage : Image

@property (nonatomic, assign) CGFloat height;

@end

@implementation GalleryImage

- (UIViewContentMode)contentMode
{
    return UIViewContentModeScaleAspectFit;
}

- (CGSize)intrinsicContentSize
{
    CGSize size = [super intrinsicContentSize];
    
    if (self.image) {
        size.width = self.image.size.width / (self.image.size.height / self.height);
        size.height = self.height;
    }
    
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
        [self.leadingAnchor constraintEqualToAnchor:self.superview.leadingAnchor].active = YES;
        [self.trailingAnchor constraintEqualToAnchor:self.superview.trailingAnchor].active = YES;
        
        [self.heightAnchor constraintEqualToConstant:self.maxHeight + self.pageControl.bounds.size.height + 16.f].active = YES;
    }
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
    CGFloat width = self.bounds.size.width;
    
    // calculate the max height that fits the tallest image. The other images will use aspect-fit.
    for (Content *content in images) { @autoreleasepool {
        CGFloat height = content.size.height / (content.size.width / width);
        suggestedMaxHeight = ceil(MAX(suggestedMaxHeight, height));
    } }
    
    self.maxHeight = suggestedMaxHeight;
    
    weakify(self);
    
    [images enumerateObjectsUsingBlock:^(Content * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        strongify(self);
        
        // find the height for this image
        CGFloat imageHeight = ceil(obj.size.height * (self.scrollView.bounds.size.width / obj.size.width));
        CGFloat y = (suggestedMaxHeight - imageHeight) / 2.f;
        
        GalleryImage *image = [[GalleryImage alloc] initWithFrame:CGRectMake(idx * width, y, width, imageHeight)];
        image.URL = [NSURL URLWithString:obj.url];
        image.height = self.maxHeight;
        image.idx = idx;
        
        [self.scrollView addSubview:image];
        
        [self.imageRefs addPointer:(__bridge void * _Nullable)(image)];
        
    }];
    
    self.scrollView.contentSize = CGSizeMake(self.images.count * width, self.maxHeight);
    
    self.pageControl.numberOfPages = images.count;
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
    
    // adding the scrollView's height here triggers loading of the image as soon as it's about to appear on screen.
    point.x += scrollView.bounds.size.width;
    
    for (GalleryImage *imageview in self.imageRefs) { @autoreleasepool {
        
        CGRect frame = imageview.frame;
        frame.size.height = scrollView.bounds.size.height;
        frame.origin.y = 0.f;
        
        BOOL contains = CGRectContainsPoint(frame, point);
        // the first image may be out of bounds of the scrollView when it's loaded.
        // check if it's frame is contained within the frame of the scrollView.
        if (imageview.idx == 0)
            contains = contains || CGRectContainsRect(scrollView.frame, imageview.frame);
        
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
