//
//  FolderVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FolderVC.h"

@interface FolderVC ()

@property (nonatomic, strong) PagingManager *folderFeedsManager;

@end

@implementation FolderVC

+ (UINavigationController *)instanceWithFolder:(Folder *)folder {
    
    FolderVC *instance = [[[self class] alloc] initWithFolder:folder];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:instance];
    nav.restorationIdentifier = @"FeedNavVC";
    
    return nav;
    
}

- (instancetype)initWithFolder:(Folder *)folder {
    
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        self.folder = folder;
        self.type = FeedVCTypeFolder;
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = self.folder.title;
    self.pagingManager = self.folderFeedsManager;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(didBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
    
}

#pragma mark - Subclassed

- (PagingManager *)folderFeedsManager {
    
    if (_folderFeedsManager == nil && _folder != nil) {
        
        NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"limit": @10}.mutableCopy;
        
        params[@"sortType"] = @([(NSNumber *)(self.sortingOption ?: @0 ) integerValue]);
            
        if ([MyFeedsManager subscription] != nil && [MyFeedsManager.subscription hasExpired] == YES) {
            params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
        }
        
        NSString *path = formattedString(@"/1.1/folder/%@/feed", self.folder.folderID);
        
        PagingManager * pagingManager = [[PagingManager alloc] initWithPath:path queryParams:params itemsKey:@"articles"];
        
        _folderFeedsManager = pagingManager;
    }
    
    if (_folderFeedsManager.preProcessorCB == nil) {
        _folderFeedsManager.preProcessorCB = ^NSArray * _Nonnull(NSArray * _Nonnull items) {
          
            NSArray *retval = [items rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
                return [FeedItem instanceFromDictionary:obj];
            }];
            
            return retval;
            
        };
    }
    
    if (_folderFeedsManager.successCB == nil) {
        weakify(self);
        
        _folderFeedsManager.successCB = ^{
            strongify(self);
            
            if (!self) {
                return;
            }
            
            [self setupData];
            
            self.controllerState = StateLoaded;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.refreshControl isRefreshing]) {
                    [self.refreshControl endRefreshing];
                }
                
                if (self.pagingManager.page == 1 && self.pagingManager.hasNextPage == YES) {
                    [self loadNextPage];
                }
            });
        
        };
    }
    
    if (_folderFeedsManager.errorCB == nil) {
        weakify(self);
        
        _folderFeedsManager.errorCB = ^(NSError * _Nonnull error) {
            NSLog(@"%@", error);
            
            strongify(self);
            
            if (!self)
                return;
            
            self.controllerState = StateErrored;
            
            weakify(self);
            
            asyncMain(^{
                strongify(self);
                
                if ([self.refreshControl isRefreshing]) {
                    [self.refreshControl endRefreshing];
                }
            })
        };
    }
    
    return _folderFeedsManager;
    
}

- (void)didBeginRefreshing:(UIRefreshControl *)sender {
    
    if (sender != nil && [sender isRefreshing]) {
        self.folderFeedsManager = nil;
        self.pagingManager = self.folderFeedsManager;
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
    
    self.folderFeedsManager = nil;
    self.pagingManager = self.folderFeedsManager;
    
}

- (NSURLSessionTask *)searchOperationTask:(NSString *)text {
    
    return [MyFeedsManager search:text folderID:self.folder.folderID success:self.searchOperationSuccess error:self.searchOperationError];
    
}

@end
