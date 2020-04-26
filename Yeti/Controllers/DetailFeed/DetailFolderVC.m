//
//  DetailFolderVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 15/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DetailFolderVC.h"
#import "FeedsManager.h"

@interface DetailFolderVC ()

@property (nonatomic, strong) PagingManager *folderFeedsManager;

@end

@implementation DetailFolderVC

+ (UINavigationController *)instanceWithFolder:(Folder *)folder {
    
    DetailFolderVC *instance = [[DetailFolderVC alloc] initWithFolder:folder];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:instance];
    nav.restorationIdentifier = @"DetailFolderNavVC";
    
    return nav;
    
}

- (instancetype)initWithFolder:(Folder *)folder {
    
    if (self = [super initWithNibName:NSStringFromClass(DetailFeedVC.class) bundle:nil]) {
        self.folder = folder;
        _canLoadNext = YES;
        self.page = 0;
        
        self.customFeed = FeedTypeFolder;
        
        self.sizeCache = @[].mutableCopy;
        
        self.restorationIdentifier = NSStringFromClass(self.class);
        self.restorationClass = self.class;
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = self.folder.title;
    
    self.controllerState = StateDefault;
    
}

- (NSString *)emptyViewSubtitle {
    
    NSString *subtitle = nil;
    
    if ([_sortingOption isEqualToString:YTSortAllDesc] || [_sortingOption isEqualToString:YTSortAllAsc]) {
        subtitle = formattedString(@"No recent articles are available from %@", self.folder.title);
    }
    else {
        subtitle = formattedString(@"No recent unread articles are available from %@", self.folder.title);
    }
    
    return subtitle;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (void)setupHeaderView { }

- (void)reloadHeaderView { }

- (NSArray <UIBarButtonItem *> *)rightBarButtonItems {
    
    // Subscribe Button appears in the navigation bar
    if (self.isExploring == YES) {
        return @[];
    }
    
    UIBarButtonItem *allRead = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"text.badge.checkmark"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapAllRead:)];
    allRead.accessibilityValue = @"Mark all articles as read";
    allRead.accessibilityHint = @"Mark all current articles as read.";
    allRead.width = 32.f;
    
    // sorting button
    YetiSortOption option = SharedPrefs.sortingOption;
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    SEL isUnread = NSSelectorFromString(@"isUnread");
    
    if (self.customFeed == FeedTypeCustom && [self respondsToSelector:isUnread] && (BOOL)[self performSelector:isUnread] == YES) {
        
        // when the active option is either of these two, we don't need
        // to do anything extra
        if (option != YTSortUnreadAsc && option != YTSortUnreadDesc) {
            
            // map it to whatever the selected option is
            if (option == YTSortAllAsc) {
                option = YTSortUnreadAsc;
            }
            else if (option == YTSortAllDesc) {
                option = YTSortUnreadDesc;
            }
            
        }
        
    }
#pragma clang diagnostic pop
    
    UIColor *tintColor = nil;
    UIImage *image = [SortImageProvider imageForSortingOption:option tintColor:&tintColor];
    
    UIBarButtonItem *sorting = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(didTapSortOptions:)];
    sorting.tintColor = tintColor;
    sorting.width = 32.f;
    
    NSMutableArray *buttons = [NSMutableArray new];
    
    [buttons addObject:allRead];
    
    if ([self showsSortingButton]) {
        [buttons addObject:sorting];
    }
    
    return buttons;
    
}

- (void)setupLayout {
    
    self->_shouldShowHeader = NO;
    
    [super setupLayout];
    
}

- (PagingManager *)pagingManager {
    
    return self.folderFeedsManager;
    
}

- (void)setPagingManager:(PagingManager *)pagingManager {
    
    _folderFeedsManager = pagingManager;
    
}

- (PagingManager *)folderFeedsManager {
    
    if (_folderFeedsManager == nil) {
        
        NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"limit": @10}.mutableCopy;
        
        params[@"sortType"] = @([(NSNumber *)(_sortingOption ?: @0 ) integerValue]);
            
        #if TESTFLIGHT == 0
            if ([MyFeedsManager subscription] != nil && [MyFeedsManager.subscription hasExpired] == YES) {
                params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
            }
        #endif
        
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
                if ([self.collectionView.refreshControl isRefreshing]) {
                    [self.collectionView.refreshControl endRefreshing];
                }
                
                if (self.pagingManager.page == 1 && self.pagingManager.hasNextPage == YES) {
                    [self loadNextPage];
                }
            });
            
            if ([self loadOnReady] != nil) {
                weakify(self);
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    strongify(self);
                    [self loadArticle];
                });
            }
        
        };
    }
    
    if (_folderFeedsManager.errorCB == nil) {
        weakify(self);
        
        _folderFeedsManager.errorCB = ^(NSError * _Nonnull error) {
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
    
    return _folderFeedsManager;
    
}

#pragma mark - State Restoration

#define kBFolderData @"FolderData"
#define kBFolderObj @"FolderObject"

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    
    Folder *folder = [coder decodeObjectForKey:kBFolderObj];
    
    DetailFolderVC *vc;
    
    if (folder != nil) {
        vc = [[DetailFolderVC alloc] initWithFolder:folder];
        vc.customFeed = FeedTypeFolder;
    }
    
    return vc;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.folder forKey:kBFolderObj];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    Folder *folder = [coder decodeObjectOfClass:Folder.class forKey:kBFolderObj];
    
    self.folder = folder;
    
    [super decodeRestorableStateWithCoder:coder];
    
}


@end
