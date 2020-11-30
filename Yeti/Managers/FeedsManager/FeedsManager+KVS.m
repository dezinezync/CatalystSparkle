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
    
    NSArray <NSNumber *> *articles = [items rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
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
    
    KVSItem *instance = [KVSItem new];
    instance.changeType = read ? KVSChangeTypeRead : KVSChangeTypeUnread;
    instance.identifiers = articles;
    
    if (self.KVSItems == nil) {
        self.KVSItems = [NSMutableOrderedSet new];
        [self.KVSItems addObject:instance];
    }
    else {
        
        // find an item with the same changeType
        KVSItem *existing = [self.KVSItems.objectEnumerator.allObjects rz_find:^BOOL(KVSItem *obj, NSUInteger idx, NSArray *array) {
           
            return obj.changeType == instance.changeType && obj.identifiers.count <= 100;
            
        }];
        
        if (existing) {
            // add it to the same
            existing.identifiers = [existing.identifiers arrayByAddingObjectsFromArray:instance.identifiers];
        }
        else {
            [self.KVSItems addObject:instance];
        }
        
    }
    
    [self trackChanges];
    
    for (FeedItem *item in items) {
        
        item.read = read;
        
        if (feeds.count > 0 && [NSCalendar.currentCalendar isDateInToday:item.timestamp]) {
            
            // adjust value for Today as well
            if (read == YES) {
                self.totalToday = self.totalToday - items.count;
            }
            else {
                self.totalToday = self.totalToday + items.count;
            }
            
        }
        
        // save it back to the DB so the read state is persisted.
        [MyDBManager addArticle:item strip:NO];
        
    }
    
    // only post the notification if it's affecting a feed or folder
    // this avoids reducing or incrementing the count for unsubscribed feeds
    if (feeds.count > 0) {
        
        if (read == YES) {
            self.totalUnread = self.totalUnread - items.count;
        }
        else {
            self.totalUnread = self.totalUnread + items.count;
        }
        
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

}

- (void)article:(FeedItem *)item markAsBookmarked:(BOOL)bookmarked success:(successBlock)successCB error:(errorBlock)errorCB {
    
    item.bookmarked = bookmarked;
    
    [MyDBManager addArticle:item strip:NO];
    
    KVSItem *instance = [KVSItem new];
    instance.changeType = bookmarked ? KVSChangeTypeBookmark : KVSChangeTypeUnbookmark;
    instance.identifiers = @[item.identifier];
    
    if (self.KVSItems == nil) {
        self.KVSItems = [NSMutableOrderedSet new];
    }
    
    [self.KVSItems addObject:instance];
    
    [self trackChanges];
    
    if (bookmarked) {
        self.totalBookmarks++;
    }
    else {
        self.totalBookmarks--;
    }
    
    if (successCB) {
        asyncMain(^{
            successCB(@(YES), nil, nil);
        });
    }
    
}

#pragma mark -

- (void)trackChanges {
    
    if (self.KVSItems == nil) {
        return;
    }
    
    if (self.batchKVSTimer != nil) {
        
        // invalidate the existing timer.
        
        if ([self.batchKVSTimer isValid]) {
            [self.batchKVSTimer invalidate];
        }
        
        self.batchKVSTimer = nil;
        
    }
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        strongify(self);
        
        weakify(self);
       
        self.batchKVSTimer = [NSTimer scheduledTimerWithTimeInterval:10 repeats:NO block:^(NSTimer * _Nonnull timer) {
            
            strongify(self);
            
            [self flushChanges];
            
        }];
        
    });
    
}

- (void)flushChanges {
    
    if (self.KVSItems == nil) {
        return;
    }
    
    if (self.KVSItems.count == 0) {
        // no changes to flush.
        return;
    }
    
    // make a copy
    NSMutableOrderedSet *set = [self.KVSItems mutableCopy];
    
    // setup a new instance immediately
    // so all future calls are scheduled
    // on a separate instance and doesn't
    // get lost in this call.
    self.KVSItems = [NSMutableOrderedSet new];
    
    for (KVSItem *instance in set) {
        
        if (instance.changeType == KVSChangeTypeUnread || instance.changeType == KVSChangeTypeRead) {
            
            if (instance.identifiers.count) {
                
                [self markRead:instance.changeType == KVSChangeTypeRead identifiers:instance.identifiers];
                
            }
            
        }
        else {
            
            if (instance.identifiers.count) {
                [self markBookmark:instance.changeType == KVSChangeTypeBookmark identifier:instance.identifiers.firstObject];
            }
            
        }
        
    }
    
}

- (void)markRead:(BOOL)read identifiers:(NSArray <NSNumber *> *)identifiers {
    
    if (identifiers == nil || (identifiers != nil && identifiers.count == 0)) {
        return;
    }
    
    NSString *path = formattedString(@"/article/%@", read ? @"true" : @"false");
    
    NSDictionary *params = @{@"articles": identifiers ?: @[], @"userID": self.userID};
    
    [self.session POST:path parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSLog(@"Marked %@ for %@", read ? @"read" : @"unread", identifiers);

    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {

        // silently handle
        error = [self errorFromResponse:error.userInfo];

        NSLog(@"error marking %@ as read: %@", identifiers, error);

    }];
    
}
    
- (void)markBookmark:(BOOL)bookmarked identifier:(NSNumber *)identifier {
    
    NSString *path = formattedString(@"/article/%@/bookmark", identifier);
    
    [self.session POST:path parameters:@{@"bookmark": @(bookmarked), @"userID": self.userID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSLog(@"Marked %@ for %@", bookmarked ? @"bookmark" : @"unboomark", identifier);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        // silently handle
        error = [self errorFromResponse:error.userInfo];
        
        NSLog(@"error marking %@ as bookmarked: %@", identifier, error);
        
    }];
        
    }

@end
