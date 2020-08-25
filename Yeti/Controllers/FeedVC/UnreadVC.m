//
//  UnreadVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "UnreadVC.h"

@interface UnreadVC ()

@property (nonatomic, strong) PagingManager *unreadsManager;

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
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(didBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
    
}

#pragma mark - Subclassed

- (PagingManager *)unreadsManager {
    
    if (_unreadsManager == nil) {
        NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"limit": @10}.mutableCopy;
        
        params[@"sortType"] = @(self.sortingOption.integerValue);
        
        if ([MyFeedsManager subscription] != nil && [MyFeedsManager.subscription hasExpired] == YES) {
            params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
        }
        
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
                if ([self.tableView.refreshControl isRefreshing]) {
                    [self.tableView.refreshControl endRefreshing];
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
    
    if (sender != nil) {
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

- (void)updateSortingOptionTo:(YetiSortOption)option sender:(UIBarButtonItem *)sender {
    
    self.sortingOption = option;
    
    UIColor *tintColor = nil;
    UIImage *image = [SortImageProvider imageForSortingOption:option tintColor:&tintColor];
    
    sender.image = image;
    sender.tintColor = tintColor;
    
}

- (void)didTapSortOptions:(UIBarButtonItem *)sender {
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Sorting Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    weakify(self);
    
    UIAlertAction *allDesc = [UIAlertAction actionWithTitle:@"Newest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        strongify(self);
        
        [self updateSortingOptionTo:YTSortUnreadDesc sender:sender];
        
    }];
    
    UIAlertAction *allAsc = [UIAlertAction actionWithTitle:@"Oldest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        strongify(self);
        
        [self updateSortingOptionTo:YTSortUnreadAsc sender:sender];
        
    }];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    @try {
        
        UIColor *tintColor = nil;
        UIImage * image = [SortImageProvider imageForSortingOption:YTSortUnreadDesc tintColor:&tintColor];
        
        [allDesc setValue:image forKeyPath:@"image"];
        
        tintColor = nil;
        image = [SortImageProvider imageForSortingOption:YTSortUnreadAsc tintColor:&tintColor];
        
        [allAsc setValue:image forKeyPath:@"image"];


    }
    @catch (NSException *exc) {
        
    }
    
    [avc addAction:allDesc];
    [avc addAction:allAsc];
    
    [self presentAllReadController:avc fromSender:sender];
    
}

- (NSURLSessionTask *)searchOperationTask:(NSString *)text {
    
    return [MyFeedsManager searchUnread:text success:self.searchOperationSuccess error:self.searchOperationError];
    
}

@end
