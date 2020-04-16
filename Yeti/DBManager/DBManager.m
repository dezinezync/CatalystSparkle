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

#import <DZKit/NSString+Extras.h>
#import <DZKit/NSArray+RZArrayCandy.h>

DBManager *MyDBManager;

NSNotificationName const UIDatabaseConnectionWillUpdateNotification = @"UIDatabaseConnectionWillUpdateNotification";
NSNotificationName const UIDatabaseConnectionDidUpdateNotification  = @"UIDatabaseConnectionDidUpdateNotification";
NSString *const kNotificationsKey = @"notifications";

@interface DBManager ()

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
        
        NSError *error = nil;
        
        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:YES error:&error];
        
        return data;
        
    };
    
    return serializer;
}

- (YapDatabaseDeserializer)databaseDeserializer
{
    // Pretty much the default serializer,
    // but it also ensures that objects coming out of the database are immutable.
    YapDatabaseDeserializer deserializer = ^(NSString *collection, NSString *key, NSData *data){
        
        id object = [NSKeyedUnarchiver unarchivedObjectOfClass:[NSObject class] fromData:data error:nil];
        
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

- (void)setupDatabase
{
    NSString *databasePath = [[self class] databasePath];
    DDLogVerbose(@"databasePath: %@", databasePath);
    
    // Configure custom class mappings for NSCoding.
    // In a previous version of the app, the "MyTodo" class was named "MyTodoItem".
    // We renamed the class in a recent version.
    
    [NSKeyedUnarchiver setClass:[Feed class] forClassName:@"Feed"];
    [NSKeyedUnarchiver setClass:FeedItem.class forClassName:@"FeedItem"];
    
    // Create the database
    
    _database = [[YapDatabase alloc] initWithURL:[NSURL fileURLWithPath:databasePath]];
    [_database registerDefaultSerializer:[self databaseSerializer]];
    [_database registerDefaultDeserializer:[self databaseDeserializer]];
    [_database registerDefaultPreSanitizer:[self databasePreSanitizer]];
    [_database registerDefaultPostSanitizer:[self databasePostSanitizer]];
    
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
    
    [self setupViews];
    
    [self cleanupDatabase];
    
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

            return nil;
            
        }];
        
        YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(YapDatabaseReadTransaction * _Nonnull transaction, NSString * _Nonnull group, NSString * _Nonnull collection1, NSString * _Nonnull key1, id  _Nonnull object1, NSString * _Nonnull collection2, NSString * _Nonnull key2, id  _Nonnull object2) {
           
            if ([group containsString:GROUP_FEEDS]) {

                Feed *feed1 = object1;
                Feed *feed2 = object2;

                return [feed1.feedID compare:feed2.feedID];

            }
            else if ([group containsString:GROUP_ARTICLES]) {
                
                FeedItem *item1 = object1;
                FeedItem *item2 = object2;
                
                return [item1.identifier compare:item2.identifier] & [item1.timestamp compare:item2.timestamp];
                
            }
            else {
                return NSOrderedSame;
            }
            
        }];
        
        NSString *versionTag = @"2020-04-14 04:52PM";
        
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

- (void)setupSync {
    
    if (self.isSyncSetup == YES) {
        return;
    }
    
    // check if sync has been setup on this device.
    [self.bgConnection asyncReadWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        
        NSString *token = [transaction objectForKey:syncToken inCollection:SYNC_COLLECTION];
        
        // if we don't have a token, we create one with an old date of 1993-03-11 06:11:00 ;)
        // date was later changed to 2020-04-14 22:30 when sync was finalised.
        if (token == nil) {
            
            NSCalendarUnit units = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour;
            
            NSDateComponents * components = [NSCalendar.currentCalendar components:units fromDate:NSDate.date];
            
            token = [NSString stringWithFormat:@"%@-%@-%@ %@:00:00", @(components.year), @(components.month), @(components.day), @(components.hour)];
            
            token = [token base64Encoded];
        
        }
        
//#ifdef DEBUG
//        token = [@"2020-04-15 06:30:00" base64Encoded];
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
    
    [MyFeedsManager getSync:token success:^(ChangeSet *changeSet, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        // save the new change token to our local db
        [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {

            [transaction setObject:changeSet.changeToken forKey:syncToken inCollection:SYNC_COLLECTION];
            
            // now for every change set, create/update an appropriate key in the database
            if (changeSet.customFeeds) {
                
                [self updateCustomFeedsMapping:changeSet transaction:transaction];
                
            }
            
            if (changeSet.feedsWithNewArticles) {
                
                // this is an async method. So we don't pass it a transaction.
                // it'll fetch its own transaction as necessary.
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    [self fetchNewArticlesFor:changeSet.feedsWithNewArticles since:token];
                    
                });
                
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
    
#ifdef DEBUG
    
    NSLog(@"[Sync] Fetching new articles for: %@", feedIDs);
    
#endif
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    queue.maxConcurrentOperationCount = 1;
    queue.name = @"com.elytra.sync.serialFetchArticles";
    
    NSBlockOperation *previousOp;
    
    for (NSNumber *feedID in feedIDs) { @autoreleasepool {
        
        NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            [self _fetchNewArticlesFor:feedID since:since queue:queue];
        }];
        
        if (previousOp != nil) {
            [operation addDependency:previousOp];
        }
        
        [queue addOperation:operation];
        
        previousOp = operation;
        
    } }
    
    [queue waitUntilAllOperationsAreFinished];
    
}

- (void)_fetchNewArticlesFor:(NSNumber *)feedID since:(NSString *)since queue:(NSOperationQueue *)queue {
    
    [queue setSuspended:YES];
    
    __block NSNumber *articleID = nil;
            
//        YapDatabaseViewRangeOptions *options = [YapDatabaseViewRangeOptions fixedRangeWithLength:1 offset:0 from:YapDatabaseViewEnd];
//        YapDatabaseViewMappings *mapping = [];
    
    // first we get the latest article for this Feed ID.
    [self.bgConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        
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
    
    NSMutableDictionary *params = @{@"feedID": feedID}.mutableCopy;
    
    if (articleID) {
        params[@"articleID"] = articleID;
    }
    else if (since) {
        params[@"since"] = since;
    }
    
    [MyFeedsManager getSyncArticles:params success:^(NSArray <FeedItem *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (responseObject == nil || responseObject.count == 0) {
            [queue setSuspended:NO];
            return;
        }
        
        // insert these articles to the DB.
        [self.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
           
            for (FeedItem *item in responseObject) {
                
                NSString *collection = [self collectionForArticle:item];
                
                [transaction setObject:item forKey:item.identifier.stringValue inCollection:collection];
                
            }
            
        }];
        
        [queue setSuspended:NO];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        NSLog(@"An error occurred when fetching articles for %@: %@", feedID, error.localizedDescription);
        
        [queue setSuspended:NO];
        
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
    
    if (!article || !article.identifier || !article.feedID || !article.content) {
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


@end
