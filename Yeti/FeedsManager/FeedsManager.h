//
//  FeedsManager.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DZNetworking/DZNetworking.h>

#import "Feed.h"
#import "Folder.h"
#import "YTUserID.h"

typedef NSString * FMNotification;

extern FMNotification _Nonnull const FeedDidUpReadCount;
extern FMNotification _Nonnull const FeedsDidUpdate;
extern FMNotification _Nonnull const UserDidUpdate;
extern FMNotification _Nonnull const BookmarksDidUpdate;
extern FMNotification _Nonnull const SubscribedToFeed;

@class FeedsManager;

extern FeedsManager * _Nonnull MyFeedsManager;

@interface FeedsManager : NSObject {
    NSArray <FeedItem *> * _bookmarks;
    NSString *_pushToken;
    
    NSString * kPushTokenFilePath;
}

@property (nonatomic, strong, readonly) DZURLSession * _Nonnull session, * _Nonnull backgroundSession;

#ifndef SHARE_EXTENSION
@property (nonatomic, strong, readonly) YTUserID * _Nonnull userIDManager;

@property (nonatomic) NSNumber * _Nullable userID;

@property (nonatomic, strong) NSString *pushToken;

@property (nonatomic, weak) Feed *subsribeAfterPushEnabled;

#endif

@property (nonatomic, copy) NSArray <FeedItem *> * _Nonnull bookmarks;

#pragma mark - Feeds

@property (nonatomic, strong) NSArray <Feed *> * _Nullable feeds;

@property (nonatomic, assign) NSInteger totalUnread;
@property (nonatomic, strong) NSArray <FeedItem *> * _Nullable unread;

@property (nonatomic, strong) NSArray <Folder *> * _Nullable folders;

- (void)getFeedsSince:(NSDate * _Nullable)since success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (Feed * _Nullable)feedForID:(NSNumber * _Nonnull)feedID;

- (void)getFeed:(Feed * _Nonnull)feed page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFeed:(NSURL * _Nonnull)url success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFeedByID:(NSNumber * _Nonnull)feedID success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)articlesByAuthor:(NSNumber * _Nonnull)authorID feedID:(NSNumber * _Nonnull)feedID page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getArticle:(NSNumber * _Nonnull)articleID success:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

#ifndef SHARE_EXTENSION

- (void)removeFeed:(NSNumber * _Nonnull)feedID success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Custom Feeds

- (void)updateUnreadArray;

- (void)getUnreadForPage:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getBookmarksWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Folders

- (void)addFolder:(NSString *)title success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)renameFolder:(NSNumber *)folderID to:(NSString *)title success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)updateFolder:(NSNumber *)folderID add:(NSArray <NSNumber *> * _Nullable)add remove:(NSArray <NSNumber *> * _Nullable)del  success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)removeFolder:(NSNumber *)folderID success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#endif

#pragma mark - Filters

- (void)getFiltersWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFilter:(NSString *)word success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)removeFilter:(NSString *)word success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Subscriptions

- (void)addPushToken:(NSString *)token success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)subsribe:(Feed * _Nonnull)feed success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)unsubscribe:(Feed * _Nonnull)feed success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Store

- (void)postAppReceipt:(NSData *)receipt success:(successBlock _Nonnull)successCB error:(errorBlock _Nonnull)errorCB;

#ifndef SHARE_EXTENSION

#pragma mark - <YTUserDelegate>

- (void)getUserInformation:(successBlock)successCB error:(errorBlock)errorCB;

- (void)updateUserInformation:(successBlock)successCB error:(errorBlock)errorCB;

- (void)getUserInformationFor:(NSString * _Nonnull)uuid success:(successBlock)successCB error:(errorBlock)errorCB;

#endif

#pragma mark - Error formatting

- (NSError * _Nonnull)errorFromResponse:(NSDictionary * _Nonnull)userInfo;

@end

#import "FeedsManager+KVS.h"
