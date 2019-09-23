//
//  BookmarksManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/09/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "BookmarksManager.h"

NSErrorDomain const BookmarksManagerErrorDomain = @"error.bookmarksManager";
NSNotificationName const BookmarksWillUpdateNotification = @"com.elytra.note.bookmarksupdating";
NSNotificationName const BookmarksDidUpdateNotification = @"com.elytra.note.bookmarksupdated";

#define kBookmarksCollection @"bookmarks"

@interface BookmarksManager ()

@property (nonatomic, copy, readwrite) NSUUID *userID;

@property (nonatomic, assign, readwrite) NSInteger bookmarksCount;

@property (nonatomic, strong) dispatch_queue_t bgQueue;

@end

@implementation BookmarksManager

- (instancetype)initWithUserID:(NSUUID *)UUID {
    
    if (UUID == nil) {
        @throw [NSError errorWithDomain:BookmarksManagerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"A UUID must be passed to initialise BookmarksManager"}];
    }
    
    if (self = [super init]) {
        
        self.userID = UUID;
        self.bgQueue = dispatch_queue_create("com.elytra.bookmarks.bg", DISPATCH_QUEUE_SERIAL);
        
        [self setupDatabase];
        
    }
    
    return self;
    
}

- (void)addBookmark:(FeedItem *)bookmark completion:(void (^)(BOOL))completion {
    
    dispatch_async(self.bgQueue, ^{
       
        [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
           
            [transaction setObject:bookmark forKey:bookmark.identifier.stringValue inCollection:kBookmarksCollection];
            
            bookmark.bookmarked = YES;
            
            self.bookmarks = [self.bookmarks arrayByAddingObject:bookmark];
            
            if (completion) { dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES);
            }); }
            
        }];
        
    });
    
}

- (void)removeBookmark:(FeedItem *)bookmark completion:(void (^)(BOOL))completion {
    
    dispatch_async(self.bgQueue, ^{
        
        [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
           
            [transaction removeObjectForKey:bookmark.identifier.stringValue inCollection:kBookmarksCollection];
            
            bookmark.bookmarked = NO;
            
            NSMutableArray <FeedItem *> *bookmarks = self.bookmarks.mutableCopy;
            [bookmarks removeObject:bookmark];
            
            self.bookmarks = bookmarks;
            
            if (completion) { dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES);
            }); }
            
        }];
        
    });
    
}

- (void)_removeAllBookmarks:(void (^)(BOOL))completion {
    
    dispatch_async(self.bgQueue, ^{
        
        [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
           
            NSArray <NSString *> *keys = [transaction allKeysInCollection:kBookmarksCollection];
            
            for (NSString *key in keys) {
                [transaction removeObjectForKey:key inCollection:kBookmarksCollection];
            }
            
            if (completion) { dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES);
            }); }
            
        }];
        
    });
    
}

#pragma mark - Internal

- (void)loadBookmarks {
    
    __block NSMutableArray *bookmarks = nil;
    
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
       
        NSArray <NSString *> *keys = [transaction allKeysInCollection:kBookmarksCollection];
        
        bookmarks = [[NSMutableArray alloc] initWithCapacity:keys.count];
        
        for (NSString *key in keys) {
            FeedItem *item = [transaction objectForKey:key inCollection:kBookmarksCollection];
            
            if (item != nil) {
                [bookmarks addObject:item];
            }
        }
        
    }];
    
    if (bookmarks) {
        
        for (FeedItem *item in bookmarks) {
            item.bookmarked = YES;
        }
        
        bookmarks = (NSMutableArray *)[bookmarks sortedArrayUsingSelector:@selector(compare:)];
        
    }
    
    self.bookmarks = bookmarks ?: @[];
    
}

#pragma mark - Setters

- (void)setBookmarks:(NSArray<FeedItem *> *)bookmarks {
    
    @synchronized (self) {
        if (self == nil) {
            return;
        }
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        
        if (self->_migrating == NO) {
            [center postNotificationName:BookmarksWillUpdateNotification object:nil];
        }
        
        self->_bookmarks = bookmarks;
        self.bookmarksCount = self->_bookmarks.count;
        
        if (self->_migrating == NO) {
            [center postNotificationName:BookmarksDidUpdateNotification object:nil];
        }
    }
    
}

#pragma mark - Database

- (NSString *)databasePath {
    NSString *databaseName = [NSString stringWithFormat:@"%@-bm-elytra.sqlite", self.userID.UUIDString];
    
#ifdef DEBUG
    databaseName = [NSString stringWithFormat:@"%@-bm-elytra-debug.sqlite", self.userID.UUIDString];
#endif
    
    NSURL *baseURL = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory
                                                            inDomain:NSUserDomainMask
                                                   appropriateForURL:nil
                                                              create:YES
                                                               error:NULL];
    
    NSURL *databaseURL = [baseURL URLByAppendingPathComponent:databaseName isDirectory:NO];
    
    return databaseURL.filePathURL.path;
}


- (YapDatabaseSerializer)databaseSerializer {
    // This is actually the default serializer.
    // We just included it here for completeness.
    YapDatabaseSerializer serializer = ^(NSString *collection, NSString *key, id object) {
        
        NSError *error = nil;
        
        return [NSKeyedArchiver archivedDataWithRootObject:object requiringSecureCoding:YES error:&error];
        
    };
    
    return serializer;
}

- (YapDatabaseDeserializer)databaseDeserializer {
    // Pretty much the default serializer,
    // but it also ensures that objects coming out of the database are immutable.
    YapDatabaseDeserializer deserializer = ^(NSString *collection, NSString *key, NSData *data) {
        
        id object = [NSKeyedUnarchiver unarchivedObjectOfClass:FeedItem.class fromData:data error:nil];
        
        return object;
    };
    
    return deserializer;
}

- (YapDatabasePreSanitizer)databasePreSanitizer {
    YapDatabasePreSanitizer preSanitizer = ^(NSString *collection, NSString *key, id object){
        
//        if ([object isKindOfClass:[MyDatabaseObject class]])
//        {
//            [object makeImmutable];
//        }
        
        return object;
    };
    
    return preSanitizer;
}

- (YapDatabasePostSanitizer)databasePostSanitizer {
    YapDatabasePostSanitizer postSanitizer = ^(NSString *collection, NSString *key, id object) {
        
//        if ([object isKindOfClass:[MyDatabaseObject class]])
//        {
//            [object clearChangedProperties];
//        }
    };
    
    return postSanitizer;
}

- (void)setupDatabase {
    
    NSString *databasePath = [self databasePath];
    DDLogVerbose(@"databasePath: %@", databasePath);
    
    // Configure custom class mappings for NSCoding.
    // In a previous version of the app, the "MyTodo" class was named "MyTodoItem".
    // We renamed the class in a recent version.
    
    [NSKeyedUnarchiver setClass:FeedItem.class forClassName:@"FeedItem"];
    
    // Create the database
    if (_database == nil) {
        _database = [[YapDatabase alloc] initWithPath:databasePath
           serializer:[self databaseSerializer]
         deserializer:[self databaseDeserializer]
         preSanitizer:[self databasePreSanitizer]
        postSanitizer:[self databasePostSanitizer]
              options:nil];
    }
    
    // Setup database connection(s)
    
    if (_uiConnection == nil) {
        
        self->_uiConnection = [self->_database newConnection];
        self->_uiConnection.objectCacheLimit = 400;
        self->_uiConnection.metadataCacheEnabled = NO;
        
        // Start the longLivedReadTransaction on the UI connection.
        [self->_uiConnection enableExceptionsForImplicitlyEndingLongLivedReadTransaction];
        [self->_uiConnection beginLongLivedReadTransaction];
        
        [self loadBookmarks];
        
    }
    
    if (_bgConnection == nil) {
        
        dispatch_async(self.bgQueue, ^{
            self->_bgConnection = [self->_database newConnection];
            self->_bgConnection.objectCacheLimit = 400;
            self->_bgConnection.metadataCacheEnabled = NO;
        });
        
    }
            
    //        [[NSNotificationCenter defaultCenter] addObserver:self
    //                                                 selector:@selector(yapDatabaseModified:)
    //                                                     name:YapDatabaseModifiedNotification
    //                                                   object:_database];
}

#pragma mark - Notifications

- (void)yapDatabaseModified:(NSNotification *)ignored {
    // Notify observers we're about to update the database connection
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BookmarksWillUpdateNotification
                                                        object:self];
    
    // Move uiDatabaseConnection to the latest commit.
    // Do so atomically, and fetch all the notifications for each commit we jump.
    
    NSArray *notifications = [self.uiConnection beginLongLivedReadTransaction];
    
    // Notify observers that the uiDatabaseConnection was updated
    
    NSDictionary *userInfo = @{@"notifications" : notifications};
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BookmarksDidUpdateNotification
                                                        object:self
                                                      userInfo:userInfo];
}

@end
