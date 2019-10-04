//
//  ImageViewerController.m
//  Yeti
//
//  Created by Nikhil Nigade on 04/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "ImageViewerController.h"
#import "ImageViewerCell.h"

#import "Image.h"
#import "Gallery.h"

#import <DZNetworking/ImageLoader.h>
#import <DZKit/NSArray+RZArrayCandy.h>

@interface ImageViewerController ()

+ (UICollectionViewLayout *)layout;

@property (nonatomic, strong) UICollectionViewDiffableDataSource *DS;

@property (nonatomic, strong) NSArray <Content *> *images;

@property (nonatomic, weak) UIPanGestureRecognizer *pan;

@property (nonatomic, assign) CGPoint initialTouchPoint;

@end

@implementation ImageViewerController

+ (UINavigationController *)instanceWithImages:(NSPointerArray *)images {
    
    ImageViewerController *instance = [[ImageViewerController alloc] initWithCollectionViewLayout:[ImageViewerController layout]];
    
    NSMutableArray *_images = [NSMutableArray new];
    
    for (id image in images.allObjects) {
        if ([image isKindOfClass:Image.class]) {
            
            Content *content = [(Image *)image content];
            
            if (content != nil) {
                [_images addObject:content];
            }
        }
        else if ([image isKindOfClass:Gallery.class]) {
            
            for (id img in [(Gallery *)image images]) {
                [_images addObject:img];
            }
                
        }
        else {
            NSLog(@"Unknown class for image in ImageViewerController :%@", NSStringFromClass([image class]));
//            [_images addObject:img];
        }
    }
    
    instance.images = [_images rz_deduped];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:instance];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    
    return nav;
    
}

+ (UICollectionViewLayout *)layout {
    
    NSCollectionLayoutSize *layoutSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.f] heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.f]];
    
    NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:layoutSize];
    
    NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.f] heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.f]];
    
    NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitems:@[item]];
    
    NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
    
    UICollectionViewCompositionalLayoutConfiguration *config = [UICollectionViewCompositionalLayoutConfiguration new];
    config.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    
    UICollectionViewCompositionalLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSection:section];
    layout.configuration = config;
    
    return layout;
    
}

#pragma mark -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(didTapDone:)];
    
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [self setNeedsStatusBarAppearanceUpdate];
    
    // Do any additional setup after loading the view.
    [self setupCollectionView];
    
}

#pragma mark - Setups

- (void)setupCollectionView {
    
    self.collectionView.directionalLockEnabled = YES;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.alwaysBounceVertical = NO;
    
    self.collectionView.showsHorizontalScrollIndicator = NO;
    self.collectionView.showsVerticalScrollIndicator = NO;
    
    self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    self.collectionView.backgroundColor = UIColor.blackColor;
    
    // Register cell classes
    [ImageViewerCell registerOn:self.collectionView];
    
    __unused UICollectionViewDiffableDataSource *DS = self.DS;
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
    
    [pan requireGestureRecognizerToFail:self.collectionView.panGestureRecognizer];
    
    [self.collectionView addGestureRecognizer:pan];
    
    self.pan = pan;
}

- (void)setupData {
    
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@0]];
    
    if (self.images != nil) {
        [snapshot appendItemsWithIdentifiers:self.images intoSectionWithIdentifier:@0];
    }
    
    [self.DS applySnapshot:snapshot animatingDifferences:NO];
    
}

#pragma mark - Getters

- (UICollectionViewDiffableDataSource *)DS {
    
    if (_DS == nil) {
        
        _DS = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, Content * _Nonnull image) {
            
            ImageViewerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kImageViewerCell forIndexPath:indexPath];
            
            cell.viewController = self;
            
            if (image.attributes != nil
                && (image.attributes[@"alt"] || image.attributes[@"title"])) {
                
                NSString *altText = image.attributes[@"alt"] ?: image.attributes[@"title"];
                cell.label.text = altText;
                [cell.label sizeToFit];
                
                cell.label.hidden = NO;
                
            }
            else {
                cell.label.hidden = YES;
            }
            
            NSString *url = [image urlCompliantWithUsersPreferenceForWidth:self.collectionView.bounds.size.width];
            
            if (url != nil) {
                cell.task = [SharedImageLoader downloadImageForURL:url success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
                    if (cell != nil && responseObject != nil && [responseObject isKindOfClass:UIImage.class]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [cell setImage:responseObject];
                        });
                    }
                    
                } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                   
                    NSLog(@"Error loading image: %@", error);
                    
                }];
            }
            
            return cell;
            
        }];
        
        [self setupData];
        
    }
    
    return _DS;
    
}

#pragma mark - Actions

- (void)didTapDone:(id)sender {
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
        if (self != nil) {
            self.images = nil;
            [self setupData];
        }
        
    }];
    
}

- (void)didPan:(UIPanGestureRecognizer *)sender {
    
    CGPoint touchPoint = [sender locationInView:sender.view.window];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        self.initialTouchPoint = touchPoint;
    }
    else if (sender.state == UIGestureRecognizerStateChanged) {
        
        if ((touchPoint.y - self.initialTouchPoint.y) > 0.f) {
            
            CGFloat diff = touchPoint.y - self.initialTouchPoint.y;
            CGFloat scale = 1.f - (diff/200.f);
            CGFloat alpha = MAX(0.f, scale);
#ifdef DEBUG
            NSLog(@"Alpha: %@", @(alpha));
#endif
            [UIView animateWithDuration:0.1 animations:^{
                self.view.alpha = alpha;
                self.view.transform = CGAffineTransformMakeScale(scale, scale);
            }];
        }
        
    }
    else if (sender.state == UIGestureRecognizerStateEnded) {
        
        if ((touchPoint.y - self.initialTouchPoint.y) > 200.f) {
            [self didTapDone:sender];
        }
        else {
            [self resetPan];
        }
        
    }
    else {
        [self resetPan];
    }
    
}

- (void)resetPan {
    
    [UIView animateWithDuration:0.2 animations:^{
        self.initialTouchPoint = CGPointZero;
        self.view.alpha = 1.f;
        self.view.transform = CGAffineTransformIdentity;
    }];
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    
    self.pan.enabled = NO;
    
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    self.pan.enabled = YES;
    
}

#pragma mark - Subclassing

- (UIStatusBarStyle)preferredStatusBarStyle {
    
    return UIStatusBarStyleDarkContent;
    
}

- (BOOL)prefersStatusBarHidden {
    
    return self.navigationController.isNavigationBarHidden;
    
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    
    return UIStatusBarAnimationSlide;
    
}

@end
