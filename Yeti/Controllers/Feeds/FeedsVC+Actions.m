//
//  FeedsVC+Actions.m
//  Yeti
//
//  Created by Nikhil Nigade on 29/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Actions.h"
#import <DZKit/AlertManager.h>
#import <DZKit/DZSectionedDatasource.h>
#import "FeedsManager.h"
#import "SettingsVC.h"

#import "MoveFoldersVC.h"

#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/NSString+Extras.h>

#import "AddFeedVC.h"
#import "NewFolderVC.h"
#import "YTNavigationController.h"
#import "RecommendationsVC.h"
#import "YetiThemeKit.h"

@implementation FeedsVC (Actions)

- (NSAttributedString *)lastUpdateAttributedString {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    
    NSString *dateString = [formatter stringFromDate:(MyFeedsManager.unreadLastUpdate ?: NSDate.date)];
    
    NSString *formatted = formattedString(@"Last update: %@", dateString);
    
    Theme *theme = [YTThemeKit theme];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:11.f],
                                 NSForegroundColorAttributeName: theme.isDark ? [UIColor lightGrayColor] : [UIColor darkGrayColor]
                                 };
    
    NSAttributedString *attrs = [[NSAttributedString alloc] initWithString:formatted attributes:attributes];
    
    return attrs;
}

- (void)beginRefreshing:(UIRefreshControl *)sender {
    
    if (_refreshing == YES || (sender != nil && [sender isRefreshing] == YES)) {
        
        return;
    }
    
    _refreshing = YES;
    
    weakify(self);
    
    [MyFeedsManager getUnreadForPage:1 sorting:@"0" success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.refreshControl.attributedTitle = [self lastUpdateAttributedString];
            
            NSIndexPath *IPOne = [NSIndexPath indexPathForRow:0 inSection:0];
            NSIndexPath *IPTwo = [NSIndexPath indexPathForRow:1 inSection:0];
            
            [self.DS reloadItemsAtIndices:@[IPOne, IPTwo]];
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        DDLogError(@"Failed to fetch unread: %@", error);
        
    }];
    
    [MyFeedsManager getFeedsSince:self.sinceDate success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (self == nil) {
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if ([responseObject integerValue] == 2) {
                [sender endRefreshing];
            }
            
            self->_refreshing = NO;
            
            if (sender != nil && sender.isRefreshing == YES) {
                [sender endRefreshing];
            }
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        DDLogError(@"%@", error);
        
        asyncMain(^{
            if ([[error userInfo] valueForKey:@"_kCFStreamErrorCodeKey"]) {
                if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
                    [AlertManager showGenericAlertWithTitle:@"Failed to Fetch Feeds" message:error.localizedDescription];
                }
            }
            
            if (sender != nil && sender.isRefreshing == YES) {
                [sender endRefreshing];
            }
        });
        
        strongify(self);
        
        self->_refreshing = NO;
        
    }];
    
}

- (void)didTapAdd:(UIBarButtonItem *)add
{
    
    UINavigationController *nav = [AddFeedVC instanceInNavController];
    
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
    
    [self.splitViewController presentViewController:navVC animated:YES completion:nil];
}

- (void)didTapRecommendations:(UIBarButtonItem *)sender
{
    RecommendationsVC *vc = [[RecommendationsVC alloc] initWithNibName:NSStringFromClass(RecommendationsVC.class) bundle:nil];
    
    if (@available(iOS 13, *)) {
        YTNavigationController *nav = [[YTNavigationController alloc] initWithRootViewController:vc];
        
        [self presentViewController:nav animated:YES completion:nil];
    }
    else {
        [self showViewController:vc sender:self];
    }

}

- (void)didLongTapOnCell:(UITapGestureRecognizer *)sender
{
    if (sender.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
    CGPoint location = [sender locationInView:sender.view];
    
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:location];
    
    if (!indexPath || indexPath.section == 0) {
        return;
    }
    
    DZSectionedDatasource *DS = [self valueForKeyPath:@"DS"];
    id obj = [DS objectAtIndexPath:indexPath];
    
    UIAlertController *avc = nil;
    
    weakify(self);
    
    if ([obj isKindOfClass:Feed.class]) {
        
        Feed *feed = (Feed *)obj;
        
        avc = [UIAlertController alertControllerWithTitle:@"Feed Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Move to Folder" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            UINavigationController *nav = [MoveFoldersVC instanceForFeed:feed];
            
            strongify(self);
            
            [self.splitViewController presentViewController:nav animated:YES completion:nil];
            
        }]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Share Feed URL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            NSString *feedURL = [feed url];
            NSURL *URL = [NSURL URLWithString:feedURL];
            
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:@[]];
            
            dispatch_async(dispatch_get_main_queue(), ^{
               
                [self presentViewController:activityVC animated:YES completion:nil];
                
            });
            
        }]];
        
        if (feed.extra && feed.extra.url) {
            
            [avc addAction:[UIAlertAction actionWithTitle:@"Share Website URL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                NSString *websiteURL = feed.extra.url;
                NSURL *URL = [NSURL URLWithString:websiteURL];
                
                UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:@[]];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self presentViewController:activityVC animated:YES completion:nil];
                    
                });
                
            }]];
            
        }
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Rename Feed" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            self.alertIndexPath = indexPath;
            
            [self renameFeed:feed];
            
        }]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Delete Feed" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            strongify(self);
            
            [self confirmFeedDelete:feed completionHandler:nil];
            
        }]];
        
    }
    else if ([obj isKindOfClass:Folder.class]) {
        Folder *folder = (Folder *)obj;
        
        avc = [UIAlertController alertControllerWithTitle:@"Folder Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Rename Folder" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            UINavigationController *nav = [NewFolderVC instanceWithFolder:folder feedsVC:self indexPath:indexPath];
            
            strongify(self);
            
            [self presentViewController:nav animated:YES completion:nil];
            
        }]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Delete Folder" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            strongify(self);
            
            [self confirmFolderDelete:folder completionHandler:nil];
            
        }]];
    }
    
    if (avc) {
        if (self.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
            
            UIPopoverPresentationController *pvc = avc.popoverPresentationController;
            pvc.sourceView = cell;
            pvc.sourceRect = CGRectMake(MAX(0, location.x -  pvc.sourceView.bounds.size.width), 0, pvc.sourceView.bounds.size.width, pvc.sourceView.bounds.size.height);
            
            pvc.sourceView = self.tableView;
        }
        
        [self presentViewController:avc animated:YES completion:nil];
    }
    
}

#pragma mark -

- (void)confirmFeedDelete:(Feed *)feed completionHandler:(void(^)(BOOL actionPerformed))completionHandler {
 
    weakify(self);
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Delete Feed?" message:@"Are you sure you want to delete this feed?" preferredStyle:UIAlertControllerStyleAlert];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        void(^removeFeedFromDS)(NSNumber *feedID) = ^(NSNumber *feedID) {
            
            if (feed.folderID != nil && feed.folderID.integerValue) {
                // remove it from the folder struct
                [MyFeedsManager.folders enumerateObjectsUsingBlock:^(Folder * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    if ([obj.folderID isEqualToNumber:feed.folderID]) {
                        
                        NSArray *feeds = [obj.feeds.allObjects rz_filter:^BOOL(Feed *objx, NSUInteger idxx, NSArray *array) {
                            return ![objx.feedID isEqualToNumber:feed.feedID];
                        }];
                        
                        [obj.feeds removeAllObjects];
                        [obj.feeds addObjectsFromArray:feeds];
                        
                        *stop = YES;
                    }
                    
                }];
            }
            
            NSArray <Feed *> *feeds = MyFeedsManager.feeds;
            
            feeds = [feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                return obj.feedID.integerValue != feedID.integerValue;
            }];
            
            MyFeedsManager.feeds = feeds;
            
            if (completionHandler) {
                dispatch_async(dispatch_get_main_queue(), ^{
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
                    [AlertManager showGenericAlertWithTitle:@"Something Went Wrong" message:error.localizedDescription];
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
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Delete Folder?" message:@"Are you sure you want to delete this folder?" preferredStyle:UIAlertControllerStyleAlert];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        if (completionHandler) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(YES);
            });
        }
        
        [MyFeedsManager removeFolder:folder success:nil error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            asyncMain(^{
                [AlertManager showGenericAlertWithTitle:@"Something Went Wrong" message:error.localizedDescription];
            });
            
        }];
        
    }]];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    asyncMain(^{
        strongify(self);
        
        [self presentViewController:avc animated:YES completion:nil];
    });
    
}

#pragma mark - Action Extensions

- (void)clearAlertProperties {
    self.alertDoneAction = nil;
    self.alertTextField = nil;
    self.alertFeed = nil;
}

- (void)renameFeed:(Feed *)feed {
    
    self.alertFeed = feed;
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Rename Feed" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *done = [UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSString *name = [[self.alertTextField text] stringByStrippingWhitespace];
        
        [MyDBManager renameFeed:self.alertFeed customTitle:name completion:^(BOOL success) {
            
            [self.tableView reloadRowsAtIndexPaths:@[self.alertIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            
            [self clearAlertProperties];
            
        }];
        
    }];
    
    [avc addAction:done];
    
    self.alertDoneAction = done;
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self clearAlertProperties];
            
        });
        
    }]];
    
    [avc addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
       
        self.alertTextField = textField;
        
        [textField setPlaceholder:@"Feed Name"];
        [textField setText:(feed.localName ?: feed.title)];
        
        textField.delegate = self;
        
        if (self.alertFeed.localName != nil) {
            self.alertDoneAction.enabled = YES;
        }
        else {
            self.alertDoneAction.enabled = ([(feed.localName ?: feed.title) stringByStrippingWhitespace].length >= 3);
        }
        
    }];
    
    [self presentViewController:avc animated:YES completion:^{
       
        [self.alertTextField becomeFirstResponder];
        
    }];
    
}

#pragma mark - <UITableViewDelegate>

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)ip {
    
    if (ip.section == 0)
        return nil;
    
    if (tableView != self.tableView)
        return nil;
    
    __strong NSIndexPath *indexPath = [ip copy];
    
    Feed *feed = [self objectAtIndexPath:indexPath];
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
        UIContextualAction *rename = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Rename" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
           
            strongify(self);
            
            UINavigationController *nav = [NewFolderVC instanceWithFolder:folder feedsVC:self indexPath:indexPath];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:nav animated:YES completion:^{
                    completionHandler(YES);
                }];
            });
            
        }];
        
        rename.backgroundColor = self.view.tintColor;
        
        configuration = [UISwipeActionsConfiguration configurationWithActions:@[delete, rename]];
    }
    else {
        
        UIContextualAction *move = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Move" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
           
            completionHandler(YES);
            
            [self feed_didTapMove:feed indexPath:indexPath];
            
        }];
        
        move.backgroundColor = [UIColor colorWithRed:0/255.f green:122/255.f blue:255/255.f alpha:1.f];
        
        UIContextualAction *share = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Share" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
           
            completionHandler(YES);
            
            [self feed_didTapShare:feed indexPath:indexPath];
            
        }];
        
        share.backgroundColor = [UIColor colorWithRed:126/255.f green:211/255.f blue:33/255.f alpha:1.f];
        
        configuration = [UISwipeActionsConfiguration configurationWithActions:@[delete, move, share]];
        
    }
    
    configuration.performsFirstActionWithFullSwipe = YES;
    
    return configuration;

}

- (BOOL)feedCanShowExtraShareLevel:(Feed *)feed {
    
    if (feed == nil) {
        return NO;
    }
    
    if (feed.extra == nil || feed.extra.url == nil) {
        return NO;
    }
    
    return YES;
    
}

- (void)showShareOptionsVC:(Feed *)feed indexPath:(NSIndexPath *)indexPath {
    
    if ([self feedCanShowExtraShareLevel:feed] == NO) {
        return;
    }
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    weakify(self);
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Share Feed URL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        
        
    }]];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Share Website URL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        
        
    }]];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    if (self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIPopoverPresentationController *pvc = avc.popoverPresentationController;
        
        pvc.sourceView = self.tableView;
        pvc.sourceRect = [self.tableView rectForRowAtIndexPath:indexPath];
        pvc.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    
    [self presentViewController:avc animated:YES completion:nil];
    
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    if (textField == self.alertTextField) {
        NSString *formatted = [textField.text stringByReplacingCharactersInRange:range withString:string];
        
        /*
         * If the user has setup a localName, they can pass a clear input to remove it.
         * If a localName is not set, the name has to be atleast 3 chars.
         */
        if (self.alertFeed.localName != nil) {
            self.alertDoneAction.enabled = YES;
        }
        else {
            self.alertDoneAction.enabled = ([[formatted stringByStrippingWhitespace] length] >= 3);
        }
    }
    
    return YES;
    
}

#pragma mark - Common Action Handlers

- (void)shareFeedURL:(Feed *)feed indexPath:(NSIndexPath *)indexPath {
    
    NSString *feedURL = [feed url];
    NSURL *URL = [NSURL URLWithString:feedURL];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:@[]];
    
    [self showActivityController:activityVC indexPath:indexPath];
    
}

- (void)shareWebsiteURL:(Feed *)feed indexPath:(NSIndexPath *)indexPath {
    
    NSString *websiteURL = feed.extra.url;
    NSURL *URL = [NSURL URLWithString:websiteURL];
    
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:@[]];
    
    [self showActivityController:activityVC indexPath:indexPath];
    
}

- (void)showActivityController:(UIActivityViewController *)avc indexPath:(NSIndexPath *)indexPath {
    
    if (indexPath != nil && self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        
        UIPopoverPresentationController *pvc = avc.popoverPresentationController;
        pvc.sourceView = self.tableView;
        pvc.sourceRect = [self.tableView rectForRowAtIndexPath:indexPath];
        
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self presentViewController:avc animated:YES completion:nil];
        
    });
    
}

- (void)feed_didTapShare:(Feed *)feed indexPath:(NSIndexPath *)indexPath {
    
    if (feed.extra && feed.extra.url) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showShareOptionsVC:feed indexPath:indexPath];
        });
    }
    else {
        NSString *feedURL = [feed url];
        NSURL *URL = [NSURL URLWithString:feedURL];
        
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:@[]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                UIPopoverPresentationController *pvc = activityVC.popoverPresentationController;
                
                pvc.sourceView = self.tableView;
                pvc.sourceRect = [self.tableView rectForRowAtIndexPath:indexPath];
                pvc.permittedArrowDirections = UIPopoverArrowDirectionAny;
            }
            
            [self presentViewController:activityVC animated:YES completion:nil];
            
        });
    }
    
}

- (void)feed_didTapMove:(Feed *)feed indexPath:(NSIndexPath *)indexPath {
    
    UINavigationController *nav = [MoveFoldersVC instanceForFeed:feed];
    
    [self.splitViewController presentViewController:nav animated:YES completion:nil];
    
}

@end
