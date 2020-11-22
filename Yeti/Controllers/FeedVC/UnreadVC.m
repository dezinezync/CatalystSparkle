//
//  UnreadVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "UnreadVC.h"
#import "SceneDelegate.h"

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
        
        YetiSortOption option = SharedPrefs.sortingOption;
        
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

        return checkTwo;

    }];
    
    self.dbFilteredView = [MyDBManager.database registeredExtension:kUnreadsDBFilteredView];
    
    if (self.dbFilteredView == nil) {
        
        YapDatabaseFilteredView *filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:DB_FEED_VIEW filtering:filter versionTag:DB_VERSION_TAG];
        
        self.dbFilteredView = filteredView;
        
        [MyDBManager.database registerExtension:self.dbFilteredView withName:kUnreadsDBFilteredView];
        
    }
    else {
        
        [MyDBManager.countsConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
           
            YapDatabaseFilteredViewTransaction *tnx = [transaction ext:kUnreadsDBFilteredView];
            
            [tnx setFiltering:filter versionTag:[NSString stringWithFormat:@"%u",(uint)self->_filteringTag++]];
            
        }];
        
    }
    
}

#pragma mark - Subclassed

- (void)_setSortingOption:(YetiSortOption)option {
    
    self.unreadsManager = nil;
    self.pagingManager = self.unreadsManager;
    
    [self setupDatabases:option];
    
}

- (NSString *)subtitle {
    
    NSString *totalArticles = [NSString stringWithFormat:@"%@ Article%@, ", @(MAX(self.unreadsManager.total, MyFeedsManager.totalUnread)), self.unreadsManager.total == 1 ? @"" : @"s"];
    
    NSString *unread = [NSString stringWithFormat:@"%@ Unread", @(MyFeedsManager.totalUnread)];
    
    return [totalArticles stringByAppendingString:unread];
    
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

- (NSString *)emptyViewSubtitle {
    return @"No Unread Articles are available.";
}

- (BOOL)showsSortingButton {
    return YES;
}

- (NSURLSessionTask *)searchOperationTask:(NSString *)text {
    
    return [MyFeedsManager searchUnread:text success:self.searchOperationSuccess error:self.searchOperationError];
    
}

@end
