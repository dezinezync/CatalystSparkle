//
//  UnreadVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "UnreadVC.h"
#import "SceneDelegate.h"
#import <DZKit/AlertManager.h>

#define kUnreadsDBFilteredView @"unreadsDBFilteredView"

@interface UnreadVC () {
    YetiSortOption _originalSortOption;
}

@property (nonatomic, strong) PagingManager *unreadsManager;

@property (nonatomic, strong) YapDatabaseAutoView *dbView;
@property (nonatomic, strong) YapDatabaseFilteredView *dbFilteredView;

@end

@implementation UnreadVC

- (instancetype)init {
    
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        
        self.type = FeedVCTypeUnread;
        self.restorationClass = [self class];
        self.restorationIdentifier = @"FeedVC-Unread";
        
        YetiSortOption option = SharedPrefs.sortingOption;
        _originalSortOption = option;
        
        if ([option isEqualToString:YTSortAllDesc]) {
            option = YTSortUnreadDesc;
        }
        else if ([option isEqualToString:YTSortAllAsc]) {
            option = YTSortUnreadAsc;
        }
        
        self.sortingOption = option;
        
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Unread";
    self.controllerState = StateLoading;
    self.pagingManager = self.unreadsManager;
    
#if !TARGET_OS_MACCATALYST
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(didBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
#else
    [self updateTitleView];
#endif
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateTitleView) name:UnreadCountDidUpdate object:nil];
    
}

- (void)dealloc {
    
    if (_originalSortOption != nil) {
        
        if ([SharedPrefs.sortingOption isEqualToString:_originalSortOption] == NO) {
            [SharedPrefs setValue:_originalSortOption forKey:propSel(sortingOption)];
        }
        
    }
    
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
}

- (void)setupDatabases:(YetiSortOption)sortingOption {
    
    NSDate *now = NSDate.date;
    NSTimeInterval interval = [now timeIntervalSince1970];

    YapDatabaseViewFiltering *filter = [YapDatabaseViewFiltering withMetadataBlock:^BOOL(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nullable metadata) {
        
        if ([collection containsString:LOCAL_ARTICLES_COLLECTION] == NO) {
            return NO;
        }

        // article metadata is an NSDictionary
        NSDictionary *dict = metadata;

        NSTimeInterval timestamp = [[metadata valueForKey:@"timestamp"] doubleValue];

        BOOL checkOne = (interval - timestamp) <= 1209600;

        if (checkOne == NO) {
            return NO;
        }

        BOOL checkTwo = ([([dict valueForKey:@"read"] ?: @(NO)) boolValue] == NO);
        
        if (checkTwo == YES) {
            // check date, should be within 14 days
            NSTimeInterval timestamp = [[metadata valueForKey:@"timestamp"] doubleValue];
            NSTimeInterval now = [NSDate.date timeIntervalSince1970];
            
            if ((now - timestamp) > 1209600) {
                checkTwo = NO;
            }
        }

        if (!checkTwo) {
            return NO;
        }
        
        // Filters
        
        if (MyFeedsManager.user.filters.count == 0) {
            return YES;
        }
        
        // compare title to each item in the filters
        
        NSArray <NSString *> *wordCloud = [metadata valueForKey:kTitleWordCloud] ?: @[];
        
        BOOL checkThree = [[NSSet setWithArray:wordCloud] intersectsSet:MyFeedsManager.user.filters];
        
        return !checkThree;

    }];
    
    self.dbFilteredView = [MyDBManager.database registeredExtension:kUnreadsDBFilteredView];
    
    if (self.dbFilteredView == nil) {
        
        YapDatabaseFilteredView *filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:DB_FEED_VIEW filtering:filter versionTag:[NSString stringWithFormat:@"%u",(uint)self.superclass.filteringTag++]];
        
        self.dbFilteredView = filteredView;
        
        [MyDBManager.database registerExtension:self.dbFilteredView withName:kUnreadsDBFilteredView];
        
    }
    else {
        
        [MyDBManager.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
           
            YapDatabaseFilteredViewTransaction *tnx = [transaction ext:kUnreadsDBFilteredView];
            
            [tnx setFiltering:filter versionTag:[NSString stringWithFormat:@"%u",(uint)self.superclass.filteringTag++]];
            
        }];
        
    }
    
}

#pragma mark - Subclassed

- (void)_setSortingOption:(YetiSortOption)option {
    
    [self setupDatabases:option];
    
    self.unreadsManager = nil;
    self.pagingManager = self.unreadsManager;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateTitleView];
    });
    
}

- (NSString *)subtitle {
    
    NSString *totalArticles = [NSString stringWithFormat:@"%@ Article%@, ", @(self.totalItemsForTitle), self.unreadsManager.total == 1 ? @"" : @"s"];
    
    NSString *unread = [NSString stringWithFormat:@"%@ Unread", @(MyFeedsManager.totalUnread)];
    
    return [totalArticles stringByAppendingString:unread];
    
}

- (NSUInteger)totalItemsForTitle {
        
    @synchronized (self) {
            
        if (self->_totalItemsForTitle == 0) {
            
            _totalItemsForTitle = MAX(self.unreadsManager.total, MyFeedsManager.totalUnread);;
            
        }
            
        return _totalItemsForTitle;
        
    }
    
}

- (NSString *)filteringViewName {
    return kUnreadsDBFilteredView;
}

- (PagingManager *)pagingManager {
    return self.unreadsManager;
}

- (PagingManager *)unreadsManager {
    
    if (_unreadsManager == nil && MyFeedsManager.userID != nil) {
        
        NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"limit": @10}.mutableCopy;
        
        params[@"sortType"] = @(self.sortingOption.integerValue);
        
        if ([MyFeedsManager subscription] != nil && [MyFeedsManager.subscription hasExpired] == YES) {
            params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
        }
        
        PagingManager * unreadsManager = [[PagingManager alloc] initWithPath:@"/unread" queryParams:params itemsKey:@"articles"];
        
        unreadsManager.fromDB = YES;
        
        weakify(self);
        
        unreadsManager.dbFetchingCB = ^(void (^ _Nonnull completion)(NSArray * _Nullable)) {
            
            strongify(self);
            
            self.controllerState = StateLoading;
            
            dispatch_async(MyDBManager.readQueue, ^{
                
                [MyDBManager.countsConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                    
                    YapDatabaseViewTransaction *ext = [transaction extension:kUnreadsDBFilteredView];
                    
                    if (ext == nil) {
                        return completion(nil);
                    }
                    
                    NSRange range = NSMakeRange(((self.unreadsManager.page - 1) * 20) - 1, 20);
                    
                    if (self.unreadsManager.page == 1) {
                        range.location = 0;
                    }
                    
                    NSMutableArray <FeedItem *> *items = [NSMutableArray arrayWithCapacity:20];
                    
                    NSEnumerationOptions options = kNilOptions;
                    
//                    if ([self.sortingOption isEqualToString:YTSortAllDesc] || [self.sortingOption isEqualToString:YTSortUnreadDesc]) {
//                        options = NSEnumerationReverse;
//                    }
                    
                    [ext enumerateKeysAndObjectsInGroup:GROUP_ARTICLES withOptions:options range:range usingBlock:^(NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object, NSUInteger index, BOOL * _Nonnull stop) {
                       
                        [items addObject:object];
                        
                    }];
                    
                    completion(items);
                    
                }];

                
            });
            
        };
        
        _unreadsManager = unreadsManager;
    }
    
    if (_unreadsManager.preProcessorCB == nil) {
        _unreadsManager.preProcessorCB = ^NSArray * _Nonnull(NSArray * _Nonnull items) {
          
            NSArray *retval = [items rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
                return [obj isKindOfClass:NSDictionary.class] ? [FeedItem instanceFromDictionary:obj] : obj;
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
                
                [self updateTitleView];
                
            }
            
            [self setupData];
            
            runOnMainQueueWithoutDeadlocking(^{
                self.controllerState = StateLoaded;
            });
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.refreshControl != nil && self.refreshControl.isRefreshing) {
                    [self.refreshControl endRefreshing];
                }
                
                if (self.unreadsManager.page == 1 && self.unreadsManager.hasNextPage == YES) {
                    [self loadNextPage];
                }
                
#if TARGET_OS_MACCATALYST
            if (self->_isRefreshing) {
                self->_isRefreshing = NO;
            }
#endif
            });
            
        };
    }
    
    if (_unreadsManager.errorCB == nil) {
        weakify(self);
        
        _unreadsManager.errorCB = ^(NSError * _Nonnull error) {
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
    
    return _unreadsManager;
    
}

- (NSString *)emptyViewSubtitle {
    return @"No Unread Articles are available.";
}

- (BOOL)showsSortingButton {
    return YES;
}

- (NSURLSessionTask *)searchOperationTask:(NSString *)text {
    
    return [MyFeedsManager searchUnread:text success:self.searchOperationSuccess error:self.searchOperationError];
    
}

//- (void)markAllDirectional:(NSInteger)direction indexPath:(NSIndexPath *)indexPath {
//    
//    YetiSortOption sorting = self.sortingOption ?: SharedPrefs.sortingOption;
//    
//    FeedItem *item = [self.DS itemIdentifierForIndexPath:indexPath];
//    
//    if (item == nil) {
//        return;
//    }
//    
//    BOOL isDescending = [sorting isEqualToString:YTSortAllDesc] || [sorting isEqualToString:YTSortUnreadDesc];
//    
//    weakify(self);
//    
//    dispatch_async(MyDBManager.readQueue, ^{
//        
//        [MyDBManager.uiConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
//            
//            NSString *localIdentifier = item.identifier.stringValue;
//            
//            YapDatabaseFilteredViewTransaction *tnx = [transaction ext:kUnreadsDBFilteredView];
//            
//            NSEnumerationOptions options = kNilOptions;
//            
//            if ((direction == 1 && isDescending) || (direction == 2 && isDescending == NO)) {
//                
//                // get all items from and before this index which are unread.
//                
//            }
//            else {
//                
//                // get all items from and after this index which are unread.
//                // enumerating backwards on our forward index will have the same effect.
//                options = NSEnumerationReverse;
//                
//            }
//            
//            NSMutableArray <id> *unreads = @[].mutableCopy;
//            
//            // get all items from and after this index which are unread.
//            [tnx enumerateKeysAndMetadataInGroup:GROUP_ARTICLES withOptions:options range:NSMakeRange(0, MyFeedsManager.totalUnread) usingBlock:^(NSString * _Nonnull collection, NSString * _Nonnull key, NSDictionary *  _Nullable metadata, NSUInteger index, BOOL * _Nonnull stop) {
//                
//                if (metadata != nil && ([([metadata valueForKey:@"read"] ?: @(NO)) boolValue] == NO)) {
//                    
//                    [unreads addObject:@(key.integerValue)];
//                    [unreads addObject:metadata];
//                    
//                }
//                
//                if ([key isEqualToString:localIdentifier]) {
//                    *stop = YES;
//                }
//                
//            }];
//            
//            NSLogDebug(@"IDs: %@", unreads);
//            
//            if (unreads.count == 0) {
//                return;
//            }
//            
//            [MyFeedsManager markRead:@"unread" articleID:item.identifier direction:direction sortType:sorting success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//              
//                dispatch_async(MyDBManager.readQueue, ^{
//                    
//                    [MyDBManager.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
//                        
//                        for (NSUInteger idx = 0; idx < unreads.count; idx+=2) {
//                            
//                            NSNumber *identifier = unreads[idx];
//                            NSMutableDictionary *metadata = [unreads[idx + 1] mutableCopy];
//                            
//                            id feedID = [metadata valueForKey:@"feedID"];
//                            NSString *collection = [NSString stringWithFormat:@"%@:%@", LOCAL_ARTICLES_COLLECTION, feedID];
//                            
//                            FeedItem * object = [transaction objectForKey:identifier.stringValue inCollection:collection];
//                            
//                            object.read = YES;
//                            [metadata setValue:@(YES) forKey:@"read"];
//                            
//                            [transaction setObject:object forKey:identifier.stringValue inCollection:collection withMetadata:metadata];
//                            
//                        }
//                        
//                        strongify(self);
//                        
//                        [self reloadCellsFrom:indexPath direction:(options == NSEnumerationReverse)];
//                        
//                    }];
//                    
//                });
//                
//            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//               
//                [AlertManager showGenericAlertWithTitle:@"Error Marking Read" message:error.localizedDescription fromVC:self];
//                
//            }];
//            
//        }];
//        
//    });
//
//}
//    
//- (void)reloadCellsFrom:(NSIndexPath *)indexPath direction:(BOOL)down {
// 
//    NSDiffableDataSourceSnapshot *snapshot = self.DS.snapshot;
//    
//    NSMutableArray <FeedItem *> * identifiers = [NSMutableArray arrayWithCapacity:snapshot.numberOfItems];
//    
//    if (down) {
//        
//        // all current cells till end of dataset
//        for (NSUInteger idx = indexPath.row; idx < snapshot.numberOfItems; idx++) {
//            
//            NSIndexPath *ip = [NSIndexPath indexPathForRow:idx inSection:indexPath.section];
//            
//            FeedItem * object = [self.DS itemIdentifierForIndexPath:ip];
//            
//            if (object != nil && object.isRead == NO) {
//                object.read = YES;
//                [identifiers addObject:object];
//            }
//            
//        }
//        
//    }
//    else {
//        
//        // current upto the 0th index
//        for (NSUInteger idx = 0; idx <= indexPath.row; idx++) {
//            
//            NSIndexPath *ip = [NSIndexPath indexPathForRow:idx inSection:indexPath.section];
//            
//            FeedItem * object = [self.DS itemIdentifierForIndexPath:ip];
//            object.read = YES;
//            
//            if (object != nil && object.isRead == NO) {
//                object.read = YES;
//            }
//            
//            [identifiers addObject:object];
//            
//        }
//        
//    }
//    
//    [snapshot reloadItemsWithIdentifiers:identifiers];
//    
//    [self.DS applySnapshot:snapshot animatingDifferences:YES];
//    
//}

- (void)didBeginRefreshing:(UIRefreshControl *)sender {
    
    // mac catalyst doesn't have a refresh control
#if !TARGET_OS_MACCATALYST
    if (sender != nil) {
#else
    if (self->_isRefreshing == NO) {
#endif
        self.unreadsManager = nil;
        [self loadNextPage];
    }
    
}

@end
