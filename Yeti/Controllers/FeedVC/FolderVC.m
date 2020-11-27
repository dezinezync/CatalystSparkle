//
//  FolderVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FolderVC.h"
#import <DZKit/AlertManager.h>

#define kFolderDBView @"folderdDBView"
#define kFolderDBFilteredView @"folderDBFilteredView"

@interface FolderVC ()

@property (nonatomic, strong) PagingManager *folderFeedsManager;

@property (nonatomic, strong) YapDatabaseAutoView *dbView;
@property (nonatomic, strong) YapDatabaseFilteredView *dbFilteredView;

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
    
#if !TARGET_OS_MACCATALYST
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(didBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    
    self.refreshControl = refreshControl;
#endif
    
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
        
        NSNumber *feedID = [dict valueForKey:@"feedID"];
        
        if ([self.folder.feedIDs containsObject:feedID] == NO) {
            return NO;
        }
        
        BOOL checkOne = YES; //[feedID isEqualToNumber:self.feed.feedID];
        BOOL checkTwo = YES;
        
        if ([sortingOption isEqualToString:YTSortUnreadAsc] || [sortingOption isEqualToString:YTSortUnreadDesc]) {
            
            checkTwo = [([metadata valueForKey:@"read"] ?: @(NO)) boolValue] == NO;
            
        }
        
        return checkOne && checkTwo;
        
    }];

    self.dbFilteredView = [MyDBManager.database registeredExtension:kFolderDBFilteredView];
    
    if (self.dbFilteredView == nil) {
        
        YapDatabaseFilteredView *filteredView = [[YapDatabaseFilteredView alloc] initWithParentViewName:DB_FEED_VIEW filtering:filter versionTag:[NSString stringWithFormat:@"%u",(uint)self.superclass.filteringTag++]];
        
        self.dbFilteredView = filteredView;
        
        [MyDBManager.database registerExtension:self.dbFilteredView withName:kFolderDBFilteredView];
        
    }
    else {
        
        [MyDBManager.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
           
            YapDatabaseFilteredViewTransaction *tnx = [transaction ext:kFolderDBFilteredView];
            
            [tnx setFiltering:filter versionTag:[NSString stringWithFormat:@"%u",(uint)self.superclass.filteringTag++]];
            
        }];
        
    }
    
}

#pragma mark - Setters

- (void)setFolder:(Folder *)folder {
    
    _folder = folder;
    
    if (_folder) {
        
        self.restorationIdentifier = [NSString stringWithFormat:@"FeedVC-Folder-%@", folder.folderID];
        self.restorationClass = [self class];
        
        _folder.unreadCountTitleObservor = self;
        
    }
    
}

#pragma mark - Subclassed

- (NSString *)filteringViewName {
    return kFolderDBFilteredView;
}

- (PagingManager *)folderFeedsManager {
    
    if (_folderFeedsManager == nil && _folder != nil) {
        
        NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"limit": @10}.mutableCopy;
        
        params[@"sortType"] = @([(NSNumber *)(self.sortingOption ?: @0 ) integerValue]);
            
        if ([MyFeedsManager subscription] != nil && [MyFeedsManager.subscription hasExpired] == YES) {
            params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
        }
        
        NSString *path = formattedString(@"/1.1/folder/%@/feed", self.folder.folderID);
        
        PagingManager * pagingManager = [[PagingManager alloc] initWithPath:path queryParams:params itemsKey:@"articles"];
        
        pagingManager.fromDB = YES;
        
        weakify(self);
        
        pagingManager.dbFetchingCB = ^(void (^ _Nonnull completion)(NSArray * _Nullable)) {
            
            strongify(self);
            
            self.controllerState = StateLoading;
            
            dispatch_async(MyDBManager.readQueue, ^{
                
                [MyDBManager.countsConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                    
                    YapDatabaseViewTransaction *ext = [transaction extension:kFolderDBFilteredView];
                    
                    if (ext == nil) {
                        return completion(nil);
                    }
                    
                    NSRange range = NSMakeRange(((self.pagingManager.page - 1) * 20) - 1, 20);
                    
                    if (self.pagingManager.page == 1) {
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
        
        _folderFeedsManager = pagingManager;
    }
    
    if (_folderFeedsManager.preProcessorCB == nil) {
        _folderFeedsManager.preProcessorCB = ^NSArray * _Nonnull(NSArray * _Nonnull items) {
          
            NSArray *retval = [items rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
                return [obj isKindOfClass:NSDictionary.class] ? [FeedItem instanceFromDictionary:obj] : obj;
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
            
            runOnMainQueueWithoutDeadlocking(^{
                self.controllerState = StateLoaded;
            });
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if ([self.refreshControl isRefreshing]) {
                    [self.refreshControl endRefreshing];
                }
                
                if (self.pagingManager.page == 1) {
                    
                    [self updateTitleView];
                    
                    if (self.pagingManager.hasNextPage == YES) {
                    
                        [self loadNextPage];
                    
                    }
                    
#if TARGET_OS_MACCATALYST
                    if (self->_isRefreshing) {
                        self->_isRefreshing = NO;
                    }
#endif
                
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
    self.totalItemsForTitle = 0;
    self.pagingManager = self.folderFeedsManager;
    
    [self setupDatabases:option];
    
    [self updateTitleView];
    
}

- (NSURLSessionTask *)searchOperationTask:(NSString *)text {
    
    return [MyFeedsManager search:text folderID:self.folder.folderID success:self.searchOperationSuccess error:self.searchOperationError];
    
}

- (void)unreadCountChangedFor:(id)item to:(NSNumber *)count {
    
    if ([item isKindOfClass:Folder.class] && [(Folder *)item isEqualToFolder:self.folder]) {
        
        [self updateTitleView];
        
    }
    
}

- (NSString *)subtitle {
    
    NSString *totalArticles = [NSString stringWithFormat:@"%@ Article%@, ", @(self.totalItemsForTitle), self.totalItemsForTitle == 1 ? @"" : @"s"];
    
    NSString *unread = [NSString stringWithFormat:@"%@ Unread", self.folder.unreadCount];
    
    return [totalArticles stringByAppendingString:unread];
    
}

- (NSUInteger)totalItemsForTitle {
        
    @synchronized (self) {
            
        if (self->_totalItemsForTitle == 0) {
            
            __block NSUInteger count = 0;
            
            [MyDBManager.countsConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
                
                YapDatabaseFilteredViewTransaction *tnx = [transaction ext:kFolderDBFilteredView];
                
                count = [tnx numberOfItemsInGroup:GROUP_ARTICLES];
                
            }];
            
            _totalItemsForTitle = count;
            
        }
            
        return _totalItemsForTitle;
        
    }
    
}

#pragma mark - Actions

- (void)didLongPressOnAllRead:(id)sender {
    
    BOOL showPrompt = SharedPrefs.showMarkReadPrompts;
    
    void(^markReadInline)(void) = ^(void) {
        
        [MyFeedsManager markFolderRead:self.folder success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                if (self != nil && [self tableView] != nil) {
                    // if we're in the unread section
                    if (self.sortingOption == YTSortUnreadAsc || self.sortingOption == YTSortUnreadDesc) {
                        
                        self.controllerState = StateLoading;
                        
                        NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
                        [snapshot appendSectionsWithIdentifiers:@[@0]];
                        
                        [self.DS applySnapshot:snapshot animatingDifferences:YES];
                        
                        self.controllerState = StateLoaded;
                        
                    }
                    else {
                        [self _markVisibleRowsRead];
                        [self _didFinishAllReadActionSuccessfully];
                    }
                }
            });
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [AlertManager showGenericAlertWithTitle:@"Error Marking all Read" message:error.localizedDescription];
            
        }];
        
    };
    
    if (showPrompt) {
        UIAlertController *avc = [UIAlertController alertControllerWithTitle:nil message:@"Mark all Articles as read including back-dated articles?" preferredStyle:UIAlertControllerStyleActionSheet];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Mark all Read" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            markReadInline();
            
        }]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentAllReadController:avc fromSender:sender];
    }
    else {
        [self.feedbackGenerator selectionChanged];
        [self.feedbackGenerator prepare];
        
        markReadInline();
    }
}

- (void)_didFinishAllReadActionSuccessfully {
    
}

#pragma mark - State Restoration

#define kFolderVCFolder @"kFolderVCFolder"

+ (nullable UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    
    FolderVC *vc = (FolderVC *)[[super class] viewControllerWithRestorationIdentifierPath:identifierComponents coder:coder];
    
    Folder *folder = [coder decodeObjectOfClass:Folder.class forKey:kFolderVCFolder];
    
    vc.folder = folder;
    
    return vc;
    
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.folder forKey:kFolderVCFolder];
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super decodeRestorableStateWithCoder:coder];
    
    Folder *folder = [coder decodeObjectOfClass:Folder.class forKey:kFolderVCFolder];
    
    self.folder = folder;
    
}

@end
