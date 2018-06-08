//
//  FeedsManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsManager+KVS.h"
#import "FeedItem.h"
#import <DZKit/NSString+Extras.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#ifndef DDLogError
#import <DZKit/DZLogger.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#endif

FeedsManager * _Nonnull MyFeedsManager = nil;

FMNotification _Nonnull const FeedDidUpReadCount = @"com.yeti.note.feedDidUpdateReadCount";
FMNotification _Nonnull const FeedsDidUpdate = @"com.yeti.note.feedsDidUpdate";
FMNotification _Nonnull const UserDidUpdate = @"com.yeti.note.userDidUpdate";
FMNotification _Nonnull const BookmarksDidUpdate = @"com.yeti.note.bookmarksDidUpdate";
FMNotification _Nonnull const SubscribedToFeed = @"com.yeti.note.subscribedToFeed";

#ifdef SHARE_EXTENSION
@interface FeedsManager () {
    NSString *_feedsCachePath;
}
#else
@interface FeedsManager () <YTUserDelegate> {
    NSString *_feedsCachePath;
}
#endif

@property (nonatomic, strong, readwrite) DZURLSession *session, *backgroundSession;
#ifndef SHARE_EXTENSION
@property (nonatomic, strong, readwrite) YTUserID *userIDManager;
@property (nonatomic, strong, readwrite) Subscription *subscription;
#endif
@end

@implementation FeedsManager

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MyFeedsManager = [[FeedsManager alloc] init];
    });
}

#pragma mark -

- (instancetype)init
{
    if (self = [super init]) {
        
        self->kPushTokenFilePath = [@"~/Documents/push.dat" stringByExpandingTildeInPath];
        
#ifndef SHARE_EXTENSION
        self.userIDManager = [[YTUserID alloc] initWithDelegate:self];
        DDLogWarn(@"%@", MyFeedsManager.bookmarks);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateBookmarks:) name:BookmarksDidUpdate object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidUpdate) name:UserDidUpdate object:nil];
        
        NSError *error = nil;
        _pushToken = [[NSString alloc] initWithContentsOfFile:self->kPushTokenFilePath encoding:NSUTF8StringEncoding error:&error];
        
        if (error) {
            DDLogError(@"Error loading push token from disk: %@", error.localizedDescription);
        }
#endif
    }
    
    return self;
}

- (NSNumber *)userID
{
#ifndef SHARE_EXTENSION
    return self.userIDManager.userID;
#else
    return nil;
#endif
}

#pragma mark - Feeds

- (void)getFeedsSince:(NSDate *)since success:(successBlock)successCB error:(errorBlock)errorCB
{
    weakify(self);
    
    NSString *docsDir;
    NSArray *dirPaths;
    
    if (MyFeedsManager.userID == nil) {
        // if the following error is thrown, it casues an undesirable user experience.
//        if (errorCB) {
//            NSError *error = [NSError errorWithDomain:@"FeedManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"No user account present."}];
//            errorCB(error, nil, nil);
//        }
        if (errorCB)
            errorCB(nil, nil, nil);
        return;
    }
    
    if (!_feedsCachePath) {
        dirPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        docsDir = [dirPaths objectAtIndex:0];
        
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
        NSString *filename = formattedString(@"feedscache-%@.json", buildNumber);
        
        NSString *path = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:filename]];
        
#ifdef DEBUG
        path = [path stringByAppendingString:@".debug"];
#endif
        
        _feedsCachePath = path;
    }
    
    __block NSError *error = nil;
    
    if ([NSFileManager.defaultManager fileExistsAtPath:_feedsCachePath]) {
        
        weakify(self);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
           
            strongify(self);
            
            NSData *data = [NSData dataWithContentsOfFile:self->_feedsCachePath];
            
            if (data) {
                NSArray *responseObject;
                
                @try {
                    responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
                }
                @catch (NSException *exc) {
                    responseObject = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                }
                // non-json error.
                if (error && error.code == 3840) {
                    responseObject = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                    error = nil;
                }
                
                if (error) {
                    DDLogError(@"%@", error);
                    if (errorCB)
                        errorCB(error, nil, nil);
                }
                else if (successCB) {
                    DDLogDebug(@"Responding to successCB from disk cache");
                    NSArray <Feed *> * feeds = [responseObject isKindOfClass:NSArray.class] ? responseObject : [self parseFeedResponse:responseObject];
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5  * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        MyFeedsManager->_feeds = feeds;
                        
                        asyncMain(^{
                            successCB(@1, nil, nil);
                        });
                    });
                }
            }
            
            data = nil;
            
        });
    }
    
    NSDictionary *params = @{@"userID": MyFeedsManager.userID};
    
    // only consider this param when we have feeds
    if (since && MyFeedsManager.feeds.count) {
        
        if ([NSDate.date timeIntervalSinceDate:since] < 3600) {
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"YYYY/MM/dd HH:mm:ss";
            
            params = @{
                       @"userID": MyFeedsManager.userID,
                       @"since": [formatter stringFromDate:since]
                       };
            
        }
    }
    
    [self.session GET:@"/feeds" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        strongify(self);
        
        NSArray <Feed *> * feeds = [self parseFeedResponse:responseObject];
        
        if (!since || !MyFeedsManager.feeds.count) {
            MyFeedsManager.feeds = feeds;
            
            // cache it
            weakify(self);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                strongify(self);
                NSError *error = nil;
                NSData *data = [NSJSONSerialization dataWithJSONObject:responseObject options:kNilOptions error:&error];
                
                if (error) {
                    DDLogError(@"Error caching feeds: %@", error);
                }
                else {
                    if (![data writeToFile:self->_feedsCachePath atomically:YES]) {
                        DDLogError(@"Writing feeds cache to %@ failed.", self->_feedsCachePath);
                    }
                }
            });
        }
        else {

            if (feeds.count) {

                NSArray <Feed *> *copy = [MyFeedsManager.feeds copy];

                for (Feed *feed in feeds) {
                    // get the corresponding feed from the memory
                    Feed *main = [MyFeedsManager.feeds rz_reduce:^id(Feed *prev, Feed *current, NSUInteger idx, NSArray *array) {
                        if (current.feedID.integerValue == feed.feedID.integerValue)
                            return current;
                        return prev;
                    }];

                    if (!main) {
                        // this is a new feed
                        copy = [copy arrayByAddingObject:feed];
                    }
                    else {
                        NSArray <FeedItem *> *newItems = [feed.articles rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                           
                            NSUInteger identifier = obj.identifier.integerValue;
                            
                            FeedItem *existing = [main.articles rz_reduce:^id(FeedItem *prev, FeedItem *current, NSUInteger idx, NSArray *array) {
                                return current.identifier.integerValue == identifier ? current : prev;
                            }];
                            
                            return existing == nil;
                            
                        }];
                        
                        // add the new articles. We add main's article to feed so the order remains in reverse-chrono
                        main.articles = [newItems arrayByAddingObjectsFromArray:main.articles];
                    }
                }

                @synchronized(self) {
                    MyFeedsManager.feeds = feeds;
                }
            }
            else {
                MyFeedsManager.feeds = feeds;
            }

        }
        
        if (successCB) {
            DDLogDebug(@"Responding to successCB from network");
            asyncMain(^{
                successCB(@2, response, task);
            });
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
}

- (NSArray <Feed *> *)parseFeedResponse:(NSArray <NSDictionary *> *)responseObject {
    NSMutableArray <Feed *> *feeds = [[[responseObject valueForKey:@"feeds"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
        return [Feed instanceFromDictionary:obj];
    }] mutableCopy];
    
    NSDictionary *foldersStruct = [responseObject valueForKey:@"struct"];
    
    // these feeds are inside folders
    NSArray <NSNumber *> *feedIDsInFolders = [foldersStruct valueForKey:@"feeds"];
    
    NSMutableArray <Feed *> *feedsInFolders = [NSMutableArray arrayWithCapacity:feedIDsInFolders.count];
    
    feeds = [feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
       
        if ([feedIDsInFolders indexOfObject:obj.feedID] != NSNotFound) {
            [feedsInFolders addObject:obj.copy];
            
            return NO;
        }
        
        return YES;
        
    }].mutableCopy;
    
    // create the folders map
    NSArray <Folder *> *folders = [[foldersStruct valueForKey:@"folders"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
       
        Folder *folder = [Folder instanceFromDictionary:obj];
        
        NSArray *feedIDs = [folder feeds];
        
        folder.feeds = [feedsInFolders rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
            BOOL inside = [feedIDs indexOfObject:obj.feedID] != NSNotFound;
            
            if (inside) {
                obj.folderID = folder.folderID;
            }
            
            return inside;
        }];
        
        return folder;
        
    }];
    
    _folders = folders;
    
    return feeds;
}

- (Feed *)feedForID:(NSNumber *)feedID
{
    
    __block Feed *feed = [MyFeedsManager.feeds rz_reduce:^id(Feed *prev, Feed *current, NSUInteger idx, NSArray *array) {
        if ([current.feedID isEqualToNumber:feedID])
            return current;
        return prev;
    }];
    
    if (!feed) {
        // check in folders
        
        [MyFeedsManager.folders enumerateObjectsUsingBlock:^(Folder * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            [obj.feeds enumerateObjectsUsingBlock:^(Feed *  _Nonnull objx, NSUInteger idxx, BOOL * _Nonnull stopx) {
               
                if ([objx.feedID isEqualToNumber:feedID]) {
                    feed = objx;
                    *stopx = YES;
                    *stop = YES;
                }
                
            }];
            
        }];
        
    }
    
    return feed;
}

- (void)getFeed:(Feed *)feed page:(NSInteger)page success:(successBlock)successCB error:(errorBlock)errorCB
{
    if (!page)
        page = 1;
    
    NSMutableDictionary *params = @{@"page": @(page)}.mutableCopy;
    
    if ([self userID] != nil) {
        params[@"userID"] = MyFeedsManager.userID;
    }
    
    [self.session GET:formattedString(@"/feeds/%@", feed.feedID) parameters:params success:^(NSDictionary * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSArray <NSDictionary *> * articles = [responseObject valueForKey:@"articles"];
        
        NSArray <FeedItem *> *items = [articles rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        if (feed)
            feed.articles = [feed.articles arrayByAddingObjectsFromArray:items];
        
        if (successCB)
            successCB(items, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
}

- (void)addFeed:(NSURL *)url success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    NSArray <Feed *> *existing = [MyFeedsManager.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
        return [obj.url isEqualToString:url.absoluteString];
    }];
    
    if (existing.count) {
        if (errorCB) {
            errorCB([NSError errorWithDomain:@"FeedsManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"You already have this feed in your list."}], nil, nil);
        }
        
        return;
    }
    
    NSDictionary *params = @{@"URL" : url};
    if ([self userID] != nil) {
        params = @{@"URL": url, @"userID": [self userID]};
    }
    
    [MyFeedsManager.session PUT:@"/feed" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if ([response statusCode] == 300) {
            
            if (successCB) {
                successCB(responseObject, response, task);
            }
            
            return;
            
        }
        else if ([response statusCode] == 302) {
            // feed already exists.
            
            NSURL *reroute = [[response allHeaderFields] valueForKey:@"Location"];
            
            if ([reroute isMemberOfClass:NSString.class]) {
                reroute = [NSURL URLWithString:(NSString *)reroute];
            }
            
            NSNumber *feedID = @([[reroute lastPathComponent] integerValue]);
            
#ifdef SHARE_EXTENSION
            if (successCB)
                successCB(feedID, response, task);
#else
            [self addFeedByID:feedID success:successCB error:errorCB];
#endif
            
            return;
            
        }
        else if ([response statusCode] == 304) {
            // feed already exists in the user's list
            
            if (errorCB) {
                NSError *error = [NSError errorWithDomain:@"FeedsManager" code:304 userInfo:@{NSLocalizedDescriptionKey: @"The feed already exists in your list."}];
                
                errorCB(error, response, task);
            }
            
            return;
        }
        
        NSDictionary *feedObj = [responseObject valueForKey:@"feed"];
        NSArray *articlesObj = [responseObject valueForKey:@"articles"];
        
        NSArray <FeedItem *> *articles = [articlesObj rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        Feed *feed = [Feed instanceFromDictionary:feedObj];
        feed.articles = articles;
        
        if (successCB)
            successCB(feed, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
}

- (void)addFeedByID:(NSNumber *)feedID success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSArray <Feed *> *existing = [MyFeedsManager.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
        return obj.feedID.integerValue == feedID.integerValue;
    }];
    
    if (existing.count) {
        if (errorCB) {
            errorCB([NSError errorWithDomain:@"FeedsManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"You already have this feed in your list."}], nil, nil);
        }
        
        return;
    }
    
    NSDictionary *params = @{@"feedID" : feedID};
    if ([MyFeedsManager userID] != nil) {
        params = @{@"feedID": feedID, @"userID": [self userID]};
    }
    
    [MyFeedsManager.session PUT:@"/feed" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
    
        NSDictionary *feedObj = [responseObject valueForKey:@"feed"] ?: responseObject;
        NSArray *articlesObj = [responseObject valueForKey:@"articles"];
        
        NSArray <FeedItem *> *articles = [articlesObj rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        Feed *feed = [Feed instanceFromDictionary:feedObj];
        feed.articles = articles;
        
        if (successCB)
            successCB(feed, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
    
}

- (void)getArticle:(NSNumber *)articleID success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSString *path = formattedString(@"/article/%@", articleID);
    
    [self.backgroundSession GET:path parameters:@{@"userID" : MyFeedsManager.userID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (successCB) {
            
            FeedItem *item = [FeedItem instanceFromDictionary:responseObject];
            
            successCB(item, response, task);
            
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

- (void)articlesByAuthor:(NSNumber *)authorID feedID:(NSNumber *)feedID page:(NSInteger)page success:(successBlock)successCB error:(errorBlock)errorCB
{
    if ([self userID] != nil) {
        if (errorCB) {
            errorCB(nil, nil, nil);
        }
        
        return;
    }
    
    NSString *path = formattedString(@"/feeds/%@/author/%@", feedID, authorID);
    
    if (!page)
        page = 1;
    
    NSDictionary *params = @{
                             @"userID": [self userID],
                             @"page": @(page)
                             };
    
    [self.session GET:path parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (!successCB)
            return;
        // we don't need this object
//        NSDictionary *feedObj = [responseObject valueForKey:@"feed"];
        NSArray <NSDictionary *> *articlesArr = [responseObject valueForKey:@"articles"];
        
        NSArray <FeedItem *> *articles = [articlesArr rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        successCB(articles, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
        
    }];
}

#ifndef SHARE_EXTENSION

- (void)removeFeed:(NSNumber *)feedID success:(successBlock)successCB error:(errorBlock)errorCB
{
    NSDictionary *params = @{};
    if ([self userID] != nil) {
        params = @{@"userID": [self userID]};
    }
    
    [self.session DELETE:formattedString(@"/feeds/%@", feedID) parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (response.statusCode != 304) {
            if (successCB) {
                successCB(responseObject, response, task);
            }
            
            return;
        }
        
        if (errorCB) {
            NSError *error = [NSError errorWithDomain:@"FeedsManager" code:response.statusCode userInfo:@{NSLocalizedDescriptionKey : @"The feed does not exist or has already been removed from your list."}];
            errorCB(error, response, task);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
}

#pragma mark - Custom Feeds

- (void)updateUnreadArray
{
    NSMutableArray <NSNumber *> * markedRead = @[].mutableCopy;
    
    NSArray <FeedItem *> *newUnread = [MyFeedsManager.unread rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
        BOOL isRead = obj.isRead;
        if (isRead) {
            [markedRead addObject:obj.identifier];
        }
        return !isRead;
    }];
    
    if (!markedRead.count)
        return;
    
    _unread = newUnread;
    
    // propagate changes to the feeds object as well
    [self updateFeedsReadCount:MyFeedsManager.feeds markedRead:markedRead];
    
    for (Folder *folder in MyFeedsManager.folders) { @autoreleasepool {
       
        [self updateFeedsReadCount:folder.feeds markedRead:markedRead];
        
    } }
    
}

- (void)updateFeedsReadCount:(NSArray <Feed *> *)feeds markedRead:(NSArray <NSNumber *> *)markedRead {
    if (!feeds || feeds.count == 0)
        return;
    
    for (Feed *obj in feeds) { @autoreleasepool {
        
        BOOL marked = NO;
        
        for (FeedItem *item in obj.articles) {
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF == %d", item.identifier.integerValue];
            NSArray *filteredArray = [markedRead filteredArrayUsingPredicate:predicate];
            DDLogDebug(@"Index: %@", filteredArray);
            
            if (filteredArray.count > 0 && !item.read) {
                item.read = YES;
                
                if (!marked)
                    marked = YES;
            }
        }
        
        if (marked) {
            [[NSNotificationCenter defaultCenter] postNotificationName:FeedDidUpReadCount object:obj.feedID];
        }
        
    }}
}

- (void)getUnreadForPage:(NSInteger)page success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    if ([self userID] == nil) {
        if (errorCB)
            errorCB(nil, nil, nil);
        
        return;
    }
    
    weakify(self);
    
    [self.session GET:@"/unread" parameters:@{@"userID": MyFeedsManager.userID, @"page": @(page), @"limit": @10} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        NSArray <FeedItem *> * items = [[responseObject valueForKey:@"articles"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        strongify(self);
        
        if (page == 1) {
            MyFeedsManager.unread = items;
        }
        else {
            if (!MyFeedsManager.unread) {
                MyFeedsManager.unread = items;
            }
            else {
                NSArray *prefiltered = [MyFeedsManager.unread rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                    return !obj.isRead;
                }];
                
                @try {
                    MyFeedsManager.unread = [prefiltered arrayByAddingObjectsFromArray:items];
                }
                @catch (NSException *exc) {}
            }
        }
        // the conditional takes care of filtered article items.
        MyFeedsManager.totalUnread = MyFeedsManager.unread.count > 0 ? [[responseObject valueForKey:@"total"] integerValue] : 0;
        
        if (successCB)
            successCB(responseObject, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
}

- (void)getBookmarksWithSuccess:(successBlock)successCB error:(errorBlock)errorCB
{
    
    NSString *existing = @"";
    
    if (MyFeedsManager.bookmarks.count) {
        existing = [[MyFeedsManager.bookmarks rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
            return obj.identifier.stringValue;
        }] componentsJoinedByString:@","];
    }
    
    [self.session POST:formattedString(@"/bookmarked?userID=%@", MyFeedsManager.userID) parameters:@{@"existing": existing} success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
}

#pragma mark - Folders

- (void)addFolder:(NSString *)title success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    weakify(self);
    
    [self.session PUT:@"/folder" queryParams:@{@"userID": [self userID]} parameters:@{@"title": title} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        id retval = [responseObject valueForKey:@"folder"];
        
        Folder *instance = [Folder instanceFromDictionary:retval];
        
        strongify(self);
        
        MyFeedsManager.folders = [MyFeedsManager.folders arrayByAddingObject:instance];
        
        if (successCB)
            successCB(instance, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
}

- (void)renameFolder:(NSNumber *)folderID to:(NSString *)title success:(successBlock)successCB error:(errorBlock)errorCB
{
    weakify(self);
    
    [self updateFolder:folderID properties:@{@"title": title} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        BOOL status = [[responseObject valueForKey:@"status"] boolValue];
        
        if (!status) {
            if (errorCB) {
                NSError *error = [NSError errorWithDomain:@"TTKit" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Failed to update the folder title. Please try again."}];
                errorCB(error, response, task);
            }
            return;
        }
      
        strongify(self);
        
        // update our caches
        [MyFeedsManager.folders enumerateObjectsUsingBlock:^(Folder * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            if ([obj.folderID isEqualToNumber:folderID]) {
                obj.title = title;
                *stop = YES;
            }
            
        }];
        
        // this will fire the notification
        MyFeedsManager.folders = [self folders];
        
        if (successCB) {
            successCB(responseObject, response, task);
        }
        
    } error:errorCB];
}

- (void)updateFolder:(NSNumber *)folderID add:(NSArray<NSNumber *> *)add remove:(NSArray<NSNumber *> *)del success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    NSMutableDictionary *dict = @{}.mutableCopy;
    
    if (add && add.count) {
        
        NSArray <NSString *> * toAdd = [add rz_map:^id(NSNumber *obj, NSUInteger idx, NSArray *array) {
            return formattedString(@"s:%@", obj);
        }];
        
        [dict setObject:toAdd forKey:@"add"];
    }
    
    if (del && del.count) {
        
        NSArray <NSString *> * toDel = [del rz_map:^id(NSNumber *obj, NSUInteger idx, NSArray *array) {
            return formattedString(@"s:%@", obj);
        }];
        
        [dict setObject:toDel forKey:@"del"];
    }
    
    weakify(self);
    
    [self updateFolder:folderID properties:dict.copy success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        BOOL status = [[responseObject valueForKey:@"status"] boolValue];
        
        if (!status) {
            if (errorCB) {
                NSError *error = [NSError errorWithDomain:@"TTKit" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Failed to update the folder preferences. Please try again."}];
                errorCB(error, response, task);
            }
            return;
        }
        
        strongify(self);
        
        Folder *folder = [MyFeedsManager.folders rz_reduce:^id(Folder *prev, Folder *current, NSUInteger idx, NSArray *array) {
            if ([current.folderID isEqualToNumber:folderID])
                return current;
            return prev;
        }];
        
        // check delete ops first
        if (del && del.count) {
            NSArray <Feed *> * removedFeeds = [folder.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                return [del indexOfObject:obj.feedID] != NSNotFound;
            }];
            
            [removedFeeds enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.folderID = nil;
            }];
            
            folder.feeds = [folder.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                return [del indexOfObject:obj.feedID] == NSNotFound;
            }];
            
            MyFeedsManager.feeds = [MyFeedsManager.feeds arrayByAddingObjectsFromArray:removedFeeds];
        }
        
        // now run add ops
        if (add && add.count) {
            NSArray <Feed *> * addedFeeds = [MyFeedsManager.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                return [add indexOfObject:obj.feedID] != NSNotFound;
            }];
            
            [addedFeeds enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.folderID = folderID;
            }];
            
            MyFeedsManager.feeds = [MyFeedsManager.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                return [add indexOfObject:obj.feedID] == NSNotFound;
            }];
            
            folder.feeds = [folder.feeds arrayByAddingObjectsFromArray:addedFeeds];
        }
        
        if (successCB) {
            successCB(responseObject, response, task);
        }
        
    } error:errorCB];
}

- (void)removeFolder:(NSNumber *)folderID success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSString *path = formattedString(@"/folder?userID=%@&folderID=%@", [self userID], folderID);
    
    [self.session DELETE:path parameters:nil success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
    
}

- (void)updateFolder:(NSNumber *)folderID properties:(NSDictionary *)props success:(successBlock)successCB error:(errorBlock)errorCB {
    
    if (![props valueForKey:@"folderID"]) {
        NSMutableDictionary *temp = props.mutableCopy;
        
        [temp setValue:folderID forKey:@"folderID"];
        
        props = temp.copy;
    }
    
    [self.session POST:@"/folder" queryParams:@{@"userID": [self userID]} parameters:props success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
    
}

#endif

#pragma mark - Filters

- (void)getFiltersWithSuccess:(successBlock)successCB error:(errorBlock)errorCB
{
    [self.session GET:@"/user/filters" parameters:@{@"userID": [self userID]} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSArray <NSString *> *filters = [responseObject valueForKey:@"filters"];
        
        if (successCB) {
            successCB(filters, response, task);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
}

- (void)addFilter:(NSString *)word success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    [self.session PUT:@"/user/filters" queryParams:@{@"userID": [self userID]} parameters:@{@"word" : word} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        id retval = [responseObject valueForKey:@"status"];
        
        if (successCB)
            successCB(retval, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
    
}

- (void)removeFilter:(NSString *)word success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    [self.session DELETE:@"/user/filters" parameters:@{@"userID": [self userID], @"word": word} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        id retval = [responseObject valueForKey:@"status"];
        
        if (successCB)
            successCB(retval, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
    
}

#pragma mark - Subscriptions

- (void)addPushToken:(NSString *)token success:(successBlock)successCB error:(errorBlock)errorCB
{
    [self.session PUT:@"/user/token" queryParams:@{@"userID": [self userID]} parameters:@{@"token": token} success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
        
    }];
}

- (void)subsribe:(Feed *)feed success:(successBlock)successCB error:(errorBlock)errorCB
{
    [self.session PUT:@"/user/subscriptions" queryParams:@{@"userID": [self userID], @"feedID": feed.feedID} parameters:@{} success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
        
    }];
}

- (void)unsubscribe:(Feed *)feed success:(successBlock)successCB error:(errorBlock)errorCB
{
    [self.session DELETE:@"/user/subscriptions" parameters:@{@"userID": [self userID], @"feedID": feed.feedID} success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
        
    }];
}

#pragma mark - Store

- (void)postAppReceipt:(NSData *)receipt success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSString *receiptString = [receipt base64EncodedStringWithOptions:0];
    
    weakify(self);
    
    [self.session POST:@"/store" queryParams:@{@"userID": [self userID]} parameters:@{@"receipt": receiptString} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        strongify(self);
        
        [self _updateSubscriptionState];
        
        if (successCB) {
            successCB(responseObject, response, task);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

- (void)getOPMLWithSuccess:(successBlock)successCB error:(errorBlock)errorCB {
    
    [self.session GET:@"/user/opml" parameters:@{@"userID": [MyFeedsManager userID]} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSString *xmlData = [responseObject valueForKey:@"file"];
        
        if (successCB) {
            successCB(xmlData, response, task);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

- (void)getSubscriptionWithSuccess:(successBlock)successCB error:(errorBlock)errorCB {
    
    [self.session GET:@"/store" parameters:@{@"userID": [MyFeedsManager userID]} success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

#pragma mark - Setters

- (void)setPushToken:(NSString *)pushToken
{
    _pushToken = pushToken;
    
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSError *error = nil;
    
    if (_pushToken) {
        if (![_pushToken writeToFile:kPushTokenFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
            DDLogError(@"Error saving push token file: %@", error.localizedDescription);
        }
#ifndef SHARE_EXTENSION
        if (MyFeedsManager.subsribeAfterPushEnabled) {
            
            [self subsribe:MyFeedsManager.subsribeAfterPushEnabled success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                [[NSNotificationCenter defaultCenter] postNotificationName:SubscribedToFeed object:MyFeedsManager.subsribeAfterPushEnabled];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    MyFeedsManager.subsribeAfterPushEnabled = nil;
                });
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
               
                MyFeedsManager.subsribeAfterPushEnabled = nil;
                
                [AlertManager showGenericAlertWithTitle:@"Subscribe failed" message:error.localizedDescription];
                
            }];
            
        }
        
        [self addPushToken:_pushToken success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            DDLogDebug(@"added push token: %@", responseObject);
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            DDLogError(@"Add push token error: %@", error);
        }];
#endif
    }
    else {
        if (![manager removeItemAtPath:kPushTokenFilePath error:&error]) {
            DDLogError(@"Error removing push token file: %@", error.localizedDescription);
        }
    }
}

//- (void)setFeeds:(NSArray<Feed *> *)feeds
//{
//    _feeds = feeds ?: @[];
//    
//    [NSNotificationCenter.defaultCenter postNotificationName:FeedsDidUpdate object:MyFeedsManager userInfo:@{@"feeds" : self.feeds, @"folders": self.folders}];
//}
//
//- (void)setFolders:(NSArray<Folder *> *)folders
//{
//    _folders = folders ?: @[];
//    
//    [NSNotificationCenter.defaultCenter postNotificationName:FeedsDidUpdate object:MyFeedsManager userInfo:@{@"feeds" : self.feeds, @"folders": self.folders}];
//}
//
//- (void)setUnread:(NSArray<FeedItem *> *)unread {
//    
//    [self willChangeValueForKey:propSel(unread)];
//    
//    _unread = unread;
//    
//    [self didChangeValueForKey:propSel(unread)];
//    
//    [[NSNotificationCenter defaultCenter] postNotificationName:FeedDidUpReadCount object:nil];
//    
//}

#pragma mark - Getters

- (DZURLSession *)session
{
    if (!_session) {
        
        // Set app-wide shared cache (first number is megabyte value)
        NSUInteger cacheSizeMemory = 500*1024*1024; // 500 MB
        NSUInteger cacheSizeDisk = 500*1024*1024; // 500 MB
        NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:@"nsurlcache"];
        [NSURLCache setSharedURLCache:sharedCache];
        sleep(1);
//
        DZURLSession *session = [[DZURLSession alloc] init];

        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        defaultConfig.HTTPMaximumConnectionsPerHost = 5;
        defaultConfig.URLCache = sharedCache;
        [defaultConfig setHTTPAdditionalHeaders:@{
                                                  @"Accept": @"application/json",
                                                  @"Content-Type": @"application/json"
                                                  }];
        
        defaultConfig.allowsCellularAccess = YES;
        defaultConfig.HTTPShouldUsePipelining = YES;

        NSURLSession *sessionSession = [NSURLSession sessionWithConfiguration:defaultConfig delegate:(id<NSURLSessionDelegate>)session delegateQueue:[NSOperationQueue currentQueue]];

        [session setValue:sessionSession forKeyPath:@"session"];
        
        session.baseURL = [NSURL URLWithString:@"http://192.168.1.15:3000"];
//        session.baseURL =  [NSURL URLWithString:@"https://api.elytra.app"];
#ifndef DEBUG
        session.baseURL = [NSURL URLWithString:@"https://api.elytra.app"];
#endif
        session.useOMGUserAgent = YES;
        session.useActivityManager = YES;
        session.responseParser = [DZJSONResponseParser new];
        
        session.requestModifier = ^NSURLRequest *(NSURLRequest *request) {
          
            NSMutableURLRequest *mutableReq = request.mutableCopy;
            [mutableReq setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            
            return mutableReq;
            
        };
        
        _session = session;
    }
    
    return _session;
}

- (DZURLSession *)backgroundSession
{
    if (!_backgroundSession) {
        
        DZURLSession *session = [[DZURLSession alloc] init];
        
        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        // one for unread and the other for bookmarks
        defaultConfig.HTTPMaximumConnectionsPerHost = 2;
        // tell the OS not to manage these, but let them continue in the background
        defaultConfig.discretionary = NO;
        // we always want fresh data from the background service
        defaultConfig.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        defaultConfig.allowsCellularAccess = YES;
        defaultConfig.waitsForConnectivity = YES;
        defaultConfig.HTTPShouldUsePipelining = YES;
        
        [defaultConfig setHTTPAdditionalHeaders:@{
                                                  @"Accept": @"application/json",
                                                  @"Content-Type": @"application/json"
                                                  }];
        
        NSURLSession *sessionSession = [NSURLSession sessionWithConfiguration:defaultConfig delegate:(id<NSURLSessionDelegate>)session delegateQueue:[NSOperationQueue currentQueue]];
        
        [session setValue:sessionSession forKeyPath:@"session"];
        
        session.baseURL = self.session.baseURL;
        session.useOMGUserAgent = YES;
        session.useActivityManager = YES;
        session.responseParser = [DZJSONResponseParser new];
        
        session.requestModifier = ^NSURLRequest *(NSURLRequest *request) {
            
            NSMutableURLRequest *mutableReq = request.mutableCopy;
            [mutableReq setValue:@"application/json" forHTTPHeaderField:@"Accept"];
            
            return mutableReq;
            
        };
        
        _backgroundSession = session;
    }
    
    return _backgroundSession;
}

//#ifndef SHARE_EXTENSION
- (NSArray <FeedItem *> *)bookmarks {
    
    if (!_bookmarks) {
        
        NSFileManager *manager = [NSFileManager defaultManager];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
        NSString *directory = [documentsDirectory stringByAppendingPathComponent:@"bookmarks"];
        BOOL isDir;

        if (![manager fileExistsAtPath:directory isDirectory:&isDir]) {
            NSError *error = nil;
            if (![manager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&error]) {
                DDLogError(@"Error creating bookmarks directory: %@", error);
            }
        }

        NSDirectoryEnumerator *enumerator = [manager enumeratorAtPath:directory];
        NSArray *objects = enumerator.allObjects;
        DDLogDebug(@"Have %@ bookmarks", @(objects.count));

        NSMutableArray <FeedItem *> *bookmarkedItems = [NSMutableArray arrayWithCapacity:objects.count+1];

        for (NSString *path in objects) {
            NSString *filePath = [directory stringByAppendingPathComponent:path];
            FeedItem *item = nil;

            @try {
                item = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
            }
            @catch (NSException *exception) {
                DDLogWarn(@"Bookmark load exception: %@", exception);
            }

            if (item) {
                [bookmarkedItems addObject:item];
            }
        }

        [self setBookmarks:bookmarkedItems];
    }
    
    return _bookmarks;
    
}

- (void)setBookmarks:(NSArray<FeedItem *> *)bookmarks
{
    if (bookmarks) {
        NSArray <FeedItem *> *sorted = [bookmarks sortedArrayUsingSelector:@selector(compare:)];
        
        _bookmarks = sorted;
    }
    else {
        _bookmarks = bookmarks;
    }
}

//#endif

#pragma mark - Notifications

- (void)didUpdateBookmarks:(NSNotification *)note {
    
    FeedItem *item = [note object];
    
    if (!item) {
        DDLogWarn(@"A bookmark notification was posted but did not include a FeedItem object.");
        return;
    }
    
    BOOL isBookmarked = [[[note userInfo] valueForKey:@"bookmarked"] boolValue];
    
    if (isBookmarked) {
        // it was added
        @try {
            MyFeedsManager.bookmarks = [MyFeedsManager.bookmarks arrayByAddingObject:item];
        }
        @catch (NSException *exc) {}
    }
    else {
        NSInteger itemID = item.identifier.integerValue;
        
        @try {
            MyFeedsManager.bookmarks = [MyFeedsManager.bookmarks rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                return obj.identifier.integerValue != itemID;
            }];
        } @catch (NSException *excp) {}
    }
    
}

- (void)userDidUpdate {
    
    if ([self userID] == nil) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UserDidUpdate object:nil];
    
    weakify(self);
    // user ID can be nil at this point
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        strongify(self);
        [self updateBookmarksFromServer];
    });
    
    if (MyFeedsManager.userID) {
        
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        
        NSData *data = [[NSData alloc] initWithContentsOfURL:receiptURL];
        
        if (data) {
            [self postAppReceipt:data success:nil error:nil];
        }
        
    }
    
}

- (void)_updateSubscriptionState {
    if (!MyFeedsManager.userID)
        return;
    
    [self getSubscriptionWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
#ifndef SHARE_EXTENSION
        if ([[responseObject valueForKey:@"status"] boolValue]) {
            Subscription *sub = [Subscription instanceFromDictionary:[responseObject valueForKey:@"subscription"]];
            MyFeedsManager.subscription = sub;
        }
        else {
            Subscription *sub = [Subscription new];
            sub.error = [NSError errorWithDomain:@"Yeti" code:-200 userInfo:@{NSLocalizedDescriptionKey: [responseObject valueForKey:@"message"]}];
            
            MyFeedsManager.subscription = sub;
        }
#endif
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        DDLogError(@"Subscription Error: %@", error.localizedDescription);
#ifndef SHARE_EXTENSION
        Subscription *sub = [Subscription new];
        sub.error = error;
        
        MyFeedsManager.subscription = sub;
#endif
    }];
}

#pragma mark - <YTUserDelegate>

- (void)getUserInformation:(successBlock)successCB error:(errorBlock)errorCB
{
    weakify(self);
    
    NSDictionary *params;
    
    if (MyFeedsManager.userID != nil) {
        params = @{@"userID": MyFeedsManager.userID};
    }
#ifndef SHARE_EXTENSION
    else if ([MyFeedsManager userIDManager]->_UUID) {
        params = @{@"userID" : [MyFeedsManager.userIDManager UUIDString]};
    }
#else
    if (errorCB) {
        errorCB(nil, nil, nil);
    }
    return;
#endif
    [self.session GET:@"/user" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
     
        if (successCB) {
            successCB(responseObject, response, task);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        strongify(self);
        error = [self errorFromResponse:error.userInfo];
        
        if (error) {
            if (errorCB)
                errorCB(error, response, task);
            else {
                DDLogError(@"Unhandled network error: %@", error);
            }
        }
    }];
    
}

#ifndef SHARE_EXTENSION

- (void)updateUserInformation:(successBlock)successCB error:(errorBlock)errorCB
{
    if (!MyFeedsManager.userIDManager.UUID) {
        if (errorCB) {
            NSError *error = [NSError errorWithDomain:@"FeedManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"No user ID currently present"}];
            errorCB(error, nil, nil);
        }
        
        return;
    }
    
    [self.session PUT:@"/user" parameters:@{@"uuid": MyFeedsManager.userIDManager.UUIDString} success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
}

- (void)getUserInformationFor:(NSString *)uuid success:(successBlock)successCB error:(errorBlock)errorCB
{
    if (!uuid || [uuid isBlank]) {
        if (errorCB) {
            NSError *error = [NSError errorWithDomain:@"FeedManager" code:-10 userInfo:@{NSLocalizedDescriptionKey: @"Please provide a valid UUID to fetch."}];
            
            errorCB(error, nil, nil);
        }
        
        return;
    }
    
    NSDictionary *params = @{@"userID": uuid};
    
    weakify(self);
    
    [self.session GET:@"/user" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (successCB) {
            successCB(responseObject, response, task);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        strongify(self);
        error = [self errorFromResponse:error.userInfo];
        
        if (error) {
            if (errorCB)
                errorCB(error, response, task);
            else {
                DDLogError(@"Unhandled network error: %@", error);
            }
        }
    }];
}

#endif

#pragma mark - Error Handler

- (NSError *)errorFromResponse:(NSDictionary *)userInfo {
    
    NSDictionary *errorData = [userInfo valueForKey:DZErrorResponse];
    NSString *errorString;
    
    if (errorData) {
        errorString = [errorData valueForKey:@"error"] ?: [errorData valueForKey:@"err"];
    }
    
    if (errorString) {
        NSURLSessionDataTask *task = [userInfo valueForKey:DZErrorTask];
        NSHTTPURLResponse *res = (NSHTTPURLResponse *)[task response];
        
        NSInteger status = res.statusCode;
        
//        if (status == 401 && [errorString isEqualToString:@"The token provided did not match with the one we generated."]) {
//            // auth error.
//            self.userIDManager = nil;
//        }
        
        return [NSError errorWithDomain:@"TTKit" code:status userInfo:@{NSLocalizedDescriptionKey: errorString}];
    }
    
    return [NSError errorWithDomain:@"TTKit" code:0 userInfo:@{NSLocalizedDescriptionKey: @"An unknown error has occurred."}];
    
}

#pragma mark -

- (void)updateBookmarksFromServer
{
    
    if (MyFeedsManager.userID == nil)
        return;
    
    NSArray <NSString *> *existingArr = [MyFeedsManager.bookmarks rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
        return obj.identifier.stringValue;
    }];
    
    NSString *existing = [existingArr componentsJoinedByString:@","];
    
    weakify(self);
    
    NSDictionary *params = @{};
    
    if (existing) {
        params = @{@"existing": existing};
    }
    
    [self.backgroundSession POST:@"/bookmarked" queryParams:@{@"userID": MyFeedsManager.userID} parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (response.statusCode >= 300) {
            // no changes.
            return;
        }
        
        NSArray <NSNumber *> * bookmarked = [responseObject valueForKey:@"bookmarks"];
        NSArray <NSNumber *> * deleted = [responseObject valueForKey:@"deleted"];
        
        DDLogDebug(@"Bookmarked: %@\nDeleted:%@", bookmarked, deleted);
        
        strongify(self);
        
        if ((bookmarked && bookmarked.count) || (deleted && deleted.count)) {
            
            NSMutableArray <FeedItem *> *bookmarks = MyFeedsManager.bookmarks.mutableCopy;
         
            if (deleted && deleted.count) {
                
                bookmarks = [bookmarks rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                   
                    NSUInteger deletedIndex = [deleted indexOfObject:obj.identifier];
                    
                    if (deletedIndex != NSNotFound) {
                        // remove the path as well
                        if (![self removeLocalBookmark:obj]) {
                            [[NSNotificationCenter defaultCenter] postNotificationName:BookmarksDidUpdate object:obj userInfo:@{@"bookmarked": @(NO)}];
                        }
                    }
                    
                    return deletedIndex == NSNotFound;
                    
                }].mutableCopy;
                
            }
            
            if (bookmarked && bookmarked.count) {
                
                __block NSUInteger count = bookmarked.count;
                
                [bookmarked enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    __block NSUInteger index = NSNotFound;
                    
                    __unused FeedItem *item = [bookmarks rz_reduce:^id(FeedItem *prev, FeedItem *current, NSUInteger idxx, NSArray *array) {
                        
                        if ([current.identifier isEqualToNumber:obj]) {
                            index = idxx;
                            return current;
                        }
                        
                        return prev;
                        
                    }];
                    
                    DDLogDebug(@"Index of bookmark: %@", @(index));
                    
                    if (index != NSNotFound) {
                        count--;
                        return;
                    }
                    
                    // this article needs to be downloaded and cached
                    
                    weakify(self);
                    
                    [self getArticle:obj success:^(FeedItem * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        
                        [bookmarks addObject:responseObject];
                        
                        strongify(self);
                        
                        [self addLocalBookmark:responseObject];
                        
                        [[NSNotificationCenter defaultCenter] postNotificationName:BookmarksDidUpdate object:responseObject userInfo:@{@"bookmarked": @(YES)}];
                        
                        count--;
                        
                        if (count == 0) {
                            MyFeedsManager.bookmarks = bookmarks;
                        }
                        
                    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                       
                        count--;
                        
                        if (count == 0) {
                            MyFeedsManager.bookmarks = bookmarks;
                        }
                        
                    }];
                    
                }];
                
            }
            else {
                MyFeedsManager.bookmarks = bookmarks;
            }
            
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        DDLogError(@"Failed to fetch bookmarks from the server.");
        DDLogError(@"%@", error.localizedDescription);
        
    }];
}

@end
