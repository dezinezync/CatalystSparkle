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

@property (nonatomic, assign, readonly) NSInteger bookmarksCount;

- (void)addBookmark:(FeedItem *)bookmark completion:(void (^ _Nullable)(BOOL success))completion;

- (void)removeBookmark:(FeedItem *)bookmark completion:(void (^ _Nullable)(BOOL success))completion;

- (void)_removeAllBookmarks:(void (^ _Nullable)(BOOL success))completion;

#pragma mark - Database

@property (nonatomic, strong) YapDatabase *database;
@property (nonatomic, strong) YapDatabaseConnection *uiConnection;
@property (nonatomic, strong) YapDatabaseConnection *bgConnection;

#pragma mark - Observing

- (void)addObserver:(id)object name:(NSNotificationName)name callback:(void (^)(void))callback;

- (void)removeObserver:(id)object name:(NSNotificationName)name;

@end

NS_ASSUME_NONNULL_END
