//
//  TodayVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "TodayVC.h"

@interface TodayVC ()

@property (nonatomic, strong) PagingManager *todayManager;

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
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(didBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
    
}

#pragma mark - Subclassed

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
        
        _todayManager = todayManager;
    }
    
    if (_todayManager.preProcessorCB == nil) {
        _todayManager.preProcessorCB = ^NSArray * _Nonnull(NSArray * _Nonnull items) {
          
            NSArray *retval = [items rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
                return [FeedItem instanceFromDictionary:obj];
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
            }
            
            [self setupData];
            
            self.controllerState = StateLoaded;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.tableView.refreshControl isRefreshing]) {
                    [self.tableView.refreshControl endRefreshing];
                }
                
                if (self.todayManager.page == 1 && self.todayManager.hasNextPage == YES) {
                    [self loadNextPage];
                }
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
    
    if (sender != nil && [sender isRefreshing]) {
        self.todayManager = nil;
        self.pagingManager = self.todayManager;
        [self loadNextPage];
    }
    
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
    
}

- (NSURLSessionTask *)searchOperationTask:(NSString *)text {
    
    return [MyFeedsManager searchToday:text success:self.searchOperationSuccess error:self.searchOperationError];
    
}


@end
