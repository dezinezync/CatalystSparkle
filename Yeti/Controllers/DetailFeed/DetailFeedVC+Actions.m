//
//  DetailFeedVC+Actions.m
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DetailFeedVC+Actions.h"
#import "ArticleCellB.h"

#import "FeedsManager.h"
#import "ArticleVC.h"

#import "Keychain.h"

#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/AlertManager.h>
#import <UserNotifications/UserNotifications.h>

@implementation DetailFeedVC (Actions)

#pragma mark - Actions

- (void)updateSortingOptionTo:(YetiSortOption)option sender:(UIBarButtonItem *)sender {
    
    [self setSortingOption:option];
    
    UIColor *tintColor = nil;
    UIImage *image = [SortImageProvider imageForSortingOption:option tintColor:&tintColor];
    
    sender.image = image;
    sender.tintColor = tintColor;
    
}

- (void)didTapSortOptions:(UIBarButtonItem *)sender {
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Sorting Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *allDesc = [UIAlertAction actionWithTitle:@"All - Newest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self updateSortingOptionTo:YTSortAllDesc sender:sender];
        
    }];
    
    UIAlertAction *allAsc = [UIAlertAction actionWithTitle:@"All - Oldest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self updateSortingOptionTo:YTSortAllAsc sender:sender];

        
    }];
    
    UIAlertAction *unreadDesc = [UIAlertAction actionWithTitle:@"Unread - Newest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self updateSortingOptionTo:YTSortUnreadDesc sender:sender];
        
    }];
    
    UIAlertAction *unreadAsc = [UIAlertAction actionWithTitle:@"Unread - Oldest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self updateSortingOptionTo:YTSortUnreadAsc sender:sender];
        
    }];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    @try {
        
        UIImage * image = [SortImageProvider imageForSortingOption:YTSortAllDesc tintColor:nil];
        
        [allDesc setValue:image forKeyPath:@"image"];
        
        image = [SortImageProvider imageForSortingOption:YTSortAllAsc tintColor:nil];
        
        [allAsc setValue:image forKeyPath:@"image"];
        
        image = [SortImageProvider imageForSortingOption:YTSortUnreadDesc tintColor:nil];
        
        [unreadDesc setValue:image forKeyPath:@"image"];
        
        image = [SortImageProvider imageForSortingOption:YTSortUnreadAsc tintColor:nil];
        
        [unreadAsc setValue:image forKeyPath:@"image"];

    }
    @catch (NSException *exc) {
        
    }
    
    [avc addAction:allDesc];
    [avc addAction:allAsc];
    [avc addAction:unreadDesc];
    [avc addAction:unreadAsc];
    
    [self presentAllReadController:avc fromSender:sender];
    
}

- (void)loadArticle {
    
    if (self.loadOnReady == nil)
        return;
    
    if (self.DDS.snapshot.numberOfItems == 0) {
        return;
    }
    
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <FeedItem *> *)[[self.DDS snapshot] itemIdentifiers] enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
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
        
        [self showViewController:vc sender:self];
        
        return;
    }
    
    self.loadOnReady = nil;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        strongify(self);
        
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically];
        [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
        
    });
    
}

- (void)_markVisibleRowsRead {
    
//    if ([self.class isKindOfClass:NSClassFromString(@"CustomFeedVC")] == YES) {
//        return;
//    }
    
    NSArray <NSIndexPath *> *indices = [self.collectionView indexPathsForVisibleItems];
    
    for (NSIndexPath *indexPath in indices) { @autoreleasepool {
        
        ArticleCellB *cell = (ArticleCellB *)[self.collectionView cellForItemAtIndexPath:indexPath];
        
        FeedItem * item = [[self.DDS.snapshot itemIdentifiers] objectAtIndex:indexPath.item];
        
        if (cell.markerView.image != nil && (item != nil && item.isBookmarked == NO)) {
            cell.markerView.image = nil;
        }
        
    } }
    
}

- (void)didTapAllRead:(id)sender {
    
    BOOL showPrompt = SharedPrefs.showMarkReadPrompts;
    
    void(^markReadInline)(void) = ^(void) {
        
        NSArray <FeedItem *> * data = self.DDS.snapshot.itemIdentifiers;

        
        NSArray <FeedItem *> *unread = [data rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
            return !obj.isRead;
        }];
        
        [MyFeedsManager articles:unread markAsRead:YES];
        
        weakify(self);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            strongify(self);
            if (self && [self collectionView]) {
                [self _markVisibleRowsRead];
                [self _didFinishAllReadActionSuccessfully];
            }
            
            if ([self isKindOfClass:NSClassFromString(@"DetailCustomVC")]) {
                if (self.cantLoadNext == NO) {
                    
                    self.page = 0;
                    self.controllerState = StateLoading;
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self loadNextPage];
                    });
                }
            }
        });
    };
    
    if (showPrompt) {
        UIAlertController *avc = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        
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
                if (self != nil && [self collectionView] != nil) {
                    // if we're in the unread section
                    if ([self isKindOfClass:NSClassFromString(@"DetailCustomVC")] == YES) {
                        
                        self.controllerState = StateLoading;
                        
                        NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
                        [snapshot appendSectionsWithIdentifiers:@[@0]];
                        
                        [self.DDS applySnapshot:snapshot animatingDifferences:YES];
                        
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
        UIAlertController *avc = [UIAlertController alertControllerWithTitle:nil message:@"Mark all Articles as read including back-dated articles?" preferredStyle:UIAlertControllerStyleActionSheet];
        
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
    
}

- (void)didTapNotifications:(UIBarButtonItem *)sender {
    
    weakify(self);
    
    sender.enabled = NO;
    
    if (self.feed.isSubscribed) {
        // unsubsribe
        
        [MyFeedsManager unsubscribe:self.feed success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            self.feed.subscribed = NO;
            
            asyncMain(^{
                sender.enabled = YES;
                sender.image = [UIImage systemImageNamed:@"bell.slash"];
                sender.accessibilityValue = @"Subscribe to notifications";
            });
            
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
        
        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:UNAuthorizationOptionAlert|UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
            
            if (error) {
                DDLogError(@"Error authorizing for push notifications: %@",error);
                return;
            }
            
            if (granted) {
                strongify(self);
                
                [Keychain add:kIsSubscribingToPushNotifications boolean:YES];
                
                asyncMain(^{
                    [UIApplication.sharedApplication registerForRemoteNotifications];
                });
                
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
        
        asyncMain(^{
            sender.enabled = YES;
            sender.image = [UIImage systemImageNamed:@"bell.fill"];
            sender.accessibilityValue = @"Unsubscribe from notifications";
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
            
            self.navigationItem.rightBarButtonItem = nil;
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
    
    Feed *obj = note.object;
    
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
        
        UIBarButtonItem *sender = [self.navigationItem.rightBarButtonItems lastObject];
        
        sender.image = [UIImage systemImageNamed:@"bell.fill"];
        sender.accessibilityValue = @"Unsubscribe from notifications";
        
    });
}

- (void)didTapSidebarButton:(UIBarButtonItem *)sender {
    
    self.to_splitViewController.primaryColumnIsHidden = !self.to_splitViewController.primaryColumnIsHidden;
    
}

#pragma mark -

- (void)setSortingOption:(YetiSortOption)option {
    
    _sortingOption = option;
    
    self.pagingManager = nil;
    
    _canLoadNext = YES;
    
    [SharedPrefs setValue:option forKey:propSel(sortingOption)];
    
    NSDiffableDataSourceSnapshot *snapshot = [NSDiffableDataSourceSnapshot new];
    [self.DDS applySnapshot:snapshot animatingDifferences:YES];
    
    self.controllerState = StateLoaded;
    
    [self loadNextPage];
}

- (void)presentAllReadController:(UIAlertController *)avc fromSender:(id)sender {
    
    if (self.to_splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad || self.to_splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        
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
    
    [self presentViewController:avc animated:YES completion:nil];
    
}

@end
