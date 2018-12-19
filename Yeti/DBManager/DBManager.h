//
//  DBManager.h
//  Yeti
//
//  Created by Nikhil Nigade on 03/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FeedsManager.h"
#import "Feed.h"

#import <YapDatabase/YapDatabase.h>
#import <YapDatabase/YapDatabaseCloudCore.h>
#import <YapDatabase/YapDatabaseCloudCorePipeline.h>

#define cloudCoreExtensionName @"ElytraCloudCoreExtension"

NS_ASSUME_NONNULL_BEGIN

@class DBManager;

extern NSNotificationName const UIDatabaseConnectionWillUpdateNotification;
extern NSNotificationName const UIDatabaseConnectionDidUpdateNotification;
extern NSString * const kNotificationsKey;

extern DBManager * MyDBManager;

@interface DBManager : NSObject {
    YapDatabaseCloudCore * _cloudCoreExtension;
}

+ (void)initialize;

+ (instancetype)sharedInstance;

@property (nonatomic, strong) YapDatabase *database;
@property (nonatomic, strong) YapDatabaseConnection *uiConnection;
@property (nonatomic, strong) YapDatabaseConnection *bgConnection;

#pragma mark - Methods

- (void)renameFeed:(Feed *)feed customTitle:(NSString *)customTitle completion:(void(^)(BOOL success))completionCB;

#pragma mark - CloudCore

@property (nonatomic, strong) YapDatabaseCloudCore *cloudCoreExtension;

@end

NS_ASSUME_NONNULL_END
