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

@interface Gallery () <UICollectionViewDelegate, UICollectionViewDataSource> {
    // if the gallery is unbounded, this means there was no height information present
    // in the images. So we keep it unbounded and reconfig ourseleves based on the
    // first successful image load.
    BOOL _unbounded;
}

@property (nonatomic, assign) CGFloat maxHeight;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@property (nonatomic, strong) NSPointerArray *imageRefs;

@end

@implementation Gallery

- (instancetype)initWithNib
{
    if (self = [super initWithNib]) {
        
        self.backgroundColor = UIColor.whiteColor;
        self.imageRefs = [NSPointerArray weakObjectsPointerArray];
        
        self.collectionView.contentInset = UIEdgeInsetsZero;
        self.collectionView.layoutMargins = UIEdgeInsetsZero;
        [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(GalleryCell.class) bundle:nil] forCellWithReuseIdentifier:kGalleryCell];
        self.collectionView.dataSource = self;
        self.collectionView.delegate = self;
        
        [self.pageControl addTarget:self action:@selector(didChangePage:) forControlEvents:UIControlEventValueChanged];
        
#if DEBUG_LAYOUT == 1
        self.collectionView.backgroundColor = UIColor.cyanColor;
        self.collectionView.backgroundColor = UIColor.purpleColor;
#endif
    }
    
    return self;
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        [self setImages:self.images];
    });
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
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            strongify(self);
//            [self scrollViewDidScroll:self.collectionView];
//        });
    }
}

- (void)setImages:(NSArray<Content *> *)images
{
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
    
    self.maxHeight = suggestedMaxHeight;
    
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
    
    self.pageControl.numberOfPages = images.count;
    
    weakify(self);
    
//    asyncMain(^{
//        strongify(self);
//        [self setNeedsUpdateConstraints];
//        [self layoutIfNeeded];
//    });
    
    asyncMain(^{
        strongify(self);
        [self.collectionView reloadData];
    });
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

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.images ? self.images.count : 0;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    GalleryCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kGalleryCell forIndexPath:indexPath];
    
    Content *content = [self.images objectAtIndex:indexPath.row];
    
    NSString *url = [content urlCompliantWithUsersPreferenceForWidth:collectionView.bounds.size.width];
    
    weakify(self);
    
    [cell.imageView il_setImageWithURL:[NSURL URLWithString:url] success:^(UIImage * _Nonnull image, NSURL * _Nonnull URL) {
        
        strongify(self);
        
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
    self.pageControl.currentPage = ceil(point.x / scrollView.bounds.size.width);
    
}

@end
