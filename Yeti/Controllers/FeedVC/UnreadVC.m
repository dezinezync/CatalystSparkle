//
//  UnreadVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "UnreadVC.h"
#import "SceneDelegate.h"

#define kUnreadsDBView @"unreadsDBView"
#define kUnreadsDBFilteredView @"unreadsDBFilteredView"

@interface UnreadVC ()

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
        
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Unread";
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

- (void)unregisterDBViews {
    
    if (self.dbFilteredView) {
        [MyDBManager.database unregisterExtensionWithName:kUnreadsDBFilteredView];
        self.dbFilteredView = nil;
    }
    
    if (self.dbView) {
        [MyDBManager.database unregisterExtensionWithName:kUnreadsDBView];
        self.dbView = nil;
    }
    
}

- (void)dealloc {
    
    [self unregisterDBViews];
    
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
}

- (void)setupDatabases:(YetiSortOption)sortingOption {
    
    YapDatabaseViewGrouping *group = [YapDatabaseViewGrouping withKeyBlock:^NSString * _Nullable(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull collection, NSString * _Nonnull key) {
       
        if ([collection containsString:LOCAL_ARTICLES_COLLECTION]) {
            return GROUP_ARTICLES;
        }
        
        return nil;
        
    }];
    
    NSDate *now = NSDate.date;
    
    YapDatabaseViewFiltering *filter = [YapDatabaseViewFiltering withRowBlock:^BOOL(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection, NSString * _Nonnull key, FeedItem *  _Nonnull object, id  _Nullable metadata) {
        
        if ([collection containsString:LOCAL_ARTICLES_COLLECTION] == NO) {
            return NO;
        }
        
        // article metadata is an NSDictionary
        NSDictionary *dict = metadata;
        
        BOOL checkOne = ([([dict valueForKey:@"read"] ?: @(NO)) boolValue] == NO);
        BOOL checkTwo = [now timeIntervalSinceDate:object.timestamp] <= 1209600;
        
        return checkOne && checkTwo;
        
    }];
    
    weakify(sortingOption);
    
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection1, NSString * _Nonnull key1, FeedItem *  _Nonnull object1, NSString * _Nonnull collection2, NSString * _Nonnull key2, FeedItem *  _Nonnull object2) {
        
        NSComparisonResult result = [object1.timestamp compare:object2.timestamp];
        
        if (result == NSOrderedSame) {
            return result;
        }
        
        strongify(sortingOption);
        
        if ([sortingOption isEqualToString:YTSortAllDesc]  || [sortingOption isEqualToString:YTSortUnreadDesc]) {
            
            if (result == NSOrderedDescending) {
                return NSOrderedAscending;
            }
            
            return NSOrderedDescending;
            
        }
        
        return result;
        
    }];
    
    YapDatabaseAutoView *view = [[YapDatabaseAutoView alloc] initWithGrouping:group sorting:sorting];
    self.dbView = view;
    
    [MyDBManager.database registerExtension:self.dbView withName:kUnreadsDBView];
    
    YapDatabaseFilteredView *filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:kUnreadsDBView filtering:filter];
    
    self.dbFilteredView = filteredView;
    
    [MyDBManager.database registerExtension:self.dbFilteredView withName:kUnreadsDBFilteredView];
    
}

#pragma mark - Subclassed

- (void)setSortingOption:(YetiSortOption)sortingOption {
    
    runOnMainQueueWithoutDeadlocking(^{
        [self unregisterDBViews];
        [self setupDatabases:sortingOption];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.125 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [super setSortingOption:sortingOption];
    });
    
}

- (NSString *)subtitle {
    
    NSString *totalArticles = [NSString stringWithFormat:@"%@ Article%@, ", @(MAX(self.unreadsManager.total, MyFeedsManager.totalUnread)), self.unreadsManager.total == 1 ? @"" : @"s"];
    
    NSString *unread = [NSString stringWithFormat:@"%@ Unread", @(MyFeedsManager.totalUnread)];
    
    return [totalArticles stringByAppendingString:unread];
    
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
            
//            YapDatabaseViewConnection *connection = [MyDBManager.uiConnection extension:UNREADS_FEED_EXT];
            
            [MyDBManager.uiConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                
                strongify(self);
                
                YapDatabaseViewTransaction *ext = [transaction extension:kUnreadsDBFilteredView];
                
                if (ext == nil) {
                    return completion(nil);
                }
                
                NSRange range = NSMakeRange(((self.unreadsManager.page - 1) * 20) - 1, 20);
                
                if (self.unreadsManager.page == 1) {
                    range.location = 0;
                }
                
                NSMutableArray <FeedItem *> *items = [NSMutableArray arrayWithCapacity:20];
                
                [ext enumerateKeysAndObjectsInGroup:GROUP_ARTICLES withOptions:kNilOptions range:range usingBlock:^(NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object, NSUInteger index, BOOL * _Nonnull stop) {
                   
                    [items addObject:object];
                    
                }];
                
                completion(items);
                
            }];
            
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
            
            self.controllerState = StateLoaded;
            
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

- (void)didBeginRefreshing:(UIRefreshControl *)sender {
    
    // mac catalyst doesn't have a refresh control
#if !TARGET_OS_MACCATALYST
    if (sender != nil) {
#else
    if (self->_isRefreshing == NO) {
#endif
        self.unreadsManager = nil;
        self.pagingManager = self.unreadsManager;
        [self loadNextPage];
    }
    
}

- (NSString *)emptyViewSubtitle {
    return @"No Unread Articles are available.";
}

- (BOOL)showsSortingButton {
    return YES;
}

- (void)_setSortingOption:(YetiSortOption)option {
    
    self.unreadsManager = nil;
    self.pagingManager = self.unreadsManager;
    
}

- (NSURLSessionTask *)searchOperationTask:(NSString *)text {
    
    return [MyFeedsManager searchUnread:text success:self.searchOperationSuccess error:self.searchOperationError];
    
}

@end
