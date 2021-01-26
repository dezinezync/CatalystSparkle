//
//  BookmarksVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "BookmarksVC.h"

@interface BookmarksVC () {
    BOOL _reloadBookmarks;
}

@property (nonatomic, strong) NSArray <FeedItem *> * articles;

@end

@implementation BookmarksVC

- (instancetype)init {
    
    if (self = [super initWithStyle:UITableViewStylePlain]) {
        
        self.type = FeedVCTypeBookmarks;
        
        self.restorationClass = [self class];
        self.restorationIdentifier = @"FeedVC-Bookmarks";
        
    }
    
    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.title = @"Bookmarks";
    
    weakify(self);
    
    [NSNotificationCenter.defaultCenter addObserverForName:BookmarksDidUpdate object:nil queue:NSOperationQueue.mainQueue usingBlock:^(NSNotification * _Nonnull note) {
       
        strongify(self);
        
        if (self == nil) {
            return;
        }
        
        if (self->_reloadBookmarks == NO) {
            self->_reloadBookmarks = YES;
        }
        
        [self updateTitleView];
        
    }];
    
}

- (void)dealloc {
    
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (self->_reloadBookmarks == YES || (self.DS.snapshot.numberOfItems == 0 && MyFeedsManager.totalBookmarks != 0)) {
        
        self->_reloadBookmarks = NO;
        
        [self setupData];
        
        [self updateTitleView];
        
    }
    
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    
    if ([NSStringFromSelector(aSelector) isEqualToString:@"_setSortingOption:"]) {
        return NO;
    }
    
    return [super respondsToSelector:aSelector];
    
}

#pragma mark - Subclassed

- (void)setupNavigationBar {
    
    [super setupNavigationBar];
    
    self.navigationItem.searchController.searchBar.scopeButtonTitles = @[@"Local"];
    self.navigationItem.searchController.searchBar.showsScopeBar = NO;
    
}

- (PagingManager *)pagingManager {
    return nil;
}

- (void)setupData {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setupData) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [MyDBManager.uiConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
       
        YapDatabaseFilteredViewTransaction *txn = [transaction ext:DB_BOOKMARKED_VIEW];
        
        __block NSArray <FeedItem *> * articles = [NSArray new];
        
        [txn enumerateKeysAndObjectsInGroup:GROUP_ARTICLES withOptions:kNilOptions usingBlock:^(NSString * _Nonnull collection, NSString * _Nonnull key, FeedItem * _Nonnull object, NSUInteger index, BOOL * _Nonnull stop) {
            
            if (object.read == NO) {
                
                if ([object.timestamp timeIntervalSince1970] > (86400 * 14)) {
                    object.read = YES;
                }
                
            }
           
            articles = [articles arrayByAddingObject:object];
            
        }];
        
        articles = [[NSSet setWithArray:articles] allObjects];
        
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:(SharedPrefs.sortingOption == YTSortAllAsc)];
        
        self.articles = [articles sortedArrayUsingDescriptors:@[sortDescriptor]];
        
        @try {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
                [snapshot appendSectionsWithIdentifiers:@[@0]];
                [snapshot appendItemsWithIdentifiers:self.articles intoSectionWithIdentifier:@0];
                
                [self.DS applySnapshot:snapshot animatingDifferences:YES];
                
            });
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.controllerState = StateLoaded;
                
            });
            
        }
        @catch (NSException *exc) {
            NSLog(@"Exception updating bookmarks articles: %@", exc);
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.controllerState = StateErrored;
                
            });
        }
        
    }];
    
}

#pragma mark - Subclassed

- (NSString *)filteringViewName {
    return @"";
}

- (NSString *)subtitle {
    
    NSString *totalArticles = [NSString stringWithFormat:@"%@ Bookmark%@", @(MyFeedsManager.totalBookmarks), MyFeedsManager.totalBookmarks == 1 ? @"" : @"s"];
    
    return totalArticles;
    
}

- (NSString *)emptyViewSubtitle {
    return @"Bookmarking a great way to save articles for referencing later or the content you really enjoyed reading.";
}

- (BOOL)showsSortingButton {
    return YES;
}

//- (void)setSortingOption:(YetiSortOption)sortingOption {
//
//    [super setSortingOption:sortingOption];
//
//    [self setupData];
//
//}

- (void)_search:(NSString *)text scope:(NSInteger)scope {
 
    // scope will always be 0 here
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    
    NSArray <FeedItem *> * items = self.articles;
    
    items = [items rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
        
        NSString *title = obj.articleTitle.lowercaseString;
        
        if ([title isEqualToString:text] || [title containsString:text]) {
            return YES;
        }
        
        if (obj.summary != nil) {
            
            NSString *summary = [obj.summary lowercaseString];
            
            if ([summary containsString:text]) {
                return YES;
            }
            
        }
        
        NSString *blogTitle = obj.blogTitle.lowercaseString;
        
        if ([blogTitle isEqualToString:text] || [blogTitle containsString:text]) {
            return YES;
        }
        
        return NO;
        
    }];
    
    [snapshot appendSectionsWithIdentifiers:@[@0]];
    [snapshot appendItemsWithIdentifiers:items intoSectionWithIdentifier:@0];
    
    [self.DS applySnapshot:snapshot animatingDifferences:YES];
    
}

- (void)didBeginRefreshing:(id)sender {
 
    [self setupData];
    
}

@end
