//
//  FeedsManager.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DZNetworking/DZNetworking.h>
#import "Reachability.h"

#import "DBManager+CloudCore.h"

#import "Feed.h"
#import "Folder.h"
#import "User.h"
#import "FeedsManagerErrors.h"
#import "ChangeSet.h"

#import "YetiConstants.h"
#import "ArticlesManager.h"

#define kAccountID @"YTUserID"
#define kUserID @"userID"
#define kUUIDString @"UUIDString"

@class KVSItem;
@class FeedsManager;

extern FeedsManager * _Nonnull MyFeedsManager;

@interface FeedsManager : NSObject {
    
    NSString *_pushToken;
    
    YTSubscription * _subscription;
    
    NSNumber * _userID;
    
    NSUInteger _totalToday;
    
    NSUInteger _totalBookmarks;
    
}

@property (nonatomic, copy, readonly) NSString * _Nullable deviceID;

@property (atomic, strong, readonly) YTSubscription * _Nullable subscription;

@property (nonatomic, strong, readonly) DZURLSession * _Nonnull session;
@property (nonatomic, strong, readonly) DZURLSession * _Nonnull backgroundSession;

/// Returns either the session (foreground) or backgroundSession (background) 
@property (nonatomic, strong, readonly) DZURLSession * _Nonnull currentSession;

@property (nonatomic, strong, readonly) User * _Nullable user;

@property (atomic) NSNumber * _Nullable userID;

@property (nonatomic, strong) NSString * _Nullable pushToken;

@property (nonatomic, weak) Feed * _Nullable subsribeAfterPushEnabled;

// these are feeds which we need to sync completely
// as the user has just added them. 
@property (nonatomic, strong) NSMutableSet * _Nullable additionalFeedsToSync;

#pragma mark - Feeds

@property (atomic, strong) NSArray <Feed *> * _Nullable temporaryFeeds;

@property (nonatomic, assign) NSUInteger totalUnread;

@property (atomic, assign) NSUInteger totalToday;

@property (atomic, assign) NSUInteger totalBookmarks;

#pragma mark - Networking

@property (nonatomic, strong, readonly) Reachability * _Nonnull reachability;

#pragma mark - Misc
@property (nonatomic, assign) BOOL shouldRequestReview;

- (void)checkConstraintsForRequestingReview;

#pragma mark Networking APIs
#pragma mark - Feeds

- (void)getCountersWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getFeedsWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (Feed * _Nullable)feedForID:(NSNumber * _Nonnull)feedID;

- (void)getFeed:(Feed * _Nonnull)feed sorting:(YetiSortOption _Nonnull)sorting page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFeed:(NSURL * _Nonnull)url success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)_checkYoutubeFeed:(NSURL * _Nonnull)url success:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

- (void)addFeedByID:(NSNumber * _Nonnull)feedID success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)updateFeedWithLocalName:(Feed * _Nonnull)feed;

- (void)articlesByAuthor:(NSNumber * _Nonnull)authorID feedID:(NSNumber * _Nonnull)feedID page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getArticle:(NSNumber * _Nonnull)articleID feedID:(NSNumber * _Nullable)feedID noAuth:(BOOL)noAuth success:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

- (void)getMercurialArticle:(NSNumber * _Nonnull)articleID success:(successBlock _Nonnull)successCB error:(errorBlock _Nullable)errorCB;

- (void)markFeedRead:(Feed * _Nonnull)feed success:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

/// Get Recommended RSS feeds
/// @param count The count to limit each set to. Default: 9
/// @param noAuth If presenting when the user hasn't authenticated yet, set this param. 
/// @param successCB The success callback
/// @param errorCB The error callback
- (void)getRecommendations:(NSInteger)count noAuth:(BOOL)noAuth success:(successBlock _Nullable)successCB error:(errorBlock _Nonnull)errorCB;

- (void)removeFeed:(NSNumber * _Nonnull)feedID success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)renameFeed:(Feed * _Nonnull)feed title:(NSString * _Nullable)title success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getYoutubeCanonicalID:(NSURL * _Nonnull)originalURL success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)markRead:(NSString * _Nonnull)feedID articleID:(NSNumber * _Nonnull)articleID direction:(NSUInteger)direction sortType:(YetiSortOption _Nonnull)sortType success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Custom Feeds

- (void)updateUnreadArray;

@property (nonatomic, copy) NSDate * _Nullable unreadLastUpdate;

- (void)getUnreadForPage:(NSInteger)page limit:(NSInteger)limit sorting:(YetiSortOption _Nonnull)sorting success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)updateBookmarksFromServer;

#pragma mark - Folders

- (Folder * _Nullable)folderForID:(NSNumber * _Nonnull)folderID;

- (void)addFolder:(NSString * _Nonnull)title success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)renameFolder:(Folder * _Nonnull)folder to:(NSString * _Nonnull)title success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)updateFolder:(Folder * _Nonnull)folder add:(NSArray <NSNumber *> * _Nullable)add remove:(NSArray <NSNumber *> * _Nullable)del  success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)removeFolder:(Folder * _Nonnull)folder success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)folderFeedFor:(Folder * _Nonnull)folder sorting:(YetiSortOption _Nullable )sorting page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)markFolderRead:(Folder * _Nonnull)folder success:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

#pragma mark - Tags

- (void)getTagFeed:(NSString * _Nonnull)tag page:(NSInteger)page success:(successBlock _Nonnull)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Filters

- (void)getFiltersWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFilter:(NSString * _Nonnull)word success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)removeFilter:(NSString * _Nonnull)word success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Subscriptions

- (void)addPushToken:(NSString * _Nonnull)token success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getAllWebSubWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)subscribe:(Feed * _Nonnull)feed success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)unsubscribe:(Feed * _Nonnull)feed success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Store

- (void)updateExpiryTo:(NSDate * _Nonnull)date isTrial:(BOOL)isTrial success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)postAppReceipt:(NSData * _Nonnull)receipt success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getSubscriptionWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getOPMLWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Sync

- (void)getSync:(NSString * _Nonnull)token success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)syncSettings;

- (void)getSyncArticles:(NSDictionary * _Nonnull)params success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Search

- (NSURLSessionTask * _Nullable)search:(NSString * _Nonnull)query scope:(NSInteger)scope page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (NSURLSessionTask * _Nullable)search:(NSString * _Nonnull)query feedID:(NSNumber * _Nonnull)feedID author:(NSString * _Nullable)author success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (NSURLSessionTask * _Nullable)search:(NSString * _Nonnull)query folderID:(NSNumber * _Nonnull)folderID success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (NSURLSessionTask * _Nullable)searchUnread:(NSString * _Nonnull)query success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (NSURLSessionTask * _Nullable)searchToday:(NSString * _Nonnull)query success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Account

/// Deactivate the current account and reset the app
/// @param successCB The success block. Call -[FeedsManager resetAccount] upon success.
/// @param errorCB The error block.
- (void)deactivateAccountWithSuccess:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

- (void)resetAccount;

#pragma mark - <YTUserDelegate>

- (void)signInWithApple:(NSString * _Nonnull)uuid success:(successBlock _Nonnull)successCB error:(errorBlock _Nullable)errorCB API_AVAILABLE(ios(13.0));

- (void)getUserInformation:(successBlock _Nonnull)successCB error:(errorBlock _Nullable)errorCB;

- (void)createUser:(NSString * _Nonnull)uuid success:(successBlock _Nonnull)successCB error:(errorBlock _Nullable)errorCB;

- (void)getUserInformationFor:(NSString * _Nonnull)uuid success:(successBlock _Nonnull)successCB error:(errorBlock _Nullable)errorCB;

- (void)startUserFreeTrial:(successBlock _Nonnull)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Error formatting

- (NSError * _Nonnull)errorFromResponse:(NSDictionary * _Nonnull)userInfo;

#pragma mark - Shared Data

- (void)writeToSharedFile:(NSString * _Nonnull)fileURL data:(NSDictionary * _Nullable)data;

- (void)updateSharedUnreadCounters;

#pragma mark - State Restoration

- (void)continueActivity:(NSUserActivity * _Nonnull)activity;

- (void)saveRestorationActivity:(NSUserActivity * _Nonnull)activity;

#pragma mark - KVS

@property (atomic, strong) NSTimer * _Nullable batchKVSTimer;

@property (nonatomic, strong) NSMutableOrderedSet <KVSItem *> * _Nullable KVSItems;

@end

#import "FeedsManager+KVS.h"
