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

#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/NSString+Extras.h>

#import "AddFeedVC.h"
#import "NewFolderVC.h"
#import "YTNavigationController.h"
#import "RecommendationsVC.h"
#import "YetiThemeKit.h"
#import "FeedsCell.h"

@implementation FeedsVC (Actions)

- (NSAttributedString *)lastUpdateAttributedString {
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    
    NSString *dateString = [formatter stringFromDate:(MyFeedsManager.unreadLastUpdate ?: NSDate.date)];
    
    NSString *formatted = formattedString(@"Last update: %@", dateString);
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:11.f],
                                 NSForegroundColorAttributeName: UIColor.secondaryLabelColor
                                 };
    
    NSAttributedString *attrs = [[NSAttributedString alloc] initWithString:formatted attributes:attributes];
    
    return attrs;
}

- (void)beginRefreshing:(UIRefreshControl *)sender {
    
    if ((ArticlesManager.shared.feeds.count == 0 || ArticlesManager.shared.folders.count == 0) && _refreshing == NO) {
        
        [MyFeedsManager getFeedsWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self beginRefreshing:sender];
            });
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self beginRefreshing:sender];
            });
            
        }];
        
        return;
        
    }
    
    if (_refreshing == YES) {  
        return;
    }
    
    if ([self.refreshControl isRefreshing] == NO) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self.refreshControl beginRefreshing];
            
        });
        
    }
    
    _refreshing = YES;
    
    [self fetchLatestCounters];
    
    [MyDBManager setValue:@(NO) forKey:@"syncSetup"];
    [MyDBManager setupSync];
    
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
    
    [self.to_splitViewController presentViewController:navVC animated:YES completion:nil];
}

- (void)didTapRecommendations:(UIBarButtonItem *)sender
{
    RecommendationsVC *vc = [[RecommendationsVC alloc] initWithNibName:NSStringFromClass(RecommendationsVC.class) bundle:nil];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [self.to_splitViewController to_showSecondaryViewController:nav sender:sender];

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
            
            strongify(self);
            
            [self feed_didTapMove:feed indexPath:indexPath];
            
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
                [ArticlesManager.shared.folders enumerateObjectsUsingBlock:^(Folder * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    
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
            
            NSArray <Feed *> *feeds = ArticlesManager.shared.feeds;
            
            feeds = [feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                return obj.feedID.integerValue != feedID.integerValue;
            }];
            
            ArticlesManager.shared.feeds = feeds;
            MyFeedsManager.totalUnread = MAX(0, MyFeedsManager.totalUnread - feed.unread.integerValue);
            
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
            
            if (success) {
                FeedsCell *cell = [self.tableView cellForRowAtIndexPath:self.alertIndexPath];
                
                if (cell) {
                    cell.titleLabel.text = name;
                }
            }
            else {
                [AlertManager showGenericAlert];
            }
            
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

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(nonnull NSIndexPath *)indexPath point:(CGPoint)point  API_AVAILABLE(ios(13.0)) {
    
    if (indexPath.section == 0) {
        return nil;
    }
    
    id obj = [self objectAtIndexPath:indexPath];
    
    if (obj == nil) {
        return nil;
    }
    
    UIContextMenuConfiguration *config = nil;
    
    if ([obj isKindOfClass:Folder.class]) {
        
        Folder *folder = (Folder *)obj;
        
        config = [UIContextMenuConfiguration configurationWithIdentifier:formattedString(@"folder-%@", folder.folderID) previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            
            UIAction * rename = [UIAction actionWithTitle:@"Rename" image:[UIImage systemImageNamed:@"pencil"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                UINavigationController *nav = [NewFolderVC instanceWithFolder:folder feedsVC:self indexPath:indexPath];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentViewController:nav animated:YES completion:nil];
                });
                
            }];
            
            UIAction * delete = [UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                [self confirmFolderDelete:folder completionHandler:nil];
                
            }];
            
            delete.attributes = UIMenuElementAttributesDestructive;
            
            NSArray <UIAction *> *actions = @[rename, delete];
            
            UIMenu *menu = [UIMenu menuWithTitle:@"Feed Menu" children:actions];
            
            return menu;
            
        }];
    }
    else {
        Feed *feed = (Feed *)obj;
        
        config = [UIContextMenuConfiguration configurationWithIdentifier:formattedString(@"feed-%@", feed.feedID) previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            
            UIMenuElement * share = nil;
            
            if ([self feedCanShowExtraShareLevel:feed] == YES) {
                
                UIAction *shareFeed = [UIAction actionWithTitle:@"Share Feed URL" image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    
                    [self shareFeedURL:feed indexPath:indexPath];
                    
                }];
                
                UIAction *shareWebsite = [UIAction actionWithTitle:@"Share Website URL" image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    
                    [self shareWebsiteURL:feed indexPath:indexPath];
                    
                }];
                
                NSArray <UIAction *> *shareChildren = @[shareFeed, shareWebsite];
                
                share = [UIMenu menuWithTitle:@"Share" children:shareChildren];
                
            }
            else {
                
                share = [UIAction actionWithTitle:@"Share" image:[UIImage systemImageNamed:@"square.and.arrow.up"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                    
                    [self feed_didTapShare:feed indexPath:indexPath];
                    
                }];
                
            }
            
            UIAction * rename = [UIAction actionWithTitle:@"Rename" image:[UIImage systemImageNamed:@"pencil"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                self.alertIndexPath = indexPath;
                
                [self renameFeed:feed];
            }];
            
            UIAction * move = [UIAction actionWithTitle:@"Move" image:[UIImage systemImageNamed:@"text.insert"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                [self feed_didTapMove:feed indexPath:indexPath];
                
            }];
            
            UIAction * delete = [UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                [self confirmFeedDelete:feed completionHandler:nil];
                
            }];
            
            delete.attributes = UIMenuElementAttributesDestructive;
            
            NSArray <UIAction *> *actions = @[(UIAction *)share, rename, move, delete];
            
            UIMenu *menu = [UIMenu menuWithTitle:@"Feed Menu" children:actions];
            
            return menu;
            
        }];
    }
    
    return config;
    
}

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
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Share Feed URL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self shareFeedURL:feed indexPath:indexPath];
        
    }]];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Share Website URL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self shareWebsiteURL:feed indexPath:indexPath];
        
    }]];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    if (self.to_splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
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
    
    if (indexPath != nil && self.to_splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        
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
            
            if (self.to_splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
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
    
    UINavigationController *nav = [MoveFoldersVC instanceForFeed:feed delegate:self];
    
//    if (feed.folderID != nil) {
//        
//        for (Folder *folder in ArticlesManager.shared.folders) {
//            
//            if ([folder.folderID isEqualToNumber:feed.folderID] && folder.expanded == YES) {
//                folder.expanded = NO;
//                
//                [self setupData];
//                break;
//            }
//            
//        }
//        
//    }
    
    [self.to_splitViewController presentViewController:nav animated:YES completion:^{
        
        self->_presentingKnown = YES;
        
    }];
    
}

#pragma mark - <MoveFoldersDelegate>

- (void)feed:(Feed *)feed didMoveFromFolder:(Folder *)sourceFolder toFolder:(Folder *)destinationFolder {
    
    if (sourceFolder == nil && destinationFolder == nil) {
        // no change occurred.
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self->_presentingKnown = NO;
    });
 
#ifdef DEBUG
    NSLog(@"Feed %@ moved from %@ - %@", feed.displayTitle, sourceFolder ? sourceFolder.title : @"nil", destinationFolder ? destinationFolder.title : @"nil");
#endif
    
    NSDiffableDataSourceSnapshot *snapshot = self.DDS.snapshot;
    
    if (sourceFolder != nil && sourceFolder.isExpanded == YES) {
     
        if (destinationFolder != nil) {
            
            NSIndexPath *indexPathOfFolder = [self.DDS indexPathForItemIdentifier:destinationFolder];
            
            if (indexPathOfFolder == nil) {
                return;
            }
            
            if (destinationFolder.isExpanded == YES) {
                [snapshot moveItemWithIdentifier:feed afterItemWithIdentifier:destinationFolder];
            }
            else {
                [snapshot deleteItemsWithIdentifiers:@[feed]];
            }
            
        }
        else {
            [snapshot deleteItemsWithIdentifiers:@[feed]];
        }
        
    }
    else {
        [snapshot deleteItemsWithIdentifiers:@[feed]];
    }
    
    [self.DDS applySnapshot:snapshot animatingDifferences:YES];
    
}

@end
