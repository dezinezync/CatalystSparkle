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

typedef NS_ENUM(NSInteger, ReccoState) {
    ReccoStateLoading,
    ReccoStateLoaded,
    ReccoStateError
};

@interface RecommendationsVC ()

@property (nonatomic, copy) NSDictionary *recommendations;
@property (nonatomic, strong) NSError *loadError;
@property (nonatomic, assign) ReccoState state;

@property (nonatomic, strong) UIActivityIndicatorView *activity;
@property (nonatomic, strong) UIStackView *errorView;
@property (nonatomic, weak) UILabel *errorTitle;
@property (nonatomic, weak) UILabel *errorCaption;

@end

@implementation RecommendationsVC

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Recommendations";
    
    // Uncomment the following line to preserve selection between presentations
    // self.clearsSelectionOnViewWillAppear = NO;
    
    self.state = ReccoStateLoading;
    
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
    
    if ([self.collectionView.indexPathsForSelectedItems count] > 0) {
        
        NSArray <NSIndexPath *> *indices = self.collectionView.indexPathsForSelectedItems;
        
        if (self.transitionCoordinator) {
            
            weakify(self);
            
            [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                
                strongify(self);
                
                for (NSIndexPath *indexPath in indices) {
                    [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
                }
                
            } completion:nil];
        }
        else {
            for (NSIndexPath *indexPath in indices) {
                [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
            }
        }
    }
    
    [self _updateMetrics];
    
    if (self.state == ReccoStateLoaded)
        return;
    
    weakify(self);
    [MyFeedsManager getRecommendationsWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        self.recommendations = responseObject;
        weakify(self);
        asyncMain(^{
            strongify(self);
            self.state = ReccoStateLoaded;
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        self.loadError = error;
        weakify(self);
        asyncMain(^{
            strongify(self);
            self.state = ReccoStateError;
        });
        
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

- (void)setState:(ReccoState)state {
    ReccoState original = _state;
    
    _state = state;
    
    if (original == _state)
        return;
    
    if (_state == ReccoStateLoaded) {
        
        if (original == ReccoStateLoading) {
            [self.activity stopAnimating];
            self.activity.hidden = YES;
        }
        
        self.collectionView.hidden = NO;
        [self.collectionView reloadData];
    }
    else {
        self.collectionView.hidden = YES;
        
        if (_state == ReccoStateLoading) {
            if (self.activity.superview == nil) {
                UIView *view = self.collectionView.superview;
                [view addSubview:self.activity];
                
                [self.activity.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
                [self.activity.centerYAnchor constraintEqualToAnchor:view.centerYAnchor].active = YES;
            }
            
            self.activity.hidden = NO;
            [self.activity startAnimating];
        }
        else {
            if (self.errorView.superview == nil) {
                UIView *view = self.collectionView.superview;
                [view addSubview:self.errorView];
                
                [self.errorView.centerXAnchor constraintEqualToAnchor:view.centerXAnchor].active = YES;
                [self.errorView.centerYAnchor constraintEqualToAnchor:view.centerYAnchor].active = YES;
            }
            
//            self.errorTitle.text = @"Error loading reccomendations";
            self.errorCaption.text = self.loadError ? self.loadError.localizedDescription : @"An unknown error occurred when loading recommendations.";
            [self.errorCaption sizeToFit];
            
            self.errorView.hidden = NO;
        }
    }
}

#pragma mark -

- (void)_updateMetrics {
    [self.collectionView layoutIfNeeded];
    
    CGFloat width = MIN(self.collectionView.bounds.size.width, self.collectionView.contentSize.width);
    CGFloat columnWidth = floor((width - 2.f) / 3.f);
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)[self collectionViewLayout];
    
    [layout setItemSize:CGSizeMake(columnWidth, columnWidth)];
    [layout setHeaderReferenceSize:CGSizeMake(width, 52.f)];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.state == ReccoStateLoaded) {
        return 3;
    }
    
    return 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (!self.recommendations) {
        return 0;
    }
    
    NSInteger const maxCells = 9;
    
    switch (section) {
        case 1:
            return MIN(maxCells, [self.recommendations[@"mostRead"] count]);
            break;
        case 2:
            return MIN(maxCells, [self.recommendations[@"highestSubs"] count]);
            break;
        default:
            return MIN(maxCells, [self.recommendations[@"trending"] count]);
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

#pragma mark -

- (UIActivityIndicatorView *)activity {
    if (_activity == nil) {
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        activity.color = theme.isDark ? [UIColor lightGrayColor] : [UIColor darkGrayColor];
        
        [activity sizeToFit];
        [activity.widthAnchor constraintEqualToConstant:activity.bounds.size.width].active = YES;
        [activity.heightAnchor constraintEqualToConstant:activity.bounds.size.height].active = YES;
        
        _activity = activity;
    }
    
    return _activity;
}

@end
