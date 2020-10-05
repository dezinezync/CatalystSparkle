//
//  SidebarVC.m
//  Elytra
//
//  Created by Nikhil Nigade on 24/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SidebarVC+DragAndDrop.h"
#import "CustomFeed.h"

#import <DZKit/NSString+Extras.h>
#import <SDWebImage/SDWebImageManager.h>

#import "NSString+ImageProxy.h"

#import "Coordinator.h"

#import "CustomFeedCell.h"
#import "FeedCell.h"
#import "FolderCell.h"

#import "Keychain.h"
#import "Elytra-Swift.h"
#import "SidebarSearchView.h"

@interface SidebarVC () {
    
    // Sync
    BOOL _refreshing;
    NSUInteger _refreshFeedsCounter;
    
    // Counters
    BOOL _fetchingCounters;
    
    BOOL _initialSyncCompleted;
    BOOL _requiresUpdatingUnreadSharedData;
    
    NSUserActivity *_restorationActivity;
    
    BOOL _initialSnapshotSetup;
    
}

@property (nonatomic, strong, readwrite) UICollectionViewDiffableDataSource <NSNumber *, Feed *> *DS;

@property (nonatomic, strong) UICollectionViewCellRegistration *customFeedRegister, *folderRegister, *feedRegister;

@property (nonatomic, weak) UILabel *progressLabel;
@property (nonatomic, weak) UIProgressView *syncProgressView;
@property (nonatomic, strong) UIStackView *progressStackView;

#if TARGET_OS_MACCATALYST

@property (nonatomic, strong) UISearchController *supplementarySearchController;

@property (nonatomic, weak) NSTimer *refreshTimer;

#endif

@end

@implementation SidebarVC

static NSString * const kSidebarFeedCell = @"SidebarFeedCell";

- (instancetype)initWithDefaultLayout {
    
    UICollectionViewCompositionalLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection * _Nullable(NSInteger section, id<NSCollectionLayoutEnvironment> _Nonnull environment) {
        
        UICollectionLayoutListAppearance appearance;
        
        if (environment.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            appearance = UICollectionLayoutListAppearancePlain;
        }
        else {
            appearance = UICollectionLayoutListAppearanceSidebar;
        }
        
        UICollectionLayoutListConfiguration *config = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:appearance];
        
        config.showsSeparators = NO;
        
        if (section == 0) {
#if TARGET_OS_MACCATALYST
            config.headerMode = UICollectionLayoutListHeaderModeSupplementary;
#endif
            return [NSCollectionLayoutSection sectionWithListConfiguration:config layoutEnvironment:environment];
            
        }
        
        if (section != 2) {
            // this is only applicable for feeds with folders
            config.headerMode = UICollectionLayoutListHeaderModeFirstItemInSection;
        }
        
        weakify(self);
        
        config.trailingSwipeActionsConfigurationProvider = ^UISwipeActionsConfiguration *(NSIndexPath * indexPath) {
            
            strongify(self);
            
            Feed *feed = [self.DS itemIdentifierForIndexPath:indexPath];
            Folder *folder = nil;
            
            if ([feed isKindOfClass:Folder.class]) {
                folder = (Folder *)feed;
            }
            
            UIContextualAction *delete = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                
                if (folder) {
                    
                    [self confirmFolderDelete:folder completionHandler:completionHandler];
                    
                    return;
                }
                
                [self confirmFeedDelete:feed completionHandler:completionHandler];
                
            }];

            UISwipeActionsConfiguration *configuration = nil;
            
            if (folder) {
                UIContextualAction *rename = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Rename" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                   
                    [self.mainCoordinator showRenameFolderVC:folder];
                    
                }];
                
                rename.backgroundColor = self.view.tintColor;
                
                configuration = [UISwipeActionsConfiguration configurationWithActions:@[delete, rename]];
            }
            else {
                
                UIContextualAction *move = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Move" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                   
                    completionHandler(YES);
                    
                    [self feed_didTapMove:feed indexPath:indexPath];
                    
                }];
                
                move.backgroundColor = [UIColor colorWithRed:0/255.f green:122/255.f blue:255/255.f alpha:1.f];
                
                UIContextualAction *share = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Share" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
                   
                    completionHandler(YES);
                    
                    [self feed_didTapShare:feed indexPath:indexPath];
                    
                }];
                
                share.backgroundColor = [UIColor colorWithRed:126/255.f green:211/255.f blue:33/255.f alpha:1.f];
                
                configuration = [UISwipeActionsConfiguration configurationWithActions:@[delete, move, share]];
                
            }
            
            configuration.performsFirstActionWithFullSwipe = YES;
            
            return configuration;
            
        };
        
        return [NSCollectionLayoutSection sectionWithListConfiguration:config layoutEnvironment:environment];
        
    }];
    
    if (self = [super initWithCollectionViewLayout:layout]) {
        self.restorationIdentifier = NSStringFromClass(self.class);
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Feeds";
    
    if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        self.collectionView.backgroundColor = UIColor.systemBackgroundColor;
    }
    
#if TARGET_OS_MACCATALYST
    self.additionalSafeAreaInsets = UIEdgeInsetsMake(12.f, 0, 0, 0);
    
    [self scheduleTimerIfValid];
    
#endif

    [self setupNavigationBar];
    
    [self setupDatasource];
    
    [self setupData];
    
    [self setupNotifications];
    
    [self updateSharedData];

}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
#if !TARGET_OS_MACCATALYST
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
#endif
    
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    if (_initialSyncCompleted == NO) {
        
        [self sync];
        
    }
    
    if (_requiresUpdatingUnreadSharedData) {
        
        [self updateSharedUnreadsData];
        
    }
    
}

- (void)dealloc {
    
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
}

#pragma mark - Setup

- (void)setupNavigationBar {
    
#if TARGET_OS_MACCATALYST
    [self.navigationController setNavigationBarHidden:YES animated:NO];
#else
    self.navigationItem.leftBarButtonItems = @[self.splitViewController.displayModeButtonItem, self.leftBarButtonItem];
    self.navigationItem.rightBarButtonItems = self.rightBarButtonItems;

    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    // Search Controller setup
    {
        self.navigationItem.searchController = [self searchControllerForSidebar];
    }
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(beginRefreshingAll:) forControlEvents:UIControlEventValueChanged];
    refresh.attributedTitle = self.lastUpdateAttributedString;
    
    self.collectionView.refreshControl = refresh;
    
    self.refreshControl = refresh;
#endif
}

- (void)setupDatasource {
    
    if (self.DS != nil) {
        return;
    }
    
    self.collectionView.dragInteractionEnabled = YES;
    self.collectionView.dragDelegate = self;
    self.collectionView.dropDelegate = self;
    
    self.DS = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, id _Nonnull item) {
        
        if ([item isKindOfClass:CustomFeed.class]) {
            
            return [collectionView dequeueConfiguredReusableCellWithRegistration:self.customFeedRegister forIndexPath:indexPath item:item];
            
        }
        else if ([item isKindOfClass:Folder.class]) {
            
            return [collectionView dequeueConfiguredReusableCellWithRegistration:self.folderRegister forIndexPath:indexPath item:item];
            
        }
        
        return [collectionView dequeueConfiguredReusableCellWithRegistration:self.feedRegister forIndexPath:indexPath item:item];
        
    }];
    
#if TARGET_OS_MACCATALYST
    
    UICollectionViewSupplementaryRegistration * searchHeaderRegistration = [UICollectionViewSupplementaryRegistration registrationWithSupplementaryClass:SidebarSearchView.class elementKind:UICollectionElementKindSectionHeader configurationHandler:^(__kindof UICollectionReusableView * _Nonnull supplementaryView, NSString * _Nonnull elementKind, NSIndexPath * _Nonnull indexPath) {
        
        supplementaryView.backgroundColor = UIColor.clearColor;
        supplementaryView.translatesAutoresizingMaskIntoConstraints = NO;
        
        UISearchController *searchController = self.supplementarySearchController;
        
        UISearchBar *searchBar = searchController.searchBar;
        searchBar.frame = CGRectMake(0, 0, self.view.bounds.size.width, 44.f);
        searchBar.backgroundImage = [UIImage new];
//        searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        [supplementaryView addSubview:searchBar];
        
        [searchBar.leadingAnchor constraintEqualToAnchor:supplementaryView.leadingAnchor].active = YES;
        [searchBar.trailingAnchor constraintEqualToAnchor:supplementaryView.trailingAnchor].active = YES;
//        [searchBar.centerXAnchor constraintEqualToAnchor:supplementaryView.centerXAnchor].active = YES;
        [searchBar.topAnchor constraintEqualToAnchor:supplementaryView.topAnchor].active = YES;
        
        [searchBar setContentCompressionResistancePriority:999 forAxis:UILayoutConstraintAxisHorizontal];
        [searchBar setContentCompressionResistancePriority:1000 forAxis:UILayoutConstraintAxisVertical];
        
        [supplementaryView.heightAnchor constraintEqualToAnchor:searchBar.heightAnchor].active = YES;
        
        [supplementaryView invalidateIntrinsicContentSize];
        [supplementaryView setNeedsLayout];
        
    }];
        
    self.DS.supplementaryViewProvider = ^UICollectionReusableView * _Nullable(UICollectionView * _Nonnull collectionView, NSString * _Nonnull kind, NSIndexPath * _Nonnull indexPath) {
      
        return [collectionView dequeueConfiguredReusableSupplementaryViewWithRegistration:searchHeaderRegistration forIndexPath:indexPath];
        
    };
#endif
    
}

- (void)setupData {
    
    // since we only allow single selection in this collection, we get the first item.
    // can be nil.
    NSIndexPath *selected = [self.collectionView.indexPathsForSelectedItems firstObject];
    
    NSDiffableDataSourceSectionSnapshot *snapshot = [NSDiffableDataSourceSectionSnapshot new];
    
    CustomFeed *unread = [[CustomFeed alloc] initWithTitle:@"Unread" imageName:@"largecircle.fill.circle" tintColor:UIColor.systemBlueColor feedType:FeedVCTypeUnread];
    unread.feedID = @( NSUIntegerMax - 3000 );
    
    CustomFeed *today = [[CustomFeed alloc] initWithTitle:@"Today" imageName:@"calendar" tintColor:UIColor.systemRedColor feedType:FeedVCTypeToday];
    unread.feedID = @(NSUIntegerMax - 2000);
    
    [snapshot appendItems:@[unread, today]];
    
    if (SharedPrefs.hideBookmarks == NO) {
        
        CustomFeed *bookmarks = [[CustomFeed alloc] initWithTitle:@"Bookmarks" imageName:@"bookmark.fill" tintColor:UIColor.systemOrangeColor feedType:FeedVCTypeBookmarks];
        
        bookmarks.feedID = @(NSUIntegerMax - 1000);
        
        [snapshot appendItems:@[bookmarks]];
        
    }
    
    [self.DS applySnapshot:snapshot toSection:@(NSUIntegerMax - 300) animatingDifferences:NO];
    
    NSDiffableDataSourceSectionSnapshot *foldersSnapshot = [NSDiffableDataSourceSectionSnapshot new];
    
    if (ArticlesManager.shared.feeds.count) {
        
        NSSortDescriptor *alphaSort = [NSSortDescriptor sortDescriptorWithKey:@"displayTitle" ascending:YES selector:@selector(localizedCompare:)];
        
        if (ArticlesManager.shared.folders.count) {
            
            NSArray *uniqueItems = ArticlesManager.shared.folders;
            
            [foldersSnapshot appendItems:uniqueItems];

            for (Folder *folder in uniqueItems) {
                
                NSArray <Feed *> *feeds = [folder.feeds.allObjects sortedArrayUsingDescriptors:@[alphaSort]];
                
                [foldersSnapshot appendItems:feeds intoParentItem:folder];
                
            }

        }
        
        [self.DS applySnapshot:foldersSnapshot toSection:@(NSUIntegerMax - 200) animatingDifferences:NO];
        
        if (ArticlesManager.shared.feedsWithoutFolders) {

            NSDiffableDataSourceSectionSnapshot *onlyFeedsSnapshot = [NSDiffableDataSourceSectionSnapshot new];
            
            NSArray <Feed *> *alphaSorted = [ArticlesManager.shared.feedsWithoutFolders sortedArrayUsingDescriptors:@[alphaSort]];
            
            [onlyFeedsSnapshot appendItems:alphaSorted];
            
            [self.DS applySnapshot:onlyFeedsSnapshot toSection:@(NSUIntegerMax - 100) animatingDifferences:NO];

        }
        
    }
    
#if TARGET_OS_MACCATALYST
    
    if (self->_initialSnapshotSetup == NO) {
        
        selected = [self.DS indexPathForItemIdentifier:unread];
        
        self->_initialSnapshotSetup = YES;
        
    }
    
#endif
    
    if (selected != nil) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            [self.collectionView selectItemAtIndexPath:selected animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            
        });
        
    }
    
}

- (void)setupNotifications {
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(setupData) name:FeedsDidUpdate object:ArticlesManager.shared];
    
    weakify(self);
    
    [NSNotificationCenter.defaultCenter addObserverForName:UnreadCountDidUpdate object:MyFeedsManager queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        
        strongify(self);
        
        if (self->_requiresUpdatingUnreadSharedData == NO) {
            self->_requiresUpdatingUnreadSharedData = YES;
        }
        
        [MyFeedsManager updateSharedUnreadCounters];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
       
        UICollectionViewListCell *cell = (UICollectionViewListCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        
        if (cell != nil) {
            
            UIListContentConfiguration *content = (UIListContentConfiguration *)[cell contentConfiguration];
            
            if (SharedPrefs.showUnreadCounts == YES) {
                
                content.secondaryText = MyFeedsManager.totalUnread > 0 ? @(MyFeedsManager.totalUnread).stringValue : nil;
                
            }
            else {
                
                content.secondaryText = nil;
                
            }
            
            cell.contentConfiguration = content;
        }
        
    }];
    
    [NSNotificationCenter.defaultCenter addObserverForName:TodayCountDidUpdate object:MyFeedsManager queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        
        strongify(self);
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:0];
       
        UICollectionViewListCell *cell = (UICollectionViewListCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        
        [MyFeedsManager updateSharedUnreadCounters];
        
        if (cell != nil) {
            
            UIListContentConfiguration *content = (UIListContentConfiguration *)[cell contentConfiguration];
            
            if (SharedPrefs.showUnreadCounts == YES) {
                
                content.secondaryText = MyFeedsManager.totalToday > 0 ? @(MyFeedsManager.totalToday).stringValue : nil;
                
            }
            else {
                
                content.secondaryText = nil;
                
            }
            
            cell.contentConfiguration = content;
        }
        
    }];
    
    if (SharedPrefs.hideBookmarks == NO) {
        
        [_bookmarksManager addObserver:self name:BookmarksDidUpdateNotification callback:^{
            
            [MyFeedsManager updateSharedUnreadCounters];
            
            NSDiffableDataSourceSnapshot *snapshot = [self.DS snapshot];
            
            id object = [self.DS itemIdentifierForIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]];
            
            if (object != nil && [object isKindOfClass:CustomFeed.class]) {
                
                [snapshot reloadItemsWithIdentifiers:@[object]];
                
                [self.DS applySnapshot:snapshot animatingDifferences:YES];
                
            }
            
        }];
        
    }
    
    MyDBManager.syncProgressBlock = ^(CGFloat progress) {
        
        NSLogDebug(@"Sync Progress: %@", @(progress));
        
        if (progress == 0.f) {
            
            [self.navigationController setToolbarHidden:NO animated:YES];
            
            self.progressLabel.text = @"Syncing...";
            [self.progressLabel sizeToFit];
            
            [self.syncProgressView setProgress:progress animated:YES];
            
        }
        else if (progress >= 0.95f) {
            
            [self.syncProgressView setProgress:progress animated:YES];
            
            self.progressLabel.text = @"Syncing Complete.";
            
            if (self->_refreshing) {
                self->_refreshing = NO;
            }
            
            if ([self.refreshControl isRefreshing]) {
                [self.refreshControl endRefreshing];
            }
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [self.navigationController setToolbarHidden:YES animated:YES];
                
            });
            
        }
        else {
            
            if (progress <= 0.95f && self.navigationController.isToolbarHidden == YES) {
                [self.navigationController setToolbarHidden:NO animated:NO];
            }
            
            if (self.navigationController.isToolbarHidden == NO) {
                
                self.progressLabel.text = [NSString stringWithFormat:@"Synced %.f%%", progress * 100];
                
                [self.syncProgressView setProgress:progress animated:YES];
                
            }
            
        }
        
    };
    
    [NSNotificationCenter.defaultCenter addObserverForName:YTSubscriptionHasExpiredOrIsInvalid object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
       
        // dont run when the app is in the background or inactive
        if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
            return;
        }
        
        // if we're already presenting a VC, don't run.
        // this is most likely the onboarding process
        if (self.presentedViewController != nil || self.splitViewController.presentedViewController != nil) {
            return;
        }
        
        [self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            obj.enabled = NO;
            
        }];
        
        [self.mainCoordinator showSubscriptionsInterface];
        
    }];
    
    [NSNotificationCenter.defaultCenter addObserverForName:YTSubscriptionPurchased object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        
        [self.navigationItem.rightBarButtonItems enumerateObjectsUsingBlock:^(UIBarButtonItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (obj.isEnabled == NO) {
                obj.enabled = YES;
            }
            
        }];
        
    }];
    
    [NSNotificationCenter.defaultCenter addObserverForName:UserDidUpdate object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
        
        strongify(self);
       
        if (self->_initialSyncCompleted == NO) {
            [self sync];
        }
        
    }];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(setupData) name:ShowBookmarksTabPreferenceChanged object:nil];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(setupData) name:ShowUnreadCountsPreferenceChanged object:nil];
    
#if TARGET_OS_MACCATALYST
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didChangeTimerPreference) name:MacRefreshFeedsIntervalUpdated object:nil];
    
#endif
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(badgePreferenceChanged) name:BadgeAppIconPreferenceUpdated object:nil];
    
}

#pragma mark - Getters

#if TARGET_OS_MACCATALYST

- (UISearchController *)supplementarySearchController {
    
    if (_supplementarySearchController == nil) {
        _supplementarySearchController = [self searchControllerForSidebar];
    }
    
    return _supplementarySearchController;
    
}

#endif

- (UISearchController *)searchControllerForSidebar {
    
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchResultsUpdater = self;
    searchController.delegate = self;
    searchController.obscuresBackgroundDuringPresentation = NO;
    searchController.searchBar.placeholder = @"Search Feeds";
    searchController.searchBar.accessibilityHint = @"Search your feeds";
    
    searchController.searchBar.layer.borderColor = [UIColor clearColor].CGColor;
    
    return searchController;
    
}

- (UICollectionViewDiffableDataSource *)datasource {
    
    return self.DS;
    
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

- (NSArray <UIBarButtonItem *> *)toolbarItems {
    
    if (_progressStackView == nil) {
        
        CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width - (LayoutPadding * 2), 32.f);
        
        UILabel *progressLabel = [[UILabel alloc] init];
        
        UIFont *sizedFont = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        
        progressLabel.font = [UIFont monospacedDigitSystemFontOfSize:MIN(11.f, sizedFont.pointSize) weight:UIFontWeightSemibold];
        progressLabel.textColor = UIColor.secondaryLabelColor;
        progressLabel.textAlignment = NSTextAlignmentCenter;
        progressLabel.frame = CGRectMake(0, 0, frame.size.width, 0);
        
        NSLayoutConstraint *labelWidthConstraint = [progressLabel.widthAnchor constraintEqualToConstant:MAX(frame.size.width, 280.f)];
        labelWidthConstraint.priority = 999;
        
        progressLabel.translatesAutoresizingMaskIntoConstraints = NO;

//#ifdef DEBUG
//        progressLabel.backgroundColor = UIColor.redColor;
//#endif
        
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        progressView.progressTintColor = SharedPrefs.tintColor;
        progressView.trackTintColor = UIColor.separatorColor;
        progressView.frame = CGRectMake(0, 0, MAX(frame.size.width, 280.f), 6.f);
        progressView.layer.cornerRadius = 2.f;
        progressView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSLayoutConstraint *widthConstraint = [progressView.widthAnchor constraintEqualToConstant:MAX(frame.size.width, 280.f)];
        widthConstraint.priority = 999;
        
        [NSLayoutConstraint activateConstraints:@[widthConstraint, labelWidthConstraint]];
        
//#ifdef DEBUG
//        progressView.backgroundColor = UIColor.greenColor;
//#endif
        
        UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[progressLabel, progressView]];
        stack.frame = frame;
        stack.axis = UILayoutConstraintAxisVertical;
        stack.distribution = UIStackViewDistributionEqualSpacing;
        stack.spacing = 4.f;
        stack.alignment = UIStackViewAlignmentCenter;
        
        _syncProgressView = progressView;
        _progressLabel = progressLabel;
        
        _progressStackView = stack;
        
    }
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:self.progressStackView];
    
    return @[item];
    
}

- (NSAttributedString *)lastUpdateAttributedString {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    
    NSString *dateString = [formatter stringFromDate:(MyFeedsManager.unreadLastUpdate ?: NSDate.date)];
    
    NSString *formatted = formattedString(@"Last update: %@", dateString);
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:11.f],
                                 NSForegroundColorAttributeName: UIColor.secondaryLabelColor
                                 };
    
    NSAttributedString *attrs = [[NSAttributedString alloc] initWithString:formatted attributes:attributes];
    
    return attrs;
    
}

#pragma mark - Cell Registrations

- (UICollectionViewCellRegistration *)customFeedRegister {
    
    if (_customFeedRegister == nil) {
        
        weakify(self);
        
        UICollectionViewCellRegistration *customFeedsRegistration = [UICollectionViewCellRegistration registrationWithCellClass:CustomFeedCell.class configurationHandler:^(__kindof CustomFeedCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, CustomFeed *  _Nonnull item) {
            
            strongify(self);
            
            cell.mainCoordinator = self.mainCoordinator;
            
            [cell configure:item indexPath:indexPath];
            
        }];
        
        _customFeedRegister = customFeedsRegistration;
        
    }
    
    return _customFeedRegister;
    
}

- (UICollectionViewCellRegistration *)folderRegister {
    
    if (_folderRegister == nil) {
        
        weakify(self);
        
        UICollectionViewCellRegistration *folderRegistration = [UICollectionViewCellRegistration registrationWithCellClass:FolderCell.class configurationHandler:^(__kindof FolderCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, Folder *  _Nonnull item) {
            
            strongify(self);

            cell.DS = self.DS;

            [cell configure:item indexPath:indexPath];
            
        }];
        
        _folderRegister = folderRegistration;
        
    }
    
    return _folderRegister;
    
}

- (UICollectionViewCellRegistration *)feedRegister {
    
    if (_feedRegister == nil) {
        
        UICollectionViewCellRegistration *feedRegistration = [UICollectionViewCellRegistration registrationWithCellClass:FeedCell.class configurationHandler:^(__kindof FeedCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, Feed *  _Nonnull item) {
           
            cell.DS = self.DS;
            
            [cell configure:item indexPath:indexPath];
            
        }];
        
        _feedRegister = feedRegistration;
        
    }
    
    return _feedRegister;
    
}

#pragma mark - <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    id item = [self.DS itemIdentifierForIndexPath:indexPath];
    
    if (item == nil) {
        
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
        return;
        
    }
    
    if ([item isKindOfClass:Folder.class] == YES) {
        
        
        return;
    }
    
    if ([item isKindOfClass:CustomFeed.class] == YES) {
        
        [self.mainCoordinator showCustomVC:item];
        
        return;
    }
    
    [self.mainCoordinator showFeedVC:item];
    
    if (self->_restorationActivity != nil) {
        
        [self.mainCoordinator.feedVC continueActivity:self->_restorationActivity];
        
        self->_restorationActivity = nil;
        
    }
    
}

#pragma mark - Misc

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)beginRefreshingAll:(UIRefreshControl *)sender {
    
    if (self->_refreshing) {
        return;
    }
    
    self->_fetchingCounters = NO;
    
    [self sync];
    
}

- (void)sync {
    
    if (MyFeedsManager.user == nil) {
        return;
    }
    
    if (_initialSyncCompleted == NO) {
        _initialSyncCompleted = YES;
    }
    
    if ((ArticlesManager.shared.feeds.count == 0 || ArticlesManager.shared.folders.count == 0)
        && _refreshing == NO
        && _refreshFeedsCounter < 3) {
        
        _refreshFeedsCounter++;
        
        weakify(self);
        
        [MyFeedsManager getFeedsWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                strongify(self);
                
                if (self->_refreshFeedsCounter > 0) {
                    [self sync];
                }
                
            });
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                strongify(self);
                
                if (self->_refreshFeedsCounter > 0) {
                    [self sync];
                }
                
            });
            
        }];
        
        return;
        
    }
    
    _refreshFeedsCounter = 0;
    
    if (_refreshing == YES) {
        return;
    }
    
    if ([MyDBManager isSyncing]) {
        return;
    }
    
    if ([self.refreshControl isRefreshing] == NO) {

        dispatch_async(dispatch_get_main_queue(), ^{

            [self.refreshControl beginRefreshing];

        });

    }
    
    _refreshing = YES;
    
    [self fetchLatestCounters];
    [self updateSharedData];
    
    [MyDBManager setValue:@(NO) forKey:@"syncSetup"];
    [MyDBManager setupSync];
    
}

- (void)fetchLatestCounters {
    
    if (self->_fetchingCounters == YES) {
        return;
    }
    
    self->_fetchingCounters = YES;
    
    [MyFeedsManager getCountersWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        self->_fetchingCounters = NO;
        self->_refreshing = NO;
        
        MyFeedsManager.unreadLastUpdate = NSDate.date;
        
        NSDiffableDataSourceSnapshot *snapshot = self.DS.snapshot;
        
        if (snapshot == nil) {

            [self setupData];

        }
        else {
            
            NSIndexPath *selected = [[self.collectionView indexPathsForSelectedItems] firstObject];
            
            NSArray <NSIndexPath *> *visible = [self.collectionView indexPathsForVisibleItems];
            
            NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:visible.count];
            
            for (NSIndexPath *indexPath in visible) {
                
                id item = [self.DS itemIdentifierForIndexPath:indexPath];
                
                if (item != nil) {
                    [identifiers addObject:item];
                }
                
            }
            
            [snapshot reloadItemsWithIdentifiers:identifiers];
            
            [self.DS applySnapshot:snapshot animatingDifferences:NO];
            
            if (selected != nil) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                   
                    [self.collectionView selectItemAtIndexPath:selected animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                    
                });
                
            }
            
        }

        if ([self.refreshControl isRefreshing]) {
            [self.refreshControl endRefreshing];
        }
        
        if (self->_refreshFeedsCounter > 0) {
            self->_refreshFeedsCounter = 0;
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSLog(@"Error: Failed to fetch counters with error:%@", error.localizedDescription);
        
        self->_fetchingCounters = NO;
        self->_refreshing = NO;
        
    }];
    
}

- (void)updateSharedData {
    
    weakify(self);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        strongify(self);
       
        [self updateSharedUnreadsData];
        
    });
    
}

- (void)updateSharedUnreadsData {
    
    [MyFeedsManager getUnreadForPage:1 limit:6 sorting:YTSortUnreadDesc success:^(NSArray <FeedItem *> * items, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
           
            NSMutableArray <NSMutableDictionary *> *list = [NSMutableArray arrayWithCapacity:items.count];
            
            NSArray *usableItems = nil;
            
            NSArray *coverItems = [items rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                return obj.coverImage != nil;
            }];
            
            if (coverItems.count >= 4) {
                usableItems = coverItems;
            }
            else {
                
                /*
                 * A: Say we have 1 item with a cover. So we take the other 3 non-cover items
                 *    and concat it here.
                 *
                 * B: Say we have 3 items with covers. We take the first non-cover item
                 *    and use it here.
                 */
                
                NSInteger coverItemsCount = coverItems.count;
                NSInteger additionalRequired = MAX(0, 4 - coverItemsCount);
                
                NSArray *nonCoverItems = [items rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                    return obj.coverImage == nil;
                }];
                
                if (nonCoverItems.count > 0) {
                    
                    additionalRequired = MIN(additionalRequired, nonCoverItems.count);
                    
                    usableItems = [coverItems arrayByAddingObjectsFromArray:[nonCoverItems subarrayWithRange:NSMakeRange(0, additionalRequired)]];
                    
                }
                
            }
            
            for (FeedItem *item in usableItems) {
                
                NSString *title = item.articleTitle;
                NSNumber *date = @(item.timestamp.timeIntervalSince1970);
                NSString *author = item.author ?: @"";
                NSString *blog = item.blogTitle;
                NSString *imageURL = item.coverImage;
                NSNumber *identifier = item.identifier;
                NSNumber *blogID = item.feedID;
                NSString *favicon = @"";
                
                Feed *feed = [MyFeedsManager feedForID:item.feedID];
                
                if (feed != nil) {
                    blog = [feed displayTitle];
                    favicon = [feed faviconURI] ?: @"";
                }
                else {
                    blog = @"";
                }
                
                if ((title == nil || [title isBlank]) && item.content != nil && item.content.count > 0) {
                    
                    NSString * titleContent = [item textFromContent];
                    
                    title = titleContent;
                    
                }
                
                NSMutableDictionary *listItem = [NSMutableDictionary dictionaryWithDictionary:@{
                    @"title": title,
                    @"date": date,
                    @"author": author,
                    @"blog": blog,
                    @"identifier": identifier,
                    @"blogID": blogID,
                    @"favicon": favicon
                }];
                
                /*
                 * Convert all image URLs to the image proxy urls. This ensures
                 * we always download correctly sized and scaled images so as to
                 * not use excessive memory in Widgets.
                 */
                if (imageURL != nil) {
                    listItem[@"imageURL"] = [imageURL pathForImageProxy:NO maxWidth:80.f quality:0.8f forWidget:YES];
                }
                
                if ([favicon isBlank] == NO) {
                    listItem[@"favicon"] = [favicon pathForImageProxy:NO maxWidth:48.f quality:0.8f forWidget:YES];
                }
                
                [list addObject:listItem];
                
            }
            
            NSDictionary *data = @{@"entries": list, @"date": @([NSDate.date timeIntervalSince1970])};
            
            [MyFeedsManager writeToSharedFile:@"articles.json" data:data];
            
            [WidgetManager reloadTimelineWithName:@"UnreadsWidget"];

            
        });
        
    } error:nil];
    
}

#pragma mark - State Restoration

- (void)continueActivity:(NSUserActivity *)activity {
    
    NSDictionary *sidebar = [activity.userInfo valueForKey:@"sidebar"];
    
    if (sidebar == nil) {
        return;
    }
    
    NSArray <NSNumber *> *openFolders = [sidebar objectForKey:@"openFolders"];
    
    if (openFolders.count) {
        
        NSDiffableDataSourceSectionSnapshot *sectionSnapshot = [self.DS snapshotForSection:@(NSUIntegerMax - 200)];
        
        NSArray <Folder *> *foldersToOpen = [openFolders rz_map:^id(NSNumber *obj, NSUInteger idx, NSArray *array) {
           
            return [ArticlesManager.shared folderForID:obj];
            
        }];
        
        [sectionSnapshot expandItems:foldersToOpen];
        
        [self.DS applySnapshot:sectionSnapshot toSection:@(NSUIntegerMax - 200) animatingDifferences:NO];
        
    }
    
    // selected index path
    NSNumber *selectedCustom = [sidebar valueForKey:@"selectedCustom"];
    NSIndexPath *indexPath = nil;
    
    if (selectedCustom != nil) {
        
        if (selectedCustom.integerValue == FeedVCTypeUnread) {
            indexPath = [NSIndexPath indexPathForItem:0 inSection:0];
        }
        else if (selectedCustom.integerValue == FeedVCTypeToday) {
            indexPath = [NSIndexPath indexPathForItem:1 inSection:0];
        }
        else {
            indexPath = [NSIndexPath indexPathForItem:2 inSection:0];
        }
        
    }
    
    NSNumber *selectedItem = [sidebar valueForKey:@"selectedItem"];
    
    if (selectedItem != nil) {
        
        Feed *item = [ArticlesManager.shared feedForID:selectedItem];
        
        if (item != nil) {
            indexPath = [self.DS indexPathForItemIdentifier:item];
        }
        
    }
    
    if (indexPath != nil) {
        
        weakify(self);
        
        runOnMainQueueWithoutDeadlocking(^{
            
            strongify(self);
            
            self->_restorationActivity = activity;
            
            [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
            
            [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
            
        });
        
    }
    
}

- (void)saveRestorationActivity:(NSUserActivity * _Nonnull)activity {
    
    NSMutableDictionary *sidebar = @{}.mutableCopy;
    
    // check for open folders
    NSDiffableDataSourceSectionSnapshot *sectionSnapshot = [self.DS snapshotForSection:@(NSUIntegerMax - 200)];
    
    NSMutableArray <NSNumber *> *openFolders = [NSMutableArray arrayWithCapacity:ArticlesManager.shared.folders.count];
    
    if (ArticlesManager.shared.folders != nil) {
        
        for (Folder *folder in ArticlesManager.shared.folders) {
            
            if ([sectionSnapshot isExpanded:folder]) {
                [openFolders addObject:folder.folderID];
            }
            
        }
        
    }
    
    [sidebar setObject:openFolders forKey:@"openFolders"];
    
    // Check for a selected item
    if (self.collectionView.indexPathsForSelectedItems > 0) {
        
        NSIndexPath *selected = self.collectionView.indexPathsForSelectedItems.firstObject;
        
        if (selected != nil) {
            
            Feed *item = [self.DS itemIdentifierForIndexPath:selected];
            
            if ([item isKindOfClass:CustomFeed.class]) {
                [sidebar setObject:@([(CustomFeed *)item feedType]) forKey:@"selectedCustom"];
            }
            else {
                [sidebar setObject:item.feedID forKey:@"selectedItem"];
            }
            
        }
        
    }
    
    [activity addUserInfoEntriesFromDictionary:@{@"sidebar": sidebar}];
    
}

#if TARGET_OS_MACCATALYST
#pragma mark - Timer

- (void)didChangeTimerPreference {
    
    if (self.refreshTimer != nil) {
        
        [self.refreshTimer invalidate];
        
        self.refreshTimer = nil;
        
    }
    
    [self scheduleTimerIfValid];
    
}

- (void)scheduleTimerIfValid {
    
    if (self.refreshTimer != nil) {
        // a timer was already setup.
        return;
    }
    
    if (SharedPrefs.refreshFeedsTimeInterval == -1) {
        return;
    }
    
    NSTimeInterval timeInterval = SharedPrefs.refreshFeedsTimeInterval;
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:timeInterval repeats:YES block:^(NSTimer * _Nonnull timer) {
        
        NSLog(@"Timer called at %@, refreshing counters and feeds", timer.fireDate);
        
        [self beginRefreshingAll:nil];
        
    }];
    
    NSLog(@"Scheduling timer with time interval: %@", @(timeInterval));
    
    [NSRunLoop.mainRunLoop addTimer:timer forMode:NSDefaultRunLoopMode];
    
    self.refreshTimer = timer;
    
}

#endif

#pragma mark -

- (void)badgePreferenceChanged {
    
    if (SharedPrefs.badgeAppIcon == NO) {
        
        UIApplication.sharedApplication.applicationIconBadgeNumber = 0;
        
    }
    else {
        
        UIApplication.sharedApplication.applicationIconBadgeNumber = MyFeedsManager.totalUnread;
        
    }
    
}

@end
