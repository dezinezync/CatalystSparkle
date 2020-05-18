//
//  TodayVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 01/04/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "TodayVC.h"

@interface TodayVC () {
    BOOL _hasSetupState;
    BOOL _reloadDataset;
}

@property (nonatomic, strong) PagingManager *todayManager;

@end

@implementation TodayVC

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Today";
    
}

- (void)setupState {
    
    if (_hasSetupState) {
        return;
    }
    
    _hasSetupState = YES;
    
    self.restorationIdentifier = @"TodayVC-Detail";
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    
    [refresh addTarget:self action:@selector(didBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    self.collectionView.refreshControl = refresh;
    
    [self setupData];

//    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didUpdateUnread) name:FeedDidUpReadCount object:MyFeedsManager];
    
}

- (void)setupData {
    
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    [snapshot appendSectionsWithIdentifiers:@[@0]];
    [snapshot appendItemsWithIdentifiers:(self.todayManager.items ?: @[]) intoSectionWithIdentifier:@0];
    
    [self.DDS applySnapshot:snapshot animatingDifferences:YES];
    
}

- (void)_didFinishAllReadActionSuccessfully {
    [self setupData];
}

#pragma mark - Getters

- (PagingManager *)pagingManager {
    
    return self.todayManager;
    
}

- (void)setPagingManager:(PagingManager *)pagingManager {
    
    _todayManager = pagingManager;
    
}

- (PagingManager *)todayManager {
    
    if (_todayManager == nil) {
        
        NSDate *today = [NSDate date];
        NSDateComponents *comps = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:today];
        
        NSString *todayString = [NSString stringWithFormat:@"%@-%@-%@", @(comps.year), @(comps.month), @(comps.day)];
        
        NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"limit": @10, @"date": todayString}.mutableCopy;
        
        params[@"sortType"] = @(_sortingOption.integerValue);

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
                if ([self.collectionView.refreshControl isRefreshing]) {
                    [self.collectionView.refreshControl endRefreshing];
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
                
                if ([self.collectionView.refreshControl isRefreshing]) {
                    [self.collectionView.refreshControl endRefreshing];
                }
            })
        };
    }
    
    return _todayManager;
    
}

- (NSString *)emptyViewSubtitle {
    return @"No Articles from today are available.";
}

#pragma mark - Notifications

- (void)didBeginRefreshing:(UIRefreshControl *)sender {
    
    if ([sender isRefreshing]) {
        self.todayManager = nil;
        _canLoadNext = YES;
        
        [self loadNextPage];
    }
    
}

- (void)didUpdateUnread {
    if (!_reloadDataset) {
        _reloadDataset = YES;
    }
}

#pragma mark - State Restoration

#define kBUnreadData @"TodayData"

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    
    TodayVC *vc = [[TodayVC alloc] initWithFeed:nil];
    
    vc.customFeed = FeedTypeCustom;
    vc.restorationIdentifier = @"TodayVC-Detail";
    
    return vc;
    
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super encodeRestorableStateWithCoder:coder];
    
    if (self.todayManager) {
        [coder encodeObject:self.todayManager forKey:@"todayManager"];
    }
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super decodeRestorableStateWithCoder:coder];
    
    self.todayManager = [coder decodeObjectOfClass:PagingManager.class forKey:@"todayManager"];
    self.controllerState = StateLoaded;
    
}

@end
