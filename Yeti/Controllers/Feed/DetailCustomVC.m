//
//  DetailCustomVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 10/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DetailCustomVC.h"

#import "FeedsManager.h"

#import <DZKit/DZBasicDatasource.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import "YetiThemeKit.h"

#import "YetiConstants.h"

static void *KVO_DETAIL_BOOKMARKS = &KVO_DETAIL_BOOKMARKS;

@interface DetailCustomVC () {
    BOOL _reloadDataset; // used for bookmarks
    BOOL _hasSetupState;
}

@end

@implementation DetailCustomVC

//- (void)viewDidLoad {
//    [super viewDidLoad];
//    
//    [self.DS resetData];
//}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    [self setupState];
    
}

- (void)setupState {
    
    if (_hasSetupState) {
        return;
    }
    
    _hasSetupState = YES;
    
    self.restorationIdentifier = self.isUnread ? @"UnreadVC-Detail" : @"BookmarksVC-Detail";
    self.title = self.isUnread ? @"Unread" : @"Bookmarks";
    
    if (!self.isUnread) {
        [MyFeedsManager addObserver:self forKeyPath:propSel(bookmarks) options:(NSKeyValueObservingOptionNew) context:KVO_DETAIL_BOOKMARKS];
        self.DS.data = MyFeedsManager.bookmarks.reverseObjectEnumerator.allObjects;
        self.navigationItem.rightBarButtonItem = nil;
    }
    else {
        UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
        
        YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
        
        if (theme.isDark) {
            refresh.tintColor = [theme captionColor];
        }
        
        [refresh addTarget:self action:@selector(didBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
        self.collectionView.refreshControl = refresh;
        
        self.DS.data = [MyFeedsManager unread];
        if (self.DS.data.count > 0) {
            _page = floor([self.DS.data count]/10.f);
        }
        
        [self loadNextPage];
        
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didUpdateUnread) name:FeedDidUpReadCount object:MyFeedsManager];
    }
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_reloadDataset) {
        _reloadDataset = NO;
        
        if (self.unread == NO) {
            self.DS.data = MyFeedsManager.bookmarks.reverseObjectEnumerator.allObjects;
        }
        else {
            self.DS.data = MyFeedsManager.unread;
        }
    }
}

- (void)_didFinishAllReadActionSuccessfully {
    if (self.isUnread) {
        self.DS.data = MyFeedsManager.unread;
    }
}

- (void)dealloc {
    
    if (MyFeedsManager.observationInfo != nil && self.unread == NO) {
        @try {
        
            [MyFeedsManager removeObserver:self forKeyPath:propSel(bookmarks) context:KVO_DETAIL_BOOKMARKS];
            
        } @catch (NSException *exc) {
            
        }
        
    }
    
}

#pragma mark - Overrides

- (BOOL)showsSortingButton {
    return YES;
}

- (void)didTapSortOptions:(UIBarButtonItem *)sender {
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Sorting Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *allDesc = [UIAlertAction actionWithTitle:@"Newest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortUnreadDesc];
        
        [self setSortingOption:YTSortAllDesc];
        
    }];
    
    UIAlertAction *allAsc = [UIAlertAction actionWithTitle:@"Oldest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortUnreadAsc];
        
        [self setSortingOption:YTSortAllAsc];
        
    }];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    @try {
        [allDesc setValue:[SortImageProvider imageForSortingOption:YTSortUnreadDesc] forKeyPath:@"image"];
        [allAsc setValue:[SortImageProvider imageForSortingOption:YTSortUnreadAsc] forKeyPath:@"image"];
    }
    @catch (NSException *exc) {
        
    }
    
    [avc addAction:allDesc];
    [avc addAction:allAsc];
    
    [self presentAllReadController:avc fromSender:sender];
    
}

- (void)setSortingOption:(YetiSortOption)option {
    
    // this will call -[DetailFeedVC loadNextPage]
    [super setSortingOption:option];
    
    if (self.isUnread == NO) {
        if ([option isEqualToString:YTSortAllDesc]) {
            self.DS.data = [MyFeedsManager.bookmarks reverseObjectEnumerator].allObjects;
        }
        else {
            self.DS.data = MyFeedsManager.bookmarks;
        }
    }
    
}

- (NSString *)emptyViewSubtitle {
    if (self.isUnread) {
        return @"No Unread Articles are available.";
    }
    
    return @"You dont have any bookmarks. Bookmarks are a great way to save articles for offline reading.";
}

- (void)loadNextPage
{
    
    if (self.isUnread == NO) {
        return;
    }
    
    if (self.loadingNext)
        return;
    
    if (self->_canLoadNext == NO) {
        return;
    }
    
    self.loadingNext = YES;
    
    weakify(self);
    
    if (self.isUnread) {
        NSInteger page = self->_page + 1;
        YetiSortOption sorting = [[NSUserDefaults standardUserDefaults] valueForKey:kDetailFeedSorting];
        
        [MyFeedsManager getUnreadForPage:page sorting:sorting success:^(NSArray * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            
            if (!self)
                return;
            
            self->_page = page;
            
            BOOL canLoadNext = YES;
            
            if (![responseObject count]) {
                canLoadNext = NO;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    self->_canLoadNext = canLoadNext;
                    self.loadingNext = NO;
                });
                
                self.DS.data = self.DS.data ?: @[];
            }
            else {
                @try {
                    if (page == 1) {
                        self.DS.data = responseObject;
                    }
                    else {
                        [self.DS append:responseObject];
                    }
                }
                @catch (NSException *exc) {
                    DDLogWarn(@"Exception setting unread articles: %@", exc);
                }
            }
            
            self->_page = page;
            
            self.loadingNext = NO;
            
            weakify(self);
            
            asyncMain(^{
                strongify(self);
                
                if ([self.collectionView.refreshControl isRefreshing]) {
                    [self.collectionView.refreshControl endRefreshing];
                }
                
                if (page == 1 && canLoadNext) {
                    [self loadNextPage];
                }
            })
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            DDLogError(@"%@", error);
            
            strongify(self);
            
            if (!self)
                return;
            
            self.loadingNext = NO;
            
            weakify(self);
            
            asyncMain(^{
                strongify(self);
                
                if ([self.collectionView.refreshControl isRefreshing]) {
                    [self.collectionView.refreshControl endRefreshing];
                }
            })
        }];
    }
    else {
        self.DS.data = MyFeedsManager.bookmarks.reverseObjectEnumerator.allObjects;
        
        asyncMain(^{
            if ([self.collectionView.refreshControl isRefreshing]) {
                [self.collectionView.refreshControl endRefreshing];
            }
        })
    }
}

#pragma mark - Notifications

- (void)didBeginRefreshing:(UIRefreshControl *)sender {
    
    if ([sender isRefreshing]) {
        _page = 0;
        _canLoadNext = YES;
        
        [self loadNextPage];
    }
    
}

- (void)didUpdateBookmarks
{
    if (!_reloadDataset) {
        _reloadDataset = YES;
    }
}

- (void)didUpdateUnread {
    if (!_reloadDataset) {
        _reloadDataset = YES;
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:propSel(bookmarks)] && context == KVO_DETAIL_BOOKMARKS) {
        [self didUpdateBookmarks];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - State Restoration

#define kBUnreadData @"UnreadData"
#define kBIsUnread @"VCIsUnread"

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    DetailCustomVC *vc = [[DetailCustomVC alloc] initWithFeed:nil];
    
    if ([coder decodeBoolForKey:kBIsUnread]) {
        vc.unread = YES;
    }
    
    vc.customFeed = FeedTypeCustom;
    vc.restorationIdentifier = vc.isUnread ? @"UnreadVC-Detail" : @"BookmarksVC-Detail";
    
    return vc;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeObject:self.DS.data forKey:kBUnreadData];
    [coder encodeBool:self.unread forKey:kBIsUnread];
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super decodeRestorableStateWithCoder:coder];
    
    NSArray <FeedItem *> *items = [coder decodeObjectForKey:kBUnreadData];
    
    if (items) {
        [self setupLayout];
        
        self.DS.data = items;
    }
    
}

@end
