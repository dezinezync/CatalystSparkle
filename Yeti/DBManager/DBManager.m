//
//  DBManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 03/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DBManager+CloudCore.h"

#import "Feed.h"
#import "FeedOperation.h"

#import <DZKit/NSString+Extras.h>

DBManager *MyDBManager;

NSNotificationName const UIDatabaseConnectionWillUpdateNotification = @"UIDatabaseConnectionWillUpdateNotification";
NSNotificationName const UIDatabaseConnectionDidUpdateNotification  = @"UIDatabaseConnectionDidUpdateNotification";
NSString *const kNotificationsKey = @"notifications";

#define SYNC_COLLECTION @"sync-collection"

@implementation DBManager

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MyDBManager = [[DBManager alloc] init];
    });
}

+ (instancetype)sharedInstance
{
    return MyDBManager;
}

+ (NSString *)databasePath
{
    NSString *databaseName = @"elytra.sqlite";
    
#ifdef DEBUG
    databaseName = @"elytra-debug.sqlite";
#endif
    
    NSURL *baseURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                            inDomain:NSUserDomainMask
                                                   appropriateForURL:nil
                                                              create:YES
                                                               error:NULL];
    
    NSURL *databaseURL = [baseURL URLByAppendingPathComponent:databaseName isDirectory:NO];
    
    return databaseURL.filePathURL.path;
}

#pragma mark - Instance

- (instancetype)init
{
    NSAssert(MyDBManager == nil, @"Must use sharedInstance singleton (global MyDBManager)");
    
    if ((self = [super init]))
    {
        [self setupDatabase];
        [self setupSync];
    }
    
    return self;
}

#pragma mark - Methods

- (FeedOperation *)_renameFeed:(Feed *)feed title:(NSString *)title {
    
    if (feed == nil) {
        return nil;
    }
    
    FeedOperation *operation = [[FeedOperation alloc] init];
    operation.feed = feed;
    operation.customTitle = title ?: @"";
    
    return operation;
    
}

- (void)renameFeed:(Feed *)feed customTitle:(NSString *)customTitle completion:(nonnull void (^)(BOOL))completionCB {
    
    NSString *localNameKey = formattedString(@"feed-%@", feed.feedID);
    
    if (feed.localName != nil) {
        // the user can pass a clear string to clear the local name
        
        if ([customTitle length] == 0) {
            // clear the local name
            [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                
                FeedOperation *operation = [self _renameFeed:feed title:customTitle];
                
                feed.localName = nil;
                
                [transaction removeObjectForKey:localNameKey inCollection:LOCAL_NAME_COLLECTION];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    if (completionCB) {
                        completionCB(YES);
                    }
                    
                });
                
                [(YapDatabaseCloudCoreTransaction *)[transaction ext:cloudCoreExtensionName] addOperation:operation];
                
            }];
            
            return;
        }
    }
    
    // setup the new name for the user
    [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        
        FeedOperation *operation = [self _renameFeed:feed title:customTitle];
        
        feed.localName = customTitle;
        
        [transaction setObject:customTitle forKey:localNameKey inCollection:LOCAL_NAME_COLLECTION];
        
        if (completionCB) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                completionCB(YES);
            });
            
        }
        
        [(YapDatabaseCloudCoreTransaction *)[transaction ext:cloudCoreExtensionName] addOperation:operation];
        
    }];
    
}

#pragma mark - Setup

- (YapDatabaseSerializer)databaseSerializer
{
    // This is actually the default serializer.
    // We just included it here for completeness.
    YapDatabaseSerializer serializer = ^(NSString *collection, NSString *key, id object) {
        
        return [NSKeyedArchiver archivedDataWithRootObject:object];
        
    };
    
    return serializer;
}

- (YapDatabaseDeserializer)databaseDeserializer
{
    // Pretty much the default serializer,
    // but it also ensures that objects coming out of the database are immutable.
    YapDatabaseDeserializer deserializer = ^(NSString *collection, NSString *key, NSData *data){
        
        id object = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        
        return object;
    };
    
    return deserializer;
}

- (YapDatabasePreSanitizer)databasePreSanitizer
{
    YapDatabasePreSanitizer preSanitizer = ^(NSString *collection, NSString *key, id object){
        
//        if ([object isKindOfClass:[MyDatabaseObject class]])
//        {
//            [object makeImmutable];
//        }
        
        return object;
    };
    
    return preSanitizer;
}

- (YapDatabasePostSanitizer)databasePostSanitizer
{
    YapDatabasePostSanitizer postSanitizer = ^(NSString *collection, NSString *key, id object) {
        
//        if ([object isKindOfClass:[MyDatabaseObject class]])
//        {
//            [object clearChangedProperties];
//        }
    };
    
    return postSanitizer;
}

- (void)setupDatabase
{
    NSString *databasePath = [[self class] databasePath];
    DDLogVerbose(@"databasePath: %@", databasePath);
    
    // Configure custom class mappings for NSCoding.
    // In a previous version of the app, the "MyTodo" class was named "MyTodoItem".
    // We renamed the class in a recent version.
    
    [NSKeyedUnarchiver setClass:[Feed class] forClassName:@"Feed"];
    
    // Create the database
    
    _database = [[YapDatabase alloc] initWithPath:databasePath
                                       serializer:[self databaseSerializer]
                                     deserializer:[self databaseDeserializer]
                                     preSanitizer:[self databasePreSanitizer]
                                    postSanitizer:[self databasePostSanitizer]
                                          options:nil];
    
    // Setup the extensions
    
    // Setup database connection(s)
    
    _uiConnection = [_database newConnection];
    _uiConnection.objectCacheLimit = 400;
    _uiConnection.metadataCacheEnabled = NO;
    
    _bgConnection = [_database newConnection];
    _bgConnection.objectCacheLimit = 400;
    _bgConnection.metadataCacheEnabled = NO;
    
    // Start the longLivedReadTransaction on the UI connection.
    [_uiConnection enableExceptionsForImplicitlyEndingLongLivedReadTransaction];
    [_uiConnection beginLongLivedReadTransaction];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:_database];
}

#pragma mark - Sync

#define syncToken @"syncToken" // last sync date we stored or the one sent by the server
#define syncedChanges @"syncedChanges" // have the synced the changes with our local store ?

- (void)setupSync {
    
    // check if sync has been setup on this device.
    [self.bgConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        
        NSString *token = [transaction objectForKey:syncToken inCollection:SYNC_COLLECTION];
        
        // if we don't have a token, we create one with an old date of 1993-03-11 06:11:00 ;)
        if (token == nil) {
            
            NSString *token = [@"1993-03-11 06:11:00" base64Encoded];
            
            [self syncNow:token];
            
        }
        else {
            // if we do, check with the server for updates
            [self syncNow:token];
        }
        
    }];
    
}

- (void)syncNow:(NSString *)token {
    
    if (MyFeedsManager == nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self syncNow:token];
        });
        
        return;
    }
    
    [MyFeedsManager getSync:token success:^(ChangeSet *changeSet, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        // save the new change token to our local db
        [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {

            [transaction setObject:changeSet.changeToken forKey:syncToken inCollection:SYNC_COLLECTION];
            
            // now for every change set, create/update an appropriate key in the database
            
            for (SyncChange *change in changeSet.changes) {
                
                NSString *localNameKey = formattedString(@"feed-%@", change.feedID);
                
                // for now we're only syncing titles, so check those
                if (change.title == nil) {
                    // remove the custom title
                    [transaction removeObjectForKey:localNameKey inCollection:LOCAL_NAME_COLLECTION];
                }
                else {
                    // doesn't matter if we overwrite the changes.
                    [transaction setObject:change.title forKey:localNameKey inCollection:LOCAL_NAME_COLLECTION];
                }
                
            }

        }];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if ([error.localizedDescription containsString:@"Try again in"]) {
            
            // get the seconds value
            NSString *secondsString = [error.localizedDescription stringByReplacingOccurrencesOfString:@"Try again in " withString:@""];
            secondsString = [error.localizedDescription stringByReplacingOccurrencesOfString:@"s" withString:@""];
            
            NSInteger seconds = secondsString.integerValue;
            
            if (seconds != NSNotFound) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                    [self syncNow:token];
                });
                
            }
            
            return;
            
        }
       
        DDLogError(@"An error occurred when syncing changes: %@", error);
        
    }];
    
}

#pragma mark - Notifications

- (void)yapDatabaseModified:(NSNotification *)ignored
{
    // Notify observers we're about to update the database connection
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIDatabaseConnectionWillUpdateNotification
                                                        object:self];
    
    // Move uiDatabaseConnection to the latest commit.
    // Do so atomically, and fetch all the notifications for each commit we jump.
    
    NSArray *notifications = [self.uiConnection beginLongLivedReadTransaction];
    
    // Notify observers that the uiDatabaseConnection was updated
    
    NSDictionary *userInfo = @{
                               kNotificationsKey : notifications,
                               };
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UIDatabaseConnectionDidUpdateNotification
                                                        object:self
                                                      userInfo:userInfo];
}


@end
