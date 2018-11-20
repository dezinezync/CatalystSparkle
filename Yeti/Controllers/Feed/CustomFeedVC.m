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

#import "EmptyView.h"
#import "YetiThemeKit.h"

#import "YetiConstants.h"

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

- (void)setUnread:(BOOL)unread {
    _unread = unread;
    
    self.restorationIdentifier = unread ? @"UnreadVC" : @"BookmarksVC";
    self.restorationClass = self.class;
}

- (BOOL)ef_hidesNavBorder
{
    return NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.loadingNext = NO;
    
    self.title = self.isUnread ? @"Unread" : @"Bookmarks";
    
    self.tableView.tableFooterView = [UIView new];
    
    if (!self.isUnread) {
        [MyFeedsManager addObserver:self forKeyPath:propSel(bookmarks) options:(NSKeyValueObservingOptionNew) context:KVO_BOOKMARKS];
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
        self.tableView.refreshControl = refresh;
        
        [self.DS resetData];
        self.DS.data = [MyFeedsManager unread];
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
            [MyFeedsManager removeObserver:self forKeyPath:propSel(bookmarks) context:KVO_BOOKMARKS];
        } @catch (NSException *exc) {}
        
    }
    
}

#pragma mark - Overrides

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isUnread) {
        return [super tableView:tableView leadingSwipeActionsConfigurationForRowAtIndexPath:indexPath];
    }
    
    return nil;
}

- (BOOL)showsSortingButton {
    return YES;
}

- (void)didTapSortOptions:(UIBarButtonItem *)sender {
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Sorting Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *allDesc = [UIAlertAction actionWithTitle:@"Newest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortAllDesc];
        
        [self setSortingOption:YTSortAllDesc];
        
    }];
    
    UIAlertAction *allAsc = [UIAlertAction actionWithTitle:@"Oldest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortAllAsc];
        
        [self setSortingOption:YTSortAllAsc];
        
    }];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    @try {
        [allDesc setValue:[SortImageProvider imageForSortingOption:YTSortAllDesc] forKeyPath:@"image"];
        [allAsc setValue:[SortImageProvider imageForSortingOption:YTSortAllAsc] forKeyPath:@"image"];
    }
    @catch (NSException *exc) {
        
    }
    
    [avc addAction:allDesc];
    [avc addAction:allAsc];
    
    [self presentAllReadController:avc fromSender:sender];
    
}

- (void)setSortingOption:(YetiSortOption)option {
    
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
    
    self.loadingNext = YES;
    
    weakify(self);
    
    if (self.isUnread) {
        NSInteger page = self->_page + 1;
        
        YetiSortOption sorting = [[NSUserDefaults standardUserDefaults] valueForKey:kDetailFeedSorting];
        
        [MyFeedsManager getUnreadForPage:page sorting:sorting success:^(NSArray * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
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
                
                if ([self.tableView.refreshControl isRefreshing]) {
                    [self.tableView.refreshControl endRefreshing];
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
    if ([keyPath isEqualToString:propSel(bookmarks)] && context == KVO_BOOKMARKS) {
        [self didUpdateBookmarks];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Restoration

#define kIsUnread @"CustomFeedVC-isUnread"

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    CustomFeedVC *vc = [[CustomFeedVC alloc] init];
    
    vc.unread = [coder decodeBoolForKey:kIsUnread];
    
    return vc;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super encodeRestorableStateWithCoder:coder];
    
    [coder encodeBool:self.isUnread forKey:kIsUnread];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    [super decodeRestorableStateWithCoder:coder];
    
    self.unread = [coder decodeBoolForKey:kIsUnread];
    
}

@end
