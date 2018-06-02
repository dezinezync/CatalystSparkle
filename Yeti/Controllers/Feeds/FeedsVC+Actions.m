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

#import "MoveFoldersVC.h"

#import <DZKit/NSArray+RZArrayCandy.h>

#import "NewFolderVC.h"
#import "YTNavigationController.h"

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
        
        asyncMain(^{
            
            strongify(self);
            
            [self.headerView.tableView reloadData];
        });
        
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
    
    YTNavigationController *navVC = [[YTNavigationController alloc] initWithRootViewController:settingsVC];
    navVC.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.splitViewController presentViewController:navVC animated:YES completion:nil];
}

- (void)didLongTapOnCell:(UITapGestureRecognizer *)sender
{
    CGPoint location = [sender locationInView:sender.view];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    if (!indexPath) {
        return;
    }
    
    DZBasicDatasource *DS = [self valueForKeyPath:@"DS"];
    id obj = [DS objectAtIndexPath:indexPath];
    
    UIAlertController *avc = nil;
    
    weakify(self);
    
    if ([obj isKindOfClass:Feed.class]) {
        
        Feed *feed = (Feed *)obj;
        
        avc = [UIAlertController alertControllerWithTitle:@"Feed options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Move to folder" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            UINavigationController *nav = [MoveFoldersVC instanceForFeed:feed];
            
            strongify(self);
            
            [self.splitViewController presentViewController:nav animated:YES completion:nil];
            
        }]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Delete feed" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            strongify(self);
            
            [self confirmFeedDelete:feed completionHandler:nil];
            
        }]];
        
    }
    else if ([obj isKindOfClass:Folder.class]) {
        Folder *folder = (Folder *)obj;
        
        avc = [UIAlertController alertControllerWithTitle:@"Folder options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Rename folder" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            UINavigationController *nav = [NewFolderVC instanceWithFolder:folder];
            
            strongify(self);
            
            [self presentViewController:nav animated:YES completion:nil];
            
        }]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Delete folder" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            strongify(self);
            
            [self confirmFolderDelete:folder completionHandler:nil];
            
        }]];
    }
    
    if (avc) {
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            
            UIPopoverPresentationController *pvc = avc.popoverPresentationController;
            pvc.sourceView = [self.tableView cellForRowAtIndexPath:indexPath];
            pvc.sourceRect = CGRectMake(location.x, location.y, pvc.sourceView.bounds.size.width, pvc.sourceView.bounds.size.height);
            
        }
        
        [self presentViewController:avc animated:YES completion:nil];
    }
    
}

#pragma mark -

- (void)confirmFeedDelete:(Feed *)feed completionHandler:(void(^)(BOOL actionPerformed))completionHandler {
 
    weakify(self);
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Are you sure?" message:@"Are you sure you want to delete this feed?" preferredStyle:UIAlertControllerStyleAlert];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
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
            
            if (completionHandler) {
                asyncMain(^{
                    completionHandler(YES);
                });
            }
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
                
                if (completionHandler) {
                    asyncMain(^{
                        completionHandler(NO);
                    });
                }
            }
            
        }];
        
    }]];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    asyncMain(^{
        strongify(self);
        
        [self presentViewController:avc animated:YES completion:nil];
    });
    
}

- (void)confirmFolderDelete:(Folder *)folder completionHandler:(void(^)(BOOL actionPerformed))completionHandler {
    
    weakify(self);
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Are you sure?" message:@"Are you sure you want to delete this folder?" preferredStyle:UIAlertControllerStyleAlert];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        [MyFeedsManager removeFolder:folder.folderID success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            MyFeedsManager.folders = [MyFeedsManager.folders rz_filter:^BOOL(Folder *obj, NSUInteger idx, NSArray *array) {
                return ![obj.folderID isEqualToNumber:folder.folderID];
            }];
            
            MyFeedsManager.feeds = [MyFeedsManager.feeds arrayByAddingObjectsFromArray:folder.feeds];
            
            strongify(self);
            
            [self setupData:MyFeedsManager.feeds];
            
            if (completionHandler) {
                asyncMain(^{
                    completionHandler(YES);
                });
            }
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            asyncMain(^{
                [AlertManager showGenericAlertWithTitle:@"Something went wrong" message:error.localizedDescription];
            });
            
            if (completionHandler) {
                asyncMain(^{
                    completionHandler(NO);
                });
            }
            
        }];
        
    }]];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    asyncMain(^{
        strongify(self);
        
        [self presentViewController:avc animated:YES completion:nil];
    });
    
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
            
            strongify(self);
            
            [self confirmFolderDelete:folder completionHandler:completionHandler];
            
            return;
        }
        
        [self confirmFeedDelete:feed completionHandler:completionHandler];
        
    }];

    UISwipeActionsConfiguration *configuration = nil;
    
    if (folder) {
         configuration = [UISwipeActionsConfiguration configurationWithActions:@[delete]];
    }
    else {
        
        UIContextualAction *move = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Move" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
           
            UINavigationController *nav = [MoveFoldersVC instanceForFeed:feed];
            
            strongify(self);
            
            [self.splitViewController presentViewController:nav animated:YES completion:^{
                completionHandler(YES);
            }];
            
        }];
        
        move.backgroundColor = [UIColor purpleColor];
        
        configuration = [UISwipeActionsConfiguration configurationWithActions:@[delete, move]];
        
    }
    
    configuration.performsFirstActionWithFullSwipe = YES;
    
    return configuration;

}

@end
