//
//  SidebarVC.m
//  Elytra
//
//  Created by Nikhil Nigade on 24/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SidebarVC+SearchResults.h"
#import "CustomFeed.h"

#import <DZKit/NSString+Extras.h>
#import <SDWebImage/SDWebImageManager.h>

#import <DZTextKit/NSString+ImageProxy.h>

@interface SidebarVC () {
    
    // Sync
    BOOL _refreshing;
    NSUInteger _refreshFeedsCounter;
    
    // Counters
    BOOL _fetchingCounters;
    
}

@property (nonatomic, strong, readwrite) UICollectionViewDiffableDataSource <NSNumber *, Feed *> *DS;

@property (nonatomic, strong) UICollectionViewCellRegistration *customFeedRegister, *folderRegister, *feedRegister;

@property (nonatomic, weak) UILabel *progressLabel;
@property (nonatomic, weak) UIProgressView *syncProgressView;
@property (nonatomic, strong) UIStackView *progressStackView;

@end

@implementation SidebarVC

static NSString * const kSidebarFeedCell = @"SidebarFeedCell";

+ (instancetype)instanceWithDefaultLayout {
    
    UICollectionViewCompositionalLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection * _Nullable(NSInteger section, id<NSCollectionLayoutEnvironment> _Nonnull environment) {
        
        UICollectionLayoutListConfiguration *config = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceSidebar];
        
        if (section == 0 || section == 2) {
            
            return [NSCollectionLayoutSection sectionWithListConfiguration:config layoutEnvironment:environment];
            
        }
        
        config.headerMode = UICollectionLayoutListHeaderModeFirstItemInSection;
        
        return [NSCollectionLayoutSection sectionWithListConfiguration:config layoutEnvironment:environment];
        
    }];
    
    SidebarVC *instance = [[SidebarVC alloc] initWithCollectionViewLayout:layout];
    
    return instance;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Feeds";

    [self setupNavigationBar];
    
    [self setupDatasource];
    
    [self setupData];
    
    [self setupNotifications];
    
    [self sync];

}

- (void)dealloc {
    
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
}

#pragma mark - Setup

- (void)setupNavigationBar {
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    
    self.navigationItem.leftBarButtonItems = @[self.splitViewController.displayModeButtonItem, self.leftBarButtonItem];
    self.navigationItem.rightBarButtonItems = self.rightBarButtonItems;
    
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    // Search Controller setup
    {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
        
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        searchController.searchResultsUpdater = self;
        searchController.delegate = self;
        searchController.obscuresBackgroundDuringPresentation = NO;
        searchController.searchBar.placeholder = @"Search Feeds";
        searchController.searchBar.accessibilityHint = @"Search your feeds";
        
        searchController.searchBar.layer.borderColor = [UIColor clearColor].CGColor;
        
        self.navigationItem.searchController = searchController;
    }
    
}

- (void)setupDatasource {
    
    if (self.DS != nil) {
        return;
    }
    
    self.DS = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, id _Nonnull item) {
        
        if ([item isKindOfClass:CustomFeed.class]) {
            
            return [collectionView dequeueConfiguredReusableCellWithRegistration:self.customFeedRegister forIndexPath:indexPath item:item];
            
        }
        else if ([item isKindOfClass:Folder.class]) {
            
            return [collectionView dequeueConfiguredReusableCellWithRegistration:self.folderRegister forIndexPath:indexPath item:item];
            
        }
        
        return [collectionView dequeueConfiguredReusableCellWithRegistration:self.feedRegister forIndexPath:indexPath item:item];
        
    }];
    
}

- (void)setupData {
    
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
            
            for (Folder *folder in ArticlesManager.shared.folders) {
                
                [foldersSnapshot appendItems:@[folder]];
                
                NSArray <Feed *> *feeds = [folder.feeds.allObjects sortedArrayUsingDescriptors:@[alphaSort]];
                
                [foldersSnapshot appendItems:feeds intoParentItem:folder];
                
            }
            
        }
        
        [self.DS applySnapshot:foldersSnapshot toSection:@(NSUIntegerMax - 200) animatingDifferences:NO];
        
        if (ArticlesManager.shared.feedsWithoutFolders) {

            NSDiffableDataSourceSectionSnapshot *onlyFeedsSnapshot = [NSDiffableDataSourceSectionSnapshot new];
            
            [onlyFeedsSnapshot appendItems:ArticlesManager.shared.feedsWithoutFolders];
            
            [self.DS applySnapshot:onlyFeedsSnapshot toSection:@(NSUIntegerMax - 100) animatingDifferences:NO];

        }
        
    }
    
}

- (void)setupNotifications {
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(setupData) name:FeedsDidUpdate object:ArticlesManager.shared];
    
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
            
//            if ([self.refreshControl isRefreshing]) {
//                [self.refreshControl endRefreshing];
//            }
            
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
    
}

#pragma mark - Getters

- (UICollectionViewCellRegistration *)customFeedRegister {
    
    if (_customFeedRegister == nil) {
        
        weakify(self);
        
        UICollectionViewCellRegistration *customFeedsRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, Feed *  _Nonnull item) {
            
            UIListContentConfiguration *content = [UIListContentConfiguration sidebarCellConfiguration];
            
            content.text = item.displayTitle;
            
            content.prefersSideBySideTextAndSecondaryText = YES;
            
            if (indexPath.item == 0) {
                
                if (MyFeedsManager.totalUnread > 0) {
                    content.secondaryText = [@(MyFeedsManager.totalUnread) stringValue];
                }
                
            }
            
            if (indexPath.item == 1) {
                
                if (MyFeedsManager.totalToday > 0) {
                    content.secondaryText = [@(MyFeedsManager.totalToday) stringValue];
                }
                
            }
            
            if (indexPath.item == 2) {
                
                strongify(self);
                
                MainCoordinator *coordinator = [self mainCoordinator];
                
                BookmarksManager *manager = coordinator.bookmarksManager;
                
                if (manager.bookmarksCount > 0) {
                    
                    content.secondaryText = [@(manager.bookmarksCount) stringValue];
                    
                }
                
            }
            
            content.image = [UIImage systemImageNamed:[(CustomFeed *)item imageName]];
            
            content.imageProperties.tintColor = [(CustomFeed *)item tintColor];
            
            cell.contentConfiguration = content;
            
        }];
        
        _customFeedRegister = customFeedsRegistration;
        
    }
    
    return _customFeedRegister;
    
}

- (UICollectionViewCellRegistration *)folderRegister {
    
    if (_folderRegister == nil) {
        
        UICollectionViewCellRegistration *folderRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, Folder *  _Nonnull item) {
           
            UIListContentConfiguration *content = [UIListContentConfiguration sidebarHeaderConfiguration];
            
            content.text = item.title;
            
            if (item.unreadCount.unsignedIntegerValue > 0) {
                
                content.secondaryText = item.unreadCount.stringValue;
                
            }
            
            content.prefersSideBySideTextAndSecondaryText = YES;
            
            NSDiffableDataSourceSectionSnapshot *snapshot = [self.DS snapshotForSection:@(NSUIntegerMax - 200)];
            
            NSString *imageName = [snapshot isExpanded:item] ? @"folder" : @"folder.fill";
            
            content.image = [UIImage systemImageNamed:imageName];
            
            cell.contentConfiguration = content;
            
            UICellAccessoryOutlineDisclosure *disclosure = [UICellAccessoryOutlineDisclosure new];
            
            disclosure.style = UICellAccessoryOutlineDisclosureStyleHeader;
            
            disclosure.actionHandler = ^{
                
                NSDiffableDataSourceSectionSnapshot *sectionSnapshot = [self.DS snapshotForSection:@(NSUIntegerMax - 200)];
                
                UIListContentConfiguration *updatedContent = (id)[cell contentConfiguration];
                
                if ([sectionSnapshot isExpanded:item] == YES) {
                    
                    [sectionSnapshot collapseItems:@[item]];
                    
                    updatedContent.image = [UIImage systemImageNamed:@"folder.fill"];
                    
                }
                else {
                    
                    [sectionSnapshot expandItems:@[item]];
                    
                    updatedContent.image = [UIImage systemImageNamed:@"folder"];
                    
                }
                
                cell.contentConfiguration = updatedContent;
                
                [self.DS applySnapshot:sectionSnapshot toSection:@(NSUIntegerMax - 200) animatingDifferences:YES];
                
            };
            
            cell.accessories = @[disclosure];
            
        }];
        
        _folderRegister = folderRegistration;
        
    }
    
    return _folderRegister;
    
}

- (UICollectionViewCellRegistration *)feedRegister {
    
    if (_feedRegister == nil) {
        
        UICollectionViewCellRegistration *feedRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, Feed *  _Nonnull item) {
           
            UIListContentConfiguration *content = [cell defaultContentConfiguration];
            
            content.text = item.displayTitle;
            
            content.prefersSideBySideTextAndSecondaryText = YES;
            
            if (item.unread.unsignedIntegerValue > 0) {
                
                content.secondaryText = item.unread.stringValue;
                
            }
            
            content.image = item.faviconImage ?: [UIImage systemImageNamed:@"square.dashed"];
            
            if (item.faviconImage == nil) {

                NSString *url = [item faviconURI];

                if (url != nil && [url isKindOfClass:NSString.class] && [url isBlank] == NO) {

                    CGFloat maxWidth = 24.f / UIScreen.mainScreen.scale;

                    url = [url pathForImageProxy:NO maxWidth:maxWidth quality:0.f];

                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

                        __unused SDWebImageCombinedOperation *op = [SDWebImageManager.sharedManager loadImageWithURL:[NSURL URLWithString:url] options:SDWebImageScaleDownLargeImages progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {

                            if (image != nil) {

                                CGFloat cornerRadius = 3.f * UIScreen.mainScreen.scale;

                                image = [image sd_roundedCornerImageWithRadius:cornerRadius corners:UIRectCornerAllCorners borderWidth:0.f borderColor:nil];

                                item.faviconImage = image;

                                NSIndexPath * feedIndexPath = [self.DS indexPathForItemIdentifier:item];

                                if (feedIndexPath == nil) {

                                    return;

                                }
                                
                                UICollectionViewListCell *blockCell = (UICollectionViewListCell *)[self.collectionView cellForItemAtIndexPath:feedIndexPath];

                                UIListContentConfiguration *config = (UIListContentConfiguration *)[blockCell contentConfiguration];
                                
                                config.image = image;
                                
                                blockCell.contentConfiguration = config;

                            }

                        }];

                    });

                }

            }
            
            cell.contentConfiguration = content;
            
            if (indexPath.section != 2) {
                
                cell.indentationLevel = 1;
                
            }
            else {
                
                cell.indentationLevel = 0;
                
            }
            
            UICellAccessoryDisclosureIndicator *disclosure = [UICellAccessoryDisclosureIndicator new];
            
            cell.accessories = @[disclosure];
            
        }];
        
        _feedRegister = feedRegistration;
        
    }
    
    return _feedRegister;
    
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
        progressView.progressTintColor = self.view.window.tintColor;
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
    
}

#pragma mark - Misc

- (void)sync {
    
    if ((ArticlesManager.shared.feeds.count == 0 || ArticlesManager.shared.folders.count == 0)
        && _refreshing == NO
        && _refreshFeedsCounter < 3) {
        
        _refreshFeedsCounter++;
        
        [MyFeedsManager getFeedsWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self sync];
            });
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self sync];
            });
            
        }];
        
        return;
        
    }
    
    _refreshFeedsCounter = 0;
    
    if (_refreshing == YES) {
        return;
    }
    
//    if ([self.refreshControl isRefreshing] == NO) {
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//
//            [self.refreshControl beginRefreshing];
//
//        });
//
//    }
    
    _refreshing = YES;
    
    [self fetchLatestCounters];
    
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
        
        if (snapshot != nil) {
            
            if (snapshot.numberOfSections > 0) {
                [snapshot reloadSectionsWithIdentifiers:snapshot.sectionIdentifiers];
            }
            else {
                snapshot = nil;
                [self setupData];
            }
            
        }
        
//        if ([self.refreshControl isRefreshing]) {
//            [self.refreshControl endRefreshing];
//        }
        
        if (snapshot != nil) {
            [self.DS applySnapshot:snapshot animatingDifferences:YES];
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSLog(@"Error: Failed to fetch counters with error:%@", error.localizedDescription);
        
        self->_fetchingCounters = NO;
        self->_refreshing = NO;
        
    }];
    
}

@end
