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

#import "NewFeedVC.h"

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
    
    return;
    
    __block __strong UITextField *_tf = nil;
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"New Feed" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }]];
    
    weakify(self);
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSString *path = _tf.text;
        
        _tf = nil;
        
        NSURL *URL = [[NSURL alloc] initWithString:path];
        
        if (!URL) {
            [AlertManager showGenericAlertWithTitle:@"Invalid URL" message:@"The URL you provided was invalid. Please check it and try again."];
            return;
        }
        
        [MyFeedsManager addFeed:URL success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            MyFeedsManager.feeds = [MyFeedsManager.feeds arrayByAddingObject:responseObject];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            [AlertManager showGenericAlertWithTitle:@"An error occurred" message:error.localizedDescription];
            
        }];
        
    }]];
    
    [avc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        _tf = textField;
        
        _tf.placeholder = @"Feed URL";
    }];
    
    asyncMain(^{
        
        strongify(self);
        
        [self presentViewController:avc animated:YES completion:nil];
        
    });
    
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
    
    __strong NSIndexPath *indexPath = [ip copy];
    
    weakify(self);
    
    UIContextualAction *delete = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        
        strongify(self);
        
        DZBasicDatasource *DS = [self valueForKeyPath:@"DS"];
        
        Feed *feed = [DS objectAtIndexPath:indexPath];
        
        void(^removeFromDS)(NSNumber *feedID) = ^(NSNumber *feedID) {
            MyFeedsManager.feeds = [MyFeedsManager.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                return obj.feedID.integerValue != feedID.integerValue;
            }];
            
//            asyncMain(^{
//                [tableView endEditing:YES];
//            });
            
            asyncMain(^{
                completionHandler(YES);
            });
        };
       
        [MyFeedsManager removeFeed:feed.feedID success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            removeFromDS(feed.feedID);
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            if (response.statusCode == 304) {
                removeFromDS(feed.feedID);
            }
            else {
                asyncMain(^{
                    [AlertManager showGenericAlertWithTitle:@"Something went wrong" message:error.localizedDescription];
                });
            }
            
            asyncMain(^{
                completionHandler(YES);
            });
            
        }];
        
    }];

    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[delete]];
    
    configuration.performsFirstActionWithFullSwipe = YES;
    
    return configuration;

}

@end
