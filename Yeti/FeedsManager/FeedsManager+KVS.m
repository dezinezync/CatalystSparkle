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
    
    [self.backgroundSession POST:path parameters:@{@"articles": articles, @"userID": self.userID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        for (FeedItem *item in items) {
            item.read = read;
        }
        
        strongify(self);
        
        if (!read) {
            MyFeedsManager.unread = [self.unread arrayByAddingObjectsFromArray:items];
        }
        else {
            
            MyFeedsManager.unread = [self.unread rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                return ![articles containsObject:obj.identifier];
            }];
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
        
        [AlertManager showGenericAlertWithTitle:@"App Error" message:error.localizedDescription];
    }
    
    return errored;
}

@end
