//
//  FeedVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 13/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+ContextMenus.h"
#import "ArticlesManager.h"
#import "FeedItem.h"

#import <DZKit/UIViewController+AnimatedDeselect.h>

#import <DZTextKit/PaddedLabel.h>
#import "YetiThemeKit.h"

#import "ArticleVC.h"

#import <DZKit/NSString+Extras.h>
#import <DZTextKit/CheckWifi.h>
#import <DZTextKit/NSString+ImageProxy.h>

#define emptyViewTag 386728

@interface FeedVC () {
    
    BOOL _shouldShowHeader;
    
    StateType _controllerState;
    
    NSUInteger _loadOnReadyTries;
    
    BOOL _reloadDataset;
    
}

@property (nonatomic, strong, readwrite) UITableViewDiffableDataSource *DS;

@property (nonatomic, strong, readwrite) UISelectionFeedbackGenerator *feedbackGenerator;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

@end

#define ArticlesSection @0

@implementation FeedVC

+ (UINavigationController *)instanceInNavigationController {
    
    FeedVC *instance = [[[self class] alloc] init];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:instance];
    nav.restorationIdentifier = @"FeedNavVC";
    
    return nav;
    
}

+ (UINavigationController *)instanceWithFeed:(Feed *)feed {
    
    FeedVC *instance = [[[self class] alloc] initWithFeed:feed];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:instance];
    nav.restorationIdentifier = @"FeedNavVC";
    
    return nav;
    
}

- (instancetype)initWithFeed:(Feed *)feed {
    
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.feed = feed;
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.sortingOption = SharedPrefs.sortingOption;
    
    if (self.type == FeedVCTypeNatural && self.feed) {
        self.title = self.feed.displayTitle;
    }
    
    [self setupNavigationBar];
    [self setupTableView];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    [self dz_smoothlyDeselectRows:self.tableView];
    
    if (self.pagingManager.page == 1 && [self.DS.snapshot numberOfItems] == 0) {
        self.controllerState = StateLoaded;
        [self loadNextPage];
    }
    
    if (_reloadDataset) {
        
        _reloadDataset = NO;
        
        [self setupData:NO];
        
    }
    
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        
        if (self.to_splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            UIImage *image = [UIImage systemImageNamed:@"sidebar.left"];
            
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(didTapSidebarButton:)];
        }
        else {
            self.navigationItem.leftBarButtonItem = nil;
        }
        
    } completion:nil];
    
}

- (void)dealloc {
    
    @try {
        [NSNotificationCenter.defaultCenter removeObserver:self];
    }
    @catch (NSException *exc) {
        NSLog(@"Exception when deallocating %@: %@", self.class, exc);
    }
    
}

- (BOOL)definesPresentationContext {
    return YES;
}

#pragma mark - Setups

- (void)setupNavigationBar {
    
    self.navigationItem.leftItemsSupplementBackButton = YES;
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
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
        
        if (PrefsManager.sharedInstance.useToolbar == NO) {
            self.navigationItem.rightBarButtonItems = self.rightBarButtonItems;
            
            self.navigationController.toolbarHidden = YES;
        }
        else {
            self.navigationController.toolbarHidden = NO;
        }
        
    }
    
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.searchBar.placeholder = @"Search Articles";
    searchController.automaticallyShowsCancelButton = YES;
    searchController.automaticallyShowsScopeBar = YES;
    searchController.searchBar.scopeButtonTitles = @[@"Local", @"Server"];
    searchController.obscuresBackgroundDuringPresentation = NO;
    
    self.navigationItem.searchController = searchController;
    self.navigationItem.hidesSearchBarWhenScrolling = YES;
    
}

- (void)setupNotifications {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self selector:@selector(didChangeContentCategory) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(didChangeTheme) name:kDidUpdateTheme object:nil];
    
    [notificationCenter addObserver:self selector:@selector(didUpdateUnread) name:FeedDidUpReadCount object:MyFeedsManager];
    
    if (ArticlesManager.shared.feeds != nil && ArticlesManager.shared.feeds.count > 0) {}
    else {
        
        NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
        
        [center addObserver:self selector:@selector(updatedFeedsNotification:) name:FeedsDidUpdate object:ArticlesManager.shared];
        
    }
    
    weakify(self);
    
    [self.bookmarksManager addObserver:self name:BookmarksDidUpdateNotification callback:^{
       
        strongify(self);
        [self didUpdateBookmarks];
        
    }];
    
}

- (void)setupTableView {
    
    [self setupDatasource];
    
    self.tableView.prefetchDataSource = self;
    
    self.tableView.tableFooterView = [UIView new];
    self.tableView.estimatedRowHeight =  150.f;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.tableView.separatorInset = UIEdgeInsetsZero;
    
    [ArticleCell registerOnTableView:self.tableView];
//    [self.tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
    
    if ([self respondsToSelector:@selector(author)]
        || (self.feed.authors && self.feed.authors.count > 1)
        || self.feed.summary || self.feed.extra.summary) {
        
        self->_shouldShowHeader = YES;
        
    }
    
}

- (void)setupDatasource {
    
    self.DS = [[UITableViewDiffableDataSource alloc] initWithTableView:self.tableView cellProvider:^UITableViewCell * _Nullable(UITableView * tableView, NSIndexPath * indexPath, FeedItem * article) {
        
        ArticleCell *cell = [tableView dequeueReusableCellWithIdentifier:kArticleCell forIndexPath:indexPath];

        [cell configure:article feedType:self.type];
        
//        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
//
//        cell.textLabel.text = article.articleTitle;
        
        return cell;
        
    }];
    
}

- (void)setupData:(BOOL)animated {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setupData) withObject:nil waitUntilDone:NO];
        return;
    }
    
    BOOL isAppending = self.DS.snapshot.numberOfItems > 0;
    
    __weak NSArray *articles = self.pagingManager.items;
    
    @try {
        
        NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
        [snapshot appendSectionsWithIdentifiers:@[ArticlesSection]];
        [snapshot appendItemsWithIdentifiers:articles intoSectionWithIdentifier:ArticlesSection];
        
        if (isAppending == YES) {
            [self.tableView setScrollEnabled:NO];
        }
        
        [self.DS applySnapshot:snapshot animatingDifferences:animated];
        
        if (isAppending == YES) {
            [self.tableView setScrollEnabled:YES];
        }
        
    }
    @catch (NSException *exc) {
        NSLog(@"Exception updating feed articles: %@", exc);
    }
    
}

- (void)setupData {
    
    BOOL animate = (self.pagingManager.items.count > 10);
    
    [self setupData:animate];
    
}

#pragma mark - Setters

- (void)setFeed:(Feed *)feed {
    
    _feed = feed;
    
    if (_feed != nil) {
        self.restorationIdentifier = [NSString stringWithFormat:@"FeedVC-Feed-%@", feed.feedID];
        self.restorationClass = [self class];
    }
    
}

#pragma mark - Getters

- (BOOL)showsSortingButton {
    
    return YES;
    
}

- (UISelectionFeedbackGenerator *)feedbackGenerator {
    
    if (!_feedbackGenerator) {
        _feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        [_feedbackGenerator prepare];
    }
    
    return _feedbackGenerator;
    
}

- (NSUInteger)indexOfItem:(FeedItem *)item retIndexPath:(NSIndexPath *)outIndexPath {
    
    NSUInteger index = NSNotFound;
    
    if (item != nil && [item isKindOfClass:FeedItem.class]) {
        NSIndexPath *indexPath = [self.DS indexPathForItemIdentifier:item];
        
        if (indexPath != nil) {
            index = indexPath.item;
            
            outIndexPath = indexPath;
        }
    }
    
    return index;
    
}

- (FeedItem *)itemForIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath == nil) {
        return nil;
    }
    
    FeedItem *article = [self.DS itemIdentifierForIndexPath:indexPath];
    
    return article;
}

- (UIActivityIndicatorView *)activityIndicatorView {
    if (_activityIndicatorView == nil) {
        
        UIActivityIndicatorViewStyle style = UIActivityIndicatorViewStyleMedium;
        
        UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:style];
        [view sizeToFit];
        
        [view.widthAnchor constraintEqualToConstant:view.bounds.size.width].active = YES;
        [view.heightAnchor constraintEqualToConstant:view.bounds.size.height].active = YES;
        
        view.hidesWhenStopped = YES;
        
        _activityIndicatorView = view;
    }
    
    return _activityIndicatorView;
}

- (PagingManager *)pagingManager {
    
    if (_pagingManager == nil) {
        
        NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"limit": @10}.mutableCopy;
        
        params[@"sortType"] = @([(NSNumber *)(_sortingOption ?: @0 ) integerValue]);
        
        if ([MyFeedsManager subscription] != nil && [MyFeedsManager.subscription hasExpired] == YES) {
            params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
        }
        
        NSString *path = [NSString stringWithFormat:@"/feeds/%@", self.feed.feedID];
        
        PagingManager * pagingManager = [[PagingManager alloc] initWithPath:path queryParams:params itemsKey:@"articles"];
        
        _pagingManager = pagingManager;
    }
    
    if (_pagingManager.preProcessorCB == nil) {
        
        _pagingManager.preProcessorCB = ^NSArray * _Nonnull(NSArray * _Nonnull items) {
          
            NSArray *retval = [items rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
                FeedItem *item = [FeedItem instanceFromDictionary:obj];
//                item.read = NO;
                return item;
            }];
            
            return retval;
            
        };
        
    }
    
    if (_pagingManager.successCB == nil) {
        
        weakify(self);
        
        _pagingManager.successCB = ^{
            strongify(self);
            
            if (!self) {
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.tableView.refreshControl isRefreshing]) {
                    [self.tableView.refreshControl endRefreshing];
                }
                
                if (self.pagingManager.page == 1 && self.pagingManager.hasNextPage == YES) {
                    [self loadNextPage];
                }
            });
            
            [self setupData];
            
            self.controllerState = StateLoaded;

        };
    }
    
    if (_pagingManager.errorCB == nil) {
        weakify(self);
        
        _pagingManager.errorCB = ^(NSError * _Nonnull error) {
            NSLog(@"%@", error);
            
            strongify(self);
            
            if (!self)
                return;
            
            self.controllerState = StateErrored;
            
            weakify(self);
            
            asyncMain(^{
                strongify(self);
                
                if ([self.tableView.refreshControl isRefreshing]) {
                    [self.tableView.refreshControl endRefreshing];
                }
            })
        };
    }
    
    _pagingManager.objectClass = FeedItem.class;
    
    return _pagingManager;
    
}


#pragma mark - State

- (StateType)controllerState {
    return self->_controllerState;
}

- (void)setControllerState:(StateType)controllerState {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setControllerState:) withObject:@(controllerState) waitUntilDone:NO];
        return;
    }
    
    if(_controllerState != controllerState)
    {
        
        @synchronized (self) {
            self->_controllerState = controllerState;
        }
        
        if (self.DS.snapshot == nil || self.DS.snapshot.numberOfItems == 0) {
            // we can be in any state
            // but we should only show the empty view
            // when there is no data
            dispatch_async(dispatch_get_main_queue(), ^{
                [self addEmptyView];
            });
        }
        else {
            // we have data, so the state doesn't matter
            dispatch_async(dispatch_get_main_queue(), ^{
                [self removeEmptyView];
            });
        }
        
    }
    
}

- (void)addEmptyView {
    
    if (!NSThread.isMainThread) {
        [self performSelectorOnMainThread:@selector(addEmptyView) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if(![self respondsToSelector:@selector(viewForEmptyDataset)])
        return;
    
    UIView *view = [self viewForEmptyDataset];
    
    if( view != nil ) {
        view.tag = emptyViewTag;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
//      Check if the previous view, if existing, is present
        [self removeEmptyView];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            UILayoutGuide *guide = [self.view layoutMarginsGuide];
            
            [self.view addSubview:view];
            
            // this can be nil
            if (guide != nil) {
                if ([view isKindOfClass:UIActivityIndicatorView.class] == NO) {
                    [view.widthAnchor constraintEqualToAnchor:guide.widthAnchor].active = YES;
                }
                
                [view.centerXAnchor constraintEqualToAnchor:guide.centerXAnchor].active = YES;
                [view.centerYAnchor constraintEqualToAnchor:guide.centerYAnchor].active = YES;
            }
            
        });
        
    }
    
}

- (void)removeEmptyView {
    
    if (!NSThread.isMainThread) {
        [self performSelectorOnMainThread:@selector(removeEmptyView) withObject:nil waitUntilDone:NO];
        return;
    }
    
    UIView *buffer = [self.view viewWithTag:emptyViewTag];
    
    while (buffer != nil && buffer.superview) {
        [buffer removeFromSuperview];
        
        buffer = [self.view viewWithTag:emptyViewTag];
    }
}

- (NSString *)emptyViewSubtitle {
    
    NSString *subtitle = nil;
    
    if ([_sortingOption isEqualToString:YTSortAllDesc] || [_sortingOption isEqualToString:YTSortAllAsc]) {
        subtitle = formattedString(@"No recent articles are available from %@", self.feed.title);
    }
    else {
        subtitle = formattedString(@"No recent unread articles are available from %@", self.feed.title);
    }
    
    return subtitle;
    
}

- (UIView *)viewForEmptyDataset {
    
    // since the Datasource is asking for this view
    // it will be presenting it.
    BOOL dataCheck = self.controllerState == StateLoading && self.pagingManager.page <= 1;
    
    if (dataCheck) {
        self.activityIndicatorView.hidden = NO;
        [self.activityIndicatorView startAnimating];
        
        return self.activityIndicatorView;
    }
    
    if (self.controllerState == StateDefault) {
        return nil;
    }
    
    if (self.DS.snapshot.numberOfItems > 0) {
        return nil;
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    CGRect layoutFrame = [self.view.readableContentGuide layoutFrame];
    
    PaddedLabel *label = [[PaddedLabel alloc] init];
    label.padding = UIEdgeInsetsMake(0, layoutFrame.origin.x, 0, layoutFrame.origin.x);
    label.numberOfLines = 0;
    label.backgroundColor = theme.cellColor;
    label.opaque = YES;
    
    NSString *title = @"No Articles";
    NSString *subtitle = [self emptyViewSubtitle];
    
    NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.lineHeightMultiple = 1.4f;
    para.alignment = NSTextAlignmentCenter;
    
    NSString *formatted = formattedString(@"%@\n%@", title, subtitle);
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    NSDictionary *attributes = @{NSFontAttributeName: font,
                                 NSForegroundColorAttributeName: theme.subtitleColor,
                                 NSParagraphStyleAttributeName: para
                                 };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:attributes];
    
    attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:font.pointSize weight:UIFontWeightSemibold],
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

#pragma mark - Notifications

- (void)didUpdateBookmarks {
    if (!_reloadDataset) {
        _reloadDataset = YES;
    }
}

- (void)didUpdateUnread {
    if (!_reloadDataset) {
        _reloadDataset = YES;
    }
}

- (void)updatedFeedsNotification:(id)sender {
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:FeedsDidUpdate object:ArticlesManager.shared];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

        NSDiffableDataSourceSnapshot *snapshot = self.DS.snapshot;
        [snapshot reloadItemsWithIdentifiers:snapshot.itemIdentifiers];
        
        [self.DS applySnapshot:snapshot animatingDifferences:NO];

    });
    
}

- (void)didChangeContentCategory {
    
    runOnMainQueueWithoutDeadlocking(^{

        if ([[self.tableView indexPathsForVisibleRows] count] > 0) {
            
            NSDiffableDataSourceSnapshot *snapshot = self.DS.snapshot;
            
            [self.DS applySnapshot:snapshot animatingDifferences:YES];
            
        }
        
    });
    
}

- (void)didChangeTheme {
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.view.backgroundColor = theme.cellColor;
    self.tableView.backgroundColor = theme.cellColor;
    
}

#pragma mark - <ScrollLoading>

- (BOOL)isLoadingNext {
    
    if (self.navigationItem.searchController.presentingViewController != nil) {
        return YES;
    }
    
    return self.controllerState == StateLoading;
    
}

- (void)loadNextPage {
    
    if (self.pagingManager.hasNextPage == NO) {
        return;
    }
    
    if (self.controllerState == StateLoading) {
        return;
    }
    
    self.controllerState = StateLoading;
    
    [self.pagingManager loadNextPage];
    
}

- (BOOL)cantLoadNext {
    return !self.pagingManager.hasNextPage;
}

#pragma mark - Table Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FeedItem *item = [self itemForIndexPath:indexPath];
    
    if (item == nil) {
        return;
    }
    
    ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];
    vc.providerDelegate = self;
    vc.bookmarksManager = self.bookmarksManager;
    
    if (self.to_splitViewController == nil) {
        // in a modal stack
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (self.to_splitViewController != nil) {
        
        if (self.to_splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];

            [self to_showDetailViewController:nav sender:self];
            
        }
        else {
            [self.navigationController pushViewController:vc animated:YES];
        }
        
    }
    else {
        [self presentViewController:vc animated:YES completion:nil];
    }
    
}

#pragma mark - <UITableViewDatasourcePrefetching>
//
//- (void)tableView:(UITableView *)tableView prefetchRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
//
//    BOOL showImage = SharedPrefs.imageLoading != ImageLoadingNever;
//
//    if (CheckWiFi() == NO && showImage == YES) {
//        showImage = NO;
//    }
//
//    if (showImage == NO) {
//        return;
//    }
//
//    BOOL imageProxy = SharedPrefs.imageProxy;
//
//    NSMutableArray <NSURL *> *imagesToCache = [NSMutableArray new];
//
//    // get any cell
//    ArticleCell *cell = [tableView cellForRowAtIndexPath:indexPaths.firstObject];
//
//    for (NSIndexPath *indexPath in indexPaths) {
//
//        FeedItem *article = [self itemForIndexPath:indexPath];
//
//        if (article == nil) {
//            continue;
//        }
//
//        if (self.type != FeedVCTypeNatural) {
//
//            // should pre-cache the Favicon
//            Feed *feed = [ArticlesManager.shared feedForID:article.feedID];
//
//            if (feed != nil) {
//
//                NSString *faviconURL = feed.faviconURI;
//
//                if (faviconURL != nil) {
//
//                    CGFloat maxWidth = 24.f;
//
//                    if (imageProxy == YES) {
//
//                        faviconURL = [faviconURL pathForImageProxy:NO maxWidth:maxWidth quality:1.f firstFrameForGIF:NO useImageProxy:YES sizePreference:ImageLoadingMediumRes];
//
//                    }
//
//                    if (faviconURL) {
//
//                        [imagesToCache addObject:[NSURL URLWithString:faviconURL]];
//
//                    }
//
//                }
//
//            }
//
//        }
//
//        // check for cover image
//        NSString *coverImageURL = article.coverImage;
//
//        if (coverImageURL == nil && article.content != nil && article.content.count > 0) {
//
//            Content *content = [article.content rz_reduce:^id(Content *prev, Content *current, NSUInteger idx, NSArray *array) {
//
//                if (prev && [prev.type isEqualToString:@"image"]) {
//                    return prev;
//                }
//
//                return current;
//            }];
//
//            if (content != nil) {
//                article.coverImage = content.url;
//                coverImageURL = article.coverImage;
//            }
//
//        }
//
//        if (coverImageURL != nil) {
//
//            CGFloat maxWidth = cell.coverImage.bounds.size.width;
//
//            if (imageProxy == YES) {
//
//                coverImageURL = [coverImageURL pathForImageProxy:NO maxWidth:maxWidth quality:1.f firstFrameForGIF:NO useImageProxy:YES sizePreference:ImageLoadingMediumRes];
//
//            }
//
//            if (coverImageURL != nil) {
//
//                [imagesToCache addObject:[NSURL URLWithString:coverImageURL]];
//
//            }
//
//        }
//
//    }
//
//    if (imagesToCache.count > 0) {
//
//        self.prefetchingTasks = [SDWebImagePrefetcher.sharedImagePrefetcher prefetchURLs:imagesToCache];
//
//    }
//
//}
//
//- (void)tableView:(UITableView *)tableView cancelPrefetchingForRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
//
//    if (self.prefetchingTasks != nil) {
//
//        [self.prefetchingTasks cancel];
//
//        self.prefetchingTasks = nil;
//
//    }
//
//}

#pragma mark - Setters

- (void)setLoadOnReady:(NSNumber *)loadOnReady
{
    if (loadOnReady == nil) {
        _loadOnReady = loadOnReady;
        return;
    }
    
    if ((self.DS == nil || self.DS.snapshot.numberOfItems == 0) && _loadOnReadyTries < 3) {
        
        weakify(self);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            strongify(self);
            
            self->_loadOnReadyTries++;
            
            [self setLoadOnReady:loadOnReady];
            
        });
        
        return;
    }
    
    _loadOnReadyTries = 0;
    
    _loadOnReady = loadOnReady;
    
    if (loadOnReady && [[self navigationController] visibleViewController] == self) {
        // we are visible
        [self loadArticle];
    }
}

- (void)setSortingOption:(YetiSortOption)option {
    
    BOOL changed = _sortingOption != option;
    
    _sortingOption = option;
    
    if (changed) {
        
        [SharedPrefs setValue:option forKey:propSel(sortingOption)];
        
        if ([self respondsToSelector:@selector(_setSortingOption:)]) {
            
            [self _setSortingOption:option];
            
            NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
            [self.DS applySnapshot:snapshot animatingDifferences:YES];
            
            self.controllerState = StateLoaded;
            
            [self loadNextPage];
            
            
        }
        
    }
    
}

- (void)_setSortingOption:(YetiSortOption)option {
    
    self.pagingManager = nil;
    
}

#pragma mark -

- (void)loadArticle {
    
    if (self.loadOnReady == nil)
        return;
    
    if (self.DS.snapshot.numberOfItems == 0) {
        return;
    }
    
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <FeedItem *> *)[[self.DS snapshot] itemIdentifiers] enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.identifier isEqualToNumber:self.loadOnReady]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index == NSNotFound) {
        
        FeedItem *item = [FeedItem new];
        item.identifier = self.loadOnReady;
        item.feedID = self.feed.feedID;
        
        ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];
        vc.providerDelegate = (id<ArticleProvider>)self;
        
        [self to_showDetailViewController:vc sender:self];
        
        return;
    }
    
    self.loadOnReady = nil;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        strongify(self);
        
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        
    });
    
}

#pragma mark - State Restoration

#define kVCType @"kFeedVCType"
#define kVCFeed @"kFeedVCFeed"
#define kPagingManager @"kPagingManager"

+ (nullable UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    
    FeedVC *vc = [[[self class] alloc] initWithFeed:nil];
    
    PagingManager *pagingManager = [coder decodeObjectOfClass:PagingManager.class forKey:kPagingManager];
    
    vc.pagingManager = pagingManager;
    
    FeedVCType type = [coder decodeIntegerForKey:kVCType];
    
    vc.type = type;
    
    if (type == FeedVCTypeNatural) {
        
        Feed *feed = [coder decodeObjectOfClass:Feed.class forKey:kVCFeed];
        
        if (feed != nil) {
            
            vc.feed = feed;
        
        }
        
    }
    
    return vc;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeInteger:self.type forKey:kVCType];
    
    if (self.type == FeedVCTypeNatural) {
        
        [coder encodeObject:self.feed forKey:kVCFeed];
        
    }
    
    [coder encodeObject:self.pagingManager forKey:kPagingManager];
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super decodeRestorableStateWithCoder:coder];
    
    FeedVCType type = [coder decodeIntegerForKey:kVCType];
    
    self.type = type;
    
    self.pagingManager = [coder decodeObjectOfClass:PagingManager.class forKey:kPagingManager];
    
    self.controllerState = StateLoaded;
    
    if (type == FeedVCTypeNatural) {
        
        Feed *feed = [coder decodeObjectOfClass:Feed.class forKey:kVCFeed];
        
        if (feed != nil) {
            
            self.feed = feed;
            
        }
        
    }
    
}

@end
