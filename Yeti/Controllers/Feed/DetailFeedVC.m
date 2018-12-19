//
//  DetailFeedVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DetailFeedVC+Actions.h"

#import "ArticleCellB.h"
#import "ArticleImageCellB.h"

#import "ArticleVC.h"
#import "DetailAuthorVC.h"
#import "DetailFeedHeaderView.h"

#import "FeedsManager.h"

#import "YetiConstants.h"

#import <DZKit/AlertManager.h>
#import <DZKit/UIViewController+AnimatedDeselect.h>
#import <DZKit/NSArray+Safe.h>

#import "ArticleProvider.h"

#import "YetiThemeKit.h"

@interface UICollectionViewController ()

- (UICollectionView *)_newCollectionViewWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout;

@end

static void *KVO_DetailFeedFrame = &KVO_DetailFeedFrame;

@interface DetailFeedVC () <DZDatasource, ArticleProvider, FeedHeaderViewDelegate, UIViewControllerRestoration> {
    UIImageView *_barImageView;
    BOOL _ignoreLoadScroll;
    
    BOOL _initialSetup;
}

@property (nonatomic, weak) UIView *hairlineView;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@property (nonatomic, weak) FeedHeaderView *headerView;

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
        
        self.restorationIdentifier = NSStringFromClass(self.class);
//        self.restorationClass = self.class;
    }
    
    return self;
    
}

- (UICollectionView *)_newCollectionViewWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout {
    
    if (layout == nil) {
        layout = [[UICollectionViewFlowLayout alloc] init];
    }
    
    UICollectionView *collectionView = [super _newCollectionViewWithFrame:frame collectionViewLayout:layout];
    
    return collectionView;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = [self.feed displayTitle];
    
    self.flowLayout = (UICollectionViewFlowLayout *)[self collectionViewLayout];
    
    self.DS = [[DZBasicDatasource alloc] initWithView:self.collectionView];
    self.DS.delegate = self;
    self.DS.data = @[];
    
    self.DS.addAnimation = UITableViewRowAnimationLeft;
    self.DS.deleteAnimation = UITableViewRowAnimationFade;
    self.DS.reloadAnimation = UITableViewRowAnimationFade;
    
    [self.collectionView addObserver:self forKeyPath:propSel(frame) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:KVO_DetailFeedFrame];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    // Register cell classes
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(ArticleCellB.class) bundle:nil] forCellWithReuseIdentifier:kiPadArticleCell];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass(ArticleImageCellB.class) bundle:nil] forCellWithReuseIdentifier:kiPadArticleImageCell];
    [self.collectionView registerClass:DetailFeedHeaderView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kDetailFeedHeaderView];
    
    // Do any additional setup after loading the view.
    if ([self respondsToSelector:@selector(author)] || (self.feed.authors && self.feed.authors.count > 1)) {
        self->_shouldShowHeader = YES;
    }
    
    [self setupLayout];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self selector:@selector(didChangeContentCategory) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(didChangeTheme) name:kDidUpdateTheme object:nil];
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
    
    @try {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        [notificationCenter removeObserver:self];
        
        if (self && self.collectionView && self.collectionView.observationInfo != nil) {
            [self.collectionView removeObserver:self forKeyPath:propSel(frame) context:KVO_DetailFeedFrame];
        }
    }
    @catch (NSException *exc) {
        
    }
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self->_initialSetup == NO) {
        [self setupNavigationBar];
        
        self->_initialSetup = YES;
        
        [self setupLayout];
        [self didChangeTheme];
    }
    
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
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    
        [self setupLayout];
        
        [self didChangeContentCategory];
    
    } completion:nil];
    
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

- (void)setRestorationIdentifier:(NSString *)restorationIdentifier {
    [super setRestorationIdentifier:restorationIdentifier];
    
    self.restorationClass = self.class;
    
    self.collectionView.restorationIdentifier = [restorationIdentifier stringByAppendingString:@"-collectionView"];
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

#pragma mark - <UICollectionViewDataSource>

- (NSString *)emptyViewSubtitle {
    return formattedString(@"No recent articles are available from %@", self.feed.title);
}

- (UIView *)viewForEmptyDataset {
    
    // since the Datasource is asking for this view
    // it will be presenting it.
    if (self.DS.state == DZDatasourceLoading && _page == 0) {
        self.activityIndicatorView.hidden = NO;
        [self.activityIndicatorView startAnimating];
        
        return self.activityIndicatorView;
    }
    
    if (self.DS.data.count > 0) {
        return nil;
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.backgroundColor = theme.cellColor;
    label.opaque = YES;
    
    NSString *title = @"No Articles";
    NSString *subtitle = [self emptyViewSubtitle];
    
    NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.lineHeightMultiple = 1.4f;
    para.alignment = NSTextAlignmentCenter;
    
    NSString *formatted = formattedString(@"%@\n%@", title, subtitle);
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                 NSForegroundColorAttributeName: theme.subtitleColor,
                                 NSParagraphStyleAttributeName: para
                                 };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:attributes];
    
    attributes = @{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
                   NSForegroundColorAttributeName: theme.titleColor,
                   NSParagraphStyleAttributeName: para
                   };
    
    NSRange range = [formatted rangeOfString:title];
    if (range.location != NSNotFound) {
        [attrs addAttributes:attributes range:range];
    }
    
    label.attributedText = attrs;
    [label sizeToFit];
    
    return label;
    
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ArticleCellB *cell = nil;
    
//    if (self.isExploring == NO && [NSUserDefaults.standardUserDefaults boolForKey:kShowArticleCoverImages]) {
//        cell = (ArticleCellB *)[collectionView dequeueReusableCellWithReuseIdentifier:kiPadArticleImageCell forIndexPath:indexPath];
//    }
//    else {
        cell = (ArticleCellB *)[collectionView dequeueReusableCellWithReuseIdentifier:kiPadArticleCell forIndexPath:indexPath];
//    }
    
    // Configure the cell
    FeedItem *item = [self.DS objectAtIndexPath:indexPath];
    
    if (item != nil) {
        [cell configure:item customFeed:self.isCustomFeed sizeCache:self.sizeCache];
    }
    
    [cell setupAppearance];
    
    BOOL showSeparator = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone || self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    
    [cell showSeparator:showSeparator];
    
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    
    if (self->_shouldShowHeader && [kind isEqualToString:UICollectionElementKindSectionHeader]) {
        
        DetailFeedHeaderView *view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:kDetailFeedHeaderView forIndexPath:indexPath];
        
        [view setupAppearance];
        
        self.headerView = view.headerContent;
        [self setupHeaderView];
        
        return view;
        
    }
    
    return nil;
    
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    FeedItem *item = [self.DS objectAtIndexPath:indexPath];
    
    ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];
    vc.providerDelegate = self;
    
    [self.navigationController pushViewController:vc animated:YES];
    
    if ([self isKindOfClass:NSClassFromString(@"CustomFeedVC")] == NO) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            ArticleCellB *cell = (ArticleCellB *)[collectionView cellForItemAtIndexPath:indexPath];
            if (cell && cell.markerView.image != nil && item.isBookmarked == NO) {
                cell.markerView.image = nil;
            }
            
        });
        
    }
    
}

#pragma mark - <ScrollLoading>

- (void)loadNextPage
{
    
    if (self.DS.state == DZDatasourceLoading) {
        return;
    }
    
    if (self->_ignoreLoadScroll)
        return;
    
    if (self->_canLoadNext == NO) {
        return;
    }
    
    self.DS.state = DZDatasourceLoading;
    
    weakify(self);
    
    NSInteger page = self->_page + 1;
    
    YetiSortOption sorting = [[NSUserDefaults standardUserDefaults] valueForKey:kDetailFeedSorting];
    
    [MyFeedsManager getFeed:self.feed sorting:sorting page:page success:^(NSArray <FeedItem *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (!self)
            return;
        
        self->_page = page;
        
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
            
            self.DS.state = DZDatasourceLoaded;
        });
        
        if (page == 1 && self.splitViewController.view.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            [self loadNextPage];
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DDLogError(@"%@", error);
        
        strongify(self);
        
        if (!self)
            return;
        
        self.DS.state = DZDatasourceError;
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
    
    if ([NSStringFromClass(self.class) isEqualToString:@"DetailCustomVC"] == YES) {
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
                    if (read == YES) {
                        cell.markerView.image = nil;
                    }
                    else {
                        cell.markerView.image = [UIImage imageNamed:@"munread"];
                    }
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
                    if (bookmarked == NO) {
                        cell.markerView.image = nil;
                    }
                    else {
                        cell.markerView.image = [UIImage imageNamed:@"mbookmark"];
                    }
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
    
    if ((self.class != NSClassFromString(@"CustomFeedVC")
         || self.class != NSClassFromString(@"CustomFolderVC")
         || self.class != NSClassFromString(@"CustomAuthorVC"))
        && !item.isRead) {
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
NSString * const kSizCache = @"FeedSizesCache";

+ (nullable UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    Feed *feed = [coder decodeObjectForKey:kBFeedData];
    
    if (feed) {
        DetailFeedVC *vc = [[DetailFeedVC alloc] initWithFeed:feed];
        
        return vc;
    }
    
    return nil;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    DDLogDebug(@"Encoding restoration: %@", self.restorationIdentifier);
    
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.feed forKey:kBFeedData];
    [coder encodeInteger:_page forKey:kBCurrentPage];
    [coder encodeObject:self.sizeCache forKey:kSizCache];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    DDLogDebug(@"Decoding restoration: %@", self.restorationIdentifier);
    
    [super decodeRestorableStateWithCoder:coder];
    
    if ([NSStringFromClass(self.class) isEqualToString:NSStringFromClass(DetailFeedVC.class)] == YES) {
        Feed *feed = [coder decodeObjectForKey:kBFeedData];
        
        if (feed) {
            [self setupLayout];
            
            self.feed = feed;
            [self.DS resetData];
            self.DS.data = self.feed.articles;
        }
    }
    
    _page = [coder decodeIntegerForKey:kBCurrentPage];
    NSDictionary *sizesCache = [coder decodeObjectForKey:kSizCache];
    
    if (sizesCache) {
        self.sizeCache = sizesCache.mutableCopy;
    }
    
}

#pragma mark - Layout

- (BOOL)showsSortingButton {
    return YES;
}

- (void)setupNavigationBar {
    
    self.navigationItem.leftBarButtonItem = self.splitViewController.displayModeButtonItem;
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    UIButton *allReadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [allReadButton setImage:[UIImage imageNamed:@"done_all"] forState:UIControlStateNormal];
    [allReadButton sizeToFit];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapAllRead:)];
    [allReadButton addGestureRecognizer:tap];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressOnAllRead:)];
    [allReadButton addGestureRecognizer:longPress];
    
    [longPress requireGestureRecognizerToFail:tap];
    
    UIBarButtonItem *allRead = [[UIBarButtonItem alloc] initWithCustomView:allReadButton];
    allRead.accessibilityValue = @"Mark all articles as read";
    allRead.accessibilityHint = @"Mark all current articles as read. Long Tap to Mark all backdated articles as read.";
    allRead.width = 32.f;
    
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
    else {
        // sorting button
        YetiSortOption option = [NSUserDefaults.standardUserDefaults valueForKey:kDetailFeedSorting];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL isUnread = NSSelectorFromString(@"isUnread");

        if (self.customFeed == FeedTypeCustom && [self respondsToSelector:isUnread] && (BOOL)[self performSelector:isUnread] == YES) {
            
            // when the active option is either of these two, we don't need
            // to do anything extra
            if (option != YTSortUnreadAsc && option != YTSortUnreadDesc) {
                
                // map it to whatever the selected option is
                if (option == YTSortAllAsc) {
                    option = YTSortUnreadAsc;
                }
                else if (option == YTSortAllDesc) {
                    option = YTSortUnreadDesc;
                }
                
            }
            
        }
#pragma clang diagnostic pop
        
        UIBarButtonItem *sorting = [[UIBarButtonItem alloc] initWithImage:[SortImageProvider imageForSortingOption:option] style:UIBarButtonItemStylePlain target:self action:@selector(didTapSortOptions:)];
        sorting.width = 32.f;
        
        if (!(self.feed.hubSubscribed && self.feed.hub)) {
            NSMutableArray *buttons = @[allRead].mutableCopy;
            
            if ([self showsSortingButton]) {
                [buttons addObject:sorting];
            }
            
            self.navigationItem.rightBarButtonItems = buttons;
        }
        else {
            // push notifications are possible
            NSString *imageString = self.feed.isSubscribed ? @"notifications_on" : @"notifications_off";
            
            UIBarButtonItem *notifications = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:imageString] style:UIBarButtonItemStylePlain target:self action:@selector(didTapNotifications:)];
            notifications.accessibilityValue = self.feed.isSubscribed ? @"Subscribe" : @"Unsubscribe";
            notifications.accessibilityHint = self.feed.isSubscribed ? @"Unsubscribe from notifications" : @"Subscribe to notifications";
            notifications.width = 32.f;
            
            NSMutableArray *buttons = @[allRead, notifications].mutableCopy;
            
            if ([self showsSortingButton]) {
                [buttons addObject:sorting];
            }
            
            self.navigationItem.rightBarButtonItems = buttons;
        }
    }
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.navigationController.navigationBar.translucent = NO;
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    CGFloat height = 1.f/[[UIScreen mainScreen] scale];
    UIView *hairline = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationController.navigationBar.bounds.size.height, self.navigationController.navigationBar.bounds.size.width, height)];
    hairline.backgroundColor = theme.cellColor;
    hairline.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    
    [self.navigationController.navigationBar addSubview:hairline];
    self.hairlineView = hairline;
    
}

- (void)setupLayout {
    
    BOOL isCompact = [[[self.collectionView valueForKeyPath:@"delegate"] traitCollection] horizontalSizeClass] == UIUserInterfaceSizeClassCompact;
    
    CGFloat padding = isCompact ? 0 : [self.flowLayout minimumInteritemSpacing];
    
    if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        self.flowLayout.sectionInset = UIEdgeInsetsMake(12.f, 0.f, 12.f, 0.f);
        self.flowLayout.minimumLineSpacing = 0;
        self.flowLayout.minimumInteritemSpacing = 0;
    }
    else {
        self.flowLayout.sectionInset = UIEdgeInsetsMake(padding, padding, padding, padding);
    }
    
    CGSize contentSize = self.collectionView.contentSize;
    
    if (CGSizeEqualToSize(contentSize, CGSizeZero)) {
        contentSize = [UIScreen mainScreen].bounds.size;
    }
    
    CGFloat width = contentSize.width;
    
    /*
     On iPads (Regular)
     |- 16 - (cell) - 16 - (cell) - 16 -|
     */
    
    /*
     On iPhones (Compact)
     |- 0 - (cell) - 0 -|
     */
    
    CGFloat totalPadding =  padding * 3.f;
    
    CGFloat usableWidth = width - totalPadding;
    
    CGFloat cellWidth = usableWidth;
    
    if (usableWidth > 601.f) {
        // the remainder will be absorbed by the interimSpacing
        cellWidth = floor(usableWidth / 2.f);
    }
    else {
        cellWidth = width - (padding * 2.f);
    }
    
    self.flowLayout.estimatedItemSize = CGSizeMake(cellWidth, 100.f);
    self.flowLayout.itemSize = UICollectionViewFlowLayoutAutomaticSize;
    
    if (self->_shouldShowHeader) {
        self.flowLayout.headerReferenceSize = CGSizeMake(CGRectGetWidth(self.collectionView.bounds), 80.f);
    }
    else {
        self.flowLayout.headerReferenceSize = CGSizeZero;
    }
    
}

- (void)setupHeaderView {
    
    if (_headerView == nil)
        return;
    
    if (_headerView.delegate && _headerView.delegate == self) {
        return;
    }
    
    [self.headerView configure:self.feed];
    self.headerView.delegate = self;
    
//    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
}

#pragma mark - <FeedHeaderViewDelegate>

- (void)didTapAuthor:(Author *)author
{
    DetailAuthorVC *vc = [[DetailAuthorVC alloc] initWithFeed:self.feed];
    vc.author = author;
    vc.customFeed = self.customFeed;
    
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - KVO

- (void)didChangeTheme {
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.view.backgroundColor = theme.cellColor;
    self.collectionView.backgroundColor = theme.cellColor;
    
    [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
    
    self.hairlineView.backgroundColor = theme.cellColor;
    
    [self reloadHeaderView];
    
}

- (void)reloadHeaderView {
    
    [(DetailFeedHeaderView *)[self.headerView superview] setupAppearance];
    
}

- (void)didChangeContentCategory {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.sizeCache = @{}.mutableCopy;
    });
    
    if ([[self.collectionView indexPathsForVisibleItems] count]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadItemsAtIndexPaths:[self.collectionView indexPathsForVisibleItems]];
        });
    }
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:propSel(frame)] && context == KVO_DetailFeedFrame) {
        
        CGRect old = [[change valueForKey:NSKeyValueChangeOldKey] CGRectValue];
        CGRect new = [[change valueForKey:NSKeyValueChangeNewKey] CGRectValue];
        
        if (CGRectEqualToRect(old, new) == NO) {
        
            [self didChangeContentCategory];
            
        }
        
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

@end
