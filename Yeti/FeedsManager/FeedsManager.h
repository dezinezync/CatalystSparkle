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

@class FeedsManager;

extern FeedsManager * _Nonnull MyFeedsManager;

@interface FeedsManager : NSObject

@property (nonatomic, strong, readonly) DZURLSession * _Nonnull session;

@property (nonatomic, strong, readonly) YTUserID * _Nonnull userIDManager;

@property (nonatomic) NSNumber * _Nullable userID;

#pragma mark - Feeds

@property (nonatomic, strong) NSArray <Feed *> * _Nullable feeds;

@property (nonatomic, strong) NSArray <id> * _Nullable folders;

- (void)getFeeds:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)getFeed:(Feed * _Nonnull)feed page:(NSInteger)page success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (void)addFeed:(NSURL * _Nonnull)url success:(successBlock _Nullable)successCB error:(errorBlock _Nullable)errorCB;

- (NSError * _Nonnull)errorFromResponse:(NSDictionary * _Nonnull)userInfo;

@end

#import "FeedsManager+KVS.h"
