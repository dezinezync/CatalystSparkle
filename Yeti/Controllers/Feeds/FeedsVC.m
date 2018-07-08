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
#import "FeedVC.h"
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

static void *KVO_Bookmarks = &KVO_Bookmarks;
static void *KVO_Unread = &KVO_Unread;

@interface FeedsVC () <DZSDatasource>

@property (nonatomic, strong, readwrite) DZSectionedDatasource *DS;
@property (nonatomic, weak, readwrite) DZBasicDatasource *DS1, *DS2;
@property (nonatomic, weak) UIView *hairlineView;

@property (nonatomic, strong) UISelectionFeedbackGenerator *feedbackGenerator;

@end

@implementation FeedsVC

- (BOOL)ef_hidesNavBorder {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Feeds";
    
    [self setupTableView];
    [self setupNavigationBar];
    
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateNotification:) name:FeedsDidUpdate object:MyFeedsManager];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(userDidUpdate) name:UserDidUpdate object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didUpdateTheme) name:ThemeDidUpdate object:nil];
    
    NSKeyValueObservingOptions kvoOptions = NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld;
    
    [MyFeedsManager addObserver:self forKeyPath:propSel(bookmarks) options:kvoOptions context:KVO_Bookmarks];
    [MyFeedsManager addObserver:self forKeyPath:propSel(unread) options:kvoOptions context:KVO_Unread];
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
    
    if (!self.DS2.data || (!self.DS2.data.count && !_noPreSetup)) {
        
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            [self.refreshControl beginRefreshing];
            self->_noPreSetup = YES;
            
            weakify(self);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                asyncMain(^{
                    strongify(self);
                    [self beginRefreshing:self.refreshControl];
                });
            });
        })
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            strongify(self);
            self->_preCommitLoading = YES;
        });
    }
}

- (BOOL)definesPresentationContext
{
    return YES;
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    if (MyFeedsManager.observationInfo != nil) {
        
        NSArray *observingObjects = [(id)(MyFeedsManager.observationInfo) valueForKeyPath:@"_observances"];
        observingObjects = [observingObjects rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [obj valueForKeyPath:@"observer"];
        }];
        
        if ([observingObjects indexOfObject:self] != NSNotFound) {
            @try {
                [MyFeedsManager removeObserver:self forKeyPath:propSel(bookmarks)];
                [MyFeedsManager removeObserver:self forKeyPath:propSel(unread)];
            } @catch (NSException *exc) {}
        }
        
    }
}

#pragma mark - Setups

- (void)setupTableView {
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
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FeedsCell.class) bundle:nil] forCellReuseIdentifier:kFeedsCell];
    
//    FeedsHeaderView *headerView = [[FeedsHeaderView alloc] initWithNib];
//    headerView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 88.f);
//    [headerView setContentCompressionResistancePriority:1000 forAxis:UILayoutConstraintAxisVertical];
    
//    self.tableView.tableHeaderView = headerView;
//    _headerView = headerView;
//    _headerView.tableView.delegate = self;
    
    self.tableView.tableFooterView = [UIView new];
    
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongTapOnCell:)];
    [self.tableView addGestureRecognizer:longPress];
}

- (void)setupNavigationBar {
    
    UIRefreshControl *control = [[UIRefreshControl alloc] init];
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    if (theme.isDark) {
        control.tintColor = [theme captionColor];
    }
    
    [control addTarget:self action:@selector(beginRefreshing:) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView addSubview:control];
    self.refreshControl = control;
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didTapAdd:)];
    UIBarButtonItem *folder = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"create_new_folder"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapAddFolder:)];
    UIBarButtonItem *recommendations = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"whatshot"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapRecommendations:)];
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapSettings)];
    
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
        searchController.searchBar.placeholder = @"Search feeds";
        searchController.searchBar.accessibilityHint = @"Search your feeds";
        searchController.searchBar.keyboardAppearance = theme.isDark ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
        
        searchController.searchBar.layer.borderColor = [UIColor clearColor].CGColor;
        
        CGFloat height = 1.f/self.traitCollection.displayScale;
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
    
    FeedsCell *cell = [tableView dequeueReusableCellWithIdentifier:kFeedsCell forIndexPath:indexPath];
    
    if (indexPath.section == 0) {
        cell.titleLabel.text = [self.DS objectAtIndexPath:indexPath];
        
        NSString *imageName = [@"l" stringByAppendingString:cell.titleLabel.text.lowercaseString];
        cell.faviconView.image = [UIImage imageNamed:imageName];
        
        if (indexPath.row == 0) {
            cell.countLabel.text = formattedString(@"%@", @(MyFeedsManager.totalUnread));
        }
        else {
            cell.countLabel.text = formattedString(@"%@", MyFeedsManager.bookmarksCount);
        }
        
    }
    else {
        // Configure the cell...
        Feed *feed = [self.DS objectAtIndexPath:indexPath];
        if ([feed isKindOfClass:Feed.class]) {
            [cell configure:feed];
        }
        else {
            // folder
            [cell configureFolder:(Folder *)feed];
        }
    }
    
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    cell.faviconView.backgroundColor = theme.cellColor;
    cell.titleLabel.backgroundColor = theme.cellColor;
    cell.titleLabel.textColor = theme.titleColor;
    
    cell.countLabel.backgroundColor = theme.unreadBadgeColor;
    cell.countLabel.textColor = theme.unreadTextColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.section == 0) {
        CustomFeedVC *vc = [[CustomFeedVC alloc] initWithStyle:UITableViewStylePlain];
        vc.unread = indexPath.row == 0;
        
        [self.navigationController pushViewController:vc animated:YES];
        
        return;
    }
    
    Feed *feed = [self.DS objectAtIndexPath:indexPath];
    
    if ([feed isKindOfClass:Feed.class]) {
        FeedVC *vc = [[FeedVC alloc] initWithFeed:feed];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else {
        // it's a folder
        Folder *folder = (Folder *)feed;
        NSUInteger index = [self.DS2.data indexOfObject:folder];
        
        CGPoint contentOffset = self.tableView.contentOffset;
        
        FeedsCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        
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
            
            NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index+1, folder.feeds.count)];
            
            [data insertObjects:folder.feeds atIndexes:set];
            
            [self.DS setData:data section:1];
            
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

- (void)setupData:(NSArray <Feed *> *)feeds
{
    
    if (![NSThread isMainThread]) {
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            
            [self setupData:feeds];
        });
        return;
    }
    
    self->_highlightedRow = nil;
    
    // ensures search bar does not dismiss on refresh or first load
    @try {
        NSArray *data = [(MyFeedsManager.folders ?: @[]) arrayByAddingObjectsFromArray:MyFeedsManager.feeds];
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
            cell.countLabel.text = [@([[(FeedsManager *)object unread] count]) stringValue];
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

#pragma mark - Notifications

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
    // we only need this once.
    [NSNotificationCenter.defaultCenter removeObserver:self name:UserDidUpdate object:nil];
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        asyncMain(^{
            strongify(self);
            [self beginRefreshing:self.refreshControl];
        });
    });
}

@end
