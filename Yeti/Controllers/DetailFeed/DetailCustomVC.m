//
//  DetailCustomVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 10/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DetailCustomVC.h"

#import "FeedsManager.h"

#import <DZKit/DZBasicDatasource.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import "YetiThemeKit.h"

#import "YetiConstants.h"

@interface DetailCustomVC () {
    BOOL _reloadDataset; // used for bookmarks
    BOOL _hasSetupState;
    YetiSortOption _sortingOption;
    
    BOOL _showingArticle;
}

@end

@implementation DetailCustomVC

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    _sortingOption = YTSortAllDesc;
    
    [self setupState];
    
}

- (void)setupState {
    
    if (_hasSetupState) {
        return;
    }
    
    _hasSetupState = YES;
    
    self.restorationIdentifier = self.isUnread ? @"UnreadVC-Detail" : @"BookmarksVC-Detail";
    self.title = self.isUnread ? @"Unread" : @"Bookmarks";
    
    if (self.isUnread == NO) {
        
        weakify(self);
        
        [self.bookmarksManager addObserver:self name:BookmarksDidUpdateNotification callback:^{
           
            strongify(self);
            [self didUpdateBookmarks];
            
        }];
        
        [self setupData];
        
        self.navigationItem.rightBarButtonItem = nil;
        
        if (@available(iOS 13, *)) {
            self.controllerState = StateLoaded;
        }
        else {
            self.DS.state = DZDatasourceLoaded;
        }
    }
    else {
        UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
        
        if (@available(iOS 13, *)) {
            YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
            
            if (theme.isDark) {
                refresh.tintColor = [theme captionColor];
            }
        }
        
        [refresh addTarget:self action:@selector(didBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
        self.collectionView.refreshControl = refresh;
        
        [self setupData];
        
        if (self.DS.data.count > 0) {
            self.page = floor([self.DS.data count]/10.f);
        }

        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didUpdateUnread) name:FeedDidUpReadCount object:MyFeedsManager];
    }
    
}

- (void)setupData {
    
    if (@available(iOS 13, *)) {
        if (self.unread == NO) {
            NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
            [snapshot appendSectionsWithIdentifiers:@[@0]];
            
            NSArray *bookmarks = self.bookmarksManager.bookmarks ?: @[];
            
            if ([_sortingOption isEqualToString:YTSortAllDesc]) {
                [snapshot appendItemsWithIdentifiers:bookmarks.reverseObjectEnumerator.allObjects];
            }
            else {
                [snapshot appendItemsWithIdentifiers:bookmarks];
            }
            
            [self.DDS applySnapshot:snapshot animatingDifferences:YES];
        }
        else {
            NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
            [snapshot appendSectionsWithIdentifiers:@[@0]];
            [snapshot appendItemsWithIdentifiers:(ArticlesManager.shared.unread ?: @[]) intoSectionWithIdentifier:@0];
            
            [self.DDS applySnapshot:snapshot animatingDifferences:YES];
        }
    }
    else {
        if (self.unread == NO) {
            
            if ([_sortingOption isEqualToString:YTSortAllDesc]) {
                self.DS.data = [self.bookmarksManager.bookmarks reverseObjectEnumerator].allObjects;
            }
            else {
                self.DS.data = self.bookmarksManager.bookmarks;
            }
            
        }
        else {
            self.DS.data = ArticlesManager.shared.unread;
        }
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_reloadDataset) {
        _reloadDataset = NO;
        
        [self setupData];
    }
    
    if (_showingArticle) {
        _showingArticle = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:animated];
    
    if (_showingArticle == NO) {
        [self.bookmarksManager removeObserver:self name:BookmarksDidUpdateNotification];
    }
    
}

- (void)_didFinishAllReadActionSuccessfully {
    if (self.isUnread) {
        [self setupData];
    }
}

#pragma mark - Overrides

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    _showingArticle = YES;
    
    [super collectionView:collectionView didSelectItemAtIndexPath:indexPath];
    
}

- (BOOL)showsSortingButton {
    return YES;
}

- (void)didTapSortOptions:(UIBarButtonItem *)sender {
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Sorting Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *allDesc = [UIAlertAction actionWithTitle:@"Newest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortUnreadDesc];
        
        [self setSortingOption:YTSortAllDesc];
        
    }];
    
    UIAlertAction *allAsc = [UIAlertAction actionWithTitle:@"Oldest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortUnreadAsc];
        
        [self setSortingOption:YTSortAllAsc];
        
    }];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    @try {
        [allDesc setValue:[SortImageProvider imageForSortingOption:YTSortUnreadDesc] forKeyPath:@"image"];
        [allAsc setValue:[SortImageProvider imageForSortingOption:YTSortUnreadAsc] forKeyPath:@"image"];
    }
    @catch (NSException *exc) {
        
    }
    
    [avc addAction:allDesc];
    [avc addAction:allAsc];
    
    [self presentAllReadController:avc fromSender:sender];
    
}

- (void)setSortingOption:(YetiSortOption)option {
    
    // this will call -[DetailFeedVC loadNextPage]
    [super setSortingOption:option];
    
    _sortingOption = option;
    
    [self setupData];
    
}

- (NSString *)emptyViewSubtitle {
    if (self.isUnread) {
        return @"No Unread Articles are available.";
    }
    
    return @"You dont have any bookmarks. Bookmarks are a great way to save articles for offline reading.";
}

- (void)loadNextPage {
    
    if (self.isUnread == NO) {
        return;
    }
    
    if (@available(iOS 13, *)) {
        if (self.controllerState == StateLoading) {
            return;
        }
    }
    else {
        if (self.DS.state == DZDatasourceLoading)
            return;
    }
    
    if (self->_canLoadNext == NO) {
        return;
    }
    
    if (@available(iOS 13, *)) {
        self.controllerState = StateLoading;
    }
    else {
        self.DS.state = DZDatasourceLoading;
    }
    
    weakify(self);
    
    if (self.isUnread) {
        NSInteger page = self.page + 1;
        YetiSortOption sorting = SharedPrefs.sortingOption;
        
        [MyFeedsManager getUnreadForPage:page sorting:sorting success:^(NSArray * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            
            if (!self)
                return;
            
            self.page = page;
            
            BOOL canLoadNext = YES;
            
            if (responseObject == nil || [responseObject count] == 0) {
                canLoadNext = NO;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->_canLoadNext = canLoadNext;
                    self.loadingNext = NO;
                });
                
            }
            else {
                [self setupData];
            }
            
            if (@available(iOS 13, *)) {
                self.controllerState = StateLoaded;
            }
            else {
                self.DS.state = DZDatasourceLoaded;
            }
            
            self.page = page;
            
            self.loadingNext = NO;
            
            weakify(self);
            
            asyncMain(^{
                strongify(self);
                
                if ([self.collectionView.refreshControl isRefreshing]) {
                    [self.collectionView.refreshControl endRefreshing];
                }
                
                if (page == 1 && canLoadNext) {
                    [self loadNextPage];
                }
            })
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            DDLogError(@"%@", error);
            
            strongify(self);
            
            if (!self)
                return;
            
            if (@available(iOS 13, *)) {
                self.controllerState = StateErrored;
            }
            else {
                self.DS.state = DZDatasourceError;
            }
            
            weakify(self);
            
            asyncMain(^{
                strongify(self);
                
                if ([self.collectionView.refreshControl isRefreshing]) {
                    [self.collectionView.refreshControl endRefreshing];
                }
            })
        }];
    }
    else {
        
        [self setupData];
        
        asyncMain(^{
            if ([self.collectionView.refreshControl isRefreshing]) {
                [self.collectionView.refreshControl endRefreshing];
            }
        })
    }
}

#pragma mark - Notifications

- (void)didBeginRefreshing:(UIRefreshControl *)sender {
    
    if ([sender isRefreshing]) {
        self.page = 0;
        _canLoadNext = YES;
        
        [self loadNextPage];
    }
    
}

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

#pragma mark - State Restoration

#define kBUnreadData @"UnreadData"
#define kBIsUnread @"VCIsUnread"

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    DetailCustomVC *vc = [[DetailCustomVC alloc] initWithFeed:nil];
    
    if ([coder decodeBoolForKey:kBIsUnread]) {
        vc.unread = YES;
    }
    
    vc.customFeed = FeedTypeCustom;
    vc.restorationIdentifier = vc.isUnread ? @"UnreadVC-Detail" : @"BookmarksVC-Detail";
    
    return vc;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    if (@available(iOS 13, *)) {
        [coder encodeObject:self.DDS.snapshot.itemIdentifiers forKey:kBUnreadData];
    }
    else {
        [coder encodeObject:self.DS.data forKey:kBUnreadData];
    }
    
    [coder encodeBool:self.unread forKey:kBIsUnread];
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super decodeRestorableStateWithCoder:coder];
    
    NSArray <FeedItem *> *items = [coder decodeObjectForKey:kBUnreadData];
    
    if (items) {
        [self setupLayout];
        
        if (@available(iOS 13, *)) {
            NSDiffableDataSourceSnapshot *snapshot = self.DDS.snapshot;
            [snapshot appendItemsWithIdentifiers:items];
            
            [self.DDS applySnapshot:snapshot animatingDifferences:YES];
        }
        else {
            self.DS.data = items;
        }
    }
    
}

@end
