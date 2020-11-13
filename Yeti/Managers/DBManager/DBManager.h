//
//  DBManager.h
//  Yeti
//
//  Created by Nikhil Nigade on 03/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <BackgroundTasks/BackgroundTasks.h>

#import "FeedsManager.h"
#import "Feed.h"
#import "FeedItem.h"
#import "Folder.h"
#import "User.h"

#import <YapDatabase/YapDatabase.h>
#import <YapDatabase/YapDatabaseCloudCore.h>
#import <YapDatabase/YapDatabaseCloudCorePipeline.h>

#define cloudCoreExtensionName @"ElytraCloudCoreExtension"

#define SYNC_COLLECTION @"sync-collection"
#define syncToken @"syncToken" // last sync date we stored or the one sent by the server
#define syncedChanges @"syncedChanges" // have the synced the changes with our local store ?    

NS_ASSUME_NONNULL_BEGIN

@class DBManager;

extern NSNotificationName const UIDatabaseConnectionWillUpdateNotification;
extern NSNotificationName const UIDatabaseConnectionDidUpdateNotification;
extern NSString * const kNotificationsKey;

typedef void (^syncProgressBlock)(CGFloat progress);

#define LOCAL_NAME_COLLECTION @"localNames"
#define LOCAL_FEEDS_COLLECTION @"localFeeds"
#define LOCAL_FOLDERS_COLLECTION @"localFolders"
#define LOCAL_ARTICLES_COLLECTION @"localArticles"
#define LOCAL_SETTINGS_COLLECTION @"localSettings" // internal app settings

extern DBManager * MyDBManager;

@interface DBManager : NSObject {
    YapDatabaseCloudCore * _cloudCoreExtension;
}

+ (void)initialize;

+ (instancetype)sharedInstance;

/// Call this method only once the userID becomes available.
- (void)setupSync;

@property (nonatomic, strong) YapDatabase *database;
@property (nonatomic, strong) YapDatabaseConnection *uiConnection;
@property (nonatomic, strong) YapDatabaseConnection *bgConnection;

@property (nonatomic, copy) syncProgressBlock syncProgressBlock;

#pragma mark - Methods

- (User * _Nullable)getUser;

- (void)setUser:(User * _Nullable)user;

- (void)setFeeds:(NSArray <Feed *> *)feeds;

- (void)updateFeed:(Feed *)feed;

- (void)setFolders:(NSArray <Folder *> *)folders;

- (void)renameFeed:(Feed *)feed customTitle:(NSString *)customTitle completion:(void(^)(BOOL success))completionCB;

#pragma mark - Articles

- (FeedItem *)articleForID:(NSNumber *)identifier feedID:(NSNumber *)feedID;

- (void)addArticle:(FeedItem *)article;

#pragma mark - CloudCore

@property (nonatomic, strong) YapDatabaseCloudCore *cloudCoreExtension;

#pragma mark - Bulk Operations 

- (void)purgeDataForResync;

- (void)setupSync:(BGAppRefreshTask *)task completionHandler:(void(^ _Nullable)(BOOL completed))completionHandler;

- (BOOL)isSyncing;

#pragma mark - Background Operations

@property (nonatomic, copy, nullable) void (^backgroundCompletionHandler)(void);

@end

NS_ASSUME_NONNULL_END
