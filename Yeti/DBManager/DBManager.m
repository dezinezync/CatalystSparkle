//
//  DBManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 03/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DBManager+CloudCore.h"

#import "Feed.h"

DBManager *MyDBManager;

NSNotificationName const UIDatabaseConnectionWillUpdateNotification = @"UIDatabaseConnectionWillUpdateNotification";
NSNotificationName const UIDatabaseConnectionDidUpdateNotification  = @"UIDatabaseConnectionDidUpdateNotification";
NSString *const kNotificationsKey = @"notifications";

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
