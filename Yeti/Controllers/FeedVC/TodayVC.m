//
//  TodayVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "TodayVC.h"

#define kTodayDBView @"todayDBView"
#define kTodayDBFilteredView @"todayDBFilteredView"

@interface TodayVC ()

@property (nonatomic, strong) PagingManager *todayManager;

@property (nonatomic, strong) YapDatabaseAutoView *dbView;
@property (nonatomic, strong) YapDatabaseFilteredView *dbFilteredView;

@end

@implementation TodayVC

- (instancetype)init {
    
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        
        self.type = FeedVCTypeToday;
        
        self.restorationClass = [self class];
        self.restorationIdentifier = @"FeedVC-Today";
        
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Today";
    self.pagingManager = self.todayManager;
    self.controllerState = StateDefault;
    
#if !TARGET_OS_MACCATALYST
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(didBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
#endif
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateTitleView) name:TodayCountDidUpdate object:nil];
    
}

- (void)dealloc {
    
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
}

- (void)setupDatabases:(YetiSortOption)sortingOption {
    
    YapDatabaseViewFiltering *filter = [YapDatabaseViewFiltering withRowBlock:^BOOL(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection, NSString * _Nonnull key, FeedItem *  _Nonnull object, id  _Nullable metadata) {
        
        if ([collection containsString:LOCAL_ARTICLES_COLLECTION] == NO) {
            return NO;
        }
        
        // article metadata is an NSDictionary
        NSDictionary *dict = metadata;
        
        NSTimeInterval interval = [[dict valueForKey:@"timestamp"] doubleValue];
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:interval];
        
        BOOL checkOne = [NSCalendar.currentCalendar isDateInToday:date];
        
        if (!checkOne) {
            return NO;
        }
        
        BOOL checkTwo = YES;
        
        if ([sortingOption isEqualToString:YTSortUnreadAsc] || [sortingOption isEqualToString:YTSortUnreadDesc]) {
            
            checkTwo = [([metadata valueForKey:@"read"] ?: @(NO)) boolValue] == NO;
            
        }
        
        if (!checkTwo) {
            return NO;
        }
        
        // Filters
        
        if (MyFeedsManager.user.filters.count == 0) {
            return YES;
        }
        
        // compare title to each item in the filters
        
        __block BOOL checkThree = YES;
        
        [MyFeedsManager.user.filters enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            
            if ([object.articleTitle.lowercaseString containsString:obj] == YES) {
                checkThree = NO;
                *stop = YES;
                return;
            }
            
            if (object.summary != nil && [object.summary.lowercaseString containsString:obj] == YES) {
                checkThree = NO;
                *stop = YES;
            }
            
        }];
        
        return checkThree;
        
    }];
    
    self.dbFilteredView = [MyDBManager.database registeredExtension:kTodayDBFilteredView];
    
    if (self.dbFilteredView == nil) {
        
        YapDatabaseFilteredView *filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:DB_FEED_VIEW filtering:filter versionTag:[NSString stringWithFormat:@"%u",(uint)self.superclass.filteringTag++]];
        
        self.dbFilteredView = filteredView;
        
        [MyDBManager.database registerExtension:self.dbFilteredView withName:kTodayDBFilteredView];
        
    }
    else {
        
        [MyDBManager.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
           
            YapDatabaseFilteredViewTransaction *tnx = [transaction ext:kTodayDBFilteredView];
            
            [tnx setFiltering:filter versionTag:[NSString stringWithFormat:@"%u",(uint)self.superclass.filteringTag++]];
            
        }];
        
    }
    
}

#pragma mark - Subclassed

- (NSString *)filteringViewName {
    return kTodayDBFilteredView;
}

- (NSString *)subtitle {
    
    NSString *totalArticles = [NSString stringWithFormat:@"%@ Article%@, ", @(self.todayManager.total), self.todayManager.total == 1 ? @"" : @"s"];
    
    NSString *unread = [NSString stringWithFormat:@"%@ Unread", @(MyFeedsManager.totalToday)];
    
    return [totalArticles stringByAppendingString:unread];
    
}

- (PagingManager *)pagingManager {
    return self.todayManager;
}

- (PagingManager *)todayManager {
    
    if (_todayManager == nil) {
        
        NSDate *today = [NSDate date];
        NSDateComponents *comps = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:today];
        
        NSString *todayString = [NSString stringWithFormat:@"%@-%@-%@", @(comps.year), @(comps.month), @(comps.day)];
        
        NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"limit": @10, @"date": todayString}.mutableCopy;
        
        params[@"sortType"] = @(self.sortingOption.integerValue);

        if ([MyFeedsManager subscription] != nil && [MyFeedsManager.subscription hasExpired] == YES) {
            params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
        }
        
        PagingManager * todayManager = [[PagingManager alloc] initWithPath:@"/1.7/today" queryParams:params itemsKey:@"articles"];
        
        todayManager.fromDB = YES;
        
        weakify(self);
        
        todayManager.dbFetchingCB = ^(void (^ _Nonnull completion)(NSArray * _Nullable)) {
          
            strongify(self);
            
            self.controllerState = StateLoading;
            
            dispatch_async(MyDBManager.readQueue, ^{
                
                [MyDBManager.countsConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                    
                    YapDatabaseViewTransaction *ext = [transaction extension:kTodayDBFilteredView];
                    
                    if (ext == nil) {
                        return completion(nil);
                    }
                    
                    NSRange range = NSMakeRange(((self.todayManager.page - 1) * 20) - 1, 20);
                    
                    if (self.todayManager.page == 1) {
                        range.location = 0;
                    }
                    
                    NSMutableArray <FeedItem *> *items = [NSMutableArray arrayWithCapacity:20];
                    
                    [ext enumerateKeysAndObjectsInGroup:GROUP_ARTICLES withOptions:kNilOptions range:range usingBlock:^(NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object, NSUInteger index, BOOL * _Nonnull stop) {
                       
                        [items addObject:object];
                        
                    }];
                    
                    completion(items);
                    
                }];

                
            });
            
        };
        
        _todayManager = todayManager;
    }
    
    if (_todayManager.preProcessorCB == nil) {
        _todayManager.preProcessorCB = ^NSArray * _Nonnull(NSArray * _Nonnull items) {
          
            NSArray *retval = [items rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
                return [obj isKindOfClass:NSDictionary.class] ? [FeedItem instanceFromDictionary:obj] : obj;
            }];
            
            return retval;
            
        };
    }
    
    if (_todayManager.successCB == nil) {
        weakify(self);
        
        _todayManager.successCB = ^{
            strongify(self);
            
            if (!self) {
                return;
            }
            
            if (self->_todayManager.page == 1) {
                MyFeedsManager.unreadLastUpdate = NSDate.date;
                
                [self updateTitleView];
            }
            
            [self setupData];
            
            runOnMainQueueWithoutDeadlocking(^{
                self.controllerState = StateLoaded;
            });
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.refreshControl != nil && self.refreshControl.isRefreshing) {
                    [self.tableView.refreshControl endRefreshing];
                }
                
                if (self.todayManager.page == 1 && self.todayManager.hasNextPage == YES) {
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
    
    if (_todayManager.errorCB == nil) {
        weakify(self);
        
        _todayManager.errorCB = ^(NSError * _Nonnull error) {
            NSLog(@"Error today manager:%@", error);
            
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
    
    return _todayManager;
    
}

- (void)didBeginRefreshing:(UIRefreshControl *)sender {
    
    // mac catalyst doesn't have a refresh control
#if !TARGET_OS_MACCATALYST
    if (sender != nil) {
#endif
        self.todayManager = nil;
        [self loadNextPage];
#if !TARGET_OS_MACCATALYST
    }
#endif
    
}

- (NSString *)emptyViewSubtitle {
    return @"No Articles from today are available.";
}

- (BOOL)showsSortingButton {
    return YES;
}

- (void)_setSortingOption:(YetiSortOption)option {
    
    self.todayManager = nil;
    self.pagingManager = self.todayManager;
    
    [self setupDatabases:option];
    
}

- (NSURLSessionTask *)searchOperationTask:(NSString *)text {
    
    return [MyFeedsManager searchToday:text success:self.searchOperationSuccess error:self.searchOperationError];
    
}


@end
