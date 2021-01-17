//
//  SidebarVC+Actions.m
//  Elytra
//
//  Created by Nikhil Nigade on 27/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SidebarVC+SearchResults.h"
#import "AddFeedVC.h"
#import "NewFolderVC.h"
#import "SettingsVC.h"

#import "Coordinator.h"
#import "ArticlesManager.h"

#import <DZKit/AlertManager.h>

@implementation SidebarVC (Actions)

- (void)didTapAdd:(UIBarButtonItem *)add {
    
    [self.mainCoordinator showNewFeedVC];
    
}

- (void)didTapAddFolder:(UIBarButtonItem *)add {
    
    [self.mainCoordinator showNewFolderVC];
    
}

- (void)didTapSettings {
    [self.mainCoordinator showSettingsVC];
}

- (void)didTapRecommendations:(UIBarButtonItem *)sender {
    
    NSArray <NSIndexPath *> *selectedIndexPaths = self.collectionView.indexPathsForSelectedItems;
    
    if (selectedIndexPaths.count > 0) {
        
        for (NSIndexPath *indexPath in selectedIndexPaths) {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
        
    }
    
    [self.mainCoordinator showRecommendations];
    
}

#pragma mark - <UICollectionViewDelegate>

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
    
    if (indexPath.section == 0) {
        return nil;
    }
    
    id obj = [self.DS itemIdentifierForIndexPath:indexPath];
    
    if (obj == nil) {
        return nil;
    }
    
    UIContextMenuConfiguration *config = nil;
    
    if ([obj isKindOfClass:Folder.class]) {
        
        Folder *folder = (Folder *)obj;
        
        config = [UIContextMenuConfiguration configurationWithIdentifier:formattedString(@"folder-%@", folder.folderID) previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            
            UIAction * feed = [UIAction actionWithTitle:@"Folder Feed" image:[UIImage systemImageNamed:@"list.bullet.below.rectangle"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
               
                [self.mainCoordinator showFolderFeed:folder];
                
            }];
            
            UIAction * rename = [UIAction actionWithTitle:@"Rename" image:[UIImage systemImageNamed:@"pencil"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                [self.mainCoordinator showRenameFolderVC:folder];
                
            }];
            
            UIAction * delete = [UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                [self confirmFolderDelete:folder completionHandler:nil];
                
            }];
            
            delete.attributes = UIMenuElementAttributesDestructive;
            
            NSArray <UIAction *> *actions = @[feed, rename, delete];
            
            UIMenu *menu = [UIMenu menuWithTitle:@"Feed Menu" children:actions];
            
            return menu;
            
        }];
    }
    else {
        Feed *feed = (Feed *)obj;
        
        config = [UIContextMenuConfiguration configurationWithIdentifier:formattedString(@"feed-%@", feed.feedID) previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            
            UIMenuElement * share = nil;
            
            if ([feed canShowExtraShareLevel] == YES) {
                
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
            
            UIAction *feedInfo = [UIAction actionWithTitle:@"Feed Info" image:[UIImage systemImageNamed:@"info.circle.fill"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
               
                [self.mainCoordinator showFeedInfo:feed from:self];
                
            }];
            
            delete.attributes = UIMenuElementAttributesDestructive;
            
            NSArray <UIAction *> *actions = @[(UIAction *)share, rename, feedInfo, move, delete];
            
            UIMenu *menu = [UIMenu menuWithTitle:@"Feed Menu" children:actions];
            
            return menu;
            
        }];
    }
    
    return config;
    
}

#pragma mark - Helpers

- (void)showShareOptionsVC:(Feed *)feed indexPath:(NSIndexPath *)indexPath {
    
    if (feed.canShowExtraShareLevel == NO) {
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
    
    [self showActivityController:(id)avc indexPath:indexPath];
    
}

- (void)confirmFeedDelete:(Feed *)feed completionHandler:(void(^)(BOOL actionPerformed))completionHandler {
 
    weakify(self);
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Delete Feed?" message:@"Are you sure you want to delete this feed?" preferredStyle:UIAlertControllerStyleAlert];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
        void(^removeFeedFromDS)(Feed * __feed) = ^(Feed * __feed) {
            
            if (__feed.folderID != nil && __feed.folderID.integerValue) {
                // remove it from the folder struct
                [ArticlesManager.shared.folders enumerateObjectsUsingBlock:^(Folder * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    if ([obj.folderID isEqualToNumber:__feed.folderID]) {
                        
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
                return obj.feedID.integerValue != __feed.feedID.integerValue;
            }];
            
            [ArticlesManager.shared willBeginUpdatingStore];
            
            ArticlesManager.shared.feeds = feeds;
            
            [ArticlesManager.shared didFinishUpdatingStore:NO];
            
            MyFeedsManager.totalUnread = MyFeedsManager.totalUnread - feed.unread.integerValue;
            
            NSDiffableDataSourceSnapshot *snapshot = self.DS.snapshot;
            [snapshot deleteItemsWithIdentifiers:@[__feed]];
            
            if (completionHandler) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    completionHandler(YES);
                     
                });
                
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.DS applySnapshot:snapshot animatingDifferences:YES];
            });
            
        };
        
        [MyFeedsManager removeFeed:feed.feedID success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            removeFeedFromDS(feed);
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            if (response.statusCode == 304) {
                removeFeedFromDS(feed);
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
        pvc.sourceView = self.collectionView;
        UICollectionViewLayoutAttributes *attrs = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
        
        pvc.sourceRect = attrs.frame;
        
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
        
        [self showActivityController:activityVC indexPath:indexPath];
    }
    
}

- (void)feed_didTapMove:(Feed *)feed indexPath:(NSIndexPath *)indexPath {
    
    UINavigationController *nav = [MoveFoldersVC instanceForFeed:feed delegate:self];
    
    [self.splitViewController presentViewController:nav animated:YES completion:^{
        
//        self->_presentingKnown = YES;
        
    }];
    
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
                UICollectionViewListCell *cell = (UICollectionViewListCell *)[self.collectionView cellForItemAtIndexPath:self.alertIndexPath];
                
                if (cell) {
                    
                    UIListContentConfiguration *config = (id)[cell contentConfiguration];
                    config.text = name;
                    
                    cell.contentConfiguration = config;
                    
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

#pragma mark - <MoveFoldersDelegate>

- (void)feed:(Feed *)feed didMoveFromFolder:(Folder *)sourceFolder toFolder:(Folder *)destinationFolder {
    
    if (sourceFolder == nil && destinationFolder == nil) {
        // no change occurred.
        return;
    }
    
    [self setupData];
    
}

@end
