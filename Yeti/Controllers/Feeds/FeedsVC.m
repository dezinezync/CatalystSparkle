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
#import "FeedVC.h"
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

static void *KVO_Bookmarks = &KVO_Bookmarks;
static void *KVO_Unread = &KVO_Unread;

@interface FeedsVC () <DZSDatasource, UIViewControllerRestoration, FolderInteractionDelegate> {
    BOOL _setupObservors;
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
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
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
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
    
    NSKeyValueObservingOptions kvoOptions = NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld;
    
    [MyFeedsManager addObserver:self forKeyPath:propSel(bookmarks) options:kvoOptions context:KVO_Bookmarks];
    [MyFeedsManager addObserver:self forKeyPath:propSel(unread) options:kvoOptions context:KVO_Unread];
    
}

#pragma mark - Setups

- (void)setupTableView {
    
    self.tableView.restorationIdentifier = self.restorationIdentifier;
    
    self.DS = [[DZSectionedDatasource alloc] initWithView:self.tableView];
    
    self.DS.addAnimation = UITableViewRowAnimationFade;
    self.DS.deleteAnimation = UITableViewRowAnimationFade;
    self.DS.reloadAnimation = UITableViewRowAnimationFade;
    
    DZBasicDatasource *DS1 = [[DZBasicDatasource alloc] init];
    DS1.data = @[@"Unread", @"Bookmarks"];
    
    DZBasicDatasource *DS2 = [[DZBasicDatasource alloc] init];
    
    self.DS.datasources = @[DS1, DS2];
    self.DS1 = [self.DS.datasources firstObject];
    self.DS2 = [self.DS.datasources lastObject];
    
    self.DS.delegate = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(EmptyCell.class) bundle:nil] forCellReuseIdentifier:kEmptyCell];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FeedsCell.class) bundle:nil] forCellReuseIdentifier:kFeedsCell];
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FolderCell.class) bundle:nil] forCellReuseIdentifier:kFolderCell];
    
    self.tableView.tableFooterView = [UIView new];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
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

- (void)setupNavigationBar {
    
    UIRefreshControl *control = [[UIRefreshControl alloc] init];
    control.attributedTitle = [self lastUpdateAttributedString];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    if (theme.isDark) {
        control.tintColor = [theme captionColor];
    }
    
    [control addTarget:self action:@selector(beginRefreshing:) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView addSubview:control];
    self.refreshControl = control;
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didTapAdd:)];
    add.accessibilityLabel = @"New Feed";
    add.accessibilityHint = @"Add a new RSS Feed";
    
    UIBarButtonItem *folder = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"create_new_folder"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapAddFolder:)];
    folder.accessibilityLabel = @"New Folder";
    folder.accessibilityHint = @"Create a new folder";
    
    UIBarButtonItem *recommendations = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whatshot"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapRecommendations:)];
    recommendations.accessibilityLabel = @"Recommendations";
    recommendations.accessibilityHint = @"View RSS Feed Recommendations";
    
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapSettings)];
    settings.accessibilityLabel = @"Settings";
    settings.accessibilityHint = @"Elytra's App Settings";
    
    self.navigationItem.rightBarButtonItems = @[add, folder, recommendations];
    self.navigationItem.leftBarButtonItem = settings;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    self.navigationController.navigationBar.translucent = NO;
    
    // Search Controller setup
    {
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
        
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:[[FeedsSearchResults alloc] initWithStyle:UITableViewStylePlain]];
        searchController.searchResultsUpdater = self;
        searchController.searchBar.placeholder = @"Search Feeds";
        searchController.searchBar.accessibilityHint = @"Search your feeds";
        searchController.searchBar.keyboardAppearance = theme.isDark ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
        
        searchController.searchBar.layer.borderColor = [UIColor clearColor].CGColor;
        
        CGFloat height = 1.f/[[UIScreen mainScreen] scale];
        UIView *hairline = [[UIView alloc] initWithFrame:CGRectMake(0, searchController.searchBar.bounds.size.height, searchController.searchBar.bounds.size.width, height)];
        hairline.backgroundColor = theme.cellColor;
        hairline.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
        
        [searchController.searchBar addSubview:hairline];
        self.hairlineView = hairline;
        
        self.navigationItem.searchController = searchController;
    }
    
    {
        [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    }
    
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
    
    BOOL showUnreadCounter = [[NSUserDefaults standardUserDefaults] boolForKey:kShowUnreadCounts];
    
    if (indexPath.section == 0) {
        FeedsCell *cell = [tableView dequeueReusableCellWithIdentifier:kFeedsCell forIndexPath:indexPath];
        
        cell.titleLabel.text = [self.DS objectAtIndexPath:indexPath];
        
        NSString *imageName = [@"l" stringByAppendingString:cell.titleLabel.text.lowercaseString];
        cell.faviconView.image = [UIImage imageNamed:imageName];
        
        if (indexPath.row == 0) {
            cell.countLabel.text = formattedString(@"%@", @(MyFeedsManager.totalUnread));
        }
        else {
            cell.countLabel.text = formattedString(@"%@", MyFeedsManager.bookmarksCount);
        }
        
        ocell = cell;
        
    }
    else {
        
        if (!self.DS2.data.count) {
            return [self rowForEmptySection:indexPath.section];
        }
        
        // Configure the cell...
        id obj = [self.DS objectAtIndexPath:indexPath];
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
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    ocell.faviconView.backgroundColor = theme.cellColor;
    ocell.titleLabel.backgroundColor = theme.cellColor;
    ocell.titleLabel.textColor = theme.titleColor;
    
    ocell.countLabel.backgroundColor = theme.unreadBadgeColor;
    ocell.countLabel.textColor = theme.unreadTextColor;
    
    ocell.countLabel.hidden = !showUnreadCounter;
    
    return ocell;
}

//- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
//    
//    if (MyFeedsManager.subscription != nil && [MyFeedsManager.subscription hasExpired] == YES) {
//        if (indexPath.section == 0 && indexPath.row == 1) {
//            return YES;
//        }
//        
//        return NO;
//    }
//    
//    return YES;
//    
//}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    BOOL useExtendedLayout = NO;
    BOOL isPhone = self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone;
    if (isPhone) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        useExtendedLayout = [defaults boolForKey:kUseExtendedFeedLayout];
    }
    
    if (indexPath.section == 0) {
        
        if (useExtendedLayout || self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            DetailCustomVC *vc = [[DetailCustomVC alloc] initWithFeed:nil];
            vc.customFeed = FeedTypeCustom;
            vc.unread = indexPath.row == 0;
            
            if (isPhone) {
                [self.navigationController pushViewController:vc animated:YES];
            }
            else {
                UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
                nav.restorationIdentifier = formattedString(@"%@-nav", indexPath.row == 0 ? @"unread" : @"bookmarks");
                
                [self.splitViewController showDetailViewController:nav sender:self];
            }
        }
        else {
            
            CustomFeedVC *vc = [[CustomFeedVC alloc] initWithStyle:UITableViewStylePlain];
            vc.unread = indexPath.row == 0;
            
            [self.navigationController pushViewController:vc animated:YES];
            
        }
        
        return;
    }
    
    Feed *feed = [self.DS objectAtIndexPath:indexPath];
    
    if ([feed isKindOfClass:Feed.class]) {
        UIViewController *vc;
        
        if (useExtendedLayout || self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            if (isPhone) {
                vc = [[DetailFeedVC alloc] initWithFeed:feed];
                [self.navigationController pushViewController:vc animated:YES];
            }
            else {
                vc = [DetailFeedVC instanceWithFeed:feed];
                [(DetailFeedVC *)[(UINavigationController *)vc topViewController] setCustomFeed:NO];
                [self.splitViewController showDetailViewController:vc sender:self];
            }
        }
        else {
            vc = [[FeedVC alloc] initWithFeed:feed];
            [self.navigationController pushViewController:vc animated:YES];
        }
    }
    else {
        // it's a folder
        Folder *folder = (Folder *)feed;
        
        UIViewController *vc;
        
        if (isPhone) {
            vc = [[DetailFolderVC alloc] initWithFolder:folder];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else {
            vc = [DetailFolderVC instanceWithFolder:folder];
            [self.splitViewController showDetailViewController:vc sender:self];
        }
        
    }
    
}

#pragma mark - Restoration

NSString * const kDS2Data = @"DS2Data";

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    return [[FeedsVC alloc] initWithStyle:UITableViewStyleGrouped];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.DS2.data forKey:kDS2Data];
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    [super decodeRestorableStateWithCoder:coder];
    
    NSArray *feedsAndFolders = [coder decodeObjectForKey:kDS2Data];
    
    if (feedsAndFolders != nil) {
        
        // for the folders, the feeds will be empty.
        // we need to remap these.
        NSArray <Folder *> *folders = [feedsAndFolders rz_filter:^BOOL(id obj, NSUInteger idx, NSArray *array) {
            return [obj isKindOfClass:Folder.class];
        }];
        
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:propSel(feedID) ascending:YES];
        
        NSArray <NSSortDescriptor *> *sortDescriptors = @[descriptor];
        
        [folders enumerateObjectsUsingBlock:^(Folder * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            // find all feeds belonging to this folder.
            NSArray <Feed *> *feeds = [[MyFeedsManager feeds] rz_filter:^BOOL(Feed *objx, NSUInteger idxx, NSArray *arrayx) {
                return [objx.folderID isEqualToNumber:obj.folderID];
            }];
            
            feeds = [feeds sortedArrayUsingDescriptors:sortDescriptors];
            
            obj.feeds = [NSPointerArray weakObjectsPointerArray];
            [obj.feeds addObjectsFromArray:feeds];
            
        }];
        
        [self.DS setData:feedsAndFolders section:1];
    }
    
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

- (void)setupData:(NSArray <Feed *> *)feeds
{
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(setupData:) withObject:feeds waitUntilDone:NO];
        return;
    }
    
    self->_highlightedRow = nil;
    
    // get a list of open folders
    NSArray <NSNumber *> *openFolders = [(NSArray <Folder *> *)[self.DS2.data rz_filter:^BOOL(id obj, NSUInteger idx, NSArray *array) {
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
        
        CGPoint contentOffset = self.tableView.contentOffset;
        
        [self.DS setData:data section:1];
        
        [self.tableView.layer removeAllAnimations];
        [self.tableView setContentOffset:contentOffset animated:NO];
        
    } @catch (NSException *exc) {
        DDLogWarn(@"Exception: %@", exc);
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    weakify(self);
    
    if (context == KVO_Unread && [keyPath isEqualToString:propSel(unread)]) {
        asyncMain(^{
            strongify(self);
            
            FeedsCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            cell.countLabel.text = [@([(FeedsManager *)object totalUnread]) stringValue];
        });
    }
    else if (context == KVO_Bookmarks && [keyPath isEqualToString:propSel(bookmarks)]) {
        
        asyncMain(^{
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
    
    NSArray <NSIndexPath *> *visible = [self.tableView indexPathsForVisibleRows];
    
    [self.tableView reloadRowsAtIndexPaths:visible withRowAnimation:UITableViewRowAnimationFade];
    
}

- (void)didUpdateTheme {
    
    weakify(self);
    
    asyncMain(^{
        
        strongify(self);
        
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        self.refreshControl.tintColor = [theme captionColor];
        
        if (self.hairlineView) {
            self.hairlineView.backgroundColor = theme.cellColor;
        }
        
        [[self.headerView tableView] reloadData];
        self.navigationItem.searchController.searchBar.keyboardAppearance = theme.isDark ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
        
        [self.tableView reloadData];
    });
    
}

- (void)updateNotification:(NSNotification *)note {
    
    [self setupData:[note.userInfo valueForKey:@"feeds"]];
    
}

- (void)userDidUpdate {
    
    // this function can be called multiple times
    // beginning 1.0.2
    
    if (MyFeedsManager.userID == nil || [MyFeedsManager.userID isEqualToNumber:@(0)]) {
        return;
    }
    
    weakify(self);
    
    if (self.DS2.data == nil || self.DS2.data.count == 0) {
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
 
    NSUInteger index = [self.DS2.data indexOfObject:folder];
    
    CGPoint contentOffset = self.tableView.contentOffset;
    
    if (folder != nil && (folder.feeds == nil || folder.feeds.allObjects.count == 0)) {
        // it is possible that this folder is actually empty
        // but let's check it anyways
        
        [folder.feedIDs enumerateObjectsUsingBlock:^(NSNumber * _Nonnull feedID, BOOL * _Nonnull stop) {
            
            Feed *feed = [MyFeedsManager feedForID:feedID];
            
            if (feed != nil && [folder.feeds containsObject:feed] == NO) {
                [folder.feeds addObject:feed];
            }
            
        }];
        
    }
    
    if (folder.isExpanded) {
        
        DDLogDebug(@"Closing index: %@", @(index));
        folder.expanded = NO;
        
        // remove these feeds from the datasource
        NSArray *data = [self.DS2.data rz_filter:^BOOL(id obj, NSUInteger idx, NSArray *array) {
            
            if ([obj isKindOfClass:Folder.class])
                return YES;
            
            if ([(Feed *)obj folderID] && [[obj folderID] isEqualToNumber:folder.folderID]) {
                return NO;
            }
            
            return YES;
            
        }];
        
        [self.DS setData:data section:1];
        
    }
    else {
        folder.expanded = YES;
        DDLogDebug(@"Opening index: %@", @(index));
        
        // add these feeds to the datasource after the above index
        NSMutableArray * data = [self.DS2.data mutableCopy];
        
        // data shouldn't contain any object with this folder ID
        data = [data rz_filter:^BOOL(id obj, NSUInteger idx, NSArray *array) {
            if ([obj isKindOfClass:Feed.class]) {
                Feed *feed = obj;
                if ([feed.folderID isEqualToNumber:folder.folderID]) {
                    return NO;
                }
            }
            
            return YES;
        }].mutableCopy;
        
        NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index+1, folder.feeds.allObjects.count)];
        
        [data insertObjects:folder.feeds.allObjects atIndexes:set];
        
        @try {
            [self.DS setData:data section:1];
        }
        @catch (NSException *exc) {
            DDLogWarn(@"Exception updating feeds: %@", exc);
        }
        
    }
    
    [self.feedbackGenerator selectionChanged];
    [self.feedbackGenerator prepare];
    
    cell.faviconView.image = [[UIImage imageNamed:(folder.isExpanded ? @"folder_open" : @"folder")] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        strongify(self);
        [self.tableView.layer removeAllAnimations];
        [self.tableView setContentOffset:contentOffset animated:NO];
    });
    
}

@end
