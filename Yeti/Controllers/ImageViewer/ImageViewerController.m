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

#import <DZNetworking/ImageLoader.h>

@interface ImageViewerController ()

+ (UICollectionViewLayout *)layout;

@property (nonatomic, strong) UICollectionViewDiffableDataSource *DS;

@property (nonatomic, weak) NSPointerArray *images;

@end

@implementation ImageViewerController

+ (UINavigationController *)instanceWithImages:(NSPointerArray *)images {
    
    ImageViewerController *instance = [[ImageViewerController alloc] initWithCollectionViewLayout:[ImageViewerController layout]];
    
    instance.images = images;
    
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
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlackTranslucent];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    // Do any additional setup after loading the view.
    [self setupCollectionView];
    
}

#pragma mark - Setups

- (void)setupCollectionView {
    
    self.collectionView.directionalLockEnabled = YES;
    self.collectionView.pagingEnabled = YES;
    self.collectionView.alwaysBounceVertical = NO;
    self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    self.collectionView.backgroundColor = UIColor.blackColor;
    
    // Register cell classes
    [ImageViewerCell registerOn:self.collectionView];
    
    __unused UICollectionViewDiffableDataSource *DS = self.DS;
    
}

- (void)setupData {
    
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@0]];
    
    if (self.images != nil) {
        [snapshot appendItemsWithIdentifiers:self.images.allObjects intoSectionWithIdentifier:@0];
    }
    
    [self.DS applySnapshot:snapshot animatingDifferences:NO];
    
}

#pragma mark - Getters

- (UICollectionViewDiffableDataSource *)DS {
    
    if (_DS == nil) {
        
        _DS = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, Image * _Nonnull image) {
            
            ImageViewerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kImageViewerCell forIndexPath:indexPath];
            
            cell.viewController = self;
            
            if (image.imageView.image != nil) {
                [cell setImage:image.imageView.image];
            }
            else {
                [SharedImageLoader downloadImageForURL:image.URL success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                    
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
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
}

@end
