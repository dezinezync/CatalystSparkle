//
//  CustomFeedVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 05/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "CustomFeedVC.h"
#import "FeedsManager.h"

#import <DZKit/DZBasicDatasource.h>
#import <DZKit/NSArray+RZArrayCandy.h>

static void *KVO_BOOKMARKS = &KVO_BOOKMARKS;

@interface CustomFeedVC () {
    BOOL _reloadDataset; // used for bookmarks
}

@end

@implementation CustomFeedVC

#pragma mark - <ScrollLoading>

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    if (self = [super initWithStyle:style]) {
        _canLoadNext = YES;
        _page = 1;
    }
    
    return self;
}

- (BOOL)ef_hidesNavBorder
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.isUnread ? @"Unread" : @"Bookmarks";
    
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    [refresh addTarget:self action:@selector(didBeginRefreshing:) forControlEvents:UIControlEventValueChanged];
    self.tableView.refreshControl = refresh;
    
    self.tableView.tableFooterView = [UIView new];
    
    if (!self.isUnread) {
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateBookmarks) name:BookmarksDidUpdate object:nil];
        [MyFeedsManager addObserver:self forKeyPath:propSel(bookmarks) options:(NSKeyValueObservingOptionNew) context:KVO_BOOKMARKS];
        self.DS.data = MyFeedsManager.bookmarks.reverseObjectEnumerator.allObjects;
    }
    else {
        self.DS.data = [MyFeedsManager unread];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_reloadDataset && !self.isUnread) {
        _reloadDataset = NO;
        
        self.DS.data = MyFeedsManager.bookmarks.reverseObjectEnumerator.allObjects;
    }
}

- (void)dealloc {
    
    if (self.observationInfo) {
        @try {
            [MyFeedsManager removeObserver:self forKeyPath:propSel(bookmarks)];
        } @catch (NSException *exc) {}
    }
    
}

#pragma mark

- (void)loadNextPage
{
    
    if (self.loadingNext)
        return;
    
    self.loadingNext = YES;
    
    weakify(self);
    
    if (self.isUnread) {
        _page++;
        [MyFeedsManager getUnreadForPage:_page success:^(NSDictionary * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            
            if (!self)
                return;
            
            if (![(NSArray *)[responseObject objectForKey:@"articles"] count]) {
                self->_canLoadNext = NO;
            }
            
            self.DS.data = MyFeedsManager.unread;
            
            self.loadingNext = NO;
            
            asyncMain(^{
                if ([self.tableView.refreshControl isRefreshing]) {
                    [self.tableView.refreshControl endRefreshing];
                }
            })
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            DDLogError(@"%@", error);
            
            strongify(self);
            self->_page--;
            
            self.loadingNext = NO;
            
            asyncMain(^{
                if ([self.tableView.refreshControl isRefreshing]) {
                    [self.tableView.refreshControl endRefreshing];
                }
            })
        }];
    }
    else {
        self.DS.data = MyFeedsManager.bookmarks.reverseObjectEnumerator.allObjects;
        
        asyncMain(^{
            if ([self.tableView.refreshControl isRefreshing]) {
                [self.tableView.refreshControl endRefreshing];
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
    if (!_reloadDataset)
        _reloadDataset = YES;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:propSel(bookmarks)] && context == KVO_BOOKMARKS) {
        [self didUpdateBookmarks];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
