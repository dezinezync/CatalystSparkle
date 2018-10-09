//
//  DetailFeedVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DetailFeedVC+Actions.h"
#import "ArticleCellB.h"
#import "ArticleVC.h"

#import "FeedsManager.h"

#import "YetiConstants.h"

#import <DZKit/AlertManager.h>
#import <DZKit/UIViewController+AnimatedDeselect.h>
#import <DZKit/NSArray+Safe.h>

#import "ArticleProvider.h"

#import "YetiThemeKit.h"

static void *KVO_DetailFeedFrame = &KVO_DetailFeedFrame;

@interface DetailFeedVC () <DZDatasource, ArticleProvider> {
    UIImageView *_barImageView;
    BOOL _ignoreLoadScroll;
}

@property (nonatomic, weak) UIView *hairlineView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, strong) UISelectionFeedbackGenerator *feedbackGenerator;

@property (nonatomic, weak) UICollectionViewFlowLayout *flowLayout;

@property (nonatomic, strong) NSMutableDictionary *sizeCache;

@end

@implementation DetailFeedVC

+ (UINavigationController *)instanceWithFeed:(Feed *)feed {
    
    DetailFeedVC *instance = [[DetailFeedVC alloc] initWithFeed:feed];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:instance];
    nav.restorationIdentifier = @"DetailFeedNavVC";
    
    return nav;
    
}

- (instancetype)initWithFeed:(Feed *)feed {
    
    if (self = [super initWithNibName:NSStringFromClass(DetailFeedVC.class) bundle:nil]) {
        self.feed = feed;
        _canLoadNext = YES;
        _page = 0;
        
        self.sizeCache = @{}.mutableCopy;
        
        self.restorationIdentifier = formattedString(@"%@-%@", NSStringFromClass(self.class), feed.feedID);
        self.restorationClass = self.class;
    }
    
    return self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.feed.title;
    self.collectionView.restorationIdentifier = self.restorationIdentifier;
    
    self.flowLayout = (UICollectionViewFlowLayout *)[self collectionViewLayout];
    
    self.DS = [[DZBasicDatasource alloc] initWithView:self.collectionView];
    self.DS.delegate = self;
    self.DS.data = self.feed.articles;
    
    self.DS.addAnimation = UITableViewRowAnimationLeft;
    self.DS.deleteAnimation = UITableViewRowAnimationFade;
    self.DS.reloadAnimation = UITableViewRowAnimationFade;
    
    [self.collectionView addObserver:self forKeyPath:propSel(frame) options:NSKeyValueObservingOptionNew context:KVO_DetailFeedFrame];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(ArticleCellB.class) bundle:nil] forCellWithReuseIdentifier:kiPadArticleCell];
    
    // Do any additional setup after loading the view.
    [self setupLayout];
    
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    
    UIBarButtonItem *allRead = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"done_all"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapAllRead:event:)];
    allRead.accessibilityValue = @"Mark all articles as read";
    
    if (self.isExploring) {
        // check if the user is subscribed to this feed
        Feed *existing = [MyFeedsManager feedForID:self.feed.feedID];
        if (!existing) {
            // allow subscription
            UIBarButtonItem *subscribe = [[UIBarButtonItem alloc] initWithTitle:@"Subscribe" style:UIBarButtonItemStyleDone target:self action:@selector(subscribeToFeed:)];
            subscribe.accessibilityValue = @"Subscribe to this feed";
            self.navigationItem.rightBarButtonItem = subscribe;
        }
    }
    else if (!(self.feed.hubSubscribed && self.feed.hub)) {
        self.navigationItem.rightBarButtonItem = allRead;
    }
    else {
        // push notifications are possible
        NSString *imageString = self.feed.isSubscribed ? @"notifications_on" : @"notifications_off";
        
        UIBarButtonItem *notifications = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageString] style:UIBarButtonItemStylePlain target:self action:@selector(didTapNotifications:)];
        notifications.accessibilityValue = self.feed.isSubscribed ? @"Subscribe" : @"Unsubscribe";
        notifications.accessibilityHint = self.feed.isSubscribed ? @"Unsubscribe from notifications" : @"Subscribe to notifications";
        
        self.navigationItem.rightBarButtonItems = @[allRead, notifications];
    }
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.navigationController.navigationBar.translucent = NO;
    
    if ([self respondsToSelector:@selector(author)] || (self.feed.authors && self.feed.authors.count > 1)) {
        [self setupHeaderView];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    self.DS.data = @[];
    _page = 0;
    _canLoadNext = YES;
    
    if (self.feed) {
        self.feed.articles = @[];
    }
    
    [AlertManager showGenericAlertWithTitle:@"Memory Warning" message:@"The app received a memory warning and to prevent unexpected crashes, it had to clear articles from the current feed. Please reload the feed to continue viewing."];
}

- (void)dealloc {
    if (self.feed) {
        self.feed.articles = @[];
    }
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    [self dz_smoothlyDeselectCells:self.collectionView];
    
    if (self.DS.data == nil || self.DS.data.count == 0) {
        [self loadNextPage];
    }
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    @try {
        [NSNotificationCenter.defaultCenter removeObserver:self];
    } @catch (NSException *exc) {
        DDLogWarn(@"Exception when unregistering: %@", exc);
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    // flush cache
    self.sizeCache = @{}.mutableCopy;
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
}

- (void)_setToolbarHidden {
    self.navigationController.toolbarHidden = YES;
}

#pragma mark - Getters

- (UISelectionFeedbackGenerator *)feedbackGenerator {
    
    if (!_feedbackGenerator) {
        _feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        [_feedbackGenerator prepare];
    }
    
    return _feedbackGenerator;
    
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if (_activityIndicatorView == nil) {
        Theme *theme = [YTThemeKit theme];
        
        UIActivityIndicatorViewStyle style = theme.isDark ? UIActivityIndicatorViewStyleWhite : UIActivityIndicatorViewStyleGray;
        
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
        [view sizeToFit];
        
        [view.widthAnchor constraintEqualToConstant:view.bounds.size.width].active = YES;
        [view.heightAnchor constraintEqualToConstant:view.bounds.size.height].active = YES;
        
        view.hidesWhenStopped = YES;
        
        _activityIndicatorView = view;
    }
    
    return _activityIndicatorView;
}

#pragma mark - Setters

- (void)setLoadOnReady:(NSNumber *)loadOnReady
{
    if (loadOnReady == nil) {
        _loadOnReady = loadOnReady;
        return;
    }
    
    if (self.DS == nil || self.DS.data == nil || self.DS.data.count == 0) {
        weakify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            strongify(self);
            [self setLoadOnReady:loadOnReady];
        });
        
        return;
    }
    
    _loadOnReady = loadOnReady;
    
    if (loadOnReady && [[self navigationController] visibleViewController] == self) {
        // we are visible
        [self loadArticle];
    }
}

#pragma mark <UICollectionViewDataSource>

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ArticleCellB *cell = (ArticleCellB *)[collectionView dequeueReusableCellWithReuseIdentifier:kiPadArticleCell forIndexPath:indexPath];
    
    // Configure the cell
    FeedItem *item = [self.DS objectAtIndexPath:indexPath];
    
    if (item != nil) {
        [cell configure:item customFeed:self.isCustomFeed sizeCache:self.sizeCache];
    }
    
    cell.backgroundView.backgroundColor = [self.view.tintColor colorWithAlphaComponent:0.3f];
    cell.selectedBackgroundView.backgroundColor = [self.view.tintColor colorWithAlphaComponent:0.3f];
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FeedItem *item = [self.DS objectAtIndexPath:indexPath];
    
    ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];
    vc.providerDelegate = self;
    
    [self.navigationController pushViewController:vc animated:YES];
    
    if ([self isKindOfClass:NSClassFromString(@"CustomFeedVC")] == NO) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
//            ArticleCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//            if (cell && cell.markerView.image != nil && item.isBookmarked == NO) {
//                cell.markerView.image = nil;
//            }
            
        });
        
    }
    
}

#pragma mark - <ScrollLoading>

- (void)loadNextPage
{
    
    if (self.loadingNext)
        return;
    
    if (self->_ignoreLoadScroll)
        return;
    
    self.loadingNext = YES;
    
    weakify(self);
    
    NSInteger page = self->_page + 1;
    
    [MyFeedsManager getFeed:self.feed page:page success:^(NSArray <FeedItem *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (!self)
            return;
        
        self.loadingNext = NO;
        
        if (!responseObject.count) {
            self->_canLoadNext = NO;
        }
        
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            NSArray *articles = page == 1 ? @[] : (self.feed.articles ?: @[]);
            articles = [articles arrayByAddingObjectsFromArray:responseObject];
            self.feed.articles = articles;
            self->_ignoreLoadScroll = YES;
            
            @try {
                self.DS.data = self.feed.articles;
            }
            @catch (NSException *exc) {
                DDLogWarn(@"Exception updating feed articles: %@", exc);
            }
        });
        
        self->_page = page;
        
        if ([self loadOnReady] != nil) {
            weakify(self);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                strongify(self);
                [self loadArticle];
            });
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            if (self->_ignoreLoadScroll) {
                self->_ignoreLoadScroll = NO;
            }
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DDLogError(@"%@", error);
        
        strongify(self);
        
        if (!self)
            return;
        
        self.loadingNext = NO;
    }];
}

- (BOOL)cantLoadNext
{
    return !_canLoadNext;
}

#pragma mark - <ArticleProvider>

- (void)willChangeArticle {
    weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        [self.feedbackGenerator selectionChanged];
        [self.feedbackGenerator prepare];
    });
}

// the logic for the following two methods is inversed
// since the articles are displayed in reverse chronological order
- (BOOL)hasNextArticleForArticle:(FeedItem *)item
{
    
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <FeedItem *> *)self.DS.data enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.guid isEqualToString:item.guid]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index == NSNotFound)
        return NO;
    
    return index > 0;
}

- (BOOL)hasPreviousArticleForArticle:(FeedItem *)item
{
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <FeedItem *> *)self.DS.data enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.guid isEqualToString:item.guid]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index == NSNotFound)
        return NO;
    
    return (index < (((NSArray <FeedItem *> *)self.DS.data).count - 1));
}

- (FeedItem *)previousArticleFor:(FeedItem *)item
{
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <FeedItem *> *)self.DS.data enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.guid isEqualToString:item.guid]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index > 0) {
        index--;
        
        [self willChangeArticle];
        
        return [((NSArray <FeedItem *> *)self.DS.data) safeObjectAtIndex:index];
    }
    
    return nil;
}

- (FeedItem *)nextArticleFor:(FeedItem *)item
{
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <FeedItem *> *)self.DS.data enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.guid isEqualToString:item.guid]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index < (((NSArray <FeedItem *> *)self.DS.data).count - 1)) {
        index++;
        
        [self willChangeArticle];
        
        return [((NSArray <FeedItem *> *)self.DS.data) safeObjectAtIndex:index];
    }
    
    return nil;
}

- (void)userMarkedArticle:(FeedItem *)article read:(BOOL)read
{
    
    if (!article)
        return;
    
    if ([self isKindOfClass:NSClassFromString(@"CustomFeedVC")]) {
        return;
    }
    
    NSUInteger index = [(NSArray <FeedItem *> *)self.DS.data indexOfObject:article];
    
    if (index == NSNotFound)
        return;
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        FeedItem *articleInFeed = [self.feed.articles safeObjectAtIndex:index];
        if (articleInFeed) {
            articleInFeed.read = read;
        }
        
        FeedItem *articleInDS = [(NSArray <FeedItem *> *)self.DS.data safeObjectAtIndex:index];
        
        if (articleInDS) {
            articleInDS.read = read;
            // if the article exists in the datasource,
            // we can expect a cell for it and therefore
            // reload it.
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            
            NSArray <NSIndexPath *> * visible = self.collectionView.indexPathsForVisibleItems;
            BOOL isVisible = NO;
            for (NSIndexPath *ip in visible) {
                if (ip.row == index) {
                    isVisible = YES;
                    break;
                }
            }
            
            if (isVisible) {
                ArticleCellB *cell = (ArticleCellB *)[self.collectionView cellForItemAtIndexPath:indexPath];
                // only change when not bookmarked. If bookmarked, continue showing the bookmark icon
                if (cell != nil && article.isBookmarked == NO) {
//                    if (read == YES) {
//                        cell.markerView.image = nil;
//                    }
//                    else {
//                        cell.markerView.image = [UIImage imageNamed:@"munread"];
//                    }
                }
            }
        }
    });
}

- (void)userMarkedArticle:(FeedItem *)article bookmarked:(BOOL)bookmarked {
    
    if (!article)
        return;
    
    if ([self isKindOfClass:NSClassFromString(@"CustomFeedVC")]) {
        return;
    }
    
    NSUInteger index = [(NSArray <FeedItem *> *)self.DS.data indexOfObject:article];
    
    if (index == NSNotFound)
        return;
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        FeedItem *articleInFeed = [self.feed.articles safeObjectAtIndex:index];
        if (articleInFeed) {
            articleInFeed.bookmarked = bookmarked;
        }
        
        FeedItem *articleInDS = [(NSArray <FeedItem *> *)self.DS.data safeObjectAtIndex:index];
        
        if (articleInDS) {
            articleInDS.bookmarked = bookmarked;
            // if the article exists in the datasource,
            // we can expect a cell for it and therefore
            // reload it.
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            
            NSArray <NSIndexPath *> * visible = self.collectionView.indexPathsForVisibleItems;
            BOOL isVisible = NO;
            for (NSIndexPath *ip in visible) {
                if (ip.row == index) {
                    isVisible = YES;
                    break;
                }
            }
            
            if (isVisible) {
                ArticleCellB *cell = (ArticleCellB *)[self.collectionView cellForItemAtIndexPath:indexPath];
                
                if (cell != nil) {
//                    if (bookmarked == NO) {
//                        cell.markerView.image = nil;
//                    }
//                    else {
//                        cell.markerView.image = [UIImage imageNamed:@"mbookmark"];
//                    }
                }
            }
        }
    });
    
}

- (void)didChangeToArticle:(FeedItem *)item
{
    
    if ([NSThread isMainThread] == NO) {
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            [self didChangeToArticle:item];
        });
        
        return;
    }
    
    __block NSUInteger index = NSNotFound;
    
    [self.DS.data enumerateObjectsUsingBlock:^(FeedItem *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.identifier isEqualToNumber:item.identifier]) {
            index = idx;
            *stop = YES;
        }
    }];
    
    if (index == NSNotFound)
        return;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    if (self.class != NSClassFromString(@"CustomFeedVC") && !item.isRead) {
        [self userMarkedArticle:item read:YES];
    }
    
    [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        
        [self scrollViewDidEndDecelerating:self.collectionView];
    });
}

#pragma mark - State Restoration

NSString * const kBFeedData = @"FeedData";
NSString * const kBCurrentPage = @"FeedsLoadedPage";

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    Feed *feed = [coder decodeObjectForKey:kBFeedData];
    
    if (feed) {
        DetailFeedVC *vc = [[DetailFeedVC alloc] initWithFeed:feed];
        return vc;
    }
    
    return nil;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.feed forKey:kBFeedData];
    [coder encodeInteger:_page forKey:kBCurrentPage];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    Feed *feed = [coder decodeObjectForKey:kBFeedData];
    
    if (feed) {
        self.feed = feed;
        self.DS.data = self.feed.articles;
        _page = [coder decodeIntegerForKey:kBCurrentPage];
    }
    
}

#pragma mark - Layout

- (void)setupLayout {
    
//    [self.collectionView layoutIfNeeded];
//
//    CGSize contentSize = self.collectionView.contentSize;
//    CGFloat width = contentSize.width;
////
////    /*
////     |- 16 - (cell) - 16 - (cell) - 16 -|
////     */
////
////    // get actual values from the layout
    CGFloat padding = self.flowLayout.minimumInteritemSpacing;
//    CGFloat totalPadding = padding * 3.f;
//
//    CGFloat usableWidth = width - totalPadding;
//
//    // the remainder will be absorbed by the interimSpacing
//    CGFloat cellWidth = floor(usableWidth / 2.f);
//
    self.flowLayout.sectionInset = UIEdgeInsetsMake(padding, padding, padding, padding);
    self.flowLayout.estimatedItemSize = UICollectionViewFlowLayoutAutomaticSize;
    
}

- (void)setupHeaderView {
    
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:propSel(frame)] && context == KVO_DetailFeedFrame) {
        
        self.sizeCache = @{}.mutableCopy;
        
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

@end
