//
//  FeedsVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Actions.h"
#import "FeedsManager.h"
#import "FeedsCell.h"
#import "FeedVC.h"
#import <DZKit/DZBasicDatasource.h>

#import <DZKit/EFNavController.h>
#import <DZKit/UIViewController+AnimatedDeselect.h>
#import <DZKit/AlertManager.h>

#import "FeedsSearchResults.h"

@interface FeedsVC () <DZDatasource>

@property (nonatomic, strong) DZBasicDatasource *DS;
//@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@end

@implementation FeedsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.DS = [[DZBasicDatasource alloc] initWithView:self.tableView];
    self.DS.delegate = self;
    
    self.title = @"Feeds";
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FeedsCell.class) bundle:nil] forCellReuseIdentifier:kFeedsCell];
    self.tableView.tableFooterView = [UIView new];
    
    UIRefreshControl *control = [[UIRefreshControl alloc] init];
    [control addTarget:self action:@selector(beginRefreshing:) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView addSubview:control];
    self.refreshControl = control;
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didTapAdd:)];
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapSettings)];
    
    self.navigationItem.rightBarButtonItems = @[settings, add];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(readNotification:) name:FeedDidUpReadCount object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateNotification:) name:FeedsDidUpdate object:MyFeedsManager];
    
    // Search Controller setup
    {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
        
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:[[FeedsSearchResults alloc] initWithStyle:UITableViewStylePlain]];
        searchController.searchResultsUpdater = self;
        searchController.searchBar.placeholder = @"Search feeds";
        searchController.searchBar.accessibilityHint = @"Search your feeds";
        self.navigationItem.searchController = searchController;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // makes sure search bar is visible when it appears
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    [self dz_smoothlyDeselectRows:self.tableView];
    
    if (!self.DS.data || (!self.DS.data.count && !_noPreSetup)) {
        
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            [self.refreshControl beginRefreshing];
            _noPreSetup = YES;
            
            weakify(self);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                asyncMain(^{
                    strongify(self);
                    [self beginRefreshing:self.refreshControl];
                });
            });
        })
        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//            
//            [MyFeedsManager getFeedsSince:self.sinceDate success:^(NSNumber *responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//                
//                strongify(self);
//                
//                // we have received one response. This is usually from the disk cache.
//                if (responseObject.integerValue == 1) {
//                    return;
//                }
//                
//                // when counter reaches 2, we end refreshing since this is the network response.
//                if (responseObject.integerValue == 2) {
//                    asyncMain(^{
//                        [self.refreshControl endRefreshing];
//                    })
//                }
//                
//                [self setupData:MyFeedsManager.feeds];
//                
//                _preCommitLoading = NO;
//                
//            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//                
//                if (error) {
//                    DDLogError(@"%@", error);
//                    [AlertManager showGenericAlertWithTitle:@"Error loading" message:error.localizedDescription];
//                }
//                
//                // end refreshing if VC is in that state.
//                asyncMain(^{
//                    
//                    strongify(self);
//                    
//                    if (self.refreshControl.isRefreshing) {
//                        [self.refreshControl endRefreshing];
//                    }
//                    
//                    // locally loaded from disk-cache
//                    if (MyFeedsManager.feeds) {
//                        [self setupData:MyFeedsManager.feeds];
//                    }
//                });
//                
//                _preCommitLoading = NO;
//                
//            }];
//            
//        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _preCommitLoading = YES;
        });
    }
}

- (BOOL)definesPresentationContext
{
    return YES;
}

#pragma mark - Setters

- (void)setSinceDate:(NSDate *)sinceDate
{
    _sinceDate = sinceDate;
    
    if (_sinceDate) {
#ifdef DEBUG
        NSString *path = [@"~/Documents/feeds.since.debug.txt" stringByExpandingTildeInPath];
#elif
        NSString *path = [@"~/Documents/feeds.since.txt" stringByExpandingTildeInPath];
#endif
        NSNumber *timestamp = @([_sinceDate timeIntervalSince1970]);
        
        NSString *data = formattedString(@"%@", timestamp);
        NSError *error = nil;
        if (![data writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            DDLogError(@"Failed to save since date for feeds. %@", error.localizedDescription);
        }
    }
    
}

#pragma mark - Getters

- (NSDate *)sinceDate
{
    if (!_sinceDate) {
#ifdef DEBUG
        NSString *path = [@"~/Documents/feeds.since.debug.txt" stringByExpandingTildeInPath];
#elif
        NSString *path = [@"~/Documents/feeds.since.txt" stringByExpandingTildeInPath];
#endif
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSError *error = nil;
            NSString *data = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];

            if (!data) {
                DDLogError(@"Failed to load since date for feeds. %@", error.localizedDescription);
            }
            else {
                NSTimeInterval timestamp = [data doubleValue];
                _sinceDate = [NSDate dateWithTimeIntervalSince1970:timestamp];
            }
        }
    }

    return _sinceDate;
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FeedsCell *cell = [tableView dequeueReusableCellWithIdentifier:kFeedsCell forIndexPath:indexPath];
    
    // Configure the cell...
    Feed *feed = [self.DS objectAtIndexPath:indexPath];
    [cell configure:feed];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Feed *feed = [self.DS objectAtIndexPath:indexPath];
    
    FeedVC *vc = [[FeedVC alloc] initWithFeed:feed];
    
    [self.navigationController pushViewController:vc animated:YES];
    
}

//- (UIView *)viewForEmptyDataset
//{
//    if (!_activityView) {
//        _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
//        _activityView.color = self.view.tintColor;
//        [_activityView startAnimating];
//    }
//
//    return _activityView;
//}

#pragma mark -

- (void)setupData:(NSArray <Feed *> *)feeds
{
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(setupData:) withObject:feeds waitUntilDone:NO];
        return;
    }
    
    // ensures search bar does not dismiss on refresh or first load
    weakify(self);
    
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    self.DS.data = feeds;
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        // ensures user can dismiss search bar on scroll
        self.navigationItem.hidesSearchBarWhenScrolling = YES;
    });
}

#pragma mark - Notifications

- (void)readNotification:(NSNotification *)note {
    
    if (note.object && [note.object isKindOfClass:NSNumber.class]) {
        
        NSInteger feedID = [note.object integerValue];
        __block NSUInteger row = NSNotFound;
        
        [self.DS.data enumerateObjectsUsingBlock:^(Feed *obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            if (obj.feedID.integerValue == feedID) {
                row = idx;
                *stop = YES;
            }
            
        }];
        
        if (row != NSNotFound) {
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        }
        
    }
    
}

- (void)updateNotification:(NSNotification *)note {
    
    DZBasicDatasource *DS = [self valueForKeyPath:@"DS"];
    DS.data = [note.userInfo valueForKey:@"feeds"];
    
}

@end
