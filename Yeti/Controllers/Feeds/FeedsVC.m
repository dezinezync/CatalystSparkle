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
#import "CustomFeedVC.h"

@interface FeedsVC () <DZDatasource>

@property (nonatomic, strong) DZBasicDatasource *DS;
//@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@end

@implementation FeedsVC

- (BOOL)ef_hidesNavBorder {
    return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.DS = [[DZBasicDatasource alloc] initWithView:self.tableView];
    self.DS.delegate = self;
    
    self.DS.addAnimation = UITableViewRowAnimationFade;
    self.DS.deleteAnimation = UITableViewRowAnimationFade;
    self.DS.reloadAnimation = UITableViewRowAnimationFade;
    
    self.tableView.dragDelegate = self;
    
    self.title = @"Feeds";
    
    [self.tableView registerNib:[UINib nibWithNibName:NSStringFromClass(FeedsCell.class) bundle:nil] forCellReuseIdentifier:kFeedsCell];
    
    FeedsHeaderView *headerView = [[FeedsHeaderView alloc] initWithNib];
    headerView.frame = CGRectMake(0, 0, self.tableView.bounds.size.width, 88.f);
    [headerView setContentCompressionResistancePriority:1000 forAxis:UILayoutConstraintAxisVertical];
    
    self.tableView.tableHeaderView = headerView;
    _headerView = headerView;
    _headerView.tableView.delegate = self;
    
    self.tableView.tableFooterView = [UIView new];
    
    UIRefreshControl *control = [[UIRefreshControl alloc] init];
    [control addTarget:self action:@selector(beginRefreshing:) forControlEvents:UIControlEventValueChanged];
    
    [self.tableView addSubview:control];
    self.refreshControl = control;
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(didTapAdd:)];
    UIBarButtonItem *folder = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"create_new_folder"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapAddFolder:)];
    UIBarButtonItem *settings = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settings"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapSettings)];
    
    self.navigationItem.rightBarButtonItems = @[settings, add, folder];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    self.navigationController.navigationBar.prefersLargeTitles = YES;
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(readNotification:) name:FeedDidUpReadCount object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(updateNotification:) name:FeedsDidUpdate object:MyFeedsManager];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(userDidUpdate) name:UserDidUpdate object:nil];
    
    // Search Controller setup
    {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
        
        UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:[[FeedsSearchResults alloc] initWithStyle:UITableViewStylePlain]];
        searchController.searchResultsUpdater = self;
        searchController.searchBar.placeholder = @"Search feeds";
        searchController.searchBar.accessibilityHint = @"Search your feeds";
        self.navigationItem.searchController = searchController;
    }
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongTapOnCell:)];
    [self.tableView addGestureRecognizer:longPress];
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
    
    if (self.tableView.indexPathForSelectedRow) {
        [self dz_smoothlyDeselectRows:self.tableView];
    }
    
    if (self.headerView.tableView.indexPathForSelectedRow) {
        
        NSIndexPath *indexpath = self.headerView.tableView.indexPathForSelectedRow;
        if (indexpath.row == 0) {
            // also update unread array
            [MyFeedsManager updateUnreadArray];
        }
        
        [self dz_smoothlyDeselectRows:self.headerView.tableView];
    }
    
    if (!self.DS.data || (!self.DS.data.count && !_noPreSetup)) {
        
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            [self.refreshControl beginRefreshing];
            self->_noPreSetup = YES;
            
            weakify(self);
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                asyncMain(^{
                    strongify(self);
                    [self beginRefreshing:self.refreshControl];
                });
            });
        })
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            strongify(self);
            self->_preCommitLoading = YES;
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
        NSString *path;
#ifdef DEBUG
        path = [@"~/Documents/feeds.since.debug.txt" stringByExpandingTildeInPath];
#else
        path = [@"~/Documents/feeds.since.txt" stringByExpandingTildeInPath];
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
#else
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
    if ([feed isKindOfClass:Feed.class]) {
        [cell configure:feed];
    }
    else {
        // folder
        [cell configureFolder:(Folder *)feed];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (tableView == self.headerView.tableView) {
        CustomFeedVC *vc = [[CustomFeedVC alloc] initWithStyle:UITableViewStylePlain];
        vc.unread = indexPath.row == 0;
        
        [self.navigationController pushViewController:vc animated:YES];
        
        return;
    }
    
    Feed *feed = [self.DS objectAtIndexPath:indexPath];
    
    if ([feed isKindOfClass:Feed.class]) {
        FeedVC *vc = [[FeedVC alloc] initWithFeed:feed];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else {
        // it's a folder
        Folder *folder = (Folder *)feed;
        NSUInteger index = [self.DS.data indexOfObject:folder];
        
        if (folder.isExpanded) {
            
            DDLogDebug(@"Closing index: %@", @(index));
            folder.expanded = NO;
            
            // remove these feeds from the datasource
            self.DS.data = [self.DS.data rz_filter:^BOOL(id obj, NSUInteger idx, NSArray *array) {
                
                if ([obj isKindOfClass:Folder.class])
                    return YES;
                
                if ([(Feed *)obj folderID] && [[obj folderID] isEqualToNumber:folder.folderID]) {
                    return NO;
                }
                
                return YES;
                
            }];
            
        }
        else {
            folder.expanded = YES;
            DDLogDebug(@"Opening index: %@", @(index));
            
            // add these feeds to the datasource after the above index
            NSMutableArray * data = [self.DS.data mutableCopy];
            
            NSIndexSet *set = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(index+1, folder.feeds.count)];
            
            [data insertObjects:folder.feeds atIndexes:set];
            
            self.DS.data = data;
            
        }
        
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        });
    }
    
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
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            
            [self setupData:feeds];
        });
        return;
    }
    
    // ensures search bar does not dismiss on refresh or first load
    weakify(self);
    
    @try {
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        
        self.DS.data = [(MyFeedsManager.folders ?: @[]) arrayByAddingObjectsFromArray:feeds];
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            strongify(self);
            // ensures user can dismiss search bar on scroll
            self.navigationItem.hidesSearchBarWhenScrolling = YES;
        });
    } @catch (NSException *exc) {
        DDLogWarn(@"Exception: %@", exc);
    }
}

#pragma mark - Notifications

- (void)readNotification:(NSNotification *)note {
    
    if (note.object && [note.object isKindOfClass:NSNumber.class]) {
        
        NSInteger feedID = [note.object integerValue];
        __block NSUInteger row = NSNotFound;
        
        [self.DS.data enumerateObjectsUsingBlock:^(Feed *obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            if ([obj isKindOfClass:Folder.class]) {
                // check inside the folder
                
                [[(Folder *)obj feeds] enumerateObjectsUsingBlock:^(Feed * _Nonnull objx, NSUInteger idxx, BOOL * _Nonnull stopx) {
                   
                    if (objx.feedID.integerValue == feedID) {
                        row = idx + (idxx + 1);
                        *stopx = YES;
                        *stop = YES;
                    }
                    
                }];
                
            }
            else {
                if (obj.feedID.integerValue == feedID) {
                    row = idx;
                    *stop = YES;
                }
            }
            
        }];
        
        if (row != NSNotFound) {
            // grab the feed
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            Feed *item = [self.DS objectAtIndexPath:indexPath];
            
            if (item) {
                
                // check userInfo for read notification type
                BOOL read = note.userInfo ? [[note.userInfo valueForKey:@"read"] boolValue] : YES;
                
                if ([item isKindOfClass:Feed.class]) {
                    item.unread = @(MAX(0, item.unread.integerValue + (read ? -1 : 1)));
                }
                else {
                    [[(Folder *)item feeds] enumerateObjectsUsingBlock:^(Feed *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        
                        if ([[obj feedID] isEqualToNumber:note.object]) {
                            obj.unread = @(MAX(0, item.unread.integerValue + (read ? -1 : 1)));
                            *stop = YES;
                        }
                        
                    }];
                }
                
                weakify(self);
                
                @try {
                    asyncMain(^{
                        strongify(self);
                        
                        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    });
                } @catch (NSException * exc) {
                    DDLogWarn(@"Exception: %@", exc);
                }
            }
        }
        
    }
    else {
        // the unread count was bumped by the user manually marking
        // an article as unread. So reload the row
        weakify(self);
        
        @try {
            asyncMain(^{
                strongify(self);
                
                NSIndexPath *selected = [self.headerView.tableView indexPathForSelectedRow];
                
                [self.headerView.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
                
                if (selected) {
                    asyncMain(^{
                        [self.headerView.tableView selectRowAtIndexPath:selected animated:NO scrollPosition:UITableViewScrollPositionNone];
                    })
                }
            });
        }
        @catch (NSException *exc) {
            DDLogWarn(@"Exception updating read count after manual unread mark: %@", exc);
        }
    }
    
}

- (void)updateNotification:(NSNotification *)note {
    
    [self setupData:[note.userInfo valueForKey:@"feeds"]];
    
}

- (void)userDidUpdate {
    // we only need this once.
    [NSNotificationCenter.defaultCenter removeObserver:self name:UserDidUpdate object:nil];
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        asyncMain(^{
            strongify(self);
            [self beginRefreshing:self.refreshControl];
        });
    });
}

@end
