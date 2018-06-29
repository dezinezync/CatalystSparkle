//
//  RecommendationsVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 29/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "RecommendationsVC.h"
#import "YetiThemeKit.h"
#import "FeedsManager.h"

#import "FeedsGridCell.h"
#import "CollectionHeader.h"

#import "FeedsVC.h"
#import "FeedVC.h"

@interface RecommendationsVC ()

@property (nonatomic, copy) NSDictionary *recommendations;

@end

@implementation RecommendationsVC

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Recommendations";
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    self.collectionView.backgroundColor = theme.backgroundColor;
    
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(FeedsGridCell.class) bundle:nil] forCellWithReuseIdentifier:kFeedsGridCell];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(CollectionHeader.class) bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kCollectionHeader];
    
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self _updateMetrics];
    
    weakify(self);
    [MyFeedsManager getRecommendationsWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        self.recommendations = responseObject;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
#warning handle the error
    }];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    if (coordinator) {
        weakify(self);
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            strongify(self);
            
            [self _updateMetrics];
        } completion:nil];
    }
    else {
        [self _updateMetrics];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -

- (void)_updateMetrics {
    CGFloat width = MIN(self.collectionView.bounds.size.width, self.collectionView.contentSize.width);
    CGFloat columnWidth = floor((width - 2.f) / 3.f);
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)[self collectionViewLayout];
    
    [layout setItemSize:CGSizeMake(columnWidth, columnWidth)];
    [layout setHeaderReferenceSize:CGSizeMake(width, 52.f)];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 3;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (!self.recommendations) {
        return 0;
    }
    
    switch (section) {
        case 1:
            return MIN(6, [self.recommendations[@"mostRead"] count]);
            break;
        case 2:
            return MIN(6, [self.recommendations[@"highestSubs"] count]);
            break;
        default:
            return MIN(6, [self.recommendations[@"trending"] count]);
            break;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    FeedsGridCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kFeedsGridCell forIndexPath:indexPath];
    
    // Configure the cell
    Feed *feed = nil;
    
    switch (indexPath.section) {
        case 1:
            feed = [self.recommendations[@"mostRead"] safeObjectAtIndex:indexPath.item];
            break;
        case 2:
            feed = [self.recommendations[@"highestSubs"] safeObjectAtIndex:indexPath.item];
            break;
        default:
            feed = [self.recommendations[@"trending"] safeObjectAtIndex:indexPath.item];
            break;
    }
    
    [cell configure:feed];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    CollectionHeader *header = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kCollectionHeader forIndexPath:indexPath];
    
    NSString *text = nil;
    
    switch (indexPath.section) {
        case 1:
            text = @"Most read";
            break;
        case 2:
            text = @"Highest Subscribers";
            break;
        default:
            text = @"Trending";
            break;
    }
    
    header.label.text = [text uppercaseString];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    header.backgroundColor = theme.backgroundColor;
    header.label.textColor = theme.isDark ? theme.captionColor : theme.titleColor;
    
    return header;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    Feed *feed = nil;
    
    switch (indexPath.section) {
        case 1:
            feed = [self.recommendations[@"mostRead"] safeObjectAtIndex:indexPath.item];
            break;
        case 2:
            feed = [self.recommendations[@"highestSubs"] safeObjectAtIndex:indexPath.item];
            break;
        default:
            feed = [self.recommendations[@"trending"] safeObjectAtIndex:indexPath.item];
            break;
    }
    
    if (feed) {
        FeedVC *vc = [[FeedVC alloc] initWithFeed:feed];
        vc.exploring = YES;
        [self.navigationController pushViewController:vc animated:YES];
    }
    else {
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
    
}

@end