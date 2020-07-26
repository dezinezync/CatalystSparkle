//
//  SidebarVC.m
//  Elytra
//
//  Created by Nikhil Nigade on 24/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SidebarVC.h"
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

@property (nonatomic, strong) UICollectionViewDiffableDataSource <NSNumber *, Feed *> *DS;

@end

@implementation SidebarVC

static NSString * const kSidebarFeedCell = @"SidebarFeedCell";

+ (instancetype)instanceWithDefaultLayout {
    
    UICollectionViewCompositionalLayout *layout = [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection * _Nullable(NSInteger section, id<NSCollectionLayoutEnvironment> _Nonnull environment) {
        
        UICollectionLayoutListConfiguration *config = [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceSidebar];
        
        if (section == 0 || section == 4) {
            
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

    self.navigationController.navigationBar.prefersLargeTitles = YES;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    
    [self setupDatasource];
    
    [self setupData];
    
    [self setupNotifications];
    
    [self sync];

}

- (void)dealloc {
    
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
}

#pragma mark - Setup

- (void)setupDatasource {
    
    if (self.DS != nil) {
        return;
    }
    
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
        
//        UIListContentImageProperties *imageProperties = [UIListContentImageProperties new];
//        imageProperties.tintColor = [(CustomFeed *)item tintColor];
//
//        content.imageProperties = imageProperties;
        
        cell.contentConfiguration = content;
        
    }];
    
    UICollectionViewCellRegistration *folderRegistration = [UICollectionViewCellRegistration registrationWithCellClass:UICollectionViewListCell.class configurationHandler:^(__kindof UICollectionViewListCell * _Nonnull cell, NSIndexPath * _Nonnull indexPath, Folder *  _Nonnull item) {
       
        UIListContentConfiguration *content = [UIListContentConfiguration groupedHeaderConfiguration];
        
        content.text = item.title;
        
        if (item.unreadCount.unsignedIntegerValue > 0) {
            
            content.secondaryText = item.unreadCount.stringValue;
            
        }
        
        content.prefersSideBySideTextAndSecondaryText = YES;
        
        NSDiffableDataSourceSectionSnapshot *snapshot = [self.DS snapshotForSection:@(indexPath.section)];
        
        NSString *imageName = [snapshot isExpanded:item] ? @"folder" : @"folder.fill";
        
        content.image = [UIImage systemImageNamed:imageName];
        
        cell.contentConfiguration = content;
        
        UICellAccessoryOutlineDisclosure *disclosure = [UICellAccessoryOutlineDisclosure new];
        
        disclosure.style = UICellAccessoryOutlineDisclosureStyleHeader;
        
        cell.accessories = @[disclosure];
        
    }];
    
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
        
        if (indexPath.section != 4) {
            
            cell.indentationLevel = 1;
            
        }
        else {
            
            cell.indentationLevel = 0;
            
        }
        
        UICellAccessoryDisclosureIndicator *disclosure = [UICellAccessoryDisclosureIndicator new];
        
        cell.accessories = @[disclosure];
        
    }];
    
    self.DS = [[UICollectionViewDiffableDataSource alloc] initWithCollectionView:self.collectionView cellProvider:^UICollectionViewCell * _Nullable(UICollectionView * _Nonnull collectionView, NSIndexPath * _Nonnull indexPath, id _Nonnull item) {
        
        if (indexPath.section == 0) {
            
            return [collectionView dequeueConfiguredReusableCellWithRegistration:customFeedsRegistration forIndexPath:indexPath item:item];
            
        }
        else if (indexPath.section == 1) {
            
            if ([item isKindOfClass:Folder.class] == YES) {
                
                return [collectionView dequeueConfiguredReusableCellWithRegistration:folderRegistration forIndexPath:indexPath item:item];
                
            }
            
        }
        
        return [collectionView dequeueConfiguredReusableCellWithRegistration:feedRegistration forIndexPath:indexPath item:item];
        
    }];
    
}

- (void)setupData {
    
    NSDiffableDataSourceSectionSnapshot *snapshot = [NSDiffableDataSourceSectionSnapshot new];
    
    CustomFeed *unread = [[CustomFeed alloc] initWithTitle:@"Unread" imageName:@"largecircle.fill.circle" tintColor:UIColor.systemBlueColor feedType:FeedVCTypeUnread];
    unread.feedID = @(0);
    
    CustomFeed *today = [[CustomFeed alloc] initWithTitle:@"Today" imageName:@"calendar" tintColor:UIColor.systemRedColor feedType:FeedVCTypeToday];
    unread.feedID = @(1);
    
    [snapshot appendItems:@[unread, today]];
    
    if (SharedPrefs.hideBookmarks == NO) {
        
        CustomFeed *bookmarks = [[CustomFeed alloc] initWithTitle:@"Bookmarks" imageName:@"bookmark.fill" tintColor:UIColor.systemOrangeColor feedType:FeedVCTypeBookmarks];
        
        bookmarks.feedID = @(2);
        
        [snapshot appendItems:@[bookmarks]];
        
    }
    
    [self.DS applySnapshot:snapshot toSection:@(0) animatingDifferences:NO];
    
    NSDiffableDataSourceSectionSnapshot *foldersSnapshot = [NSDiffableDataSourceSectionSnapshot new];
    
    if (ArticlesManager.shared.feeds.count) {
        
        if (ArticlesManager.shared.folders.count) {
            
            for (Folder *folder in ArticlesManager.shared.folders) {
                
                [foldersSnapshot appendItems:@[folder]];
                
                [foldersSnapshot appendItems:folder.feeds.allObjects intoParentItem:folder];
                
            }
            
        }
        
        [self.DS applySnapshot:foldersSnapshot toSection:@(1) animatingDifferences:NO];
        
        if (ArticlesManager.shared.feedsWithoutFolders) {

            NSDiffableDataSourceSectionSnapshot *onlyFeedsSnapshot = [NSDiffableDataSourceSectionSnapshot new];
            
            [onlyFeedsSnapshot appendItems:ArticlesManager.shared.feedsWithoutFolders];
            
            [self.DS applySnapshot:onlyFeedsSnapshot toSection:@(2) animatingDifferences:NO];

        }
        
    }
    
}

- (void)setupNotifications {
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(setupData) name:FeedsDidUpdate object:ArticlesManager.shared];
    
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
