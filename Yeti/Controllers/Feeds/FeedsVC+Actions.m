//
//  FeedsVC+Actions.m
//  Yeti
//
//  Created by Nikhil Nigade on 29/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Actions.h"
#import <DZKit/AlertManager.h>
#import <DZKit/DZBasicDatasource.h>
#import "FeedsManager.h"
#import "SettingsVC.h"

#import <DZKit/NSArray+RZArrayCandy.h>

#import "NewFolderVC.h"

@implementation FeedsVC (Actions)

- (void)beginRefreshing:(UIRefreshControl *)sender {
    
    if (_refreshing || !_noPreSetup) {
        
        if ([sender isRefreshing])
            [sender endRefreshing];
        
        return;
    }
    
    _refreshing = YES;
    
    weakify(self);
    
    [MyFeedsManager getUnreadForPage:1 success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        [self.headerView.tableView reloadData];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        DDLogError(@"Failed to fetch unread: %@", error);
    }];
    
    [MyFeedsManager getFeedsSince:self.sinceDate success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
#ifndef DEBUG
        @synchronized(self) {
            self.sinceDate = NSDate.date;
        }
#endif
        
        asyncMain(^{
            
            [self setupData:MyFeedsManager.feeds];
            
            if ([responseObject integerValue] == 2) {
                [sender endRefreshing];
            }
        });
        
        self->_refreshing = NO;
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        DDLogError(@"%@", error);
        
        asyncMain(^{
            [sender endRefreshing];
        });
        
        strongify(self);
        
        self->_refreshing = NO;
        
    }];
    
}

- (void)didTapAdd:(UIBarButtonItem *)add
{
    
    UINavigationController *nav = [NewFeedVC instanceInNavController];
    
    [self presentViewController:nav animated:YES completion:nil];
    
}

- (void)didTapAddFolder:(UIBarButtonItem *)add {
    
    UINavigationController *nav = [NewFolderVC instanceInNavController];
    
    [self presentViewController:nav animated:YES completion:nil];
    
}

- (void)didTapSettings
{
    SettingsVC *settingsVC = [[SettingsVC alloc] initWithNibName:NSStringFromClass(SettingsVC.class) bundle:nil];
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.splitViewController presentViewController:navVC animated:YES completion:nil];
}

#pragma mark - <UITableViewDelegate>

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)ip
{
    
    if (tableView != self.tableView)
        return nil;
    
    __strong NSIndexPath *indexPath = [ip copy];
    
    DZBasicDatasource *DS = [self valueForKeyPath:@"DS"];
    
    Feed *feed = [DS objectAtIndexPath:indexPath];
    Folder *folder = nil;
    
    if ([feed isKindOfClass:Folder.class]) {
        folder = (Folder *)feed;
    }
    
    weakify(self);
    
    UIContextualAction *delete = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        
        if (folder) {
            
            [MyFeedsManager removeFolder:folder.folderID success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                MyFeedsManager.folders = [MyFeedsManager.folders rz_filter:^BOOL(Folder *obj, NSUInteger idx, NSArray *array) {
                    return ![obj.folderID isEqualToNumber:folder.folderID];
                }];
                
                MyFeedsManager.feeds = [MyFeedsManager.feeds arrayByAddingObjectsFromArray:folder.feeds];
                
                strongify(self);
                
                [self setupData:MyFeedsManager.feeds];
                
                asyncMain(^{
                    completionHandler(YES);
                });
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                asyncMain(^{
                    [AlertManager showGenericAlertWithTitle:@"Something went wrong" message:error.localizedDescription];
                });
                
                completionHandler(NO);
                
            }];
            
            return;
        }
        
        void(^removeFeedFromDS)(NSNumber *feedID) = ^(NSNumber *feedID) {
            
            if (feed.folderID != nil && feed.folderID.integerValue) {
                // remove it from the folder struct
                [MyFeedsManager.folders enumerateObjectsUsingBlock:^(Folder * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                   
                    if ([obj.folderID isEqualToNumber:feed.folderID]) {
                        
                        obj.feeds = [obj.feeds rz_filter:^BOOL(Feed *objx, NSUInteger idxx, NSArray *array) {
                            return ![objx.feedID isEqualToNumber:feed.feedID];
                        }];
                        
                        *stop = YES;
                    }
                    
                }];
            }
            
            MyFeedsManager.feeds = [MyFeedsManager.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                return obj.feedID.integerValue != feedID.integerValue;
            }];
            
            asyncMain(^{
                completionHandler(YES);
            });
        };
       
        [MyFeedsManager removeFeed:feed.feedID success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            removeFeedFromDS(feed.feedID);
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            if (response.statusCode == 304) {
                removeFeedFromDS(feed.feedID);
            }
            else {
                asyncMain(^{
                    [AlertManager showGenericAlertWithTitle:@"Something went wrong" message:error.localizedDescription];
                });
                
                asyncMain(^{
                    completionHandler(NO);
                });
            }
            
        }];
        
    }];

    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[delete]];
    
    configuration.performsFirstActionWithFullSwipe = YES;
    
    return configuration;

}

@end
