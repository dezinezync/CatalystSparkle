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
}

@end

@implementation DetailCustomVC

- (void)setUnread:(BOOL)unread {
    _unread = unread;
    
    self.restorationIdentifier = unread ? @"UnreadVC" : @"BookmarksVC";
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.isUnread ? @"Unread" : @"Bookmarks";
    
    [self.DS resetData];
    
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
        
        NSArray *observingObjects = [(id)(MyFeedsManager.observationInfo) valueForKeyPath:@"_observances"];
        observingObjects = [observingObjects rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [obj valueForKeyPath:@"observer"];
        }];
        
        if ([observingObjects indexOfObject:self] != NSNotFound) {
            @try {
                [MyFeedsManager removeObserver:self forKeyPath:propSel(bookmarks)];
            } @catch (NSException *exc) {}
        }
        
    }
    
}

#pragma mark - Overrides

- (void)loadNextPage
{
    
    if (self.loadingNext)
        return;
    
    self.loadingNext = YES;
    
    weakify(self);
    
    if (self.isUnread) {
        NSInteger page = self->_page + 1;
        [MyFeedsManager getUnreadForPage:page success:^(NSArray * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            
            if (!self)
                return;
            
            if (![responseObject count]) {
                self->_canLoadNext = NO;
            }
            else {
                @try {
                    if (page == 1) {
                        self.DS.data = responseObject;
                    }
                    else {
                        self.DS.data = [self.DS.data arrayByAddingObjectsFromArray:responseObject];
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
                
                if (page == 1) {
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


@end
