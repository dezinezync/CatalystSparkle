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
        DDLogWarn(@"%@", self.bookmarks);
        
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
    
    if (self.userID == nil) {
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
        NSString *path = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:@"feedscache.json"]];
        
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
                        self->_feeds = feeds;
                        
                        asyncMain(^{
                            successCB(@1, nil, nil);
                        });
                    });
                }
            }
            
        });
    }
    
    NSDictionary *params = @{@"userID": self.userID};
    
    // only consider this param when we have feeds
    if (since && self.feeds.count) {
        
        if ([NSDate.date timeIntervalSinceDate:since] < 3600) {
            
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"YYYY/MM/dd HH:mm:ss";
            
            params = @{
                       @"userID": self.userID,
                       @"since": [formatter stringFromDate:since]
                       };
            
        }
    }
    
    [self.session GET:@"/feeds" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        strongify(self);
        
        NSArray <Feed *> * feeds = [self parseFeedResponse:responseObject];
        
        if (!since || !self.feeds.count) {
            self.feeds = feeds;
            
            // cache it
            weakify(self);
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                strongify(self);
                NSError *error = nil;
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:responseObject];
                
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

                NSArray <Feed *> *copy = [self.feeds copy];

                for (Feed *feed in feeds) {
                    // get the corresponding feed from the memory
                    Feed *main = [self.feeds rz_reduce:^id(Feed *prev, Feed *current, NSUInteger idx, NSArray *array) {
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
                    self.feeds = feeds;
                }
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
    
    NSInteger fid = feedID.integerValue;
    
    return [self.feeds rz_reduce:^id(Feed *prev, Feed *current, NSUInteger idx, NSArray *array) {
        if (current.feedID.integerValue == fid)
            return current;
        return prev;
    }];
}

- (void)getFeed:(Feed *)feed page:(NSInteger)page success:(successBlock)successCB error:(errorBlock)errorCB
{
    if (!page)
        page = 1;
    
    NSMutableDictionary *params = @{@"page": @(page)}.mutableCopy;
    
    if ([self userID] != nil) {
        params[@"userID"] = self.userID;
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
    
    NSArray <Feed *> *existing = [self.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
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
    
    [self.session PUT:@"/feed" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
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
    
    NSArray <Feed *> *existing = [self.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
        return obj.feedID.integerValue == feedID.integerValue;
    }];
    
    if (existing.count) {
        if (errorCB) {
            errorCB([NSError errorWithDomain:@"FeedsManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"You already have this feed in your list."}], nil, nil);
        }
        
        return;
    }
    
    NSDictionary *params = @{@"feedID" : feedID};
    if ([self userID] != nil) {
        params = @{@"feedID": feedID, @"userID": [self userID]};
    }
    
    [self.session PUT:@"/feed" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
    
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
    
    [self.backgroundSession GET:path parameters:@{@"userID" : self.userID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
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
    if (![self userID]) {
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
    
    self.unread = [self.unread rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
        BOOL isRead = obj.isRead;
        if (isRead)
            [markedRead addObject:obj.identifier];
        return isRead;
    }];
    
    if (!markedRead.count)
        return;
    
    // propagate changes to the feeds object as well
    for (Feed *obj in self.feeds) { @autoreleasepool {
        
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
    
    if (![self userID]) {
        if (errorCB)
            errorCB(nil, nil, nil);
        
        return;
    }
    
    [self.session GET:@"/unread" parameters:@{@"userID": self.userID, @"page": @(page), @"limit": @10} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        NSArray <FeedItem *> * items = [[responseObject valueForKey:@"articles"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        if (page == 1) {
            self.unread = items;
        }
        else {
            if (!self.unread) {
                self.unread = items;
            }
            else {
                NSArray *prefiltered = [self.unread rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                    return !obj.isRead;
                }];
                self.unread = [prefiltered arrayByAddingObjectsFromArray:items];
            }
        }
        // the conditional takes care of filtered article items.
        self.totalUnread = self.unread.count > 0 ? [[responseObject valueForKey:@"total"] integerValue] : 0;
        
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
    
    if (self.bookmarks.count) {
        existing = [[self.bookmarks rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
            return obj.identifier.stringValue;
        }] componentsJoinedByString:@","];
    }
    
    [self.session POST:formattedString(@"/bookmarked?userID=%@", self.userID) parameters:@{@"existing": existing} success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
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
        
        self.folders = [self.folders arrayByAddingObject:instance];
        
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
        if (self.subsribeAfterPushEnabled) {
            
            weakify(self);
            
            [self subsribe:self.subsribeAfterPushEnabled success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                [[NSNotificationCenter defaultCenter] postNotificationName:SubscribedToFeed object:self.subsribeAfterPushEnabled];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    self.subsribeAfterPushEnabled = nil;
                });
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
               
                strongify(self);
                
                self.subsribeAfterPushEnabled = nil;
                
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

- (void)setFeeds:(NSArray<Feed *> *)feeds
{
    _feeds = feeds ?: @[];
    
    [NSNotificationCenter.defaultCenter postNotificationName:FeedsDidUpdate object:MyFeedsManager userInfo:@{@"feeds" : self.feeds, @"folders": self.folders}];
}

- (void)setFolders:(NSArray<Folder *> *)folders
{
    _folders = folders ?: @[];
    
    [NSNotificationCenter.defaultCenter postNotificationName:FeedsDidUpdate object:MyFeedsManager userInfo:@{@"feeds" : self.feeds, @"folders": self.folders}];
}

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
        session.baseURL = [NSURL URLWithString:@"https://yeti.dezinezync.com"];
#ifndef DEBUG
        session.baseURL = [NSURL URLWithString:@"https://yeti.dezinezync.com"];
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
        self.bookmarks = [self.bookmarks arrayByAddingObject:item];
    }
    else {
        NSInteger itemID = item.identifier.integerValue;
        
        self.bookmarks = [self.bookmarks rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
            return obj.identifier.integerValue != itemID;
        }];
    }
    
}

- (void)userDidUpdate {
    
    if (![self userID]) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UserDidUpdate object:nil];
    
    weakify(self);
    // user ID can be nil at this point
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        strongify(self);
        [self updateBookmarksFromServer];
    });
    
}

#pragma mark - <YTUserDelegate>

- (void)getUserInformation:(successBlock)successCB error:(errorBlock)errorCB
{
    weakify(self);
    
    NSDictionary *params;
    
    if (self.userID != nil) {
        params = @{@"userID": self.userID};
    }
#ifndef SHARE_EXTENSION
    else if ([self userIDManager]->_UUID) {
        params = @{@"userID" : [self.userIDManager UUIDString]};
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
    if (!self.userIDManager.UUID) {
        if (errorCB) {
            NSError *error = [NSError errorWithDomain:@"FeedManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"No user ID currently present"}];
            errorCB(error, nil, nil);
        }
        
        return;
    }
    
    [self.session PUT:@"/user" parameters:@{@"uuid": self.userIDManager.UUIDString} success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
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
    
    if (!self.userID)
        return;
    
    NSArray <NSString *> *existingArr = [self.bookmarks rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
        return obj.identifier.stringValue;
    }];
    
    NSString *existing = [existingArr componentsJoinedByString:@","];
    
    weakify(self);
    
    [self.backgroundSession POST:@"/bookmarked" queryParams:@{@"userID": self.userID} parameters:@{@"existing": existing} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (response.statusCode >= 300) {
            // no changes.
            return;
        }
        
        NSArray <NSNumber *> * bookmarked = [responseObject valueForKey:@"bookmarks"];
        NSArray <NSNumber *> * deleted = [responseObject valueForKey:@"deleted"];
        
        DDLogDebug(@"Bookmarked: %@\nDeleted:%@", bookmarked, deleted);
        
        strongify(self);
        
        if ((bookmarked && bookmarked.count) || (deleted && deleted.count)) {
            
            NSMutableArray <FeedItem *> *bookmarks = self.bookmarks.mutableCopy;
         
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
                            self.bookmarks = bookmarks;
                        }
                        
                    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                       
                        count--;
                        
                        if (count == 0) {
                            self.bookmarks = bookmarks;
                        }
                        
                    }];
                    
                }];
                
            }
            else {
                self.bookmarks = bookmarks;
            }
            
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        DDLogError(@"Failed to fetch bookmarks from the server.");
        DDLogError(@"%@", error.localizedDescription);
        
    }];
}

@end
