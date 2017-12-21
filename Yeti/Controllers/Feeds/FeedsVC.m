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

@interface FeedsVC () <DZDatasource> {
    
}

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
    
    self.navigationItem.rightBarButtonItems = @[add];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(readNotification:) name:FeedDidUpReadCount object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self dz_smoothlyDeselectRows:self.tableView];
    
    if (!self.DS.data || (!self.DS.data.count && !_noPreSetup)) {
        
        _preCommitLoading = YES;
        
        weakify(self);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [MyFeedsManager getFeeds:^(NSNumber *responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                strongify(self);
                
                // we have received one response. This is usually from the disk cache.
                if (responseObject.integerValue == 1) {
                    asyncMain(^{
                        [self.refreshControl beginRefreshing];
                    })
                }
                
                // when counter reaches 2, we end refreshing since this is the network response.
                if (responseObject.integerValue == 2) {
                    asyncMain(^{
                        [self.refreshControl endRefreshing];
                    })
                }
                
                [self setupData:MyFeedsManager.feeds];
                
                _preCommitLoading = NO;
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
               
                DDLogError(@"%@", error);
                
                [AlertManager showGenericAlertWithTitle:@"Error loading" message:error.localizedDescription];
                
                // end refreshing if VC is in that state.
                asyncMain(^{
                    
                    strongify(self);
                    
                    if (self.refreshControl.isRefreshing) {
                        [self.refreshControl endRefreshing];
                    }
                });
                
                _preCommitLoading = NO;
                
            }];
            
        });
        
        _noPreSetup = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
    self.DS.data = feeds;
}

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

@end
