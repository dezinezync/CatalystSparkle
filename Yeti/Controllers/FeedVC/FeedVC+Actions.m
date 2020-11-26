//
//  FeedVC+Actions.m
//  Yeti
//
//  Created by Nikhil Nigade on 13/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+Actions.h"
#import "ArticleVC.h"

#import <DZKit/AlertManager.h>
#import "Keychain.h"

#import "Coordinator.h"

#import <UserNotifications/UserNotifications.h>

@implementation FeedVC (Actions)

- (void)updateSortingOptionTo:(YetiSortOption)option sender:(UIBarButtonItem *)sender {
    
    self.sortingOption = option;
    
    if (sender != nil && [sender isKindOfClass:UIBarButtonItem.class]) {
        
        UIImage *image = [self.mainCoordinator imageForSortingOption:option];
        
        sender.image = image;
        
    }
    
}

- (void)loadArticle {
    
    if (self.loadOnReady == nil)
        return;
    
    if (self.DS.snapshot.numberOfItems == 0) {
        return;
    }
    
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <FeedItem *> *)[[self.DS snapshot] itemIdentifiers] enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.identifier isEqualToNumber:self.loadOnReady]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index == NSNotFound) {
        FeedItem *item = [FeedItem new];
        item.identifier = self.loadOnReady;
        item.feedID = self.feed.feedID;
        
        ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];
        vc.providerDelegate = (id<ArticleProvider>)self;
        
        [self _showArticleVC:vc];
        
        return;
    }
    
    self.loadOnReady = nil;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        strongify(self);
        
        [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        
        [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
        
    });
    
}

- (void)_markVisibleRowsRead {
    
//    if ([self.class isKindOfClass:NSClassFromString(@"CustomFeedVC")] == YES) {
//        return;
//    }
    
    NSArray <NSIndexPath *> *indices = [self.tableView indexPathsForVisibleRows];
    
    for (NSIndexPath *indexPath in indices) { @autoreleasepool {
        
        ArticleCell *cell = (ArticleCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        
        cell.article.read = YES;
        
        [cell updateMarkerView];
        
    } }
    
}

- (void)didTapAllRead:(id)sender {
    
    BOOL showPrompt = SharedPrefs.showMarkReadPrompts;
    
    void(^markReadInline)(void) = ^(void) {
        
        NSArray <FeedItem *> * data = self.DS.snapshot.itemIdentifiers;

        NSArray <FeedItem *> *unread = [data rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
            return !obj.isRead;
        }];
        
        [MyFeedsManager articles:unread markAsRead:YES];
        
        weakify(self);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            strongify(self);
            
            if (self && [self tableView]) {
                [self _markVisibleRowsRead];
            }
            
        });
        
    };
    
    if (showPrompt) {
        
        UIAlertController *avc = [UIAlertController alertControllerWithTitle:nil message:@"Mark currently loaded articles as read?" preferredStyle:UIAlertControllerStyleAlert];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Mark all Read" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            markReadInline();
            
        }]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentAllReadController:avc fromSender:sender];
        
    }
    else {
        
        [self.feedbackGenerator selectionChanged];
        [self.feedbackGenerator prepare];
        
        markReadInline();
        
    }
    
}

- (void)didLongPressOnAllRead:(id)sender {
    
//    if (sender && [sender isKindOfClass:UILongPressGestureRecognizer.class]
//        && [(UILongPressGestureRecognizer *)sender state] != UIGestureRecognizerStateBegan) {
//        return;
//    }
    
    BOOL showPrompt = SharedPrefs.showMarkReadPrompts;
    
    void(^markReadInline)(void) = ^(void) {
        [MyFeedsManager markFeedRead:self.feed success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self != nil && [self tableView] != nil) {
                    // if we're in the unread section
                    if (self.type == FeedVCTypeUnread || self.sortingOption == YTSortUnreadAsc || self.sortingOption == YTSortUnreadDesc) {
                        
                        self.controllerState = StateLoading;
                        
                        NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
                        [snapshot appendSectionsWithIdentifiers:@[@0]];
                        
                        [self.DS applySnapshot:snapshot animatingDifferences:YES];
                        
                        self.controllerState = StateLoaded;
                        
                    }
                    else {
                        [self _markVisibleRowsRead];
                        [self _didFinishAllReadActionSuccessfully];
                    }
                }
            });
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            [AlertManager showGenericAlertWithTitle:@"Error Marking all Read" message:error.localizedDescription];
            
        }];
    };
    
    if (showPrompt) {
        UIAlertController *avc = [UIAlertController alertControllerWithTitle:nil message:@"Mark all Articles as read including back-dated articles?" preferredStyle:UIAlertControllerStyleAlert];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Mark all Read" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            markReadInline();
            
        }]];
        
        [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        
        [self presentAllReadController:avc fromSender:sender];
    }
    else {
        [self.feedbackGenerator selectionChanged];
        [self.feedbackGenerator prepare];
        
        markReadInline();
    }
}

- (void)_didFinishAllReadActionSuccessfully {
    
    if (self.feed != nil && self.feed.unread.unsignedIntegerValue > 0) {
        MyFeedsManager.totalUnread -= self.feed.unread.unsignedIntegerValue;
        self.feed.unread = @(0);
    }
    
}

- (void)didTapNotifications:(UIBarButtonItem *)sender {
    
    weakify(self);
    
    sender.enabled = NO;
    
    if (self.feed.isSubscribed) {
        // unsubsribe
        
        [MyFeedsManager unsubscribe:self.feed success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            self.feed.subscribed = NO;
            
            if ([sender isKindOfClass:UIBarButtonItem.class]) {
                
                sender.enabled = YES;
                sender.image = [UIImage systemImageNamed:@"bell.slash"];
                sender.accessibilityValue = @"Subscribe to notifications";
                
            }
            else if ([sender isKindOfClass:UIButton.class]) {
                
                sender.enabled = YES;
                [(UIButton *)sender setImage:[UIImage systemImageNamed:@"bell.slash"] forState:UIControlStateNormal];
                sender.accessibilityValue = @"Subscribe to notifications";
                
            }
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            asyncMain(^{
                sender.enabled = YES;
            });
            
            [AlertManager showGenericAlertWithTitle:@"Unsubscribe Failed" message:error.localizedDescription];
            
        }];
        
        return;
    }
    
    if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] == NO) {
        
        MyFeedsManager.subsribeAfterPushEnabled = self.feed;
        
        weakify(self);
        
        asyncMain(^{
            sender.enabled = YES;
        });
        
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:UNAuthorizationOptionBadge|UNAuthorizationOptionAlert|UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
            
            if (error) {
                NSLog(@"Error authorizing for push notifications: %@",error);
                return;
            }
            
            if (granted) {
                strongify(self);
                
                [Keychain add:kIsSubscribingToPushNotifications boolean:YES];
                
                asyncMain(^{
                    [UIApplication.sharedApplication registerForRemoteNotifications];
                });
                
#if TARGET_OS_SIMULATOR
                [self subscribedToFeed:self.feed];
#endif
                [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(subscribedToFeed:) name:SubscribedToFeed object:nil];
            }
            
        }];
        
        return;
    }
    else {
        
        if ([Keychain boolFor:kIsSubscribingToPushNotifications error:nil] == NO) {
            [Keychain add:kIsSubscribingToPushNotifications boolean:YES];
        }
        
        asyncMain(^{
            [UIApplication.sharedApplication registerForRemoteNotifications];
        });
    }
    
    // add subscription
    [MyFeedsManager subsribe:self.feed success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        self.feed.subscribed = YES;
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            if ([sender isKindOfClass:UIBarButtonItem.class]) {
                
                sender.enabled = YES;
                sender.image = [UIImage systemImageNamed:@"bell.fill"];
                sender.accessibilityValue = @"Unsubscribe from notifications";
                
            }
            else if ([sender isKindOfClass:UIButton.class]) {
                
                sender.enabled = YES;
                [(UIButton *)sender setImage:[UIImage systemImageNamed:@"bell.fill"] forState:UIControlStateNormal];
                sender.accessibilityValue = @"Unsubscribe from notifications";
                
            }
            
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        asyncMain(^{
            sender.enabled = YES;
        });
        
        [AlertManager showGenericAlertWithTitle:@"Subscribe Failed" message:error.localizedDescription];
    }];
    
}

- (void)subscribeToFeed:(UIBarButtonItem *)sender {
    
    sender.enabled = NO;
    
    weakify(self);
    
    [MyFeedsManager addFeedByID:self.feed.feedID success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSArray <Feed *> *feeds = ArticlesManager.shared.feeds;
        feeds = [feeds arrayByAddingObject:responseObject];
        
        ArticlesManager.shared.feeds = feeds;
        
        MyFeedsManager.totalUnread = MyFeedsManager.totalUnread + [[(Feed *)responseObject unread] integerValue];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            strongify(self);
            
#if TARGET_OS_MACCATALYST
            FeedHeaderView *header = (id)[self.tableView tableHeaderView];
            header.subscribeButton.hidden = YES;
#else
            self.navigationItem.rightBarButtonItem = nil;
#endif
            
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            sender.enabled = YES;
        });
        
        [AlertManager showGenericAlertWithTitle:@"Error Subscribing" message:error.localizedDescription];
        
    }];
    
}

// this is push notifications
- (void)subscribedToFeed:(NSNotification *)note {
    
#if TARGET_OS_SIMULATOR
    Feed *obj = (id)note;
#else
    Feed *obj = note.object;
#endif
    if (!obj)
        return;
    
    if (![obj.feedID isEqualToNumber:self.feed.feedID]) {
        return;
    }
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:SubscribedToFeed object:nil];
    
    weakify(self);
    
    asyncMain(^{
        
        strongify(self);
        
        self.feed.subscribed = YES;
        
        UIBarButtonItem *sender = [self.navigationItem.rightBarButtonItems objectAtIndex:(self.navigationItem.rightBarButtonItems.count - 2)];
        
        sender.image = [UIImage systemImageNamed:@"bell.fill"];
        sender.accessibilityValue = @"Unsubscribe from notifications";
        
    });
}

//- (void)didTapSidebarButton:(UIBarButtonItem *)sender {
//
//    self.to_splitViewController.primaryColumnIsHidden = !self.to_splitViewController.primaryColumnIsHidden;
//
//}

- (void)presentAllReadController:(UIAlertController *)avc fromSender:(id)sender {
#if !TARGET_OS_MACCATALYST
    if (self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad || self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        
        UIPopoverPresentationController *pvc = avc.popoverPresentationController;
        
        if ([sender isKindOfClass:UIGestureRecognizer.class]) {
            UIView *view = [(UITapGestureRecognizer *)sender view];
            pvc.sourceView = self.view;
            CGRect frame = [view convertRect:view.frame toView:self.view];
            
            frame.origin.x -= [avc preferredContentSize].width;
            pvc.sourceRect = frame;
        }
        else {
            pvc.barButtonItem = sender;
        }
        
    }
#endif
    [self presentViewController:avc animated:YES completion:nil];
    
}

- (void)markAllNewerRead:(NSIndexPath *)indexPath {
    
    [self markAllDirectional:1 indexPath:indexPath];
    
}

- (void)markAllOlderRead:(NSIndexPath *)indexPath {
    
    [self markAllDirectional:2 indexPath:indexPath];
    
}

- (void)markAllDirectional:(NSInteger)direction indexPath:(NSIndexPath *)indexPath {
    
    YetiSortOption sorting = self.sortingOption ?: SharedPrefs.sortingOption;
    
    NSString *feed = nil;
    
    if (self.type == FeedVCTypeUnread) {
        feed = @"unread";
    }
    else if (self.type == FeedVCTypeToday) {
        feed = @"today";
    }
    else if (self.type == FeedVCTypeNatural) {
        feed = self.feed.feedID.stringValue;
    }
    
    if (feed == nil) {
        return;
    }
    
    FeedItem *item = [self.DS itemIdentifierForIndexPath:indexPath];
    
    if (item == nil) {
        return;
    }
    
    /*
    [MyFeedsManager markRead:feed articleID:item.identifier direction:direction sortType:sorting success:^(NSNumber * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (responseObject.integerValue == 0) {
            return;
        }
        
        NSMutableArray <FeedItem *> *affectedIndices = @[].mutableCopy;
        
        if (item.isRead == NO) {
            
            item.read = YES;
            
            [affectedIndices addObject:item];
            
        }
        
        BOOL isDescending = [sorting isEqualToString:YTSortAllDesc] || [sorting isEqualToString:YTSortUnreadDesc];
        
        if ((direction == 1 && isDescending) || (direction == 2 && isDescending == NO)) {
            
            // mark all items above this item
            for (NSInteger idx = indexPath.row; idx > 0; idx--) {
                
                NSInteger row = indexPath.row - idx;
                
                if (row < 0) {
                    continue;
                }
                
                NSIndexPath *indexPathNew = [NSIndexPath indexPathForRow:row inSection:indexPath.section];
                
                FeedItem *newItem = [self.DS itemIdentifierForIndexPath:indexPathNew];
                
                if (newItem && newItem.isRead == NO) {
                    
                    newItem.read = YES;
                    
                    [affectedIndices addObject:newItem];
                    
                }
                
            }
            
        }
        else {
            
            // mark all items below this item
            id lastItem = [[[self.DS snapshot] itemIdentifiers] lastObject];
            NSIndexPath *lastItemIndexPath = [self.DS indexPathForItemIdentifier:lastItem];
            
            for (NSInteger idx = 1; idx <= lastItemIndexPath.row; idx++) {
                
                NSInteger row = indexPath.row + idx;
                
                if (row > lastItemIndexPath.row) {
                    continue;
                }
                
                NSIndexPath *indexPathNew = [NSIndexPath indexPathForRow:row inSection:indexPath.section];
                
                FeedItem *newItem = [self.DS itemIdentifierForIndexPath:indexPathNew];
                
                if (newItem && newItem.isRead == NO) {
                    
                    newItem.read = YES;
                    
                    [affectedIndices addObject:newItem];
                    
                }
                
            }
            
        }
        
        NSLogDebug(@"Affected indices: %@", affectedIndices);
        
        if (affectedIndices.count == 0) {
            return;
        }
        
        NSDiffableDataSourceSnapshot *snapshot = [self.DS snapshot];
        
        [snapshot reloadItemsWithIdentifiers:affectedIndices];
        
        [self.DS applySnapshot:snapshot animatingDifferences:YES];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        [AlertManager showGenericAlertWithTitle:@"Error Marking Read" message:error.localizedDescription fromVC:self];
        
    }];
     */
    
}

- (void)didTapBack {
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}

#if TARGET_OS_MACCATALYST

#endif

@end
