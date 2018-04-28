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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateBookmarks) name:BookmarksDidUpdate object:nil];
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
            
            NSArray <FeedItem *> *items = [responseObject objectForKey:@"articles"];
            items = [items rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
                return [FeedItem instanceFromDictionary:obj];
            }];
            
            if (self->_page == 1) {
                MyFeedsManager.unread = items;
            }
            else {
                MyFeedsManager.unread = [MyFeedsManager.unread arrayByAddingObjectsFromArray:items];
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

@end
