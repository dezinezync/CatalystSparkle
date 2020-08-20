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
    
    if (item.read == read) {
        return;
    }
    
    [self articles:@[item] markAsRead:read];
    
}

- (void)articles:(NSArray<FeedItem *> *)items markAsRead:(BOOL)read {
    
    if (!self || !self.userID || [self.userID integerValue] == 0) {
        return;
    }
    
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
    
    NSDictionary *params = @{@"articles": articles ?: @[], @"userID": self.userID};
    
    weakify(self);
    
    [self.session POST:path parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);

        for (FeedItem *item in items) {
            
            item.read = read;
            
            // save it back to the DB so the read state is persisted.
            [MyDBManager addArticle:item];
            
        }
        
        if (read == YES) {
            self.totalUnread = self.totalUnread - items.count;
        }
        else {
            self.totalUnread = self.totalUnread + items.count;
        }
        
        // only post the notification if it's affecting a feed or folder
        // this avoids reducing or incrementing the count for unsubscribed feeds
        if (feeds.count > 0) {
            
            for (Feed *feed in feeds) {
                
                NSInteger current = [feed.unread integerValue];
                
                NSArray <FeedItem *> *articlesForFeed = [items rz_filter:^BOOL(FeedItem *objx, NSUInteger idxx, NSArray *array) {
                    return objx.feedID.integerValue == feed.feedID.integerValue;
                }];
                
                NSInteger affectedArticles = articlesForFeed.count;
                
                NSInteger updated = MAX(0, current + (read ? (-1 * affectedArticles) : affectedArticles));
                
                feed.unread = @(updated);
                
            }
        
        }

    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {

        // silently handle
        error = [self errorFromResponse:error.userInfo];

        NSLog(@"error marking %@ as read: %@", articles, error.localizedDescription);

    }];
}

- (void)article:(FeedItem *)item markAsBookmarked:(BOOL)bookmarked success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSString *path = formattedString(@"/article/%@/bookmark", item.identifier);
    
    [self.session POST:path parameters:@{@"bookmark": @(bookmarked), @"userID": self.userID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
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
            NSLog(@"error marking %@ as bookmarked: %@", item, error.localizedDescription);
        }
        
    }];
}

- (void)_removeAllLocalBookmarks {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *directory = [documentsDirectory stringByAppendingPathComponent:@"bookmarks"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       
        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *error = nil;
        if (![manager removeItemAtPath:directory error:&error]) {
            NSLog(@"Error deleting directory %@", directory);
        }
        
    });
    
}

#pragma mark -

//+ (void)load {
//    if([NSUbiquitousKeyValueStore defaultStore]) {  // is iCloud enabled
//        
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(updateFromiCloud:)
//                                                     name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
//                                                   object:nil];
//        
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                 selector:@selector(updateToiCloud:)
//                                                     name:NSUserDefaultsDidChangeNotification
//                                                   object:nil];
//    } else {
//        NSLog(@"iCloud not enabled");
//    }
//}
//
//+ (void) updateToiCloud:(NSNotification*) notificationObject {
//    
//    NSDictionary *dict = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
//    
//    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
//    
//    @try {
//        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) { @autoreleasepool {
//            [store setObject:obj forKey:key];
//        } }];
//    }
//    @catch (NSException *exc) {
//        NSLog(@"updateToiCloud: %@", exc);
//    }
//    
//    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
//}
//
//+ (void) updateFromiCloud:(NSNotification*) notificationObject {
//    
//    NSUbiquitousKeyValueStore *iCloudStore = [NSUbiquitousKeyValueStore defaultStore];
//    NSDictionary *dict = [iCloudStore dictionaryRepresentation];
//    
//    // prevent NSUserDefaultsDidChangeNotification from being posted while we update from iCloud
//    
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:NSUserDefaultsDidChangeNotification
//                                                  object:nil];
//    
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    
//    @try {
//        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) { @autoreleasepool {
//            [defaults setObject:obj forKey:key];
//        } }];
//    }
//    @catch (NSException *exc) {
//        NSLog(@"updateToiCloud: %@", exc);
//    }
//    
//    [[NSUserDefaults standardUserDefaults] synchronize];
//    
//    // enable NSUserDefaultsDidChangeNotification notifications again
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(updateToiCloud:)
//                                                 name:NSUserDefaultsDidChangeNotification
//                                               object:nil];
//    
////    [[NSNotificationCenter defaultCenter] postNotificationName:kMKiCloudSyncNotification object:nil];
//}
//
//+ (void) dealloc {
//    
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
//                                                  object:nil];
//    
//    [[NSNotificationCenter defaultCenter] removeObserver:self
//                                                    name:NSUserDefaultsDidChangeNotification
//                                                  object:nil];
//}

@end
