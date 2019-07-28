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
#import "CustomFeedVC.h"
#import "UIViewController+Hairline.h"

#import "YetiThemeKit.h"
#import "EmptyView.h"
#import "TableHeader.h"

#import "EmptyCell.h"
#import "StoreVC.h"
#import "YetiConstants.h"

#import <StoreKit/SKStoreReviewController.h>

NSString *const TopSection = @"top";
NSString *const MainSection = @"main";

static void *KVO_Bookmarks = &KVO_Bookmarks;
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
    
    if (self.headerView.tableView.indexPathForSelectedRow) {
        
        NSIndexPath *indexpath = self.headerView.tableView.indexPathForSelectedRow;
        if (indexpath.row == 0) {
            // also update unread array
            [MyFeedsManager updateUnreadArray];
        }
        
        [self dz_smoothlyDeselectRows:self.headerView.tableView];
    }
    
    if (_noPreSetup == NO) {
        _noPreSetup = YES;
        
        if (MyFeedsManager.userID) {
            [self userDidUpdate];
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
    
    if (MyFeedsManager.shouldRequestReview == YES) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [SKStoreReviewController requestReview];
            MyFeedsManager.shouldRequestReview = NO;
            MyFeedsManager.keychain[YTRequestedReview] = [@(YES) stringValue];
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
            
            [MyFeedsManager removeObserver:self forKeyPath:propSel(bookmarks) context:KVO_Bookmarks];
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
    
    [center addObserver:self selector:@selector(updateNotification:) name:FeedsDidUpdate object:MyFeedsManager];
    [center addObserver:self selector:@selector(userDidUpdate) name:UserDidUpdate object:nil];
    [center addObserver:self selector:@selector(didUpdateTheme) name:ThemeDidUpdate object:nil];
    [center addObserver:self selector:@selector(subscriptionExpired:) name:YTSubscriptionHasExpiredOrIsInvalid object:nil];
    [center addObserver:self selector:@selector(didPurchaseSubscription:) name:YTUserPurchasedSubscription object:nil];
    [center addObserver:self selector:@selector(unreadCountPreferenceChanged) name:ShowUnreadCountsPreferenceChanged object:nil];
    [center addObserver:self selector:@selector(updateNotification:) name:UIDatabaseConnectionDidUpdateNotification object:nil];
    [center addObserver:self selector:@selector(hideBookmarksPreferenceChanged) name:ShowBookmarksTabPreferenceChanged object:nil];
    
    NSKeyValueObservingOptions kvoOptions = NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld;
    
    [MyFeedsManager addObserver:self forKeyPath:propSel(bookmarks) options:kvoOptions context:KVO_Bookmarks];
    [MyFeedsManager addObserver:self forKeyPath:propSel(unread) options:kvoOptions context:KVO_Unread];
    
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
    
    if (@available(iOS 13, *)) {
        
        UITableViewDiffableDataSource *DDS = [[UITableViewDiffableDataSource alloc] initWithTableView:self.tableView cellProvider:^UITableViewCell * _Nullable(UITableView * _Nonnull tableView, NSIndexPath * _Nonnull indexPath, id _Nonnull obj) {
            
            return [self tableView:tableView cellForRowAtIndexPath:indexPath];
            
        }];
        
        self.DDS = DDS;
        
    }
    else {
        self.DS = [[DZSectionedDatasource alloc] initWithView:self.tableView];
        
        self.DS.addAnimation = UITableViewRowAnimationFade;
        self.DS.deleteAnimation = UITableViewRowAnimationFade;
        self.DS.reloadAnimation = UITableViewRowAnimationFade;
        
        DZBasicDatasource *DS1 = [[DZBasicDatasource alloc] init];
        NSArray *DS1Data = @[@"Unread"];
        
        if (PrefsManager.sharedInstance.hideBookmarks == NO) {
            DS1Data = @[@"Unread", @"Bookmarks"];
        }
        
        DS1.data = DS1Data;
        
        DZBasicDatasource *DS2 = [[DZBasicDatasource alloc] init];
        
        self.DS.datasources = @[DS1, DS2];
        self.DS1 = [self.DS.datasources firstObject];
        self.DS2 = [self.DS.datasources lastObject];
        
        self.DS.delegate = self;
    }
    
    [self setupData];
    
    if ([[[[UIApplication sharedApplication] delegate] window] traitCollection].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongTapOnCell:)];
        [self.tableView addGestureRecognizer:longPress];
    }
    else {
        // enable drag and drop on iPad
        self.tableView.dragDelegate = self;
        self.tableView.dropDelegate = self;
    }
}

- (UIBarButtonItem *)leftBarButtonItem {
    
    UIImage *settingsImage = [UIImage imageNamed:@"settings"];
    
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithImage:settingsImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapSettings)];
    settings.accessibilityLabel = @"Settings";
    settings.accessibilityHint = @"Elytra's App Settings";
    
    return settings;
    
}

- (NSArray <UIBarButtonItem *> *)rightBarButtonItems {
    
    UIImage * newFolderImage = [UIImage imageNamed:@"create_new_folder"],
            * recommendationsImage = [UIImage imageNamed:@"whatshot"],
            * newFeedImage = [UIImage imageNamed:@"new"];
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithImage:newFeedImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapAdd:)];
    add.accessibilityLabel = @"New Feed";
    add.accessibilityHint = @"Add a new RSS Feed";
    add.width = 40.f;
    
    UIBarButtonItem *folder = [[UIBarButtonItem alloc] initWithImage:newFolderImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapAddFolder:)];
    folder.accessibilityLabel = @"New Folder";
    folder.accessibilityHint = @"Create a new folder";
    folder.width = 40.f;
    
    UIBarButtonItem *recommendations = [[UIBarButtonItem alloc] initWithImage:recommendationsImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapRecommendations:)];
    recommendations.accessibilityLabel = @"Recommendations";
    recommendations.accessibilityHint = @"View RSS Feed Recommendations";
    recommendations.width = 40.f;
    
    return @[add, folder, recommendations];
    
}

- (void)setupNavigationBar {
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    UIRefreshControl *control = [[UIRefreshControl alloc] init];
    control.attributedTitle = [self lastUpdateAttributedString];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    if (@available(iOS 13, *)) {}
    else {
        if (theme.isDark) {
            control.tintColor = [theme captionColor];
        }
    }
    
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
        
        if (@available(iOS 13, *)) {}
        else {
            searchController.searchBar.keyboardAppearance = theme.isDark ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
        }
        
        searchController.searchBar.layer.borderColor = [UIColor clearColor].CGColor;
        
        CGFloat height = 1.f/[[UIScreen mainScreen] scale];
        
        if (@available(iOS 13, *)) {}
        else {
            UIView *hairline = [[UIView alloc] initWithFrame:CGRectMake(0, searchController.searchBar.bounds.size.height, searchController.searchBar.bounds.size.width, height)];
            hairline.backgroundColor = theme.cellColor;
            hairline.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
            
            [searchController.searchBar addSubview:hairline];
            self.hairlineView = hairline;
        }
        
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

- (UISelectionFeedbackGenerator *)feedbackGenerator {
    if (!_feedbackGenerator) {
        _feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        [_feedbackGenerator prepare];
    }
    
    return _feedbackGenerator;
}

- (NSDate *)sinceDate
{
    if (!_sinceDate) {
#ifdef DEBUG
        NSString *path = [@"~/Documents/feeds.since.debug.txt" stringByExpandingTildeInPath];
#else
        NSString *path = [@"~/Documents/feeds.since.txt" stringByExpandingTildeInPath];
#endif
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSError *error = nil;
            NSString *data = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];

            if (!data) {
                DDLogError(@"Failed to load since date for feeds. %@", error.localizedDescription);
            }
            else {
                NSTimeInterval timestamp = [data doubleValue];
                _sinceDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
            }
        }
    }

    return _sinceDate;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    
    id obj = nil;
    
    if (@available(iOS 13, *)) {
        obj = [self.DDS itemIdentifierForIndexPath:indexPath];
    }
    else {
        obj = [self.DS objectAtIndexPath:indexPath];
    }
    
    return obj;
    
}

- (NSUInteger)indexOfObject:(id)obj indexPath:(NSIndexPath *)outIndexPath {
    
    NSUInteger index = NSNotFound;
    NSIndexPath *indexPath = nil;
    
    if (@available(iOS 13, *)) {
        indexPath = [self.DDS indexPathForItemIdentifier:obj];
        
        if (indexPath != nil) {
            index = indexPath.row;
        }
    }
    else {
        index = [self.DS2.data indexOfObject:obj];
        if (index != NSNotFound) {
            indexPath = [NSIndexPath indexPathForRow:index inSection:1];
        }
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    FeedsCell *ocell = nil;
    
    BOOL showUnreadCounter = SharedPrefs.showUnreadCounts;
    
    if (indexPath.section == 0) {
        FeedsCell *cell = [tableView dequeueReusableCellWithIdentifier:kFeedsCell forIndexPath:indexPath];
        
        cell.titleLabel.text = [self objectAtIndexPath:indexPath];
        
        NSString *imageName = [@"l" stringByAppendingString:cell.titleLabel.text.lowercaseString];
        UIImage *image = [UIImage imageNamed:imageName];
        
        cell.faviconView.image = image;
        
        if (indexPath.row == 0) {
            
            cell.countLabel.text = formattedString(@"%@", @(MyFeedsManager.totalUnread));
        }
        else {
            
            cell.countLabel.text = formattedString(@"%@", MyFeedsManager.bookmarksCount);
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
    
    if (@available(iOS 13, *)) {}
    else {
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        ocell.faviconView.backgroundColor = theme.cellColor;
        ocell.titleLabel.backgroundColor = theme.cellColor;
        ocell.titleLabel.textColor = theme.titleColor;
        
        ocell.countLabel.backgroundColor = theme.unreadBadgeColor;
        ocell.countLabel.textColor = theme.unreadTextColor;
    }
    
    ocell.countLabel.hidden = !showUnreadCounter;
    
    return ocell;
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    BOOL isPhone = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone
                    && self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact;
    
    if (indexPath.section == 0) {
        
        DetailCustomVC *vc = [[DetailCustomVC alloc] initWithFeed:nil];
        vc.customFeed = FeedTypeCustom;
        vc.unread = indexPath.row == 0;
        
        BOOL animated = YES;
        
        // we dont want an animated push on the navigation stack
        // when the app is launched and the user wants this behavior
        if (_openingOnLaunch == YES) {
            animated = NO;
            _openingOnLaunch = NO;
        }
        
        if (isPhone) {
            [self showDetailController:vc sender:self];
        }
        else {
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
            nav.restorationIdentifier = formattedString(@"%@-nav", indexPath.row == 0 ? @"unread" : @"bookmarks");
            
            [self showDetailController:nav sender:self];
        }
        
        return;
    }
    
    Feed *feed = [self objectAtIndexPath:indexPath];
    
    if ([feed isKindOfClass:Feed.class]) {
        UIViewController *vc;
        
        if (isPhone) {
            vc = [[DetailFeedVC alloc] initWithFeed:feed];
        }
        else {
            vc = [DetailFeedVC instanceWithFeed:feed];
            [(DetailFeedVC *)[(UINavigationController *)vc topViewController] setCustomFeed:NO];
        }
        
        [self showDetailController:vc sender:self];
    }
    else {
        // it's a folder
        Folder *folder = (Folder *)feed;
        
        UIViewController *vc;
        
        if (isPhone) {
            vc = [[DetailFolderVC alloc] initWithFolder:folder];
        }
        else {
            vc = [DetailFolderVC instanceWithFolder:folder];
        }
        
        [self showDetailViewController:vc sender:self];
        
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
    
    _noPreSetup = YES;
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
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(setupData) withObject:nil waitUntilDone:NO];
        return;
    }
    
    self->_highlightedRow = nil;
    
    NSArray *data = nil;
    if (@available(iOS 13, *)) {
        data = [self.DDS.snapshot itemIdentifiersInSectionWithIdentifier:MainSection];
    }
    else {
        data = self.DS2.data;
    }
    
    // get a list of open folders
    NSArray <NSNumber *> *openFolders = [(NSArray <Folder *> *)[data rz_filter:^BOOL(id obj, NSUInteger idx, NSArray *array) {
        return [obj isKindOfClass:Folder.class] && [(Folder *)obj isExpanded];
    }] rz_map:^id(Folder *obj, NSUInteger idx, NSArray *array) {
        return obj.folderID;
    }];
    
    // ensures search bar does not dismiss on refresh or first load
    @try {
        NSArray *folders = (MyFeedsManager.folders ?: @[]);
        
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
                [data addObjectsFromArray:obj.feeds.allObjects];
            }
            
        }];
        
        [data addObjectsFromArray:MyFeedsManager.feedsWithoutFolders];
        
        if (@available(iOS 13, *)) {
            
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
            
            [self.DDS applySnapshot:snapshot animatingDifferences:YES];
            
        }
        else {
            [self.DS2 resetData];
            [self.tableView reloadData];
            
            [self.DS setData:data section:1];
        }
        
    } @catch (NSException *exc) {
        DDLogWarn(@"Exception: %@", exc);
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    weakify(self);
    
    if (context == KVO_Unread && [keyPath isEqualToString:propSel(unread)]) {
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
                
                cell.countLabel.text = [@([(FeedsManager *)object totalUnread]) stringValue];
            }
        });
    }
    else if (context == KVO_Bookmarks && [keyPath isEqualToString:propSel(bookmarks)]) {
        
       dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            FeedsCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            cell.countLabel.text = [@([[(FeedsManager *)object bookmarks] count]) stringValue];
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
    
    UICKeyChainStore *keychain = MyFeedsManager.keychain;
#if TESTFLIGHT == 1
    // during betas and for testflight builds, this option should be left on.
    id betaCheck = [keychain stringForKey:YTSubscriptionPurchased];
    BOOL betaVal = betaCheck ? [betaCheck boolValue] : NO;

    if (betaVal == YES) {
        DDLogWarn(@"Beta user has already gone through the subscription check. Ignoring.");
        return;
    }
#endif
    
    id addedFirst = [keychain stringForKey:YTSubscriptionHasAddedFirstFeed];
    BOOL addedVal = addedFirst ? [addedFirst boolValue] : NO;
    
    if (addedVal == NO) {
        DDLogWarn(@"User hasn't added their first feed yet. Ignoring.");
        return;
    }
#if TESTFLIGHT == 0
    [self subscriptionExpired:nil];
#endif
}

#pragma mark - Notifications

- (void)unreadCountPreferenceChanged {
    
    if (@available(iOS 13, *)) {
        [self setupData];
    }
    else {
        NSArray <NSIndexPath *> *visible = [self.tableView indexPathsForVisibleRows];
        
        [self.tableView reloadRowsAtIndexPaths:visible withRowAnimation:UITableViewRowAnimationFade];
    }
    
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
    
    if (@available(iOS 13, *)) {}
    else {
        if (self.hairlineView != nil) {
            self.hairlineView.backgroundColor = theme.cellColor;
            [self.hairlineView setNeedsDisplay];
        }
    }
    
    [[self.headerView tableView] reloadData];
    if (@available(iOS 13, *)) {}
    else {
        self.navigationItem.searchController.searchBar.keyboardAppearance = theme.isDark ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    }
    
    [self.tableView reloadData];
    
}

- (void)updateNotification:(NSNotification *)note {
    
    [self setupData];
    
}

- (void)userDidUpdate {
    
    // this function can be called multiple times
    // beginning 1.0.2
    
    if (MyFeedsManager.userID == nil || [MyFeedsManager.userID isEqualToNumber:@(0)]) {
        return;
    }
    
    weakify(self);
    
    BOOL userUpdatedButWeHaveData = YES;
    
    if (@available(iOS 13, *)) {
        if ([self.DDS.snapshot numberOfItemsInSection:MainSection] == 0) {
            userUpdatedButWeHaveData = NO;
        }
    }
    else {
        if (self.DS2.data == nil || self.DS2.data.count == 0) {
            userUpdatedButWeHaveData = NO;
        }
    }
    
    if (userUpdatedButWeHaveData == NO) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            asyncMain(^{
                strongify(self);
                [self beginRefreshing:self.refreshControl];
            });
        });
    }
    
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
    if (MyFeedsManager.keychain[YTSubscriptionHasAddedFirstFeed] == nil) {
        return;
    }
#if TESTFLIGHT == 0
    StoreVC *vc = [[StoreVC alloc] initWithStyle:UITableViewStyleGrouped];
    
    if (@available(iOS 13, *)) {
        vc.modalInPresentation = YES;
    }
    
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
        [self.splitViewController presentViewController:nav animated:YES completion:nil];
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
    
    __block Folder * actionableFolder = folder;
 
    NSIndexPath *indexPath = nil;
    __block NSUInteger index = [self indexOfObject:folder indexPath:indexPath];
    
    if (index == NSNotFound) {
        DDLogDebug(@"The folder:%@-%@ was not found in the Datasource", folder.folderID, folder.title);
        return;
    }
    
    CGPoint contentOffset = self.tableView.contentOffset;
    
    if (@available(iOS 13, *)) {
        
        if (indexPath == nil) {
            indexPath = [NSIndexPath indexPathForRow:index inSection:1];
        }
        
        Folder *folderFromDS = [self.DDS itemIdentifierForIndexPath:indexPath];
        
        folderFromDS.expanded = folderFromDS.isExpanded ? NO : YES;
        
        [self setupData];
    }
    else {
        if (actionableFolder.isExpanded) {
            
            DDLogDebug(@"Closing index: %@", @(index));
            actionableFolder.expanded = NO;
            
            // remove these feeds from the datasource
            NSArray *data = [self.DS2.data rz_filter:^BOOL(id obj, NSUInteger idx, NSArray *array) {
                
                if ([obj isKindOfClass:Folder.class])
                    return YES;
                
                if ([(Feed *)obj folderID] && [[obj folderID] isEqualToNumber:actionableFolder.folderID]) {
                    return NO;
                }
                
                return YES;
                
            }];
            
            [self.DS setData:data section:1];
            
        }
        else {
            actionableFolder.expanded = YES;
            DDLogDebug(@"Opening index: %@", @(index));
            
            // add these feeds to the datasource after the above index
            NSMutableArray * data = [self.DS2.data mutableCopy];
            
            // data shouldn't contain any object with this folder ID
            data = [data rz_filter:^BOOL(id obj, NSUInteger idx, NSArray *array) {
                if ([obj isKindOfClass:Feed.class]) {
                    Feed *feed = obj;
                    if ([feed.folderID isEqualToNumber:actionableFolder.folderID]) {
                        return NO;
                    }
                }
                
                return YES;
            }].mutableCopy;
            
            NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index+1, actionableFolder.feeds.allObjects.count)];
            
            [data insertObjects:actionableFolder.feeds.allObjects atIndexes:set];
            
            @try {
                [self.DS setData:data section:1];
            }
            @catch (NSException *exc) {
                DDLogWarn(@"Exception updating feeds: %@", exc);
            }
            
        }
    }
    
    [self.feedbackGenerator selectionChanged];
    [self.feedbackGenerator prepare];
    
    UIImage *image = nil;
    
    image = [[UIImage imageNamed:([folder isExpanded] ? @"folder_open" : @"folder")] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    cell.faviconView.image = image;
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        [self.tableView.layer removeAllAnimations];
        [self.tableView setContentOffset:contentOffset animated:NO];
    });
    
}

@end
