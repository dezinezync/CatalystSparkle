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
#define syncToken @"syncToken-2.2" // last sync date we stored or the one sent by the server
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
#define LOCAL_ARTICLES_COLLECTION @"articles"

// cannot use "articles" here as it conflicts with the db setup.
#define LOCAL_ARTICLES_CONTENT_COLLECTION @"artContent"
#define LOCAL_ARTICLES_FULLTEXT_COLLECTION @"artFullText"

#define LOCAL_SETTINGS_COLLECTION @"localSettings" // internal app settings

#define GROUP_ARTICLES @"articles"
#define GROUP_FEEDS @"feeds"
#define GROUP_FOLDERS @"folders"

#define UNREADS_FEED_EXT @"unreadsFeedView"
#define DB_FEED_VIEW @"feedView"
#define DB_BASE_ARTICLES_VIEW @"baseArticlesView"
#define DB_BOOKMARKED_VIEW @"bookmarksView"

#define DB_VERSION_TAG @"2020-12-23 10:20AM IST"

// Key for article metadata which includes the title word cloud
// for filtering. 
#define kTitleWordCloud @"titleWordCloud"

extern NSComparisonResult NSTimeIntervalCompare(NSTimeInterval time1, NSTimeInterval time2);

extern DBManager * MyDBManager;

@interface DBManager : NSObject {
    
    YapDatabaseCloudCore * _cloudCoreExtension;
    
    BOOL _indexingFeeds;
    
}

+ (void)initialize;

+ (instancetype)sharedInstance;

/// Call this method only once the userID becomes available.
- (void)setupSync;

@property (nonatomic, strong) YapDatabase *database;
@property (nonatomic, strong) YapDatabaseConnection *uiConnection;
@property (nonatomic, strong) YapDatabaseConnection *bgConnection;
@property (nonatomic, strong) YapDatabaseConnection *countsConnection;

@property (nonatomic, copy) syncProgressBlock syncProgressBlock;

@property (atomic, strong, readonly) dispatch_queue_t readQueue;

#pragma mark - Methods

- (User * _Nullable)getUser;

- (void)setUser:(User * _Nullable)user;

/// Set the user with an optional completion block.
/// @param user The User object
/// @param completion The completion block. This block is always called on the main thread.
- (void)setUser:(User *)user completion:(void (^ _Nullable)(void))completion;

- (void)setFeeds:(NSArray <Feed *> *)feeds;

- (NSDictionary * _Nullable)metadataForFeed:(Feed * _Nonnull)feed;

- (void)updateFeed:(Feed * _Nonnull)feed;

- (void)updateFeed:(Feed * _Nonnull)feed metadata:(NSDictionary * _Nullable)metadata;

- (void)setFolders:(NSArray <Folder *> *)folders;

- (void)renameFeed:(Feed *)feed customTitle:(NSString *)customTitle completion:(void(^)(BOOL success))completionCB;

- (void)fetchNewArticlesFor:(NSArray <NSNumber *> *)feedIDs since:(NSString *)since;

- (void)updateUnreadCounters;

#pragma mark - Articles

- (FeedItem *)articleForID:(NSNumber *)identifier feedID:(NSNumber *)feedID;

- (NSArray <Content *> *)contentForArticle:(NSNumber *)identifier;

- (NSArray <Content *> *)fullTextContentForArticle:(NSNumber *)identifier;

- (void)addArticle:(FeedItem *)article;

- (void)addArticle:(FeedItem *)article strip:(BOOL)strip;

- (void)addArticleFullText:(NSArray <Content *> *)content identifier:(NSNumber *)identifier;

- (void)deleteArticleFullText:(NSNumber *)identifier;

- (void)removeAllArticlesFor:(NSNumber *)feedID;

#pragma mark - CloudCore

@property (nonatomic, strong) YapDatabaseCloudCore *cloudCoreExtension;

#pragma mark - Bulk Operations 

- (void)purgeDataForResync;

- (void)purgeFeedsForResync;

- (void)setupSync:(BGAppRefreshTask *)task completionHandler:(void(^ _Nullable)(BOOL completed))completionHandler;

- (BOOL)isSyncing;

- (void)cleanupDatabase;

#pragma mark - Background Operations

@property (nonatomic, copy, nullable) void (^backgroundCompletionHandler)(void);

@property (nonatomic, copy, nullable) void(^backgroundFetchHandler)(UIBackgroundFetchResult result);

@end

NS_ASSUME_NONNULL_END
