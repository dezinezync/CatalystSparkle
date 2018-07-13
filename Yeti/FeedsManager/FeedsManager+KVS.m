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

@implementation FeedsManager (KVS)

- (void)article:(FeedItem *)item markAsRead:(BOOL)read
{
    if (!item)
        return;
    
    [self articles:@[item] markAsRead:read];
    
}

- (void)articles:(NSArray<FeedItem *> *)items markAsRead:(BOOL)read
{
    NSMutableDictionary *folders = @{}.mutableCopy;
    NSMutableDictionary *feeds = @{}.mutableCopy;
    
    NSMutableArray *articles = [NSMutableArray arrayWithCapacity:items.count];

    for (FeedItem *item in items) {
        [articles addObject:item.identifier];
        
        Feed *feed = [self feedForID:item.feedID];
        if (feed != nil) {
            if (feed.folderID != nil) {
                // get the existing count, if one is available.
                NSString *key = feed.folderID.stringValue;
                NSNumber *count = folders[key];
                
                if (!count) {
                    count = @1;
                }
                else {
                    count = @(count.integerValue + 1);
                }
                
                // update the count against the folder ID
                folders[key] = count;
            }
            
            // get the existing count, if one is available.
            NSString *key = feed.feedID.stringValue;
            NSNumber *count = feeds[key];
            
            if (!count) {
                count = @1;
            }
            else {
                count = @(count.integerValue + 1);
            }
            
            // update the count against the feed ID
            feeds[key] = count;
            
        }
    }

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
            
            self.totalUnread = newUnread;
            self.unread = unread;
        }
        
        [NSNotificationCenter.defaultCenter postNotificationName:FeedDidUpReadCount object:self userInfo:@{@"folders": folders, @"feeds": feeds, @"read": @(read)}];

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
