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
#import "DetailFeedVC.h"

#import "YetiConstants.h"

#import <DZKit/NSArray+Safe.h>
#import <DZKit/UIViewController+AnimatedDeselect.h>

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
    
    self.restorationIdentifier = NSStringFromClass(self.class);
    self.restorationClass = [self class];
    
    self.collectionView.restorationIdentifier = [self.restorationIdentifier stringByAppendingString:@"-collectionView"];
    
    self.title = @"Recommended";
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
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
    
    [self dz_smoothlyDeselectCells:self.collectionView];
    
    [self _updateMetrics];
    
    self.navigationController.toolbarHidden = YES;
    
    if (self.state == ReccoStateLoaded)
        return;
    
    NSInteger count = 9;
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        count = 20;
    }
    
    [MyFeedsManager getRecommendations:count success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        self.recommendations = responseObject;
        
        self.state = ReccoStateLoaded;
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        self.loadError = error;
        
        self.state = ReccoStateError;
        
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:animated];
    
    if (PrefsManager.sharedInstance.useToolbar == YES) {
        self.navigationController.toolbarHidden = NO;
    }
    
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
    
    CGFloat columns = 3.f;
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        columns = 4.f;
    }
    
    CGFloat width = MIN(self.collectionView.bounds.size.width, self.collectionView.contentSize.width);
    CGFloat columnWidth = floor((width - (columns - 1.f)) / columns);
    
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)[self collectionViewLayout];
    
    [layout setItemSize:CGSizeMake(columnWidth, columnWidth)];
    [layout setHeaderReferenceSize:CGSizeMake(width, 52.f)];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if (self.state == ReccoStateLoaded) {
        return 4;
    }
    
    return 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (!self.recommendations) {
        return 0;
    }
    
    NSInteger MAX_CELLS = 9;
    
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        MAX_CELLS = 8;
    }
    
    switch (section) {
        case 1:
            return MIN(MAX_CELLS, [self.recommendations[@"mostRead"] count]);
            break;
        case 2:
            return MIN(MAX_CELLS, [self.recommendations[@"highestSubs"] count]);
            break;
        case 0:
            return MIN(20, [self.recommendations[@"similar"] count]);
            break;
        default:
            return MIN(MAX_CELLS, [self.recommendations[@"trending"] count]);
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
        case 0:
            feed = [self.recommendations[@"similar"] safeObjectAtIndex:indexPath.item];
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
            text = @"Most Read";
            break;
        case 2:
            text = @"Most Subscribers";
            break;
        case 0:
            text = @"Similar";
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

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    Feed *feed = nil;
    
    switch (indexPath.section) {
        case 1:
            feed = [self.recommendations[@"mostRead"] safeObjectAtIndex:indexPath.item];
            break;
        case 2:
            feed = [self.recommendations[@"highestSubs"] safeObjectAtIndex:indexPath.item];
            break;
        case 0:
            feed = [self.recommendations[@"similar"] safeObjectAtIndex:indexPath.item];
            break;
        default:
            feed = [self.recommendations[@"trending"] safeObjectAtIndex:indexPath.item];
            break;
    }
    
    BOOL isPhone = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone
                    && self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    
    if (feed) {
        UIViewController *vcc;
        
        if (isPhone) {
            DetailFeedVC *vc = [[DetailFeedVC alloc] initWithFeed:feed];
            vc.customFeed = NO;
            vc.exploring = YES;
            vc.customFeed = FeedTypeFeed;
            
            vcc = vc;
        }
        else {
            UINavigationController *nav = [DetailFeedVC instanceWithFeed:feed];
            [(DetailFeedVC *)[nav topViewController] setCustomFeed:NO];
            [(DetailFeedVC *)[nav topViewController] setExploring:YES];
            
            vcc = nav;
        }
        
        [self showDetailViewController:vcc sender:self];
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

#pragma mark -

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray<NSString *> *)identifierComponents coder:(NSCoder *)coder {
    
    return [[RecommendationsVC alloc] initWithNibName:NSStringFromClass([self class]) bundle:nil];
    
}

@end
