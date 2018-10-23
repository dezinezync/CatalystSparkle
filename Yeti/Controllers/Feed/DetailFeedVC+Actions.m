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

#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/AlertManager.h>
#import <UserNotifications/UserNotifications.h>

@implementation DetailFeedVC (Actions)

#pragma mark - Actions

- (void)didTapSortOptions:(UIBarButtonItem *)sender {
    
    UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Sorting Options" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *allDesc = [UIAlertAction actionWithTitle:@"All - Newest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortAllDesc];
        
        [self setSortingOption:YTSortAllDesc];
        
    }];
    
    UIAlertAction *allAsc = [UIAlertAction actionWithTitle:@"All - Oldest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortAllAsc];
        
        [self setSortingOption:YTSortAllAsc];
        
    }];
    
    UIAlertAction *unreadDesc = [UIAlertAction actionWithTitle:@"Unread - Newest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortUnreadDesc];
        
        [self setSortingOption:YTSortUnreadDesc];
        
    }];
    
    UIAlertAction *unreadAsc = [UIAlertAction actionWithTitle:@"Unread - Oldest First" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        sender.image = [SortImageProvider imageForSortingOption:YTSortUnreadAsc];
        
        [self setSortingOption:YTSortUnreadAsc];
        
    }];
    
    [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    @try {
        [allDesc setValue:[SortImageProvider imageForSortingOption:YTSortAllDesc] forKeyPath:@"image"];
        [allAsc setValue:[SortImageProvider imageForSortingOption:YTSortAllAsc] forKeyPath:@"image"];
        [unreadDesc setValue:[SortImageProvider imageForSortingOption:YTSortUnreadDesc] forKeyPath:@"image"];
        [unreadAsc setValue:[SortImageProvider imageForSortingOption:YTSortUnreadAsc] forKeyPath:@"image"];
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
    
    if (!self.DS.data.count)
        return;
    
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <FeedItem *> *)[self.DS data] enumerateObjectsUsingBlock:^(FeedItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj.identifier isEqualToNumber:self.loadOnReady]) {
            index = idx;
            *stop = YES;
        }
        
    }];
    
    if (index == NSNotFound)
        return;
    
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
    
    if ([self.class isKindOfClass:NSClassFromString(@"CustomFeedVC")] == YES) {
        return;
    }
    
    NSArray <NSIndexPath *> *indices = [self.collectionView indexPathsForVisibleItems];
    
    for (NSIndexPath *indexPath in indices) { @autoreleasepool {
        
        ArticleCellB *cell = (ArticleCellB *)[self.collectionView cellForItemAtIndexPath:indexPath];
        
        FeedItem *item = [self.DS objectAtIndexPath:indexPath];
        
        if (cell.markerView.image != nil && (item != nil && item.isBookmarked == NO)) {
            cell.markerView.image = nil;
        }
        
    } }
    
}

- (void)didTapAllRead:(id)sender {
    
    BOOL showPrompt = [NSUserDefaults.standardUserDefaults boolForKey:kShowMarkReadPrompt];
    
    void(^markReadInline)(void) = ^(void) {
        NSArray <FeedItem *> *unread = [(NSArray <FeedItem *> *)self.DS.data rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
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
    
    if (sender && [sender isKindOfClass:UILongPressGestureRecognizer.class]
        && [(UILongPressGestureRecognizer *)sender state] != UIGestureRecognizerStateBegan) {
        return;
    }
    
    BOOL showPrompt = [NSUserDefaults.standardUserDefaults boolForKey:kShowMarkReadPrompt];
    
    void(^markReadInline)(void) = ^(void) {
        [MyFeedsManager markFeedRead:self.feed success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self && [self collectionView]) {
                    if ([self isKindOfClass:NSClassFromString(@"CustomFeedVC")]) {
                        self.DS.data = @[];
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
        UIAlertController *avc = [UIAlertController alertControllerWithTitle:nil message:@"Mark all articles as read including back-dated articles?" preferredStyle:UIAlertControllerStyleActionSheet];
        
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
                sender.image = [UIImage imageNamed:@"notifications_off"];
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
    
    if (!MyFeedsManager.pushToken) {
        // register for push notifications first.
        
        if (![[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) {
            
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
                    
                    MyFeedsManager.keychain[kIsSubscribingToPushNotifications] = [@YES stringValue];
                    
                    asyncMain(^{
                        [UIApplication.sharedApplication registerForRemoteNotifications];
                    });
                    
                    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(subscribedToFeed:) name:SubscribedToFeed object:nil];
                }
                
            }];
            
            return;
        }
        else {
            
            if (MyFeedsManager.keychain[kIsSubscribingToPushNotifications] == nil) {
                MyFeedsManager.keychain[kIsSubscribingToPushNotifications] = [@YES stringValue];
            }
            
            asyncMain(^{
                [UIApplication.sharedApplication registerForRemoteNotifications];
            });
        }
    }
    
    // add subscription
    [MyFeedsManager subsribe:self.feed success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        self.feed.subscribed = YES;
        
        asyncMain(^{
            sender.enabled = YES;
            sender.image = [UIImage imageNamed:@"notifications_on"];
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
        
        NSArray <Feed *> *feeds = MyFeedsManager.feeds;
        feeds = [feeds arrayByAddingObject:responseObject];
        
        MyFeedsManager.feeds = feeds;
        
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
        
        sender.image = [UIImage imageNamed:@"notifications_on"];
        sender.accessibilityValue = @"Unsubscribe from notifications";
        
    });
}

#pragma mark -

- (void)setSortingOption:(YetiSortOption)option {
    
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setValue:option forKey:kDetailFeedSorting];
    [defaults synchronize];
    
    self->_canLoadNext = YES;
    self.loadingNext = NO;
    
    self->_page = 0;
    [self.DS resetData];
    
    [self loadNextPage];
}

- (void)presentAllReadController:(UIAlertController *)avc fromSender:(id)sender {
    
    if (self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular){
        
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
