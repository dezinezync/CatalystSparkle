//
//  ImageViewerCell.m
//  Yeti
//
//  Created by Nikhil Nigade on 04/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "ImageViewerCell.h"

NSString *const kImageViewerCell = @"com.elytra.cell.imageViewer";

@interface ImageViewerCell () <UIScrollViewDelegate>

@property (nonatomic, assign) CGFloat maximumZoomScale;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;

@end

@implementation ImageViewerCell

+ (void)registerOn:(UICollectionView *)collectionView {
    
    if (collectionView == nil) {
        return;
    }
    
    [collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(ImageViewerCell.class) bundle:nil] forCellWithReuseIdentifier:kImageViewerCell];
    
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.scrollView.backgroundColor = UIColor.blackColor;
    self.imageView.backgroundColor = UIColor.blackColor;
    self.backgroundColor = UIColor.blackColor;
    
#if DEBUG_LAYOUT == 1
    self.scrollView.backgroundColor = UIColor.systemBackgroundColor;
    self.imageView.backgroundColor = UIColor.systemRedColor;
    self.backgroundColor = UIColor.systemBlueColor;
#endif
    
    self.maximumZoomScale = 1.f;
    self.scrollView.delegate = self;
    
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.bouncesZoom = YES;
    self.scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    
    [self setupGestureRecognizers];
    
    [self updateZoomScale];
    [self centerScrollViewContents];
}

- (void)prepareForReuse {
    
    [super prepareForReuse];
    
    if (self.task != nil) {
        [self.task cancel];
        self.task = nil;
    }
    
    self.viewController = nil;
    
    self.imageView.image = nil;
    
}

- (void)setFrame:(CGRect)frame {
    
    [super setFrame:frame];
    
    [self updateZoomScale];
    [self centerScrollViewContents];
    
}

- (void)setImage:(UIImage *)image {
    
    self.imageView.transform = CGAffineTransformIdentity;
    self.imageView.image = image;
    
    CGRect frame = CGRectMake(0, 0, image.size.width, image.size.height);
    self.imageView.frame = frame;
    
    self.scrollView.contentSize = image.size;
    
    [self updateZoomScale];
    [self centerScrollViewContents];
    
}

#pragma mark -

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    
    return self.imageView;
    
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    scrollView.panGestureRecognizer.enabled = YES;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    // There is a bug, especially prevalent on iPhone 6 Plus, that causes zooming to render all other gesture recognizers ineffective.
    // This bug is fixed by disabling the pan gesture recognizer of the scroll view when it is not needed.
    if (scrollView.zoomScale == scrollView.minimumZoomScale) {
        scrollView.panGestureRecognizer.enabled = NO;
    }
}

- (void)updateZoomScale {
    
    if (self.imageView.image) {
    
        CGRect scrollViewFrame = self.scrollView.bounds;
        
        CGFloat scaleWidth = scrollViewFrame.size.width / self.imageView.image.size.width;
        CGFloat scaleHeight = scrollViewFrame.size.height / self.imageView.image.size.height;
        CGFloat minScale = MIN(scaleWidth, scaleHeight);
        
        self.scrollView.minimumZoomScale = minScale;
        self.scrollView.maximumZoomScale = MAX(minScale, self.maximumZoomScale);
        
        self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
        
        // scrollView.panGestureRecognizer.enabled is on by default and enabled by
        // viewWillLayoutSubviews in the container controller so disable it here
        // to prevent an interference with the container controller's pan gesture.
        //
        // This is enabled in scrollViewWillBeginZooming so panning while zoomed-in
        // is unaffected.
        self.scrollView.panGestureRecognizer.enabled = NO;
    }
    
}

- (void)centerScrollViewContents {
    CGFloat horizontalInset = 0;
    CGFloat verticalInset = 0;
    
    if (self.scrollView.contentSize.width < CGRectGetWidth(self.bounds)) {
        horizontalInset = (CGRectGetWidth(self.bounds) - self.scrollView.contentSize.width) * 0.5;
    }
    
    if (self.scrollView.contentSize.height < CGRectGetHeight(self.bounds)) {
        verticalInset = (CGRectGetHeight(self.bounds) - self.scrollView.contentSize.height) * 0.5;
    }
    
    if (self.window.screen.scale < 2.0) {
        horizontalInset = floor(horizontalInset);
        verticalInset = floor(verticalInset);
    }
    
    // Use `contentInset` to center the contents in the scroll view. Reasoning explained here: http://petersteinberger.com/blog/2013/how-to-center-uiscrollview/
    self.scrollView.contentInset = UIEdgeInsetsMake(verticalInset, horizontalInset, verticalInset, horizontalInset);
}

#pragma mark - Gestures

- (void)setupGestureRecognizers {
    self.doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didDoubleTapWithGestureRecognizer:)];
    self.doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    
    [self.scrollView addGestureRecognizer:self.doubleTapGestureRecognizer];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    tap.delaysTouchesBegan = YES;
    [tap requireGestureRecognizerToFail:self.doubleTapGestureRecognizer];
    
    [self addGestureRecognizer:tap];
    
//    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressWithGestureRecognizer:)];
}

- (void)didDoubleTapWithGestureRecognizer:(UITapGestureRecognizer *)recognizer {
    
    CGPoint pointInView = [recognizer locationInView:self.imageView];
    
    CGFloat newZoomScale = self.maximumZoomScale;

    if (self.scrollView.zoomScale >= self.scrollView.maximumZoomScale
        || ABS(self.scrollView.zoomScale - self.scrollView.maximumZoomScale) <= 0.01) {
        newZoomScale = self.scrollView.minimumZoomScale;
    }
    
    CGSize scrollViewSize = self.scrollView.bounds.size;
    
    CGFloat width = scrollViewSize.width / newZoomScale;
    CGFloat height = scrollViewSize.height / newZoomScale;
    CGFloat originX = pointInView.x - (width / 2.0);
    CGFloat originY = pointInView.y - (height / 2.0);
    
    CGRect rectToZoomTo = CGRectMake(originX, originY, width, height);
    
    [self.scrollView zoomToRect:rectToZoomTo animated:YES];
}

- (void)didTap:(id)sender {
    
    BOOL show = ![self.viewController.navigationController isNavigationBarHidden];
    
    [self.viewController.navigationController setNavigationBarHidden:show animated:YES];
    [self.viewController setNeedsStatusBarAppearanceUpdate];
    
}


@end
