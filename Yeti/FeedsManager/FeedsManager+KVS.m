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

@implementation FeedsManager (KVS)

- (void)article:(FeedItem *)item markAsRead:(BOOL)read
{
    [self articles:@[item] markAsRead:read];
    
}

- (void)articles:(NSArray<FeedItem *> *)items markAsRead:(BOOL)read
{
    NSMutableSet *feeds = [NSMutableSet setWithCapacity:items.count];
    NSMutableArray *articles = [NSMutableArray arrayWithCapacity:items.count];

    for (FeedItem *item in items) {
        [articles addObject:item.identifier];
        [feeds addObject:item.feedID];
    }

    NSString *path = formattedString(@"/article/%@", read ? @"true" : @"false");
    
    weakify(self);
    
    [self.session POST:path parameters:@{@"articles": articles, @"userID": self.userID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        for (FeedItem *item in items) {
            item.read = read;
        }
        
        asyncMain(^{
            for (NSNumber *feedID in feeds.allObjects) { @autoreleasepool {
                [NSNotificationCenter.defaultCenter postNotificationName:FeedDidUpReadCount object:feedID];
            } }
            
            strongify(self);
            
            self.totalUnread = MAX(0, self.totalUnread - items.count);
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        // silently handle
        error = [self errorFromResponse:error.userInfo];
        
        DDLogError(@"error marking %@ as read: %@", articles, error.localizedDescription);
        
    }];
}

#pragma mark -

+ (void)load
{
    
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
//    // Clear everything regardless of actual key:
//    for (NSString *key in store.dictionaryRepresentation.allKeys)
//    {
//        [store removeObjectForKey:key];
//    }
//
//    // clear all local defaults
//    NSString *bundleID = [NSBundle.mainBundle bundleIdentifier];
//    [defaults removePersistentDomainForName:bundleID];
    
    if (store) {
        [[NSNotificationCenter defaultCenter] addObserver:MyFeedsManager selector: @selector (storeDidChange:) name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:store];
        [NSNotificationCenter.defaultCenter addObserver:MyFeedsManager selector:@selector(defaultsDidChange:) name:NSUserDefaultsDidChangeNotification object:defaults];
    }
    
//    [defaults synchronize];
    
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
