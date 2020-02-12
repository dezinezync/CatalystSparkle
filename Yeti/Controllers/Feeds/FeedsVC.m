//
//  FeedsVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Actions.h"
#import "FeedsManager.h"
#import "FeedsCell.h"
#import "FolderCell.h"
#import "DetailFeedVC.h"
#import "DetailCustomVC.h"
#import "DetailFolderVC.h"

#import <DZKit/DZBasicDatasource.h>

#import <DZKit/EFNavController.h>
#import <DZKit/UIViewController+AnimatedDeselect.h>
#import <DZKit/AlertManager.h>

#import "FeedsSearchResults.h"
#import "UIViewController+Hairline.h"

#import "YetiThemeKit.h"
#import "EmptyView.h"
#import "TableHeader.h"

#import "EmptyCell.h"
#import "StoreVC.h"
#import "YetiConstants.h"
#import "Keychain.h"

#import <StoreKit/SKStoreReviewController.h>
#import "SplitVC.h"

static void *KVO_Unread = &KVO_Unread;

@interface FeedsVC () <DZSDatasource, UIViewControllerRestoration, FolderInteractionDelegate> {
    BOOL _setupObservors;
    
    BOOL _openingOnLaunch;
    
    BOOL _hasSetupTable;
}

@property (nonatomic, strong, readwrite) DZSectionedDatasource *DS;
@property (nonatomic, weak, readwrite) DZBasicDatasource *DS1, *DS2;
@property (nonatomic, weak) UIView *hairlineView;

@property (nonatomic, strong) UISelectionFeedbackGenerator *feedbackGenerator;

@end

@implementation FeedsVC

- (instancetype)initWithStyle:(UITableViewStyle)style {
    if (self = [super initWithStyle:style]) {
        self.restorationIdentifier = NSStringFromClass(self.class);
    }
    
    return self;
}

- (BOOL)ef_hidesNavBorder {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Feeds";
    
    [self setupTableView];
    [self setupNavigationBar];
    
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    
    [self setupObservors];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setupTableView];
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    if (self.tableView.indexPathForSelectedRow) {
        [self dz_smoothlyDeselectRows:self.tableView];
    }
    
    if (_noPreSetup == NO) {
        _noPreSetup = YES;
        
        if (MyFeedsManager.userID) {
            [self userDidUpdate:NO];
        }
        
        BOOL pref = [[NSUserDefaults standardUserDefaults] boolForKey:kOpenUnreadOnLaunch];
        
        if (pref) {
            _openingOnLaunch = YES;
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        }
    }
    
    if (PrefsManager.sharedInstance.useToolbar == YES) {
        self.additionalSafeAreaInsets = UIEdgeInsetsMake(0, 0, 10.f, 0);
    }
    else {
        self.additionalSafeAreaInsets = UIEdgeInsetsZero;
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self setupTableView];
    
    [self becomeFirstResponder];
    
    if (MyFeedsManager.shouldRequestReview == YES) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SKStoreReviewController requestReview];
            MyFeedsManager.shouldRequestReview = NO;
            [Keychain add:YTRequestedReview boolean:YES];
        });
    }
}

- (BOOL)definesPresentationContext
{
    return YES;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    if (_setupObservors == YES && MyFeedsManager.observationInfo != nil) {
        
        NSArray *observingObjects = [(id)(MyFeedsManager.observationInfo) valueForKeyPath:@"_observances"];
        observingObjects = [observingObjects rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [obj valueForKeyPath:@"observer"];
        }];
        
        @try {

            [MyFeedsManager removeObserver:self forKeyPath:propSel(unread) context:KVO_Unread];
            
        }
        @catch (NSException * exc) {}
        
    }
}

- (void)setupObservors {
    
    if (_setupObservors == YES) {
        return;
    }
    
    _setupObservors = YES;
    
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    
    [center addObserver:self selector:@selector(updateNotification:) name:FeedsDidUpdate object:ArticlesManager.shared];
    [center addObserver:self selector:@selector(userDidUpdate) name:UserDidUpdate object:nil];
//    [center addObserver:self selector:@selector(didUpdateTheme) name:ThemeDidUpdate object:nil];
    [center addObserver:self selector:@selector(subscriptionExpired:) name:YTSubscriptionHasExpiredOrIsInvalid object:nil];
    [center addObserver:self selector:@selector(didPurchaseSubscription:) name:YTUserPurchasedSubscription object:nil];
    [center addObserver:self selector:@selector(unreadCountPreferenceChanged) name:ShowUnreadCountsPreferenceChanged object:nil];
    [center addObserver:self selector:@selector(updateNotification:) name:UIDatabaseConnectionDidUpdateNotification object:nil];
    [center addObserver:self selector:@selector(hideBookmarksPreferenceChanged) name:ShowBookmarksTabPreferenceChanged object:nil];
    
    NSKeyValueObservingOptions kvoOptions = NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld;

    [MyFeedsManager addObserver:self forKeyPath:propSel(totalUnread) options:kvoOptions context:KVO_Unread];
    
}

#pragma mark - Setups

- (void)setupTableView {
    
    if (_hasSetupTable == YES) {
        return;
    }
    
//    if (self.tableView.window == nil) {
//        return;
//    }
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setupTableView) withObject:nil waitUntilDone:NO];
        return;
    }
    
    _hasSetupTable = YES;
    
    self.tableView.restorationIdentifier = self.restorationIdentifier;
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(EmptyCell.class) bundle:nil] forCellReuseIdentifier:kEmptyCell];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FeedsCell.class) bundle:nil] forCellReuseIdentifier:kFeedsCell];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FolderCell.class) bundle:nil] forCellReuseIdentifier:kFolderCell];
    
    self.tableView.tableFooterView = [UIView new];
    
    UITableViewDiffableDataSource *DDS = [[UITableViewDiffableDataSource alloc] initWithTableView:self.tableView cellProvider:^UITableViewCell * _Nullable(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath, id _Nonnull obj) {
        
        FeedsCell *ocell = nil;
        
        BOOL showUnreadCounter = SharedPrefs.showUnreadCounts;
        
        if (indexPath.section == 0) {
            FeedsCell *cell = [tableView dequeueReusableCellWithIdentifier:kFeedsCell forIndexPath:indexPath];
            
            cell.titleLabel.text = [self objectAtIndexPath:indexPath];
            
            NSString *imageName = nil;
            UIColor *tintColor = nil;
            
            if (indexPath.row == 0) {
                imageName = @"largecircle.fill.circle";
                tintColor = UIColor.systemBlueColor;
            }
            else if (indexPath.row == 1) {
                imageName = @"bookmark.fill";
                tintColor = UIColor.systemOrangeColor;
            }
            else {
                imageName = @"calendar";
                tintColor = UIColor.systemRedColor;
            }
            
            UIImage *image = [[UIImage systemImageNamed:imageName] imageWithTintColor:tintColor renderingMode:UIImageRenderingModeAlwaysTemplate];
            
            cell.faviconView.image = image;
            cell.faviconView.tintColor = tintColor;
            
            if (indexPath.row == 0) {
                cell.countLabel.text = formattedString(@"%@", @(MyFeedsManager.totalUnread));
            }
            else {
                cell.countLabel.text = formattedString(@"%@", @(self.bookmarksManager.bookmarksCount));
            }
            
            ocell = cell;
            
        }
        else {
            
            // Configure the cell...
            id obj = [self objectAtIndexPath:indexPath];
            if (obj) {
                if ([obj isKindOfClass:Feed.class]) {
                    FeedsCell *cell = [tableView dequeueReusableCellWithIdentifier:kFeedsCell forIndexPath:indexPath];
                    [cell configure:obj];
                    
                    ocell = cell;
                }
                else {
                    // folder
                    FolderCell *cell = [tableView dequeueReusableCellWithIdentifier:kFolderCell forIndexPath:indexPath];
                    [(FolderCell *)cell configureFolder:(Folder *)obj dropDelegate:self];
                    cell.interactionDelegate = self;
                    ocell = (FeedsCell *)cell;
                }
            }
        }
        
        ocell.countLabel.hidden = !showUnreadCounter;
        
        return ocell;
        
    }];
    
    self.DDS = DDS;
    
//    [self setupData];

    // @TODO this is not tested on iOS 13
    
//    if ([[[[UIApplication sharedApplication] delegate] window] traitCollection].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
//        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongTapOnCell:)];
//        [self.tableView addGestureRecognizer:longPress];
//    }
//    else {
//        // enable drag and drop on iPad
//        // crashes on iOS 13 Beta 5
//        self.tableView.dragDelegate = self;
//        self.tableView.dropDelegate = self;
//    }
}

- (UIBarButtonItem *)leftBarButtonItem {
    
    UIImage *settingsImage = [UIImage systemImageNamed:@"gear"];
    
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithImage:settingsImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapSettings)];
    settings.accessibilityLabel = @"Settings";
    settings.accessibilityHint = @"Elytra's App Settings";
    
    return settings;
    
}

- (NSArray <UIBarButtonItem *> *)rightBarButtonItems {
    
    UIImage * newFolderImage = [UIImage systemImageNamed:@"folder.badge.plus"],
            * recommendationsImage = [UIImage systemImageNamed:@"flame"],
            * newFeedImage = [UIImage systemImageNamed:@"plus"];
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithImage:newFeedImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapAdd:)];
    add.accessibilityLabel = @"New Feed";
    add.accessibilityHint = @"Add a new RSS Feed";
    // add.width = 40.f;
    
    UIBarButtonItem *folder = [[UIBarButtonItem alloc] initWithImage:newFolderImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapAddFolder:)];
    folder.accessibilityLabel = @"New Folder";
    folder.accessibilityHint = @"Create a new folder";
    // folder.width = 40.f;
    
    UIBarButtonItem *recommendations = [[UIBarButtonItem alloc] initWithImage:recommendationsImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapRecommendations:)];
    recommendations.accessibilityLabel = @"Recommendations";
    recommendations.accessibilityHint = @"View RSS Feed Recommendations";
    // recommendations.width = 40.f;
    
    return @[add, folder, recommendations];
    
}

- (void)setupNavigationBar {
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    UIRefreshControl *control = [[UIRefreshControl alloc] init];
    control.attributedTitle = [self lastUpdateAttributedString];
    
    [control addTarget:self action:@selector(beginRefreshing:) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView addSubview:control];
    self.refreshControl = control;
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.navigationController.navigationBar.translucent = NO;
    
    // Search Controller setup
    {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
        
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:[[FeedsSearchResults alloc] initWithStyle:UITableViewStylePlain]];
        searchController.searchResultsUpdater = self;
        searchController.searchBar.placeholder = @"Search Feeds";
        searchController.searchBar.accessibilityHint = @"Search your feeds";
        
        searchController.searchBar.layer.borderColor = [UIColor clearColor].CGColor;
        
        self.navigationItem.searchController = searchController;
    }
    
    {
        [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    }
    
    if (PrefsManager.sharedInstance.useToolbar == NO) {
        self.navigationItem.rightBarButtonItems = self.rightBarButtonItems;
        self.navigationItem.leftBarButtonItem = self.leftBarButtonItem;
        
        self.navigationController.toolbarHidden = YES;
    }
    else {
        self.navigationController.toolbarHidden = NO;
    }
    
}

- (NSArray <UIBarButtonItem *> *)toolbarItems {
    
    if (PrefsManager.sharedInstance.useToolbar == NO) {
        return nil;
    }
    
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixed.width = 24.f;
    
    NSArray *right = [[self.rightBarButtonItems rz_map:^id(UIBarButtonItem *obj, NSUInteger idx, NSArray *array) {
        
        if (idx == 0) {
            return obj;
        }
        
        return @[flex, obj];
        
    }] rz_flatten];
    
    return [@[self.leftBarButtonItem, flex] arrayByAddingObjectsFromArray:right];
}

#pragma mark - Setters

- (void)setSinceDate:(NSDate *)sinceDate
{
    _sinceDate = sinceDate;
    
    if (_sinceDate) {
        NSString *path;
#ifdef DEBUG
        path = [@"~/Documents/feeds.since.debug.txt" stringByExpandingTildeInPath];
#else
        path = [@"~/Documents/feeds.since.txt" stringByExpandingTildeInPath];
#endif
        NSNumber *timestamp = @([_sinceDate timeIntervalSince1970]);
        
        NSString *data = formattedString(@"%@", timestamp);
        NSError *error = nil;
        if (![data writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            DDLogError(@"Failed to save since date for feeds. %@", error.localizedDescription);
        }
    }
    
}

#pragma mark - Getters

- (BookmarksManager *)bookmarksManager {
    
    if (_bookmarksManager == nil) {
        _bookmarksManager = [BookmarksManager new];
        
        MyFeedsManager.bookmarksManager = _bookmarksManager;
        
        weakify(self);
        
        [_bookmarksManager addObserver:self name:BookmarksDidUpdateNotification callback:^{
            strongify(self);
            [self didUpdateBookmarks];
        }];
        
//        [self didUpdateBookmarks];
        
    }
    
    return _bookmarksManager;
    
}

- (UISelectionFeedbackGenerator *)feedbackGenerator {
    if (!_feedbackGenerator) {
        _feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        [_feedbackGenerator prepare];
    }
    
    return _feedbackGenerator;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    
    id obj = [self.DDS itemIdentifierForIndexPath:indexPath];
    
    return obj;
    
}

- (NSUInteger)indexOfObject:(id)obj indexPath:(NSIndexPath *)outIndexPath {
    
    NSUInteger index = NSNotFound;
    NSIndexPath *indexPath = [self.DDS indexPathForItemIdentifier:obj];
    
    if (indexPath != nil) {
        index = indexPath.row;
    }
    
    outIndexPath = [indexPath copy];
    
    return index;
    
}

#pragma mark - Table view data source

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    TableHeader *view = [[TableHeader alloc] initWithNib];
    
    if (section == 0) {
        view.label.text = [@"Smart Feeds" uppercaseString];
    }
    else {
        view.label.text =  [@"Subscriptions" uppercaseString];
    }
    
    return view;
    
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    BOOL isPhone = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone
                    && self.to_splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    
    if (indexPath.section == 0) {
        
        DetailCustomVC *vc = [[DetailCustomVC alloc] initWithFeed:nil];
        vc.customFeed = FeedTypeCustom;
        vc.bookmarksManager = self.bookmarksManager;
        vc.unread = indexPath.row == 0;
        
        BOOL animated = YES;
        
        // we dont want an animated push on the navigation stack
        // when the app is launched and the user wants this behavior
        if (_openingOnLaunch == YES) {
            animated = NO;
            _openingOnLaunch = NO;
        }
        
        if (isPhone) {
            [self to_showSecondaryViewController:vc sender:self];
        }
        else {
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            nav.restorationIdentifier = formattedString(@"%@-nav", indexPath.row == 0 ? @"unread" : @"bookmarks");
            
            [self to_showSecondaryViewController:nav setDetailViewController:[(SplitVC *)[self to_splitViewController] emptyVC] sender:self];
        }
        
        return;
    }
    
    Feed *feed = [self objectAtIndexPath:indexPath];
    
    if ([feed isKindOfClass:Feed.class]) {
        UIViewController *vc;
        
        if (isPhone) {
            vc = [[DetailFeedVC alloc] initWithFeed:feed];
            [(DetailFeedVC *)vc setBookmarksManager:self.bookmarksManager];
            
            [self to_showSecondaryViewController:vc sender:self];
        }
        else {
            vc = [DetailFeedVC instanceWithFeed:feed];
            
            [(DetailFeedVC *)[(UINavigationController *)vc topViewController] setCustomFeed:NO];
            [(DetailFeedVC *)[(UINavigationController *)vc topViewController] setBookmarksManager:self.bookmarksManager];
            
            [self to_showSecondaryViewController:vc setDetailViewController:[(SplitVC *)[self to_splitViewController] emptyVC] sender:self];
        }
        
    }
    else {
        // it's a folder
        Folder *folder = (Folder *)feed;
        
        UIViewController *vc;
        
        if (isPhone) {
            vc = [[DetailFolderVC alloc] initWithFolder:folder];
            [(DetailFeedVC *)vc setBookmarksManager:self.bookmarksManager];
            
            [self to_showSecondaryViewController:vc sender:self];
        }
        else {
            vc = [DetailFolderVC instanceWithFolder:folder];
            
            [(DetailFeedVC *)[(UINavigationController *)vc topViewController] setCustomFeed:NO];
            [(DetailFeedVC *)[(UINavigationController *)vc topViewController] setBookmarksManager:self.bookmarksManager];
            
            [self to_showSecondaryViewController:vc setDetailViewController:[(SplitVC *)[self to_splitViewController] emptyVC] sender:self];
        }
        
    }
    
}

#pragma mark - Restoration

NSString * const kDS2Data = @"DS2Data";

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    return [[FeedsVC alloc] initWithStyle:UITableViewStyleGrouped];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
     DDLogDebug(@"Encoding restoration: %@", self.restorationIdentifier);
    
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    DDLogDebug(@"Decoding restoration: %@", self.restorationIdentifier);
    
    [super decodeRestorableStateWithCoder:coder];
    
    _noPreSetup = NO;
    _hasSetupTable = NO;
}

#pragma mark - Data

- (UIView *)viewForEmptyDataset {
    
    EmptyView *view = [[EmptyView alloc] initWithNib];
    view.imageView.image = [UIImage imageNamed:@"feeds-empty"];
    view.label.text = self.refreshControl.isRefreshing ? @"Loading your subscriptions" : @"Get started by adding a RSS Subscription.";
    [view.label sizeToFit];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    view.label.textColor = theme.subtitleColor;
    view.backgroundColor = theme.tableColor;
    
    return view;
}

//- (UITableViewCell *)rowForEmptySection:(NSInteger)section {
//    
//    if (section == 1) {
//        EmptyCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kEmptyCell forIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
//        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
//        
//        cell.backgroundColor = theme.cellColor;
//        cell.activityIndicator.color = theme.isDark ? [UIColor lightGrayColor] : [UIColor darkGrayColor];
//        
//        return cell;
//    }
//    
//    return nil;
//    
//}

- (void)setupData {
    
    if (self->_presentingKnown == YES) {
        return;
    }
    
    BOOL presentingSelf = (self.navigationController.topViewController == self) || self.presentedViewController == nil;
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(setupData) withObject:nil waitUntilDone:NO];
        return;
    }
    
    self->_highlightedRow = nil;
    
    NSArray *data = [self.DDS.snapshot itemIdentifiersInSectionWithIdentifier:MainSection];
    
    // get a list of open folders
    NSArray <NSNumber *> *openFolders = [(NSArray <Folder *> *)[data rz_filter:^BOOL(id obj, NSUInteger idx, NSArray *array) {

        return [obj isKindOfClass:Folder.class] && [(Folder *)obj isExpanded];

    }] rz_map:^id(Folder *obj, NSUInteger idx, NSArray *array) {

        return obj.folderID;

    }];
    
    // ensures search bar does not dismiss on refresh or first load
    @try {
        NSArray *folders = (ArticlesManager.shared.folders ?: @[]);
        
        NSSortDescriptor *alphaSort = [NSSortDescriptor sortDescriptorWithKey:@"displayTitle" ascending:YES];
        
        if (openFolders.count) {
            [folders enumerateObjectsUsingBlock:^(Folder * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([openFolders containsObject:obj.folderID]) {
                    obj.expanded = YES;
                }
            }];
        }
        
        NSMutableArray *data = @[].mutableCopy;
        
        [folders enumerateObjectsUsingBlock:^(Folder *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [data addObject:obj];
            
            if (obj.isExpanded) {
                
                NSArray <Feed *> *feeds = obj.feeds.allObjects;
                
                feeds = [feeds sortedArrayUsingDescriptors:@[alphaSort]];
                
                [data addObjectsFromArray:feeds];
            }
            
        }];
        
        [data addObjectsFromArray:[ArticlesManager.shared.feedsWithoutFolders sortedArrayUsingDescriptors:@[alphaSort]]];
        
        NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
        [snapshot appendSectionsWithIdentifiers:@[TopSection, MainSection]];
        
        BOOL pref = [[NSUserDefaults standardUserDefaults] boolForKey:kHideBookmarksTab];
        
        if (pref) {
            [snapshot appendItemsWithIdentifiers:@[@"Unread"] intoSectionWithIdentifier:TopSection];
        }
        else {
            [snapshot appendItemsWithIdentifiers:@[@"Unread", @"Bookmarks"] intoSectionWithIdentifier:TopSection];
        }
        
        [snapshot appendItemsWithIdentifiers:data intoSectionWithIdentifier:MainSection];
        
        [self.DDS applySnapshot:snapshot animatingDifferences:presentingSelf];
        
        if (presentingSelf == YES) {
            FeedsCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            if (cell != nil) {
                cell.countLabel.text = @(MyFeedsManager.totalUnread).stringValue;
            }
        }
        
    } @catch (NSException *exc) {
        DDLogWarn(@"Exception: %@", exc);
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    weakify(self);
    
    if (context == KVO_Unread && [keyPath isEqualToString:propSel(totalUnread)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            
            NSArray <NSIndexPath *> *indexPaths = [self.tableView indexPathsForVisibleRows];
            
            BOOL visible = NO;
            
            for (NSIndexPath *ip in indexPaths) {
                if (ip.section == indexPath.section && ip.row == indexPath.row) {
                    visible = YES;
                    break;
                }
            }
            
            if (visible) {
                FeedsCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                
                cell.countLabel.text = [@([MyFeedsManager totalUnread]) stringValue];
            }
        });
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Subscription Handler

- (void)showSubscriptionsInterface {
    
#if TARGET_OS_SIMULATOR
//    return;
#endif
    
    if (NSThread.isMainThread == NO) {
        weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            [self showSubscriptionsInterface];
        });
        return;
    }
    
    if (self.presentedViewController != nil) {
        DDLogWarn(@"FeedsVC is already presenting a viewController. Not showing the subscriptions interface.");
        return;
    }
    
#if TESTFLIGHT == 1
    // during betas and for testflight builds, this option should be left on.
    BOOL betaVal = [Keychain boolFor:YTSubscriptionPurchased error:nil];

    if (betaVal == YES) {
        DDLogWarn(@"Beta user has already gone through the subscription check. Ignoring.");
        return;
    }
#endif
    
    BOOL addedVal = [Keychain boolFor:YTSubscriptionHasAddedFirstFeed error:nil];
    
    if (addedVal == NO) {
        DDLogWarn(@"User hasn't added their first feed yet. Ignoring.");
        return;
    }
#if TESTFLIGHT == 0
    [self subscriptionExpired:nil];
#endif
}

#pragma mark - Notifications

- (void)didUpdateBookmarks {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(didUpdateBookmarks) withObject:nil waitUntilDone:NO];
        return;
    }
    
    NSArray <NSIndexPath *> *visible = [self.tableView indexPathsForVisibleRows];
    
    for (NSIndexPath *indexpath in visible) {
        // check if the bookmarks row is visible
        if (indexpath.section == 0 && indexpath.row == 1) {
            
            FeedsCell *cell = (FeedsCell *)[self tableView:self.tableView cellForRowAtIndexPath:indexpath];
            
            if (cell != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    cell.countLabel.text = @(self.bookmarksManager.bookmarksCount).stringValue;
                    [cell.countLabel sizeToFit];
                    [cell setNeedsDisplay];
                    
                });
            }
            
            break;
            
        }
        
    }
    
}

- (void)unreadCountPreferenceChanged {
    
    [self setupData];
    
}

- (void)hideBookmarksPreferenceChanged {
    
    [self setupData];
    
}

- (void)didUpdateTheme {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(didUpdateTheme) withObject:nil waitUntilDone:NO];
        return;
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.refreshControl.tintColor = [theme captionColor];
    
    [self.tableView reloadData];
    
}

- (void)updateNotification:(NSNotification *)note {
    
    [self setupData];
    
}

- (void)userDidUpdate {
    
    [MyFeedsManager syncSettings];
    
    [self userDidUpdate:YES];
    
}

- (void)userDidUpdate:(BOOL)resetBookmarksManager {
    
    // this function can be called multiple times
    // beginning 1.0.2
    
    if (MyFeedsManager.userID == nil || [MyFeedsManager.userID isEqualToNumber:@(0)]) {
        return;
    }
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        strongify(self);
        
        BOOL userUpdatedButWeHaveData = YES;
        
        if (self.DDS != nil && self.DDS.snapshot != nil && ([self.DDS.snapshot numberOfSections] == 1 || [self.DDS.snapshot numberOfItemsInSection:MainSection] == 0)) {
            userUpdatedButWeHaveData = NO;
        }
        
        if (userUpdatedButWeHaveData == NO) {
            [self beginRefreshing:self.refreshControl];
        }
        
    });
    
    if (MyFeedsManager.subscription == nil) {
        [MyFeedsManager getSubscriptionWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            
            if (MyFeedsManager.subscription == nil) {
                [self showSubscriptionsInterface];
                return;
            }
            
            if ([MyFeedsManager.subscription hasExpired]) {
                [self showSubscriptionsInterface];
                return;
            }
            
            DDLogDebug(@"Get Subscription: %@", MyFeedsManager.subscription.expiry);
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            DDLogDebug(@"Get Subscription: %@", MyFeedsManager.subscription.error.localizedDescription);
            
            if ([MyFeedsManager.subscription hasExpired]) {
                [self showSubscriptionsInterface];
                return;
            }
            
        }];
    }
    
}

- (void)subscriptionExpired:(NSNotification *)note {
    
    // dont run when the app is in the background or inactive
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
        return;
    }
    
    // if we're already presenting a VC, don't run.
    // this is most likely the onboarding process
    if (self.presentedViewController != nil) {
        return;
    }
    
    // if the user hasn't added their first feed,
    // dont run
    if ([Keychain boolFor:YTSubscriptionHasAddedFirstFeed error:nil]) {
        return;
    }
#if TESTFLIGHT == 0
    StoreVC *vc = [[StoreVC alloc] initWithStyle:UITableViewStyleGrouped];
    
    vc.modalInPresentation = YES;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:vc action:@selector(didTapDone:)];
    
    vc.navigationItem.rightBarButtonItem = done;
    
//    storeVC.checkAndShowError = YES;
    
    [self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
       
        obj.enabled = NO;
        
    }];
    
    weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        [self.to_splitViewController presentViewController:nav animated:YES completion:nil];
    });
#endif
}

- (void)didPurchaseSubscription:(NSNotification *)note {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(didPurchaseSubscription:) withObject:note waitUntilDone:NO];
        return;
    }
    
    [self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.isEnabled == NO) {
            obj.enabled = YES;
        }
        
    }];
    
}

#pragma mark - <FolderInteractionDelegate>

- (void)didTapFolderIcon:(Folder *)folder cell:(FolderCell *)cell {
    
    NSIndexPath *indexPath = nil;
    __block NSUInteger index = [self indexOfObject:folder indexPath:indexPath];
    
    if (index == NSNotFound) {
        DDLogDebug(@"The folder:%@-%@ was not found in the Datasource", folder.folderID, folder.title);
        return;
    }
    
    CGPoint contentOffset = self.tableView.contentOffset;
    
    if (indexPath == nil) {
        indexPath = [NSIndexPath indexPathForRow:index inSection:1];
    }
    
    Folder *folderFromDS = [self.DDS itemIdentifierForIndexPath:indexPath];
    
    folderFromDS.expanded = folderFromDS.isExpanded ? NO : YES;
    
    [self setupData];
    
    [self.feedbackGenerator selectionChanged];
    [self.feedbackGenerator prepare];
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
            
        UIImage *image = [[UIImage systemImageNamed:([folder isExpanded] ? @"folder" : @"folder.fill")] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        cell.faviconView.image = image;
        
        [cell.faviconView setNeedsDisplay];
        [cell setNeedsDisplay];
        
        [self.tableView.layer removeAllAnimations];
        [self.tableView setContentOffset:contentOffset animated:NO];
    });
    
}

@end
