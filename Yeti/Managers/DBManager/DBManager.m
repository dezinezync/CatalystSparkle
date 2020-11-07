//
//  DBManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 03/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DBManager+CloudCore.h"

#import <YapDatabase/YapDatabaseAutoView.h>
#import <YapDatabase/YapDatabaseViewRangeOptions.h>

#import "FeedOperation.h"
#import "NSPointerArray+AbstractionHelpers.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/NSArray+RZArrayCandy.h>

DBManager *MyDBManager;

NSNotificationName const UIDatabaseConnectionWillUpdateNotification = @"UIDatabaseConnectionWillUpdateNotification";
NSNotificationName const UIDatabaseConnectionDidUpdateNotification  = @"UIDatabaseConnectionDidUpdateNotification";
NSString *const kNotificationsKey = @"notifications";

#define kLastFeedsFetchTimeInterval @"lastFeedsFetchTimeInterval"

@interface DBManager () {
    CGFloat _totalProgress;
    CGFloat _currentProgress;
    NSOperationQueue *_syncQueue;
}

@property (nonatomic, assign, getter=isSyncSetup) BOOL syncSetup;

@end

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
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    NSString *databaseName = @"elytra.sqlite";
    
#ifdef DEBUG
    databaseName = @"elytra-debug.sqlite";
#endif
    
    NSURL *baseURL = [fileManager URLForDirectory:NSApplicationSupportDirectory
                                         inDomain:NSUserDomainMask
                                appropriateForURL:nil
                                           create:YES
                                            error:NULL];
    
    NSURL *containerURL = [fileManager containerURLForSecurityApplicationGroupIdentifier:@"group.elytra"];
    
    NSUserDefaults * sharedDefs = NSUserDefaults.standardUserDefaults;
    
    NSURL *databaseURL = [baseURL URLByAppendingPathComponent:databaseName isDirectory:NO];
    
    /**
     * Using the container for the DB causes crashes in background mode. AVOID!
     
     
    // https://stackoverflow.com/a/29704581/1387258
    if (containerURL != nil) {
        
        if (![sharedDefs boolForKey:@"YapDatabaseDataMovedToSharedContainer"]) {
        
            NSURL* oldLocation = [baseURL URLByAppendingPathComponent:databaseName isDirectory:NO];
            NSURL* newLocation = [containerURL URLByAppendingPathComponent:databaseName isDirectory:NO];

            if ([fileManager fileExistsAtPath:oldLocation.filePathURL.path])
            {
                //Check if a new file exists. This can happen when the watch app is run before
                if ([fileManager fileExistsAtPath:newLocation.filePathURL.path]) {
                    [fileManager removeItemAtURL:newLocation error:nil];
                }
                
                NSError *error = nil;

                [fileManager moveItemAtURL:oldLocation toURL:newLocation error:&error];
                
                if (error == nil) {
                    [sharedDefs setBool:YES forKey:@"YapDatabaseDataMovedToSharedContainer"];
                    [sharedDefs synchronize];
                    
                    databaseURL = [containerURL URLByAppendingPathComponent:databaseName isDirectory:NO];
                }
                
            }

        }
        else {
            databaseURL = [containerURL URLByAppendingPathComponent:databaseName isDirectory:NO];
        }
        
    }
    */
    
    return databaseURL.filePathURL.path;
}

#pragma mark - Instance

- (instancetype)init
{
    NSAssert(MyDBManager == nil, @"Must use sharedInstance singleton (global MyDBManager)");
    
    if (self = [super init]) {
        
        [self setupDatabase];
        
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 1;
        queue.name = @"com.elytra.sync.serialFetchArticles";
//        queue.underlyingQueue = dispatch_queue_create("com.elytra.sync.serialFetchQueue", DISPATCH_QUEUE_SERIAL);
        
        _syncQueue = queue;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self checkIfResetIsNeeded];
            
            [ArticlesManager.shared willBeginUpdatingStore];
            
            [self loadFeeds];
            [self loadFolders];
            
            [ArticlesManager.shared didFinishUpdatingStore];
            
        });
        
    }
    
    return self;
}

- (void)checkIfResetIsNeeded {
    
    __block NSNumber * lastFetch = nil;
    
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        
        lastFetch = [transaction objectForKey:kLastFeedsFetchTimeInterval inCollection:LOCAL_SETTINGS_COLLECTION];
        
    }];
    
    BOOL shouldResetAndRefresh = NO;
    
    if (lastFetch == nil) {
        
        shouldResetAndRefresh = YES;
        
    }
    else {
        
        NSDate *today = NSDate.date;
        
        NSDate *earlier = [NSDate dateWithTimeIntervalSince1970:lastFetch.doubleValue];
        
        NSTimeInterval diff = [today timeIntervalSinceDate:earlier];
        
        NSLogDebug(@"Time interval since last reset: %@", @(diff));
        
        // if it has been more than 3 days
        if (diff > 259200) {
            
            shouldResetAndRefresh = YES;
            
        }
        
    }
    
    if (shouldResetAndRefresh) {
        
        [self purgeDataForResync];
        
        [self->_syncQueue addOperationWithBlock:^{
            
            [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
               
                [transaction setObject:@(NSDate.date.timeIntervalSince1970) forKey:kLastFeedsFetchTimeInterval inCollection:LOCAL_SETTINGS_COLLECTION];
                
            }];
            
        }];
        
    }
    
}

#pragma mark - Methods

- (User *)getUser {
    
    User *user = nil;
    __block NSDictionary *data = nil;
    
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        
        data = [transaction objectForKey:@"user" inCollection:@"user"];
        
    }];
    
    if (data != nil) {
        
        user = [User instanceFromDictionary:data];
        
    }
    
    return user;
    
}

- (void)setUser:(User *)user {
    
    [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
       
        if (user == nil) {
            [transaction removeObjectForKey:@"user" inCollection:@"user"];
        }
        else {
            
            NSDictionary *data = user.dictionaryRepresentation;
            
            [transaction setObject:data forKey:@"user" inCollection:@"user"];
            
        }
        
        [MyFeedsManager setValue:user forKey:@"user"];
        
    }];
    
}

- (void)loadFeeds {
    
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
       
        NSArray <NSString *> *keys = [transaction allKeysInCollection:LOCAL_FEEDS_COLLECTION];
        
        if (keys.count == 0) {
            return;
        }
        
        NSMutableArray <Feed *> *feeds = [NSMutableArray arrayWithCapacity:keys.count];
        
        for (NSString *key in keys) {
            
            Feed *feed = [transaction objectForKey:key inCollection:LOCAL_FEEDS_COLLECTION];
            
            if (feed != nil) {
                
                feed.unread = @(0);
                
                [feeds addObject:feed];
                
            }
            
        }
        
        runOnMainQueueWithoutDeadlocking(^{
            [ArticlesManager.shared setFeeds:feeds];
        });
        
    }];
    
    NSLogDebug(@"Fetched feeds from local cache");
    
}

- (void)setFeeds:(NSArray <Feed *> *)feeds {
    
    if (feeds == nil || (feeds && feeds.count == 0)) {
        return;
    }
    
    [self.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        
        for (Feed *feed in feeds) {
            
            NSString *key = feed.feedID.stringValue;
        
#ifdef DEBUG
            NSAssert(key != nil, @"Expected feed to have a feedID.");
#endif
            
            [transaction setObject:feed forKey:key inCollection:LOCAL_FEEDS_COLLECTION];
            
        }
        
    }];
    
    NSLogDebug(@"Updated local cache of feeds");
    
}

- (void)updateFeed:(Feed *)feed {
    
    if (feed == nil) {
        return;
    }
    
    NSString *key = feed.feedID.stringValue;
    
    [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
       
        [transaction setObject:feed forKey:key inCollection:LOCAL_FEEDS_COLLECTION];
        
    }];
    
}

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
                
                runOnMainQueueWithoutDeadlocking(^{
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
            
            runOnMainQueueWithoutDeadlocking(^{
                completionCB(YES);
            });
            
        }
        
        [(YapDatabaseCloudCoreTransaction *)[transaction ext:cloudCoreExtensionName] addOperation:operation];
        
    }];
    
}

- (void)loadFolders {
    
//    NSMutableSet <Feed *> * mappedFeeds = [NSMutableSet new];
        
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
       
        NSArray <NSString *> *keys = [transaction allKeysInCollection:LOCAL_FOLDERS_COLLECTION];
        
        if (keys.count == 0) {
            return;
        }
        
        NSMutableArray <Folder *> *folders = [NSMutableArray arrayWithCapacity:keys.count];
        
        for (NSString *key in keys) {
            
            Folder *folder = [transaction objectForKey:key inCollection:LOCAL_FOLDERS_COLLECTION];
            
            if (folder != nil) {
                
                if (folder.feedIDs != nil && folder.feedIDs.count > 0) {
                    
                    folder.feeds = [NSPointerArray weakObjectsPointerArray];
                    
                    NSArray *feedIDs = folder.feedIDs.allObjects;
                    
                    NSMutableArray *allFeeds = [NSMutableArray arrayWithCapacity:folder.feedIDs.count];
                    
                    [feedIDs enumerateObjectsUsingBlock:^(NSNumber * _Nonnull objx, NSUInteger idx, BOOL * _Nonnull stop) {
                        
                        Feed *feed = [ArticlesManager.shared feedForID:objx];
                        
                        if (feed != nil) {
                            
                            [allFeeds addObject:feed];
                            feed.folderID = folder.folderID;
                            feed.folder = folder;
                            
                        }
                        
                    }];
                    
                    [folder.feeds addObjectsFromArray:allFeeds];
//                    [mappedFeeds addObjectsFromArray:allFeeds];
                    
                }
                
                [folders addObject:folder];
                
            }
            
        }
        
        runOnMainQueueWithoutDeadlocking(^{
            [ArticlesManager.shared setFolders:folders];
        });
        
    }];
    
    NSLogDebug(@"Fetched feeds from local cache");
    
}

- (void)setFolders:(NSArray<Folder *> *)folders {
    
    if (folders == nil || (folders && folders.count == 0)) {
        return;
    }
    
    [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        
        for (Folder *folder in folders) {
            
            NSMutableDictionary *dict = folder.dictionaryRepresentation.mutableCopy;
            
            if ([dict objectForKey:@"feeds"]) {
                [dict removeObjectForKey:@"feeds"];
            }
            
            Folder *object = [Folder instanceFromDictionary:dict];
            
            [transaction setObject:object forKey:object.folderID.stringValue inCollection:LOCAL_FOLDERS_COLLECTION];
            
        }
        
    }];
    
    NSLogDebug(@"Updated local cache of folders");
    
}

#pragma mark - Setup

- (YapDatabaseSerializer)databaseSerializer {
    // This is actually the default serializer.
    // We just included it here for completeness.
    YapDatabaseSerializer serializer = ^(NSString *collection, NSString *key, id object) {
        
        NSError *error = nil;
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:YES error:&error];
        
        if (error) {
            NSLog(@"Error: Failed to serialize object for key:%@:%@ -> %@", collection, key, error.localizedDescription);
        }
        
        return data;
        
    };
    
    return serializer;
}

- (YapDatabaseDeserializer)databaseDeserializer
{
    // Pretty much the default serializer,
    // but it also ensures that objects coming out of the database are immutable.
    YapDatabaseDeserializer deserializer = ^(NSString *collection, NSString *key, NSData *data) {
        
        NSError *error = nil;
        Class objClass = NSObject.class;
        
        if ([collection isEqualToString:LOCAL_FEEDS_COLLECTION]) {
            objClass = Feed.class;
        }
        else if ([collection containsString:LOCAL_ARTICLES_COLLECTION]) {
            objClass = FeedItem.class;
        }
        else if ([collection isEqualToString:LOCAL_FOLDERS_COLLECTION]) {
            objClass = Folder.class;
        }
        
        id object = [NSKeyedUnarchiver unarchivedObjectOfClass:objClass fromData:data error:&error];
        
        if (error) {
            NSLog(@"Error: Failed to deserialize object for key:%@:%@ -> %@", collection, key, error.localizedDescription);
        }
        
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

#define GROUP_ARTICLES @"articles"
#define GROUP_FEEDS @"feeds"
#define GROUP_FOLDERS @"folders"

- (void)setupDatabase
{
    NSString *databasePath = [[self class] databasePath];
    NSLog(@"databasePath: %@", databasePath);
    
    // Configure custom class mappings for NSCoding.
    // In a previous version of the app, the "MyTodo" class was named "MyTodoItem".
    // We renamed the class in a recent version.
    
    [NSKeyedUnarchiver setClass:Feed.class forClassName:@"Feed"];
    [NSKeyedUnarchiver setClass:FeedItem.class forClassName:@"FeedItem"];
    
    // Create the database
    
    _database = [[YapDatabase alloc] initWithURL:[NSURL fileURLWithPath:databasePath]];
    [_database registerDefaultSerializer:[self databaseSerializer]];
    [_database registerDefaultDeserializer:[self databaseDeserializer]];
    [_database registerDefaultPreSanitizer:[self databasePreSanitizer]];
    [_database registerDefaultPostSanitizer:[self databasePostSanitizer]];
    
    [_database registerMetadataSerializer:^NSData * _Nonnull(NSString * _Nonnull collection, NSString * _Nonnull key, NSDictionary *  _Nonnull object) {
        
        if (object == nil) {
            return nil;
        }
        
        NSError *error = nil;
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:YES error:&error];
        
        if (error) {
            NSLog(@"Error serializing metadata:%@ with error:\n%@", object, error);
        }
        
        return data;
        
    } forCollection:LOCAL_ARTICLES_COLLECTION];
    
    [_database registerMetadataDeserializer:^id _Nullable(NSString * _Nonnull collection, NSString * _Nonnull key, NSData * _Nonnull data) {
        
        if (data == nil) {
            return nil;
        }
        
        NSError *error = nil;
        
        NSDictionary * object = [NSKeyedUnarchiver unarchivedObjectOfClass:NSDictionary.class fromData:data error:&error];
        
        if (error != nil) {
            NSLog(@"Error deserializing metadata:%@ with error:\n%@", object, error);
        }
        
        return object;
        
    } forCollection:LOCAL_ARTICLES_COLLECTION];
    
    // Setup the extensions
    
    // Setup database connection(s)
    
    _uiConnection = [_database newConnection];
    _uiConnection.objectCacheLimit = 100;
    _uiConnection.metadataCacheEnabled = YES;
    
    _bgConnection = [_database newConnection];
    _bgConnection.objectCacheLimit = 25;
    _bgConnection.metadataCacheEnabled = NO;
    
    // Start the longLivedReadTransaction on the UI connection.
    [_uiConnection enableExceptionsForImplicitlyEndingLongLivedReadTransaction];
    [_uiConnection beginLongLivedReadTransaction];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:_database];
    
    [self setupViews];
    
//#ifdef DEBUG
//    [self purgeDataForResync];
//#endif
//    [self cleanupDatabase];
    
}

- (void)setupViews {
    
    // Articles View
    {
        YapDatabaseViewGrouping *group = [YapDatabaseViewGrouping withObjectBlock:^NSString * _Nullable(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull collection, NSString * _Nonnull key, id  _Nonnull object) {
            
            if ([collection containsString:LOCAL_ARTICLES_COLLECTION]) {
                return [NSString stringWithFormat:@"%@:%@", GROUP_ARTICLES, [(FeedItem *)object feedID]];
            }
            else if ([collection containsString:LOCAL_FEEDS_COLLECTION]) {
                return GROUP_FEEDS;
            }
            else if ([collection containsString:LOCAL_FOLDERS_COLLECTION]) {
                return GROUP_FOLDERS;
            }

            return nil;
            
        }];
        
        YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection1, NSString * _Nonnull key1, id  _Nonnull object1, NSString * _Nonnull collection2, NSString * _Nonnull key2, id  _Nonnull object2) {
           
            if ([group containsString:GROUP_FEEDS]) {

                Feed *feed1 = object1;
                Feed *feed2 = object2;
                
                if (feed1 == nil || feed2 == nil) {
                    return NSOrderedSame;
                }

                return [feed1.feedID compare:feed2.feedID];

            }
            else if ([group containsString:GROUP_ARTICLES]) {
                
                FeedItem *item1 = object1;
                FeedItem *item2 = object2;
                
                if (!item1 || !item2) {
                    return NSOrderedSame;
                }
                
                return [item1.identifier compare:item2.identifier] & [item1.timestamp compare:item2.timestamp];
                
            }
            else if ([group isEqualToString:GROUP_FOLDERS]) {
                
                Folder *item1 = object1;
                Folder *item2 = object2;
                
                if (!item1 || !item2) {
                    return NSOrderedSame;
                }
                
                return [item1.title localizedCompare:item2.title];
                
            }
            else {
                return NSOrderedSame;
            }
            
        }];
        
        NSString *versionTag = @"2020-04-22 04:55PM";
        
        YapDatabaseViewOptions *options = [[YapDatabaseViewOptions alloc] init];
        
        YapDatabaseAutoView *view = [[YapDatabaseAutoView alloc] initWithGrouping:group sorting:sorting versionTag:versionTag options:options];
        [_database registerExtension:view withName:@"articlesView"];
    }
    
}

- (void)cleanupDatabase {
    
    // remove articles older than 2 weeks from the DB cache.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        NSDate *now = NSDate.date;
       
        [self.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
           
            NSArray <NSString *> * collections = [[transaction allCollections] rz_filter:^BOOL(NSString *obj, NSUInteger idx, NSArray *array) {
                return [obj containsString:LOCAL_ARTICLES_COLLECTION];
            }];
            
            NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES selector:@selector(compare:)];
            
            for (NSString *col in collections) {
                
                NSArray <NSNumber *> *keys = [[transaction allKeysInCollection:col] rz_map:^id(NSString *obj, NSUInteger idx, NSArray *array) {
                        
                    return @(obj.integerValue);
                    
                }];
                
                keys = [keys sortedArrayUsingDescriptors:@[descriptor]];
                
                if (keys.count == 0) {
                    continue;
                }
                
                // check the last 20 items
                NSRange range = NSMakeRange(0, MIN(keys.count, 20));
                
                keys = [keys subarrayWithRange:range];
                
                for (NSNumber *key in keys) {
                    
                    FeedItem *item = [transaction objectForKey:key.stringValue inCollection:col];
                    
                    // if it is older than 2 weeks, delete it
                    if (item != nil) {
                        
                        NSDate *created = item.timestamp;
                        
                        NSTimeInterval since = [now timeIntervalSinceDate:created];
                        
                        double days = floor(since / 86400);
                        
                        if(days >= 14.f) {
                            
                            NSLog(@"Article is stale %@:%@. Deleted.", col, key);
                            
                            [self _deleteArticle:key.stringValue collection:col transaction:transaction];
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }];
        
    });
    
}

#pragma mark - Sync

//- (void)setBackgroundCompletionHandler:(void (^)(void))backgroundCompletionHandler {
//    
//    MyFeedsManager.backgroundSession.backgroundCompletionHandler = backgroundCompletionHandler;
//    
//}

- (BOOL)isSyncing {
    
    return _totalProgress != 0 && (_totalProgress < 0.95f);
    
}

- (void)setupSync:(BGAppRefreshTask *)task completionHandler:(void (^ _Nullable)(BOOL))completionHandler {
    
    syncProgressBlock originalSyncBlock = [self.syncProgressBlock copy];
    
    weakify(self);
    weakify(task);
    
    __block BOOL cancelled = NO;
    
    self.syncProgressBlock = ^(CGFloat progress) {
        
        if (progress >= 0.95f) {
            
            MyFeedsManager.unreadLastUpdate = NSDate.date;
            
            strongify(self);
            
            BOOL completed = self->_syncQueue != nil && cancelled == NO;
            
            NSLogDebug(@"Background sync completed. Success: %@", @(completed));
            
            runOnMainQueueWithoutDeadlocking(^{
                
                if (self.backgroundCompletionHandler) {
                    self.backgroundCompletionHandler();
                }
                
                if (completionHandler) {
                    completionHandler(YES);
                }
                
                [task setTaskCompletedWithSuccess:completed];
                
                self->_syncProgressBlock = originalSyncBlock;
                
            });
            
        }
        
    };
    
    task.expirationHandler = ^{
        
        strongify(self);
        
        if (self->_syncQueue != nil) {
            
            cancelled = YES;
            
            runOnMainQueueWithoutDeadlocking(^{
               
                if (self.backgroundCompletionHandler) {
                    self.backgroundCompletionHandler();
                }
                
                if (completionHandler) {
                    completionHandler(NO);
                }
                
                [self->_syncQueue cancelAllOperations];
                
                strongify(task);
                
                [task setTaskCompletedWithSuccess:NO];
                
            });
            
        }
        
    };
    
    self->_syncSetup = NO;
    [self setupSync];
    
}

- (void)setupSync {
    
    if (self.isSyncSetup == YES) {
        return;
    }
    
    if (MyFeedsManager.user == nil) {
        return;
    }
    
    // check if sync has been setup on this device.
    [self.bgConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        
        __block NSString *token = [transaction objectForKey:syncToken inCollection:SYNC_COLLECTION];
        
        // if we don't have a token, we create one with an old date of 1993-03-11 06:11:00 ;)
        // date was later changed to 2020-04-14 22:30 when sync was finalised.
        if (token == nil) {
            
            NSCalendarUnit units = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour;
            
            NSDateComponents * components = [NSCalendar.currentCalendar components:units fromDate:NSDate.date];
            
            token = [NSString stringWithFormat:@"%@-%@-%@ %@:00:00", @(components.year), @(components.month), @(components.day), @(components.hour)];
            
            token = [token base64Encoded];
        
        }
        
//#ifdef DEBUG
//        
//        runOnMainQueueWithoutDeadlocking(^{
//            
////            if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
//                
//                token = [@"2020-05-30 13:13:00" base64Encoded];
//                
////            }
//            
//        });
//        
//#endif
        
        self.syncSetup = YES;
        
        [self syncNow:token];
        
    }];
    
}

- (void)syncNow:(NSString *)token {
    
    if (MyFeedsManager == nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self syncNow:token];
        });
        
        return;
    }
    
    _totalProgress = 0.f;
    _currentProgress = 0.f;
    
    if (self.syncProgressBlock) {
        
        runOnMainQueueWithoutDeadlocking(^{
            self.syncProgressBlock(0.f);
        });
        
    }
    
    weakify(self);
    
    [_syncQueue addOperationWithBlock:^{
       
        [MyFeedsManager getSync:token success:^(ChangeSet *changeSet, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            if (changeSet == nil) {
                
                if (self.syncProgressBlock) {
                    
                    runOnMainQueueWithoutDeadlocking(^{
                        self.syncProgressBlock(1.f);
                    });
                    
                }
                
                return;
                
            }
            
            // save the new change token to our local db
            [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                
                strongify(self);

                [transaction setObject:changeSet.changeToken forKey:syncToken inCollection:SYNC_COLLECTION];
                
                // now for every change set, create/update an appropriate key in the database
                if (changeSet.customFeeds) {
                    
                    self->_totalProgress += changeSet.customFeeds.count;
                    self->_currentProgress = self->_totalProgress;
                    
                    [self updateCustomFeedsMapping:changeSet transaction:transaction];
                    
                }
                
                if (changeSet.feedsWithNewArticles) {
                    
                    self->_totalProgress += changeSet.feedsWithNewArticles.count;
                    
                    if (self.syncProgressBlock) {
                        
                        runOnMainQueueWithoutDeadlocking(^{
                            self.syncProgressBlock(self->_currentProgress/self->_totalProgress);
                        });
                        
                    }
                    
                    // this is an async method. So we don't pass it a transaction.
                    // it'll fetch its own transaction as necessary.
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        
                        [self fetchNewArticlesFor:changeSet.feedsWithNewArticles since:token];
                        
                    });
                    
                }
                
                if (self->_totalProgress == 0.f) {
                    
                    if (self.syncProgressBlock) {
                        
                        runOnMainQueueWithoutDeadlocking(^{
                            self.syncProgressBlock(1.f);
                        });
                        
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
            
            if (self.syncProgressBlock) {
                
                runOnMainQueueWithoutDeadlocking(^{
                    self.syncProgressBlock(1.f);
                });
                
            }
           
            NSLog(@"An error occurred when syncing changes: %@", error);
            
        }];
        
    }];
    
}

- (void)updateCustomFeedsMapping:(ChangeSet *)changeSet transaction:(YapDatabaseReadWriteTransaction *)transaction {
    
    for (SyncChange *change in changeSet.customFeeds) {
        
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
    
}

- (void)fetchNewArticlesFor:(NSArray <NSNumber *> *)feedIDs since:(NSString *)since {
    
    NSLogDebug(@"[Sync] Fetching new articles for: %@", feedIDs);
    
    for (NSNumber *feedID in feedIDs) { @autoreleasepool {
        
        [self->_syncQueue addOperationWithBlock:^{
            
            [self _fetchNewArticlesFor:feedID since:since queue:self->_syncQueue];
            
        }];
        
    } }
    
    [self->_syncQueue waitUntilAllOperationsAreFinished];
    
}

- (void)_fetchNewArticlesFor:(NSNumber *)feedID since:(NSString *)since queue:(NSOperationQueue *)queue {
    
//    [queue setSuspended:YES];
    
    __block NSNumber *articleID = nil;
    
//     first we get the latest article for this Feed ID.
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {

        YapDatabaseViewTransaction *viewTransaction = [transaction extension:@"articlesView"];

        NSString *group = [NSString stringWithFormat:@"%@:%@", GROUP_ARTICLES, feedID];

        NSString *collection = nil;
        NSString *key = nil;

        [viewTransaction getFirstKey:&key collection:&collection inGroup:group];

        if (key != nil && collection != nil) {
            articleID = @(key.integerValue);
        }

    }];

    if (articleID) {
        NSLog(@"[Sync] Fetching articles for %@ since %@", feedID, articleID);
    }
    else {
        NSLog(@"[Sync] Fetching articles for %@ using token %@", feedID, since);
    }
    
    NSMutableDictionary *params = @{
        @"feedID": feedID,
        @"userID": MyFeedsManager.userID
    }.mutableCopy;
    
    if (articleID) {
        params[@"articleID"] = @(articleID.integerValue - 100);
    }
    else if (since) {
        params[@"since"] = since;
    }
    
    weakify(self);
    
    [MyFeedsManager getSyncArticles:params success:^(NSArray <FeedItem *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (self.syncProgressBlock) {
            
            self->_currentProgress += 1;
            
            runOnMainQueueWithoutDeadlocking(^{
                self.syncProgressBlock(self->_currentProgress/self->_totalProgress);
            });
            
        }
        
        if (responseObject == nil || responseObject.count == 0) {
//            [queue setSuspended:NO];
            return;
        }
        
        // insert these articles to the DB.
        [self.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
           
            for (FeedItem *item in responseObject) {
                
                NSString *collection = [self collectionForArticle:item];
                
                [transaction setObject:item forKey:item.identifier.stringValue inCollection:collection];
                
            }
            
        }];
        
//        [queue setSuspended:NO];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        if (self.syncProgressBlock) {
            
            self->_currentProgress += 1;
            
            runOnMainQueueWithoutDeadlocking(^{
                self.syncProgressBlock(self->_currentProgress/self->_totalProgress);
            });
            
        }
       
        NSLog(@"An error occurred when fetching articles for %@: %@", feedID, error.localizedDescription);
        
//        [queue setSuspended:NO];
        
    }];
    
}

#pragma mark - Articles

- (NSString *)articlesCollectionForFeed:(NSNumber *)feedID {
    
    return [NSString stringWithFormat:@"%@:%@", LOCAL_ARTICLES_COLLECTION, feedID];
    
}

- (NSString *)collectionForArticle:(FeedItem *)article {
    
    NSString *collection = [self articlesCollectionForFeed:article.feedID];
    
    return collection;
    
}

- (FeedItem *)articleForID:(NSNumber *)identifier feedID:(NSNumber *)feedID {
    
    __block FeedItem *article = nil;
    
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        
        NSString *collection = [self articlesCollectionForFeed:feedID];
        
        article = [transaction objectForKey:identifier.stringValue inCollection:collection];
        
    }];
    
    return article;
    
}

- (void)addArticle:(FeedItem *)article {
    
    if (!article || !article.identifier || !article.feedID) {
        NSLog(@"Error adding article to db. Missing information.\n%@", article);
        return;
    }
    
    [self.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        
        NSString *collection = [self collectionForArticle:article];
       
        [transaction setObject:article forKey:article.identifier.stringValue inCollection:collection];
        
    }];
    
}

- (void)deleteArticle:(FeedItem *)article {
    
    NSString *collection = [self collectionForArticle:article];
    
    [self.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
        
        [self _deleteArticle:article.identifier.stringValue collection:collection transaction:transaction];
        
    }];
    
}

- (void)_deleteArticle:(NSString *)key collection:(NSString *)col transaction:(YapDatabaseReadWriteTransaction *)transaction {
    
    [transaction removeObjectForKey:key inCollection:col];
    
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

#pragma mark - Bulk Operations

- (void)purgeDataForResync {
    
    /* during a re-sync, we remove all local refs to feeds and folders. */
    
    [self.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
       
        [transaction removeAllObjectsInCollection:LOCAL_ARTICLES_COLLECTION];
        [transaction removeAllObjectsInCollection:LOCAL_FEEDS_COLLECTION];
        [transaction removeAllObjectsInCollection:LOCAL_FOLDERS_COLLECTION];
        
    }];
    
    [self.uiConnection beginLongLivedReadTransaction];
    
}

@end
