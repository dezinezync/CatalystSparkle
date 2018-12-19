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

#import "YetiConstants.h"

#import <UICKeyChainStore/UICKeyChainStore.h>

@class FeedsManager;

extern FeedsManager * _Nonnull MyFeedsManager;

@interface FeedsManager : NSObject {
    NSString *_pushToken;
}

@property (nonatomic, strong, readonly) Subscription *subscription;

@property (nonatomic, strong, readonly) DZURLSession * _Nonnull session, * _Nonnull backgroundSession;

@property (nonatomic, strong, readonly) YTUserID * _Nonnull userIDManager;

@property (nonatomic) NSNumber * _Nullable userID;

@property (nonatomic, strong) NSString *pushToken;

@property (nonatomic, weak) Feed *subsribeAfterPushEnabled;

@property (nonatomic, strong) UICKeyChainStore *keychain;

@property (nonatomic, copy) NSArray <FeedItem *> * _Nullable bookmarks;
@property (nonatomic, copy) NSNumber * _Nonnull bookmarksCount;

#pragma mark - Feeds

@property (nonatomic, strong) NSArray <Feed *> * _Nullable feeds;

@property (nonatomic, readonly) NSArray <Feed *> * _Nullable feedsWithoutFolders;

@property (nonatomic, assign) NSInteger totalUnread;
@property (nonatomic, strong) NSArray <FeedItem *> * _Nullable unread;

@property (nonatomic, strong) NSArray <Folder *> * _Nullable folders;

#pragma mark - Networking

@property (nonatomic, strong, readonly) Reachability *reachability;

#pragma mark - Misc
@property (nonatomic, assign) BOOL shouldRequestReview;

- (void)checkConstraintsForRequestingReview;

#pragma mark Networking APIs
#pragma mark - Feeds

- (void)getFeedsSince:(NSDate * _Nullable)since success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (Feed * _Nullable)feedForID:(NSNumber * _Nonnull)feedID;

- (void)getFeed:(Feed * _Nonnull)feed sorting:(YetiSortOption)sorting page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFeed:(NSURL * _Nonnull)url success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFeedByID:(NSNumber * _Nonnull)feedID success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)articlesByAuthor:(NSNumber * _Nonnull)authorID feedID:(NSNumber * _Nonnull)feedID page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getArticle:(NSNumber * _Nonnull)articleID success:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

- (void)markFeedRead:(Feed * _Nonnull)feed success:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

- (void)getRecommendationsWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nonnull)errorCB;

- (void)removeFeed:(NSNumber * _Nonnull)feedID success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)renameFeed:(Feed * _Nonnull)feed title:(NSString * _Nullable)title success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Custom Feeds

- (void)updateUnreadArray;

@property (nonatomic, copy) NSDate *unreadLastUpdate;

- (void)getUnreadForPage:(NSInteger)page sorting:(YetiSortOption)sorting success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getBookmarksWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Folders

- (Folder * _Nullable)folderForID:(NSNumber * _Nonnull)folderID;

- (void)addFolder:(NSString *)title success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)renameFolder:(Folder *)folder to:(NSString *)title success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)updateFolder:(Folder *)folder add:(NSArray <NSNumber *> * _Nullable)add remove:(NSArray <NSNumber *> * _Nullable)del  success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)removeFolder:(Folder *)folder success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)folderFeedFor:(Folder *)folder sorting:(YetiSortOption)sorting page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Filters

- (void)getFiltersWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFilter:(NSString *)word success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)removeFilter:(NSString *)word success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Subscriptions

- (void)addPushToken:(NSString *)token success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)subsribe:(Feed * _Nonnull)feed success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)unsubscribe:(Feed * _Nonnull)feed success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Store

- (void)updateExpiryTo:(NSDate *)date isTrial:(BOOL)isTrial success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)postAppReceipt:(NSData *)receipt success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getSubscriptionWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getOPMLWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark -

- (void)resetAccount;

#pragma mark - <YTUserDelegate>

- (void)getUserInformation:(successBlock)successCB error:(errorBlock)errorCB;

- (void)updateUserInformation:(successBlock)successCB error:(errorBlock)errorCB;

- (void)getUserInformationFor:(NSString * _Nonnull)uuid success:(successBlock)successCB error:(errorBlock)errorCB;

#pragma mark - Error formatting

- (NSError * _Nonnull)errorFromResponse:(NSDictionary * _Nonnull)userInfo;

#pragma mark - Local Data

@end

#import "FeedsManager+KVS.h"
