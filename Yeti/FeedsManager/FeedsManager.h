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
#import "YTUserID.h"

typedef NSString * FMNotification;

extern FMNotification _Nonnull const FeedDidUpReadCount;
extern FMNotification _Nonnull const FeedsDidUpdate;
extern FMNotification _Nonnull const UserDidUpdate;

@class FeedsManager;

extern FeedsManager * _Nonnull MyFeedsManager;

@interface FeedsManager : NSObject

@property (nonatomic, strong, readonly) DZURLSession * _Nonnull session;

#ifndef SHARE_EXTENSION
@property (nonatomic, strong, readonly) YTUserID * _Nonnull userIDManager;

@property (nonatomic) NSNumber * _Nullable userID;

#endif

@property (nonatomic, copy) NSArray <FeedItem *> * _Nonnull bookmarks;

#pragma mark - Feeds

@property (nonatomic, strong) NSArray <Feed *> * _Nullable feeds;

@property (nonatomic, assign) NSInteger totalUnread;
@property (nonatomic, strong) NSArray <FeedItem *> * _Nullable unread;

@property (nonatomic, strong) NSArray <id> * _Nullable folders;

- (void)getFeedsSince:(NSDate * _Nullable)since success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getFeed:(Feed * _Nonnull)feed page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFeed:(NSURL * _Nonnull)url success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFeedByID:(NSNumber * _Nonnull)feedID success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#ifndef SHARE_EXTENSION

- (void)removeFeed:(NSNumber * _Nonnull)feedID success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#pragma mark - Custom Feeds

- (void)updateUnreadArray;

- (void)getUnreadForPage:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getBookmarksWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

#endif

- (NSError * _Nonnull)errorFromResponse:(NSDictionary * _Nonnull)userInfo;

@end

#import "FeedsManager+KVS.h"
