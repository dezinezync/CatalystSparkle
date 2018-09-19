//
//  FeedsManager+KVS.m
//  Yeti
//
//  Created by Nikhil Nigade on 05/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsManager+KVS.h"
#import <DZKit/NSString+Extras.h>
#import <DZKit/NSArray+RZArrayCandy.h>
#import <DZKit/AlertManager.h>
#import "YetiConstants.h"

#import <DZKit/DZUtilities.h>

@implementation FeedsManager (KVS)

- (void)article:(FeedItem *)item markAsRead:(BOOL)read
{
    if (!item)
        return;
    
    [self articles:@[item] markAsRead:read];
    
}

- (void)articles:(NSArray<FeedItem *> *)items markAsRead:(BOOL)read
{
    NSArray *articles = [items rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
        return obj.identifier;
    }];
    
    NSArray *feeds = [[items rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
        
        Feed *feed = [self feedForID:obj.feedID];
        
        if (feed) {
            return feed;
        }
        
        return [NSNull null];
        
    }] rz_filter:^BOOL(id obj, NSUInteger idx, NSArray *array) {
        return [obj isKindOfClass:Feed.class];
    }];

    NSString *path = formattedString(@"/article/%@", read ? @"true" : @"false");
    
    weakify(self);

    [self.backgroundSession POST:path parameters:@{@"articles": articles, @"userID": self.userID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {

        for (FeedItem *item in items) {
            item.read = read;
        }

        strongify(self);

        NSArray <FeedItem *> *unread = self.unread;

        if (!read) {
            unread = [unread arrayByAddingObjectsFromArray:items];
        }
        else {
            unread = [unread rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                return ![articles containsObject:obj.identifier];
            }];
        }

        @synchronized (self) {
            // new total unread
            NSInteger currentUnread = self.totalUnread;
            NSInteger newUnread = currentUnread;
            
            if (read) {
                newUnread -= items.count;
            }
            else {
                newUnread += items.count;
            }
            
            self.totalUnread = MAX(0, newUnread);
            self.unread = unread;
        }
        
        // only post the notification if it's affecting a feed or folder
        // this avoids reducing or incrementing the count for unsubscribed feeds
        if (feeds.count > 0) {
            for (Feed *feed in feeds) {
                NSInteger current = [feed.unread integerValue];
                NSInteger updated = current + (read ? -1 : 1);
                
                feed.unread = @(updated);
                
                if (feed.folderID != nil) {
                    Folder *folder = [self folderForID:feed.folderID];
                    if (folder != nil) {
                        [folder willChangeValueForKey:propSel(unreadCount)];
                        // simply tell the unreadCount property that it has been updated.
                        // KVO should handle the rest for us
                        [folder didChangeValueForKey:propSel(unreadCount)];
                    }
                }
            }
        }

    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {

        // silently handle
        error = [self errorFromResponse:error.userInfo];

        DDLogError(@"error marking %@ as read: %@", articles, error.localizedDescription);

    }];
}

- (void)article:(FeedItem *)item markAsBookmarked:(BOOL)bookmarked success:(successBlock)successCB error:(errorBlock)errorCB
{
    NSString *path = formattedString(@"/article/%@/bookmark", item.identifier);
    
    [self.backgroundSession POST:path parameters:@{@"bookmark": @(bookmarked), @"userID": self.userID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        item.bookmarked = bookmarked;
        
        if (successCB) {
            asyncMain(^{
                successCB(responseObject, response, task);
            });
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        // silently handle
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB) {
            errorCB(error, response, task);
        }
        else {
            DDLogError(@"error marking %@ as bookmarked: %@", item, error.localizedDescription);
        }
        
    }];
}

- (BOOL)addLocalBookmark:(FeedItem *)item
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *directory = [documentsDirectory stringByAppendingPathComponent:@"bookmarks"];
    
    NSString *path = [directory stringByAppendingPathComponent:formattedString(@"%@.dat", item.identifier)];
    
    BOOL errored = NO;
    
    if (![NSKeyedArchiver archiveRootObject:item toFile:path]) {
        errored = YES;
        
        [AlertManager showGenericAlertWithTitle:@"App Error" message:@"Bookmarking the article failed as Yeti was unable to write the data to your device's storage. Please try again."];
    }
    
    return errored;
}

- (BOOL)removeLocalBookmark:(FeedItem *)item
{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *directory = [documentsDirectory stringByAppendingPathComponent:@"bookmarks"];
    
    NSString *path = [directory stringByAppendingPathComponent:formattedString(@"%@.dat", item.identifier)];
    
    BOOL errored = NO;
    
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
        errored = YES;
        
        if (error.code == 4) {
            errored = NO;
        }
        else {
            [AlertManager showGenericAlertWithTitle:@"App Error" message:error.localizedDescription];
        }
    }
    
    return errored;
}

- (void)removeAllLocalBookmarks {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *directory = [documentsDirectory stringByAppendingPathComponent:@"bookmarks"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *error = nil;
        if (![manager removeItemAtPath:directory error:&error]) {
            DDLogError(@"Error deleting directory %@", directory);
        }
        
    });
    
}

#pragma mark -

+ (void)load
{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            if (store) {
                @synchronized (store) {
                    [[NSNotificationCenter defaultCenter] addObserver:MyFeedsManager selector: @selector (storeDidChange:) name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:store];
                }
                
                @synchronized (defaults) {
                    [NSNotificationCenter.defaultCenter addObserver:MyFeedsManager selector:@selector(defaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:defaults];
                }
            }
            
        });
        
    });
    
}

- (void)storeDidChange:(NSNotification *)note {
    
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    
    NSDictionary *userInfo = [store dictionaryRepresentation];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:NSUserDefaultsDidChangeNotification object:defaults];
    
//    DDLogDebug(@"NSUKV: %@", userInfo);
    
    [userInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        if (obj) {
            [defaults setValue:obj forKey:key];
        }
        else {
            [defaults removeObjectForKey:key];
        }
        
    }];
    
    [defaults synchronize];
    
    // become an observor again
    [[NSNotificationCenter defaultCenter] addObserver:self selector: @selector (defaultsDidChange:) name: NSUserDefaultsDidChangeNotification object:defaults];
}

- (void)defaultsDidChange:(NSNotification *)note {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *userInfo = [defaults dictionaryRepresentation];
    
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    
//    DDLogDebug(@"NSKV: %@", userInfo);
    
    [NSNotificationCenter.defaultCenter removeObserver:self name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:store];
    
    [userInfo enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [store setObject:obj forKey:key];
    }];
    
    [store synchronize];
    
    [NSNotificationCenter.defaultCenter addObserver:MyFeedsManager selector:@selector(storeDidChange:) name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:store];
    
}

@end
