//
//  DBManager.h
//  Yeti
//
//  Created by Nikhil Nigade on 03/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <YapDatabase/YapDatabase.h>

NS_ASSUME_NONNULL_BEGIN

@class DBManager;

extern NSNotificationName const UIDatabaseConnectionWillUpdateNotification;
extern NSNotificationName const UIDatabaseConnectionDidUpdateNotification;
extern NSString * const kNotificationsKey;

extern DBManager * MyDBManager;

@interface DBManager : NSObject

+ (void)initialize;

+ (instancetype)sharedInstance;

@property (nonatomic, strong) YapDatabase *database;
@property (nonatomic, strong) YapDatabaseConnection *uiConnection;
@property (nonatomic, strong) YapDatabaseConnection *bgConnection;

@end

NS_ASSUME_NONNULL_END
