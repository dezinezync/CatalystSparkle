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

#import "PagingManager.h"

@interface DetailCustomVC () {
    BOOL _reloadDataset; // used for bookmarks
    BOOL _hasSetupState;
    YetiSortOption _sortingOption;
    
    BOOL _showingArticle;
}

@property (nonatomic, strong) PagingManager *unreadsManager;

@end

@implementation DetailCustomVC

- (void)viewWillAppear:(BOOL)animated {
    
    _sortingOption = YTSortUnreadDesc;
    
    [super viewWillAppear:animated];
    
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
        
        self.controllerState = StateLoaded;
    }
    else {
        
        UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
        
        [refresh addTarget:self action:@selector(didBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
        self.collectionView.refreshControl = refresh;
        
        [self setupData];

        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didUpdateUnread) name:FeedDidUpReadCount object:MyFeedsManager];
    }
    
}

- (void)setupData {
    
    if (self.unread == NO) {
        NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
        [snapshot appendSectionsWithIdentifiers:@[@0]];
        
        NSArray *bookmarks = self.bookmarksManager.bookmarks ?: @[];
        NSOrderedSet *set = [NSOrderedSet orderedSetWithArray:bookmarks];
        
        bookmarks = set.array;
        
        if ([_sortingOption isEqualToString:YTSortUnreadDesc]) {
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
        [snapshot appendItemsWithIdentifiers:(self.unreadsManager.items ?: @[]) intoSectionWithIdentifier:@0];
        
        [self.DDS applySnapshot:snapshot animatingDifferences:YES];
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

#pragma mark - Getters

- (PagingManager *)pagingManager {
    
    return self.unreadsManager;
    
}

- (PagingManager *)unreadsManager {
    
    if (_unreadsManager == nil) {
        NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"limit": @10}.mutableCopy;
        
        params[@"sortType"] = @(_sortingOption.integerValue);
            
        #if TESTFLIGHT == 0
            if ([MyFeedsManager subscription] != nil && [MyFeedsManager.subscription hasExpired] == YES) {
                params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
            }
        #endif
        
        PagingManager * unreadsManager = [[PagingManager alloc] initWithPath:@"/unread" queryParams:params itemsKey:@"articles"];
        
        _unreadsManager = unreadsManager;
    }
    
    if (_unreadsManager.preProcessorCB == nil) {
        _unreadsManager.preProcessorCB = ^NSArray * _Nonnull(NSArray * _Nonnull items) {
          
            NSArray *retval = [items rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
                return [FeedItem instanceFromDictionary:obj];
            }];
            
            return retval;
            
        };
    }
    
    if (_unreadsManager.successCB == nil) {
        weakify(self);
        
        _unreadsManager.successCB = ^{
            strongify(self);
            
            if (!self) {
                return;
            }
            
            if (self->_unreadsManager.page == 1) {
                MyFeedsManager.unreadLastUpdate = NSDate.date;
            }
            
            [self setupData];
            
            self.controllerState = StateLoaded;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.collectionView.refreshControl isRefreshing]) {
                    [self.collectionView.refreshControl endRefreshing];
                }
                
                if (self.unreadsManager.page == 1 && self.unreadsManager.hasNextPage == YES) {
                    [self loadNextPage];
                }
            });
            
        };
    }
    
    if (_unreadsManager.errorCB == nil) {
        weakify(self);
        
        _unreadsManager.errorCB = ^(NSError * _Nonnull error) {
            DDLogError(@"%@", error);
            
            strongify(self);
            
            if (!self)
                return;
            
            self.controllerState = StateErrored;
            
            weakify(self);
            
            asyncMain(^{
                strongify(self);
                
                if ([self.collectionView.refreshControl isRefreshing]) {
                    [self.collectionView.refreshControl endRefreshing];
                }
            })
        };
    }
    
    return _unreadsManager;
    
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
    
    weakify(self);
    
    UIAlertAction *allDesc = [UIAlertAction actionWithTitle:@"Newest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortUnreadDesc];
        
        strongify(self);
        
        self->_sortingOption = YTSortUnreadDesc;
        
        [self setSortingOption:self->_sortingOption];
        
    }];
    
    UIAlertAction *allAsc = [UIAlertAction actionWithTitle:@"Oldest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortUnreadAsc];
        
        strongify(self);
        
        self->_sortingOption = YTSortUnreadAsc;
        
        [self setSortingOption:self->_sortingOption];
        
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

//- (void)setSortingOption:(YetiSortOption)option {
//
//    self.unreadsManager = nil;
//
//    // this will call -[DetailFeedVC loadNextPage]
//    [super setSortingOption:option];
//
//    _sortingOption = option;
//
//}

- (NSString *)emptyViewSubtitle {
    if (self.isUnread) {
        return @"No Unread Articles are available.";
    }
    
    return @"You dont have any bookmarks. Bookmarks are a great way to save articles for offline reading.";
}

- (void)loadNextPage {
    
    if (self.isUnread == NO) {
        [self setupData];
        return;
    }
    
    [super loadNextPage];
}

#pragma mark - Notifications

- (void)didBeginRefreshing:(UIRefreshControl *)sender {
    
    if ([sender isRefreshing]) {
        self.unreadsManager = nil;
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
    
    if (self.unreadsManager) {
        [coder encodeObject:self.unreadsManager forKey:@"unreadsManager"];
    }
    
    [coder encodeBool:self.unread forKey:kBIsUnread];
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super decodeRestorableStateWithCoder:coder];
    
    self.unreadsManager = [coder decodeObjectOfClass:PagingManager.class forKey:@"unreadsManager"];
    self.controllerState = StateLoaded;
    
}

@end
