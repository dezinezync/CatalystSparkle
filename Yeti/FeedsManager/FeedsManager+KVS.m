//
//  FeedsManager+KVS.m
//  Yeti
//
//  Created by Nikhil Nigade on 05/12/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsManager+KVS.h"
#import <DZKit/NSString+Extras.h>

@implementation FeedsManager (KVS)

- (void)article:(FeedItem *)item markAsRead:(BOOL)read
{
    NSString *key = item.guid.length > 32 ? item.guid.md5 : item.guid;
    
    item.read = YES;
    
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setBool:read forKey:key];
    [defaults synchronize];
    
    NSUbiquitousKeyValueStore *NSUKV = NSUbiquitousKeyValueStore.defaultStore;
    [NSUKV setBool:read forKey:key];
    [NSUKV synchronize];
    
    [NSNotificationCenter.defaultCenter postNotificationName:FeedDidUpReadCount object:item.feedID];
}

- (void)articles:(NSArray<FeedItem *> *)items markAsRead:(BOOL)read
{
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSUbiquitousKeyValueStore *NSUKV = NSUbiquitousKeyValueStore.defaultStore;
    
    NSMutableSet *feeds = [NSMutableSet setWithCapacity:items.count];
    
    for (FeedItem *item in items) {
        item.read = YES;
        
        NSString *key = item.guid.length > 32 ? item.guid.md5 : item.guid;
        [defaults setBool:read forKey:key];
        [NSUKV setBool:read forKey:key];
        
        [feeds addObject:item.feedID];
    }
    
    [defaults synchronize];
    [NSUKV synchronize];
    
    for (NSNumber *feedID in feeds.allObjects) {
        [NSNotificationCenter.defaultCenter postNotificationName:FeedDidUpReadCount object:feedID];
    }
}

#pragma mark -

+ (void)load
{
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector: @selector (storeDidChange:)
        name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification
        object: [NSUbiquitousKeyValueStore defaultStore]];
    
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (void)storeDidChange:(NSNotification *)note {
    NSDictionary *userInfo = note.userInfo;
    DDLogDebug(@"NSUKV: %@", userInfo);
}

@end
