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
#import "FeedHeaderView.h"

#import <DZKit/UIViewController+AnimatedDeselect.h>

#import "PaddedLabel.h"

#import <DZKit/NSString+Extras.h>
#import "CheckWifi.h"
#import "NSString+ImageProxy.h"

#import "Coordinator.h"

#import "NSString+ImageProxy.h"
#import <SDWebImage/UIImageView+WebCache.h>

#if TARGET_OS_MACCATALYST

#import "AppDelegate.h"
#import <AppKit/NSToolbarItemGroup.h>

#endif

#define emptyViewTag 386728

@interface FeedVC () {
    
    BOOL _shouldShowHeader;
    
    StateType _controllerState;
    
    NSUInteger _loadOnReadyTries;
    
    BOOL _reloadDataset;
    
    NSUserActivity *_restorationActivity;
    
}

@property (nonatomic, strong, readwrite) UITableViewDiffableDataSource *DS;

@property (nonatomic, strong, readwrite) UISelectionFeedbackGenerator *feedbackGenerator;

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicatorView;

/// Special handling for specific feeds
@property (assign) BOOL isiOSIconGallery;

@end

#define ArticlesSection @0

@implementation FeedVC

+ (UINavigationController *)instanceInNavigationController {
    
    FeedVC *instance = [[[self class] alloc] init];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:instance];
    nav.restorationIdentifier = @"FeedNavVC";
    nav.restorationClass = [nav class];
    
    return nav;
    
}

+ (UINavigationController *)instanceWithFeed:(Feed *)feed {
    
    FeedVC *instance = [[[self class] alloc] initWithFeed:feed];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:instance];
    nav.restorationIdentifier = @"FeedNavVC";
    nav.restorationClass = [nav class];
    
    return nav;
    
}

- (instancetype)initWithFeed:(Feed *)feed {
    
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        
        NSLogDebug(@"Feed:%@", feed.feedID);
        
        self.feed = feed;
        
        if (feed.url != nil && [feed.url containsString:@"iosicongallery"]) {
            self.isiOSIconGallery = YES;
        }
        
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.sortingOption = self.isExploring ? YTSortAllDesc : SharedPrefs.sortingOption;
    
    if (self.type == FeedVCTypeNatural && self.feed) {
        self.title = self.feed.displayTitle;
    }
    
    [self setupNavigationBar];
    [self setupTableView];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
#if !TARGET_OS_MACCATALYST
        
    self.navigationController.navigationBar.prefersLargeTitles = YES;

#endif 
    
    [self dz_smoothlyDeselectRows:self.tableView];
    
    if (self.pagingManager.page == 1 && [self.DS.snapshot numberOfItems] == 0) {
        self.controllerState = StateLoaded;
        [self loadNextPage];
    }
    
#if TARGET_OS_MACCATALYST
    
    [UIMenuSystem.mainSystem setNeedsRebuild];
    
#endif
    
    if (_reloadDataset) {
        
        _reloadDataset = NO;
        
        [self setupData:NO];
        
    }
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
#if TARGET_OS_MACCATALYST
    SceneDelegate *delegate = (id)[self.view.window.windowScene delegate];
    
    [delegate.toolbar removeItemAtIndex:5];
    [delegate.toolbar insertItemWithItemIdentifier:@"com.yeti.toolbar.sortingMenu" atIndex:5];
#endif
    
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
    
#if TARGET_OS_MACCATALYST
        
    if (self.isExploring == NO) {
        self.navigationController.navigationBar.hidden = YES;
    }
    
    return;
    
#else
    
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
    
#endif
    
}

- (void)setupNotifications {
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self selector:@selector(didChangeContentCategory) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
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

- (void)setupTableHeaderView {
    
    FeedHeaderView *header = [[FeedHeaderView alloc] initWithNib];
    
    NSString *path = [self.feed faviconURI];
    
    if (path != nil) {
         
        if (SharedPrefs.imageProxy) {
            
            path = [path pathForImageProxy:YES maxWidth:128.f quality:1.f firstFrameForGIF:NO useImageProxy:YES sizePreference:SharedPrefs.imageLoading];
            
        }
        
        NSURL *url = [NSURL URLWithString:path];
        
        [header.faviconView sd_setImageWithURL:url];
        
    }
    
    header.titleLabel.text = self.feed.displayTitle;
    
    if (self.feed.summary != nil && [self.feed.summary isBlank] == NO) {
        header.descriptionLabel.text = [self.feed.summary stringByDecodingHTMLEntities];
    }
    else if (self.feed.extra.title != nil && [self.feed.extra.title isBlank] == NO) {
        header.descriptionLabel.text = [self.feed.extra.title stringByDecodingHTMLEntities];
    }
    
    BOOL isPushFromHub = (self.feed.hubSubscribed && self.feed.hub);
    BOOL isPushFromRPC = self.feed.rpcCount > 0;
    
    if (isPushFromHub || isPushFromRPC) {
        
        UIButton *notificationsButton = header.notificationsButton;
        
        if (self.feed.isSubscribed) {
            
            notificationsButton.accessibilityValue = @"Unsubscribe from notifications";
            
            [notificationsButton setImage:[UIImage systemImageNamed:@"bell.fill"] forState:UIControlStateNormal];
            [notificationsButton setNeedsDisplay];
            
        }
        else {
            notificationsButton.accessibilityValue = @"Subscribe to notifications";
        }
        
        notificationsButton.hidden = NO;
        
        [notificationsButton addTarget:self action:@selector(didTapNotifications:) forControlEvents:UIControlEventTouchUpInside];
        
        header.descriptionLabel.preferredMaxLayoutWidth = self.view.bounds.size.width - 24.f - 24.f - 12.f;
        
    }
    else {
        header.notificationsButton.hidden = YES;
        header.descriptionLabel.preferredMaxLayoutWidth = self.view.bounds.size.width - 24.f;
    }
    
    [header.descriptionLabel sizeToFit];
    
    [header.mainStackView setNeedsUpdateConstraints];
    [header setNeedsUpdateConstraints];
    [header setNeedsLayout];
    
    self.tableView.tableHeaderView = header;
    
}

- (void)setupTableView {
    
    [self setupDatasource];
    
    if (self.type == FeedVCTypeNatural
        && self.feed != nil
        && self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomMac) {
        
        [self setupTableHeaderView];
    }
    
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
        
        cell.tintColor = SharedPrefs.tintColor;
        
        if (self.isiOSIconGallery) {
            
            cell.coverImage.layer.cornerRadius = cell.coverImage.bounds.size.width * (180.f / 1024.f);
            cell.coverImage.layer.cornerCurve = kCACornerCurveContinuous;
            cell.coverImage.layer.masksToBounds = YES;
            
        }
        
        [cell configure:article feedType:self.type];
        
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
    
    if (_pagingManager == nil && MyFeedsManager.userID != nil) {
        
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
        subtitle = formattedString(@"No recent articles are available from %@", [self.feed displayTitle]);
    }
    else {
        subtitle = formattedString(@"No recent unread articles are available from %@", [self.feed displayTitle]);
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
    
    CGRect layoutFrame = [self.view.readableContentGuide layoutFrame];
    
    PaddedLabel *label = [[PaddedLabel alloc] init];
    label.padding = UIEdgeInsetsMake(0, layoutFrame.origin.x, 0, layoutFrame.origin.x);
    label.numberOfLines = 0;
    label.backgroundColor = UIColor.systemBackgroundColor;
    label.opaque = YES;
    
    NSString *title = @"No Articles";
    NSString *subtitle = [self emptyViewSubtitle];
    
    NSMutableParagraphStyle *para = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    para.lineHeightMultiple = 1.4f;
    para.alignment = NSTextAlignmentCenter;
    
    NSString *formatted = formattedString(@"%@\n%@", title, subtitle);
    
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    NSDictionary *attributes = @{NSFontAttributeName: font,
                                 NSForegroundColorAttributeName: UIColor.secondaryLabelColor,
                                 NSParagraphStyleAttributeName: para
                                 };
    
    NSMutableAttributedString *attrs = [[NSMutableAttributedString alloc] initWithString:formatted attributes:attributes];
    
    attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:font.pointSize weight:UIFontWeightSemibold],
                   NSForegroundColorAttributeName: UIColor.labelColor,
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
    
    [self _showArticleVC:vc];
    
}

- (void)_showArticleVC:(ArticleVC *)vc {
    
    if (self.mainCoordinator != nil) {
        
        [self.mainCoordinator showArticleVC:vc];
        
    }
    else {
        
        vc.exploring = YES;
        
        [self.navigationController pushViewController:vc animated:YES];
        
    }
    
    if (self->_restorationActivity != nil) {
        
        [vc continueActivity:self->_restorationActivity];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self->_restorationActivity = nil;
        });
        
    }
    
}

#pragma mark - Setters

- (void)setFeed:(Feed *)feed {
    
    _feed = feed;
    
    if (_feed != nil) {
        self.restorationIdentifier = [NSString stringWithFormat:@"FeedVC-Feed-%@", feed.feedID];
        self.restorationClass = [self class];
    }
    
}

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
        
        [self.mainCoordinator showArticleVC:vc];
        
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

- (void)continueActivity:(NSUserActivity *)activity {
    
    // check if we're showing the right feed
    
    
    // check if an article is stored
    NSNumber *selectedItem = [activity.userInfo valueForKeyPath:@"feed.selectedItem"];
    
    if (selectedItem) {
        
        self.loadOnReady = selectedItem;
        
        _restorationActivity = activity;
        
        [self loadArticle];
        
    }
    
}

- (void)saveRestorationActivity:(NSUserActivity * _Nonnull)activity {
    
    NSMutableDictionary *feed = @{}.mutableCopy;
    
    // Check for a selected item
    NSIndexPath *selected = self.tableView.indexPathForSelectedRow;
    
    if (selected != nil) {
        
        FeedItem *item = [self.DS itemIdentifierForIndexPath:selected];
        
        [feed setObject:item.identifier forKey:@"selectedItem"];
        
    }
    
    [activity addUserInfoEntriesFromDictionary:@{@"feed": feed}];
    
}

@end
