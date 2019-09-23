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
#import "YTUserID.h"
#import "Subscription.h"
#import "FeedsManagerErrors.h"
#import "ChangeSet.h"

#import "YetiConstants.h"
#import "ArticlesManager.h"
#import "BookmarksManager.h"

#import <UICKeyChainStore/UICKeyChainStore.h>

@class FeedsManager;

extern FeedsManager * _Nonnull MyFeedsManager;

@interface FeedsManager : NSObject {
    NSString *_pushToken;
    
    Subscription * _subscription;
    
    NSNumber * _userID;
    
    UICKeyChainStore * _keychain;
}

@property (atomic, strong, readonly) Subscription * _Nullable subscription;

@property (nonatomic, strong, readonly) DZURLSession * _Nonnull session, * _Nonnull backgroundSession;

@property (atomic, strong, readonly) YTUserID * _Nonnull userIDManager;

@property (atomic) NSNumber * _Nullable userID;

@property (nonatomic, strong) NSString * _Nullable pushToken;

@property (nonatomic, weak) Feed * _Nullable subsribeAfterPushEnabled;

@property (atomic, strong) UICKeyChainStore * _Nonnull keychain;

@property (nonatomic, copy) NSNumber * _Nonnull bookmarksCount;

@property (nonatomic, weak) BookmarksManager * _Nullable bookmarksManager;

#pragma mark - Feeds

@property (atomic, strong) NSArray <Feed *> * _Nullable temporaryFeeds;

@property (atomic, assign) NSInteger totalUnread;

#pragma mark - Networking

@property (nonatomic, strong, readonly) Reachability * _Nonnull reachability;

#pragma mark - Misc
@property (nonatomic, assign) BOOL shouldRequestReview;

- (void)checkConstraintsForRequestingReview;

#pragma mark Networking APIs
#pragma mark - Feeds

- (void)getFeedsSince:(NSDate * _Nullable)since success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (Feed * _Nullable)feedForID:(NSNumber * _Nonnull)feedID;

- (void)getFeed:(Feed * _Nonnull)feed sorting:(YetiSortOption _Nonnull)sorting page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFeed:(NSURL * _Nonnull)url success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFeedByID:(NSNumber * _Nonnull)feedID success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)articlesByAuthor:(NSNumber * _Nonnull)authorID feedID:(NSNumber * _Nonnull)feedID page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getArticle:(NSNumber * _Nonnull)articleID success:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

- (void)getMercurialArticle:(NSNumber * _Nonnull)articleID success:(successBlock _Nonnull)successCB error:(errorBlock _Nullable)errorCB;

- (void)markFeedRead:(Feed * _Nonnull)feed success:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

/// Get Recommended RSS feeds
/// @param count The count to limit each set to. Default: 9
/// @param successCB The success callback
/// @param errorCB The error callback
- (void)getRecommendations:(NSInteger)count success:(successBlock _Nullable)successCB error:(errorBlock _Nonnull)errorCB;

- (void)removeFeed:(NSNumber * _Nonnull)feedID success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)renameFeed:(Feed * _Nonnull)feed title:(NSString * _Nullable)title success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Custom Feeds

- (void)updateUnreadArray;

@property (nonatomic, copy) NSDate * _Nullable unreadLastUpdate;

- (void)getUnreadForPage:(NSInteger)page sorting:(YetiSortOption _Nonnull)sorting success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getBookmarksWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Folders

- (Folder * _Nullable)folderForID:(NSNumber * _Nonnull)folderID;

- (void)addFolder:(NSString * _Nonnull)title success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)renameFolder:(Folder * _Nonnull)folder to:(NSString * _Nonnull)title success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)updateFolder:(Folder * _Nonnull)folder add:(NSArray <NSNumber *> * _Nullable)add remove:(NSArray <NSNumber *> * _Nullable)del  success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)removeFolder:(Folder * _Nonnull)folder success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)folderFeedFor:(Folder * _Nonnull)folder sorting:(YetiSortOption _Nullable )sorting page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Tags

- (void)getTagFeed:(NSString * _Nonnull)tag page:(NSInteger)page success:(successBlock _Nonnull)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Filters

- (void)getFiltersWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFilter:(NSString * _Nonnull)word success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)removeFilter:(NSString * _Nonnull)word success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Subscriptions

- (void)addPushToken:(NSString * _Nonnull)token success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)subsribe:(Feed * _Nonnull)feed success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)unsubscribe:(Feed * _Nonnull)feed success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Store

- (void)updateExpiryTo:(NSDate * _Nonnull)date isTrial:(BOOL)isTrial success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)postAppReceipt:(NSData * _Nonnull)receipt success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getSubscriptionWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getOPMLWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Sync

- (void)getSync:(NSString * _Nonnull)token success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Search

- (NSURLSessionTask * _Nullable)search:(NSString * _Nonnull)query scope:(NSInteger)scope page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Account

/// Deactivate the current account and reset the app
/// @param successCB The success block. Call -[FeedsManager resetAccount] upon success.
/// @param errorCB The error block.
- (void)deactivateAccountWithSuccess:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

- (void)resetAccount;

#pragma mark - <YTUserDelegate>

- (void)getUserInformation:(successBlock _Nonnull)successCB error:(errorBlock _Nullable)errorCB;

- (void)updateUserInformation:(successBlock _Nonnull)successCB error:(errorBlock _Nullable)errorCB;

- (void)getUserInformationFor:(NSString * _Nonnull)uuid success:(successBlock _Nonnull)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Error formatting

- (NSError * _Nonnull)errorFromResponse:(NSDictionary * _Nonnull)userInfo;

#pragma mark - Local Data

@end

#import "FeedsManager+KVS.h"
