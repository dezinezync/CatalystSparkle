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
#import "GalleryCell.h"

#import "YetiThemeKit.h"

@interface GalleryImage : Image

@property (nonatomic, assign) CGFloat height;

@end

@implementation GalleryImage

- (UIViewContentMode)contentMode {
    return UIViewContentModeScaleAspectFit|UIViewContentModeCenter;
}

- (CGSize)intrinsicContentSize {
    CGSize size = [super intrinsicContentSize];
    
    size.width = floor(self.superview.bounds.size.width);
    size.height = self.height;
    
    return size;
}

@end

@interface Gallery () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching> {
    // if the gallery is unbounded, this means there was no height information present
    // in the images. So we keep it unbounded and reconfig ourseleves based on the
    // first successful image load.
    BOOL _unbounded;
    
    NSInteger _compoundedPaging;
}

@property (nonatomic, assign) CGFloat maxHeight;

@property (nonatomic, strong) NSPointerArray *imageRefs;

@end

@implementation Gallery

- (instancetype)initWithNib {
    if (self = [super initWithNib]) {
        
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        self.backgroundColor = theme.articleBackgroundColor;
        self.imageRefs = [NSPointerArray weakObjectsPointerArray];
        
        self.collectionView.contentInset = UIEdgeInsetsZero;
        self.collectionView.layoutMargins = UIEdgeInsetsZero;
        [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(GalleryCell.class) bundle:nil] forCellWithReuseIdentifier:kGalleryCell];
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        self.collectionView.backgroundColor = theme.articleBackgroundColor;
        
        self.collectionView.prefetchDataSource = self;
        self.collectionView.prefetchingEnabled = YES;
        
        [self.pageControl addTarget:self action:@selector(didChangePage:) forControlEvents:UIControlEventValueChanged];
        self.pageControl.currentPageIndicatorTintColor = theme.tintColor;
        self.pageControl.pageIndicatorTintColor = theme.captionColor;
        
#if DEBUG_LAYOUT == 1
        self.collectionView.backgroundColor = UIColor.purpleColor;
#endif
    }
    
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        [self setImages:self.images];
    });
}

#pragma mark -

- (void)setLoading:(BOOL)loading {
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
        });
    }
}

- (void)setImages:(NSArray<Content *> *)images {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setImages:) withObject:images waitUntilDone:NO];
        return;
    }
    
    _images = images;
    
    if (!_images)
        return;
    
    [self.collectionView setNeedsUpdateConstraints];
    [self.collectionView layoutIfNeeded];
    
    CGFloat suggestedMaxHeight = 0.f;
    CGFloat width = floor(self.collectionView.bounds.size.width);
    
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
    
    if (self.maxScreenHeight == 0) {
        self.maxScreenHeight = suggestedMaxHeight;
    }
    
    self.maxHeight = MIN(self.maxScreenHeight, suggestedMaxHeight);
    
    if (self.maxHeight > 0.f) {
        [self setupHeight];
    }
    else {
        if (self.heightC) {
            [self removeConstraint:self.heightC];
        }
        
        self.heightC = [self.heightAnchor constraintEqualToConstant:self.bounds.size.height + self.pageControl.bounds.size.height + LayoutPadding];
        self.heightC.priority = 999;
        self.heightC.identifier = @"GalleryHeightTemp";
        self.heightC.active = YES;
        
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)[self.collectionView collectionViewLayout];
        layout.itemSize = CGSizeMake(width, self.heightC.constant);
        
        _unbounded = YES;
    }
    
    if (([self.pageControl sizeForNumberOfPages:images.count].width - LayoutPadding) > width) {
        _compoundedPaging = 5;
        self.pageControl.numberOfPages = floor(images.count / _compoundedPaging);
    }
    else {
        self.pageControl.numberOfPages = images.count;
    }
    
    [self.collectionView setNeedsUpdateConstraints];
    [self.collectionView layoutIfNeeded];
    
    [self.collectionView reloadData];
}

- (void)setupHeight {
    
    if (_unbounded) {
        _unbounded = NO;
    }
    
    CGFloat width = floor(self.collectionView.bounds.size.width);
    
    if (self.heightC) {
        [self removeConstraint:self.heightC];
    }
    
    self.heightC = [self.heightAnchor constraintEqualToConstant:self.maxHeight + self.pageControl.bounds.size.height + LayoutPadding];
    self.heightC.priority = 1000;
    self.heightC.identifier = @"GalleryHeight";
    self.heightC.active = YES;
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)[self.collectionView collectionViewLayout];
    layout.itemSize = CGSizeMake(width, self.maxHeight);
}

#pragma mark - Events

- (void)didChangePage:(UIPageControl *)sender {
    [self.collectionView setContentOffset:CGPointMake(sender.currentPage * self.collectionView.bounds.size.width, 0.f) animated:YES];
}

#pragma mark - <UICollectionViewDatasource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.images ? self.images.count : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    GalleryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kGalleryCell forIndexPath:indexPath];
    cell.backgroundColor = theme.unreadBadgeColor;
    
    Content *content = [self.images objectAtIndex:indexPath.item];
    
    NSString *url = [content urlCompliantWithUsersPreferenceForWidth:collectionView.bounds.size.width];
    
    weakify(self);
    
    [cell.imageView il_setImageWithURL:[NSURL URLWithString:url] success:^(UIImage * _Nonnull image, NSURL * _Nonnull URL) {
        
        strongify(self);
        
        if (!self)
            return;

        cell.backgroundColor = theme.articleBackgroundColor;
        
        if (!self->_unbounded)
            return;
        
        if (image) {
            asyncMain(^{
                CGFloat width = floor(self.collectionView.bounds.size.width);
                
                CGSize size = image.size;
                
                CGFloat height = width * (size.height / size.width);
                CGFloat suggestedMaxHeight = ceil(height);
                
                self.maxHeight = suggestedMaxHeight;
                
                [self setupHeight];
            });
        }
        
    } error:nil];
    
    return cell;
    
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint point = scrollView.contentOffset;
    
    // update page control
    if (_compoundedPaging) {
        self.pageControl.currentPage = floor(ceil(point.x / scrollView.bounds.size.width) / _compoundedPaging);
    }
    else {
        self.pageControl.currentPage = ceil(point.x / scrollView.bounds.size.width);
    }
    
}

#pragma mark - <UICollectionViewDataSourcePrefetching>

- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    
    for (NSIndexPath *indexPath in indexPaths) {
        Content *content = [self.images objectAtIndex:indexPath.item];
        
        if (content.task == nil) {
            NSString *url = [content urlCompliantWithUsersPreferenceForWidth:collectionView.bounds.size.width];
            
            content.task = [SharedImageLoader downloadImageForURL:url success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
               
                content.task = nil;
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                content.task = nil;
                
            }];
        }
    }
    
}

- (void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    
    for (NSIndexPath *indexPath in indexPaths) {
        Content *content = [self.images objectAtIndex:indexPath.item];
        
        if (content.task != nil) {
            [content.task cancel];
            content.task = nil;
        }
    }
    
}

@end
