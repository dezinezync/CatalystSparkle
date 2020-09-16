//
//  BookmarksManager.h
//  Yeti
//
//  Created by Nikhil Nigade on 23/09/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YapDatabase/YapDatabase.h>

#import "FeedItem.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName const BookmarksWillUpdateNotification;
FOUNDATION_EXPORT NSNotificationName const BookmarksDidUpdateNotification;

extern NSErrorDomain const BookmarksManagerErrorDomain;

@interface BookmarksManager : NSObject {
@public
    // when set to YES, it disables dispatching any new notifications for changes.
    // notifications must be dispatched manually in this case.
    BOOL _migrating;
}

- (instancetype)init;

@property (nonatomic, strong) NSArray <FeedItem *> *bookmarks;

@property (nonatomic, assign, readonly) NSUInteger bookmarksCount;

- (void)addBookmark:(FeedItem *)bookmark completion:(void (^ _Nullable)(BOOL success))completion;

- (void)removeBookmark:(FeedItem *)bookmark completion:(void (^ _Nullable)(BOOL success))completion;

- (void)removeBookmarkForID:(NSNumber *)articleID completion:(void (^ _Nullable)(BOOL success))completion;

- (void)_removeAllBookmarks:(void (^ _Nullable)(BOOL success))completion;

#pragma mark - Database

@property (nonatomic, strong) YapDatabase *database;
@property (nonatomic, strong) YapDatabaseConnection *uiConnection;
@property (nonatomic, strong) YapDatabaseConnection *bgConnection;

#pragma mark - Observing

- (void)addObserver:(id _Nonnull)object name:(NSNotificationName _Nonnull)name callback:(void (^)(void))callback;

- (void)removeObserver:(id _Nonnull)object name:(NSNotificationName _Nonnull)name;

- (void)postNotification:(NSNotificationName _Nonnull)name object:(id _Nullable)object;

@end

NS_ASSUME_NONNULL_END
