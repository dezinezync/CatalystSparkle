//
//  BookmarksManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 23/09/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "BookmarksManager.h"
#import <DZKit/NSArray+RZArrayCandy.h>

@interface BookmarksObserver : NSObject

@property (nonatomic, weak) id object;
@property (nonatomic, copy) NSNotificationName notificationName;
@property (nonatomic, copy, nonnull) void(^callback)(void);

@end

@implementation BookmarksObserver

- (BOOL)isEqual:(id)object {
    
    if (object == nil) {
        return NO;
    }
    
    if ([object isKindOfClass:BookmarksObserver.class] == NO) {
        return NO;
    }
    
    if (object == self) {
        return YES;
    }
    
    if (([(BookmarksObserver *)object object] == self.object)
        && ([[(BookmarksObserver *)object notificationName] isEqualToString:self.notificationName])) {
        return YES;
    }
    
    return NO;
    
}

@end

NSErrorDomain const BookmarksManagerErrorDomain = @"error.bookmarksManager";
NSNotificationName const BookmarksWillUpdateNotification = @"com.elytra.note.bookmarksupdating";
NSNotificationName const BookmarksDidUpdateNotification = @"com.elytra.note.bookmarksupdated";

#define kBookmarksCollection @"bookmarks"

@interface BookmarksManager () {
    NSArray <FeedItem *> *_bookmarks;
}

@property (nonatomic, assign, readwrite) NSUInteger bookmarksCount;

@property (nonatomic, strong) dispatch_queue_t bgQueue;

@property (nonatomic, strong) NSMutableArray *observers;

@end

@implementation BookmarksManager

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.observers = [NSMutableArray new];
        self.bgQueue = dispatch_queue_create("com.elytra.bookmarks.bg", DISPATCH_QUEUE_SERIAL);
        
        [self setupDatabase];
        
    }
    
    return self;
    
}

- (void)addBookmark:(FeedItem *)bookmark completion:(void (^)(BOOL))completion {
    
    NSLogDebug(@"Removing bookmark: %@", bookmark.identifier);
    
    dispatch_async(self.bgQueue, ^{
       
        [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            
            id existing = [transaction objectForKey:bookmark.identifier.stringValue inCollection:kBookmarksCollection];
            
            if (existing) {
                
                bookmark.bookmarked = YES;
                
                if (completion) { dispatch_async(dispatch_get_main_queue(), ^{
                    completion(YES);
                }); }
                
                return;
            }
           
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
    
    NSLogDebug(@"Removing bookmark: %@", bookmark.identifier);
    
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

- (void)removeBookmarkForID:(NSNumber *)articleID completion:(void (^)(BOOL))completion {
    
    dispatch_async(self.bgQueue, ^{
        
        FeedItem * existing = [self.bookmarks rz_reduce:^id(FeedItem *prev, FeedItem *current, NSUInteger idx, NSArray *array) {
           
            if ([current.identifier isEqualToNumber:articleID] == YES) {
                return current;
            }
            
            return prev;
            
        }];
        
        if (existing != nil) {
            [self removeBookmark:existing completion:completion];
        }
        else {
            
            if (completion) { dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES);
            }); }
            
        }
        
    });
    
}

- (void)_removeAllBookmarks:(void (^)(BOOL))completion {
    
    dispatch_async(self.bgQueue, ^{
        
        [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
           
            NSArray <NSString *> *keys = [transaction allKeysInCollection:kBookmarksCollection];
            
            for (NSString *key in keys) {
                [transaction removeObjectForKey:key inCollection:kBookmarksCollection];
            }
            
            self.bookmarks = @[];
            
            if (completion) { dispatch_async(dispatch_get_main_queue(), ^{
                completion(YES);
            }); }
            
        }];
        
    });
    
}

#pragma mark - Internal

- (void)loadBookmarks {
    
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
       
        NSArray <NSString *> *keys = [transaction allKeysInCollection:kBookmarksCollection];
        
        self.bookmarksCount = keys.count;
        
    }];
    
}

- (NSArray <FeedItem *> *)bookmarks {
 
    if (_bookmarks == nil) {
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
            
            NSSortDescriptor *dateDesc = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
            
            bookmarks = (NSMutableArray *)[bookmarks sortedArrayUsingDescriptors:@[dateDesc]];
            
        }
        
        _bookmarks = bookmarks ?: @[];
    }
    
    return _bookmarks;
    
}

#pragma mark - Setters

- (void)setBookmarks:(NSArray<FeedItem *> *)bookmarks {
    
    if (NSThread.isMainThread == NO) {
        [self performSelectorOnMainThread:@selector(setBookmarks:) withObject:bookmarks waitUntilDone:NO];
        return;
    }
    
    if (self == nil) {
        return;
    }
    
    if (self->_migrating == NO) {
        [self postNotification:BookmarksWillUpdateNotification object:nil];
    }
    
    self->_bookmarks = bookmarks;
    self.bookmarksCount = bookmarks.count;
    
    if (self->_migrating == NO) {
        [self postNotification:BookmarksDidUpdateNotification object:nil];
    }
    
}

#pragma mark - Database

- (NSString *)databasePath {
    NSString *databaseName = [NSString stringWithFormat:@"bookmarks-elytra.sqlite"];
    
#ifdef DEBUG
    databaseName = [NSString stringWithFormat:@"bookmarks-elytra-debug.sqlite"];
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
    NSLog(@"databasePath: %@", databasePath);
    
    // Configure custom class mappings for NSCoding.
    // In a previous version of the app, the "MyTodo" class was named "MyTodoItem".
    // We renamed the class in a recent version.
    
    [NSKeyedUnarchiver setClass:FeedItem.class forClassName:@"FeedItem"];
    
    // Create the database
    if (_database == nil) {
        
        _database = [[YapDatabase alloc] initWithURL:[NSURL fileURLWithPath:databasePath]];
        [_database registerDefaultSerializer:[self databaseSerializer]];
        [_database registerDefaultDeserializer:[self databaseDeserializer]];
        [_database registerDefaultPreSanitizer:[self databasePreSanitizer]];
        [_database registerDefaultPostSanitizer:[self databasePostSanitizer]];

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

#pragma mark - Observers

- (void)addObserver:(id)object name:(NSNotificationName)name callback:(void (^)(void))callback {
    
    BookmarksObserver *instance = [BookmarksObserver new];
    instance.object = object;
    instance.callback = [callback copy];
    instance.notificationName = name;
    
    NSUInteger index = [self.observers indexOfObject:instance];
    
    if (index == NSNotFound) {
        [self.observers addObject:instance];
    }
    else {
        instance = nil;
    }
    
}

- (void)removeObserver:(id)object name:(NSNotificationName)name {
    
    BookmarksObserver *instance = [BookmarksObserver new];
    instance.object = object;
    instance.notificationName = name;
    
    NSUInteger index = [self.observers indexOfObject:instance];
    
    if (index != NSNotFound) {
        [self.observers removeObjectAtIndex:index];
    }
    
}

- (void)postNotification:(NSNotificationName)name object:(id)obj {
    
    for (BookmarksObserver *obs in self.observers) {
        
        if ([obs.notificationName isEqualToString:name]) {
            obs.callback();
        }
        
    }
    
}

@end
