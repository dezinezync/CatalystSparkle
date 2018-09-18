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

#ifndef SHARE_EXTENSION
#import <CommonCrypto/CommonHMAC.h>
#endif

#ifndef DDLogError
#import <DZKit/DZLogger.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#endif

#import "YetiConstants.h"

FeedsManager * _Nonnull MyFeedsManager = nil;

#ifdef SHARE_EXTENSION
@interface FeedsManager ()
#else
@interface FeedsManager () <YTUserDelegate, UIStateRestoring, UIObjectRestoration>
#endif
{
//    NSString *_feedsCachePath;
    NSString *_receiptLastUpdatePath;
    Subscription * _subscription;
}

@property (nonatomic, strong, readwrite) DZURLSession *session, *backgroundSession, *gifSession;
@property (nonatomic, strong, readwrite) Reachability *reachability;
#ifndef SHARE_EXTENSION
@property (nonatomic, strong, readwrite) YTUserID *userIDManager;
@property (nonatomic, strong, readwrite) Subscription *subscription;
#endif
@end

@implementation FeedsManager

+ (void)load {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            @synchronized (MyFeedsManager) {
                MyFeedsManager = [[FeedsManager alloc] init];
            }
        });
    });
}

#pragma mark -

- (instancetype)init
{
    if (self = [super init]) {
        
#ifndef SHARE_EXTENSION
        self.userIDManager = [[YTUserID alloc] initWithDelegate:self];
        
        self.unreadManager = [[UnreadManager alloc] init];
        
//        DDLogWarn(@"%@", MyFeedsManager.bookmarks);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateBookmarks:) name:BookmarksDidUpdate object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidUpdate) name:UserDidUpdate object:nil];
        
        NSError *error = nil;
        
        if (error) {
            DDLogError(@"Error loading push token from disk: %@", error.localizedDescription);
        }
        
        NSString *docsDir;
        NSArray *dirPaths;
//        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        
//        if (!_feedsCachePath) {
//            dirPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//            docsDir = [dirPaths objectAtIndex:0];
//            
//            NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
//            NSString *filename = formattedString(@"feedscache-%@.json", buildNumber);
//            
//            NSString *path = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:filename]];
//            
//#ifdef DEBUG
//            path = [path stringByAppendingString:@".debug"];
//#endif
//            
//            _feedsCachePath = path;
//        }
        
        if (_receiptLastUpdatePath == nil) {
            if (!docsDir) {
                dirPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                docsDir = [dirPaths objectAtIndex:0];
            }
            
            NSBundle *bundle = [NSBundle mainBundle];
            
            NSDictionary *infoDict = [bundle infoDictionary];
            NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
            NSString *filename = formattedString(@"receiptDate-%@.json", buildNumber);
            
            NSString *path = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:filename]];
            
#ifdef DEBUG
            path = [path stringByAppendingString:@".debug"];
#endif
            
            infoDict = nil;
            buildNumber = nil;
            filename = nil;
            
            _receiptLastUpdatePath = path;
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
#ifndef SHARE_EXTENSION
- (void)getFeedsSince:(NSDate *)since success:(successBlock)successCB error:(errorBlock)errorCB
{
    weakify(self);
    
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
    
    NSDictionary *params = @{@"userID": MyFeedsManager.userID};
    
    [self.session GET:@"/feeds" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        strongify(self);

        NSArray <Feed *> * feeds = [self parseFeedResponse:responseObject];
        
        id firstFeedObj = self.keychain[YTSubscriptionHasAddedFirstFeed];
        BOOL hasAddedFirstFeed = firstFeedObj ? [firstFeedObj boolValue] : NO;
        
        if (hasAddedFirstFeed == NO) {
            // check if feeds count is higher than 2
            if (feeds.count >= 2) {
                hasAddedFirstFeed = YES;
            }
            else if (self.folders.count) {
                // check count of feeds in folders
                NSNumber *total = (NSNumber *)[self.folders rz_reduce:^id(NSNumber *prev, Folder *current, NSUInteger idx, NSArray *array) {
                    return @(prev.integerValue + current.feeds.count);
                } initialValue:@(0)];
                
                if (total.integerValue >= 2) {
                    hasAddedFirstFeed = YES;
                }
            }
            
            self.keychain[YTSubscriptionHasAddedFirstFeed] = [@(hasAddedFirstFeed) stringValue];
        }
        
        if (!since || !MyFeedsManager.feeds.count) {
            @synchronized (self.unreadManager) {
                self.unreadManager.feeds = feeds;
            }
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

                @synchronized (self.unreadManager) {
                    self.unreadManager.feeds = feeds;
                }
            }
            else {
                @synchronized (self.unreadManager) {
                    self.unreadManager.feeds = feeds;
                }
            }

        }
        
        [self.unreadManager finishedUpdating];
        
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
    
    self.unreadManager.feeds = feeds;
    
    NSDictionary *foldersStruct = [responseObject valueForKey:@"struct"];
    
    // these feeds are inside folders
    NSArray <NSNumber *> *feedIDsInFolders = [foldersStruct valueForKey:@"feeds"];
    
    NSMutableArray <Feed *> *feedsInFolders = [NSMutableArray arrayWithCapacity:feedIDsInFolders.count];
    
    // create the folders map
    NSArray <Folder *> *folders = [[foldersStruct valueForKey:@"folders"] rz_map:^id(id obj, NSUInteger idxxx, NSArray *array) {
       
        Folder *folder = [Folder instanceFromDictionary:obj];
        
        NSArray <NSNumber *> * feedIDs = [obj valueForKey:@"feeds"];
        
        folder.feeds = [NSPointerArray weakObjectsPointerArray];
        
        [feedIDs enumerateObjectsUsingBlock:^(NSNumber * _Nonnull objx, NSUInteger idx, BOOL * _Nonnull stop) {
            
            [feeds enumerateObjectsUsingBlock:^(Feed * _Nonnull feed, NSUInteger idxx, BOOL * _Nonnull stopx) {
                
                if ([feed.feedID isEqualToNumber:objx]) {
                    feed.folderID = folder.folderID;
                    [folder.feeds addPointer:(__bridge void *)feed];
                }
                
            }];
            
        }];
        
        return folder;
        
    }];
    
    self.unreadManager.folders = folders;
    
    return feeds;
}

#endif

- (Feed *)feedForID:(NSNumber *)feedID
{
    
    __block Feed *feed = [MyFeedsManager.feeds rz_reduce:^id(Feed *prev, Feed *current, NSUInteger idx, NSArray *array) {
        if ([current.feedID isEqualToNumber:feedID])
            return current;
        return prev;
    }];
    
//    if (!feed) {
//        // check in folders
//        
//        [MyFeedsManager.folders enumerateObjectsUsingBlock:^(Folder * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//           
//            [obj.feeds enumerateObjectsUsingBlock:^(Feed *  _Nonnull objx, NSUInteger idxx, BOOL * _Nonnull stopx) {
//               
//                if (objx && objx.feedID != nil && [objx.feedID isEqualToNumber:feedID]) {
//                    feed = objx;
//                    *stopx = YES;
//                    *stop = YES;
//                }
//                
//            }];
//            
//        }];
//        
//    }
    
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
#ifndef SHARE_EXTENSION
#if TESTFLIGHT == 0
    if ([self subscription] != nil && [self.subscription hasExpired] == YES) {
        params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
    }
#endif
#endif
    
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
#ifndef SHARE_EXTENSION
    weakify(self);
#endif
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
            strongify(self);
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

#ifndef SHARE_EXTENSION
        strongify(self);

        self.keychain[YTSubscriptionHasAddedFirstFeed] = [@(YES) stringValue];
#endif
        
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
            errorCB([NSError errorWithDomain:@"FeedsManager" code:kFMErrorExisting userInfo:@{NSLocalizedDescriptionKey: @"You already have this feed in your list."}], nil, nil);
        }
        
        return;
    }
    
    NSDictionary *params = @{@"feedID" : feedID};
    if ([MyFeedsManager userID] != nil) {
        params = @{@"feedID": feedID, @"userID": [self userID]};
    }
#ifndef SHARE_EXTENSION
    weakify(self);
#endif
    [MyFeedsManager.session PUT:@"/feed" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
#ifndef SHARE_EXTENSION
        strongify(self);
        
        self.keychain[YTSubscriptionHasAddedFirstFeed] = [@(YES) stringValue];
#endif
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
    
    if (articleID == nil || [articleID integerValue] == 0) {
        if (errorCB) {
            NSError *error = [NSError errorWithDomain:@"FeedsManager" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Invalid or no article ID"}];
            errorCB(error, nil, nil);
        }
        return;
    }
    
    NSString *path = formattedString(@"/article/%@", articleID);
    
    NSMutableDictionary *params = @{}.mutableCopy;
    
    if (MyFeedsManager.userID) {
        params[@"userID"] = MyFeedsManager.userID;
    }
    
    [self.session GET:path parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
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
    if ([self userID] == nil) {
        if (errorCB) {
            errorCB(nil, nil, nil);
        }
        
        return;
    }
    
    NSString *path = formattedString(@"/feeds/%@/author/%@", feedID, authorID);
    
    if (!page)
        page = 1;
    
    NSMutableDictionary *params = @{
                             @"userID": [self userID],
                             @"page": @(page)
                             }.mutableCopy;
    
#ifndef SHARE_EXTENSION
#if TESTFLIGHT == 0
    if ([self subscription] != nil && [self.subscription hasExpired] == YES) {
        params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
    }
#endif
#endif
    
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

- (void)markFeedRead:(Feed *)feed success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSString *path;
    NSNumber *userID = [self userID] ?: @(0);
    
    if (feed) {
        NSNumber *feedID = feed.feedID;
        
        path = formattedString(@"/feeds/%@/allread", feedID);
        
        [self.session GET:path parameters:@{@"userID": userID} success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            error = [self errorFromResponse:error.userInfo];
            
            if (errorCB)
                errorCB(error, response, task);
            else {
                DDLogError(@"Unhandled network error: %@", error);
            }
            
        }];
    }
    else {
        path = formattedString(@"/unread/markall?userID=%@", userID);
        
        [self.session POST:path parameters:nil success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            error = [self errorFromResponse:error.userInfo];
            
            if (errorCB)
                errorCB(error, response, task);
            else {
                DDLogError(@"Unhandled network error: %@", error);
            }
            
        }];
    }
    
}

#ifndef SHARE_EXTENSION

- (void)getRecommendationsWithSuccess:(successBlock _Nullable)successCB error:(errorBlock _Nonnull)errorCB {
    
    [self.session GET:@"/recommendations" parameters:@{} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (!successCB)
            return;
        
        NSMutableDictionary *dict = [responseObject mutableCopy];
        
        NSArray <Feed *> *trending = [dict[@"trending"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [Feed instanceFromDictionary:obj];
        }];
        
        NSArray <Feed *> *subs = [dict[@"highestSubs"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [Feed instanceFromDictionary:obj];
        }];
        
        NSArray <Feed *> *read = [dict[@"mostRead"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [Feed instanceFromDictionary:obj];
        }];
        
        dict[@"trending"] = trending;
        dict[@"highestSubs"] = subs;
        dict[@"mostRead"] = read;
        
        if (successCB) {
            successCB(dict.copy, response, task);
            dict = nil;
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
        NSNumber *feedID = obj.feedID.copy;
        
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
            [[NSNotificationCenter defaultCenter] postNotificationName:FeedDidUpReadCount object:feedID];
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
    
    NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"page": @(page), @"limit": @10}.mutableCopy;
    
#ifndef SHARE_EXTENSION
#if TESTFLIGHT == 0
    if ([self subscription] != nil && [self.subscription hasExpired] == YES) {
        params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
    }
#endif
#endif
    
    weakify(self);
    
    [self.session GET:@"/unread" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        NSArray <FeedItem *> * items = [[responseObject valueForKey:@"articles"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        strongify(self);
        
        self.unreadLastUpdate = NSDate.date;
        
        if (page == 1) {
            @synchronized (self) {
                self.unread = items;
            }
        }
        else {
            if (!MyFeedsManager.unread) {
                @synchronized (self) {
                    self.unread = items;
                }
            }
            else {
                NSArray *unread = MyFeedsManager.unread;
                NSArray *prefiltered = [unread rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                    return !obj.isRead;
                }];
                
                @try {
                    prefiltered = [prefiltered arrayByAddingObjectsFromArray:items];
                    @synchronized (MyFeedsManager) {
                        MyFeedsManager.unread = prefiltered;
                    }
                }
                @catch (NSException *exc) {}
            }
        }
        // the conditional takes care of filtered article items.
        @synchronized (self) {
            self.totalUnread = MyFeedsManager.unread.count > 0 ? [[responseObject valueForKey:@"total"] integerValue] : 0;
        }
        
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

- (void)getBookmarksWithSuccess:(successBlock)successCB error:(errorBlock)errorCB
{
    
    NSString *existing = @"";
    
    if (MyFeedsManager.bookmarks.count) {
        NSArray <FeedItem *> *bookmarks = MyFeedsManager.bookmarks;
        existing = [[bookmarks rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
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
    
    [self.session PUT:@"/folder" queryParams:@{@"userID": [self userID]} parameters:@{@"title": title} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        id retval = [responseObject valueForKey:@"folder"];
        
        Folder *instance = [Folder instanceFromDictionary:retval];
        
        NSArray <Folder *> *folders = [MyFeedsManager folders];
        folders = [folders arrayByAddingObject:instance];
        
        @synchronized (MyFeedsManager) {
            MyFeedsManager.folders = folders;
        }
        
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
    
    [self updateFolder:folderID properties:@{@"title": title} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        BOOL status = [[responseObject valueForKey:@"status"] boolValue];
        
        if (!status) {
            if (errorCB) {
                NSError *error = [NSError errorWithDomain:@"TTKit" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Failed to update the folder title. Please try again."}];
                errorCB(error, response, task);
            }
            return;
        }
      
        NSArray <Folder *> *folders = [MyFeedsManager folders];
        
        // update our caches
        [folders enumerateObjectsUsingBlock:^(Folder * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            if ([obj.folderID isEqualToNumber:folderID]) {
                obj.title = title;
                *stop = YES;
            }
            
        }];
        
        // this will fire the notification
        @synchronized (MyFeedsManager) {
            MyFeedsManager.folders = folders;
        }
        
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
    
    [self updateFolder:folderID properties:dict.copy success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        BOOL status = [[responseObject valueForKey:@"status"] boolValue];
        
        if (!status) {
            if (errorCB) {
                NSError *error = [NSError errorWithDomain:@"TTKit" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Failed to update the folder preferences. Please try again."}];
                errorCB(error, response, task);
            }
            return;
        }
        
        NSArray <Folder *> *folders = MyFeedsManager.folders;
        
        Folder *folder = [folders rz_reduce:^id(Folder *prev, Folder *current, NSUInteger idx, NSArray *array) {
            if ([current.folderID isEqualToNumber:folderID])
                return current;
            return prev;
        }];
        
        // check delete ops first
        if (del && del.count) {
//            NSArray <Feed *> * removedFeeds = [folder.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
//                return [del indexOfObject:obj.feedID] != NSNotFound;
//            }];
//
//            [removedFeeds enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                obj.folderID = nil;
//            }];
//
//            folder.feeds = [folder.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
//                return [del indexOfObject:obj.feedID] == NSNotFound;
//            }];
//
//            NSArray <Feed *> *feeds = [MyFeedsManager.feeds arrayByAddingObjectsFromArray:removedFeeds];
//
//            @synchronized (MyFeedsManager) {
//                MyFeedsManager.feeds = feeds;
//            }
        }
        
        // now run add ops
        if (add && add.count) {
//            NSArray <Feed *> * addedFeeds = [MyFeedsManager.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
//                return [add indexOfObject:obj.feedID] != NSNotFound;
//            }];
//            
//            [addedFeeds enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//                obj.folderID = folderID;
//            }];
//            
//            @synchronized (MyFeedsManager) {
//                NSArray *feeds = MyFeedsManager.feeds;
//                feeds = [feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
//                    return [add indexOfObject:obj.feedID] == NSNotFound;
//                }];
//                
//                MyFeedsManager.feeds = feeds;
//            }
//            
//            folder.feeds = [folder.feeds arrayByAddingObjectsFromArray:addedFeeds];
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
    if (token == nil)
        return;
    
    if ([self userID] == nil)
        return;
    
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
    
    if (!self.userID)
        return;
    
    NSString *receiptString = [receipt base64EncodedStringWithOptions:0];
    
    weakify(self);
    
    [self.session POST:@"/store" queryParams:@{@"userID": [self userID]} parameters:@{@"receipt": receiptString} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        strongify(self);
        
        [self _updateSubscriptionStateWithSuccess:^(id responseObjectx, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            if (successCB) {
                successCB(responseObject, response, task);
            }
            
        } error:errorCB];
        
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
#ifndef SHARE_EXTENSION
    weakify(self);
#endif
    
    [self.session GET:@"/store" parameters:@{@"userID": [MyFeedsManager userID]} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
     
#ifndef SHARE_EXTENSION
        strongify(self);
        
        if ([[responseObject valueForKey:@"status"] boolValue]) {
            Subscription *sub = [Subscription instanceFromDictionary:[responseObject valueForKey:@"subscription"]];
            
            @synchronized (self) {
                self.subscription = sub;
            }
        }
        else {
            Subscription *sub = [Subscription new];
            sub.error = [NSError errorWithDomain:@"Yeti" code:-200 userInfo:@{NSLocalizedDescriptionKey: [responseObject valueForKey:@"message"]}];
            
            @synchronized (self) {
                self.subscription = sub;
            }
        }
#endif
        
        if (successCB) {
            successCB(responseObject, response, task);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        DDLogError(@"Subscription Error: %@", error.localizedDescription);
#ifndef SHARE_EXTENSION
        Subscription *sub = [Subscription new];
        sub.error = error;
        
        strongify(self);
        
        @synchronized (self) {
            self.subscription = sub;
        }
#endif
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

#pragma mark - OPML

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

#pragma mark - Setters

//- (void)setBookmarks:(NSArray<FeedItem *> *)bookmarks
//{
//    if (bookmarks) {
//        NSArray <FeedItem *> *sorted = [bookmarks sortedArrayUsingSelector:@selector(compare:)];
//
//        _bookmarks = sorted;
//    }
//    else {
//        _bookmarks = bookmarks;
//    }
//}

//- (void)setFeeds:(NSArray<Feed *> *)feeds {
//
//    _feeds = feeds;
//    
//    [NSNotificationCenter.defaultCenter postNotificationName:FeedsDidUpdate object:self];
//
//}

- (void)setPushToken:(NSString *)pushToken
{
    _pushToken = pushToken;
    
    if (_pushToken) {
#ifndef SHARE_EXTENSION
        if (MyFeedsManager.subsribeAfterPushEnabled) {
            
            [self subsribe:MyFeedsManager.subsribeAfterPushEnabled success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                [[NSNotificationCenter defaultCenter] postNotificationName:SubscribedToFeed object:MyFeedsManager.subsribeAfterPushEnabled];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    @synchronized (MyFeedsManager) {
                        MyFeedsManager.subsribeAfterPushEnabled = nil;
                    }
                });
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                @synchronized (MyFeedsManager) {
                    MyFeedsManager.subsribeAfterPushEnabled = nil;
                }
                
                [AlertManager showGenericAlertWithTitle:@"Subscribe Failed" message:error.localizedDescription];
                
            }];
            
        }
        
        [self addPushToken:_pushToken success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            DDLogDebug(@"added push token: %@", responseObject);
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            DDLogError(@"Add push token error: %@", error);
        }];
#endif
    }
}

#ifndef SHARE_EXTENSION
- (void)setSubscription:(Subscription *)subscription {
    _subscription = subscription;
    
#if TESTFLIGHT == 1
    if (_subscription && _subscription.error == nil) {
        // Sat Aug 31 2019 23:59:59 GMT+0000 (UTC)
        _subscription.expiry = [NSDate dateWithTimeIntervalSince1970:1567295999];
    }
#endif
    
    if (subscription && [subscription hasExpired] && [subscription preAppstore] == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:YTSubscriptionHasExpiredOrIsInvalid object:subscription];
        });
    }
    
}
#endif

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

#ifndef SHARE_EXTENSION
- (NSArray <Feed *> *)feeds {
    return self.unreadManager.feedsWithoutFolders;
}

- (NSArray <Folder *> *)folders {
    return self.unreadManager.folders;
}

#endif

- (Subscription *)getSubscription {
    return _subscription;
}

- (Reachability *)reachability {
    if (!_reachability) {
        _reachability = [Reachability reachabilityWithHostName:@"api.elytra.app"];
    }
    
    return _reachability;
}

#ifndef SHARE_EXTENSION
- (UICKeyChainStore *)keychain {
    
    if (!_keychain) {
        UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:@"com.dezinezync.Yeti"];
        keychain.synchronizable = YES;
        
//        [keychain setAccessibility:kSecAccessControlApplicationPassword authenticationPolicy:UICKeyChainStoreAuthenticationPolicyUserPresence];
//        keychain.authenticationPrompt = @"Elytra needs to access your account ID securely.";
        
        _keychain = keychain;
    }
    
    return _keychain;
}
#endif

- (DZURLSession *)session
{
    if (_session == nil) {

        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        defaultConfig.HTTPMaximumConnectionsPerHost = 10;

        NSDictionary *const additionalHTTPHeaders = @{
                                                      @"Accept": @"application/json",
                                                      @"Content-Type": @"application/json"
                                                      };

        [defaultConfig setHTTPAdditionalHeaders:additionalHTTPHeaders];

        defaultConfig.allowsCellularAccess = YES;
        defaultConfig.HTTPShouldUsePipelining = YES;
        defaultConfig.waitsForConnectivity = NO;
        defaultConfig.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        defaultConfig.timeoutIntervalForRequest = 30;

        DZURLSession *session = [[DZURLSession alloc] init];
        
        session.baseURL = [NSURL URLWithString:@"http://192.168.1.15:3000"];
        session.baseURL =  [NSURL URLWithString:@"https://api.elytra.app"];
#ifndef DEBUG
        session.baseURL = [NSURL URLWithString:@"https://api.elytra.app"];
#endif
        session.useOMGUserAgent = YES;
        session.useActivityManager = YES;
        session.responseParser = [DZJSONResponseParser new];

#ifndef SHARE_EXTENSION
        weakify(self);
#endif
        session.requestModifier = ^NSURLRequest *(NSURLRequest *request) {
          
            NSMutableURLRequest *mutableReq = request.mutableCopy;
            [mutableReq setValue:@"application/json" forHTTPHeaderField:@"Accept"];
#ifndef SHARE_EXTENSION
            // compute Authorization
            strongify(self);
            
            NSNumber *userID = self.userIDManager.userID ?: @0;
            
            NSString *UUID = (userID.integerValue > 0 && self.userIDManager.UUIDString) ? self.userIDManager.UUIDString : @"x890371abdgvdfggsnnaa=";
            NSString *encoded = [[UUID dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
            
            NSString *timecode = @([NSDate.date timeIntervalSince1970]).stringValue;
            NSString *stringToSign = formattedString(@"%@_%@_%@", userID, UUID, timecode);
            
            NSString *signature = [self hmac:stringToSign withKey:encoded];
            
            [mutableReq setValue:signature forHTTPHeaderField:@"Authorization"];
            [mutableReq setValue:userID.stringValue forHTTPHeaderField:@"x-userID"];
            [mutableReq setValue:timecode forHTTPHeaderField:@"x-timestamp"];
#endif
            return mutableReq;
            
        };
        
        session.redirectModifier = ^NSURLRequest *(NSURLSessionTask *task, NSURLRequest *request, NSHTTPURLResponse *redirectResponse) {
            NSURLRequest *retval = request;
#ifdef SHARE_EXTENSION
            if ([[retval.URL absoluteString] containsString:@"/feed/"]) {
                // we're being redirected to add a new feed. The share extension handles this internally in it's success block.
                // therefore we deny the request from here.
                retval = nil;
            }
#endif
            return retval;
        };
        
        _session = session;
    }
    
    return _session;
}

- (DZURLSession *)backgroundSession
{
    if (!_backgroundSession) {
        
        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        // one for unread and the other for bookmarks
        defaultConfig.HTTPMaximumConnectionsPerHost = 2;
        // tell the OS not to manage these, but let them continue in the background
        defaultConfig.discretionary = NO;
        // we always want fresh data from the background service
        defaultConfig.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
        
        defaultConfig.allowsCellularAccess = YES;
        defaultConfig.waitsForConnectivity = NO;
        defaultConfig.HTTPShouldUsePipelining = YES;
        
        [defaultConfig setHTTPAdditionalHeaders:@{
                                                  @"Accept": @"application/json",
                                                  @"Content-Type": @"application/json"
                                                  }];
        
        DZURLSession *session = [[DZURLSession alloc] initWithSessionConfiguration:defaultConfig];
        
        session.baseURL = self.session.baseURL;
        session.useOMGUserAgent = YES;
        session.useActivityManager = YES;
        session.responseParser = [DZJSONResponseParser new];
        
        session.requestModifier = self.session.requestModifier;
        
        _backgroundSession = session;
    }
    
    return _backgroundSession;
}

- (DZURLSession *)gifSession
{
    if (!_gifSession) {
        
        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        defaultConfig.HTTPMaximumConnectionsPerHost = 5;
        
        defaultConfig.allowsCellularAccess = YES;
        defaultConfig.HTTPShouldUsePipelining = YES;
        defaultConfig.waitsForConnectivity = NO;
        
        DZURLSession *session = [[DZURLSession alloc] initWithSessionConfiguration:defaultConfig];
    
        session.useOMGUserAgent = YES;
        session.useActivityManager = NO;
        
        _gifSession = session;
    }
    
    return _gifSession;
}

#ifndef SHARE_EXTENSION
- (NSString *)hmac:(NSString *)plaintext withKey:(NSString *)key
{
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [plaintext cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    NSData *HMACData = [NSData dataWithBytes:cHMAC length:sizeof(cHMAC)];
    const unsigned char *buffer = (const unsigned char *)[HMACData bytes];
    NSMutableString *HMAC = [NSMutableString stringWithCapacity:HMACData.length * 2];
    for (int i = 0; i < HMACData.length; ++i){
        [HMAC appendFormat:@"%02x", buffer[i]];
    }
    
    return HMAC;
}
#endif
//#ifndef SHARE_EXTENSION

- (NSNumber *)bookmarksCount {
    
    if (!_bookmarksCount) {
        
        weakify(self);
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
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
            
            strongify(self);
            
            self->_bookmarksCount = @(objects.count);
            dispatch_semaphore_signal(sema);
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    
    return _bookmarksCount;
}

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
//            DDLogDebug(@"Have %@ bookmarks", @(objects.count));
        
        NSMutableArray <FeedItem *> *bookmarkedItems = [NSMutableArray arrayWithCapacity:objects.count+1];
        
        for (NSString *path in objects) { @autoreleasepool {
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
        } }
        
        _bookmarks = [bookmarkedItems sortedArrayUsingSelector:@selector(compare:)];
    }
    
    return _bookmarks;
    
}

//#endif

#pragma mark - Notifications

- (void)didUpdateBookmarks:(NSNotification *)note {
    
    FeedItem *item = [note object];
    
    @synchronized(self) {
        self->_bookmarksCount = nil;
    }
    
    if (!item) {
        DDLogWarn(@"A bookmark notification was posted but did not include a FeedItem object.");
        return;
    }
    
    BOOL isBookmarked = [[[note userInfo] valueForKey:@"bookmarked"] boolValue];
    
    if (isBookmarked) {
        // it was added
        @try {
            NSArray *bookmarks = [MyFeedsManager.bookmarks arrayByAddingObject:item];
            @synchronized (self) {
                self.bookmarks = bookmarks;
            }
        }
        @catch (NSException *exc) {}
    }
    else {
        NSInteger itemID = item.identifier.integerValue;
        
        @try {
            NSArray <FeedItem *> *bookmarks = MyFeedsManager.bookmarks;
            bookmarks = [bookmarks rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                return obj.identifier.integerValue != itemID;
            }];
            
            @synchronized (self) {
                self.bookmarks = bookmarks;
            }
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
        
        NSDate *lastUpdate = [NSKeyedUnarchiver unarchiveObjectWithFile:_receiptLastUpdatePath];
        
        if (lastUpdate != nil) {
            // check every 3 days
            NSTimeInterval threeDays = 86400 * 3;
            if ([NSDate.date timeIntervalSinceDate:lastUpdate] < threeDays) {
                return;
            }
        }
        
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        
        NSData *data = [[NSData alloc] initWithContentsOfURL:receiptURL];
        
        if (data) {
            [self postAppReceipt:data success:nil error:nil];
        }
        
        lastUpdate = NSDate.date;
        
        if (![NSKeyedArchiver archiveRootObject:lastUpdate toFile:_receiptLastUpdatePath]) {
            DDLogError(@"Failed to archive receipt update date");
        }
        
    }
    
}

- (void)_updateSubscriptionStateWithSuccess:(successBlock)successCB error:(errorBlock)errorCB {
    if (!MyFeedsManager.userID) {
        if (errorCB) {
            NSError *error = [NSError errorWithDomain:@"FeedManager" code:-401 userInfo:@{NSLocalizedDescriptionKey : @"No user account exists on this device."}];
            errorCB(error, nil, nil);
        }
        
        return;
    }
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        [self getSubscriptionWithSuccess:successCB error:errorCB];
    });
}

#pragma mark -
#ifndef SHARE_EXTENSION
- (void)resetAccount {
    self.folders = nil;
    self.feeds = nil;
    self.bookmarks = nil;
    self.unread = nil;
    self.totalUnread = 0;
    
    [self removeAllLocalBookmarks];
    
    NSString *kAccountID = @"YTUserID";
    NSString *kUserID = @"userID";
    
    NSUbiquitousKeyValueStore *store = [NSUbiquitousKeyValueStore defaultStore];
    if (store) {
        [store removeObjectForKey:kAccountID];
        [store removeObjectForKey:kUserID];
        [store synchronize];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (defaults) {
        [defaults removeObjectForKey:kAccountID];
        [defaults removeObjectForKey:kUserID];
        [defaults synchronize];
    }
    
    UICKeyChainStore *keychain = [self keychain];
    keychain[kAccountID] = nil;
    keychain[kUserID] = nil;
    
    self.userIDManager.UUID = nil;
    self.userIDManager.userID = nil;
}
#endif

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
    
    if (errorData != nil && errorData.allKeys.count > 0) {
        errorString = [errorData valueForKey:@"error"] ?: [errorData valueForKey:@"err"];
    }
    else if ([userInfo valueForKey:DZErrorData]) {
        NSError *err;
        id obj = [NSJSONSerialization JSONObjectWithData:[userInfo valueForKey:DZErrorData] options:kNilOptions error:&err];
        if (err == nil && obj != nil && [obj isKindOfClass:NSDictionary.class]) {
            errorString = [obj valueForKey:@"error"];
        }
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
    else {
        errorString = [userInfo valueForKey:NSLocalizedDescriptionKey];
    }
    
    if (errorString)
        return [NSError errorWithDomain:@"TTKit" code:0 userInfo:userInfo];
    
    return [NSError errorWithDomain:@"TTKit" code:0 userInfo:@{NSLocalizedDescriptionKey: @"An unknown error has occurred."}];
    
}

#pragma mark - Misc

- (void)checkConstraintsForRequestingReview {
#ifndef SHARE_EXTENSION
    id countVal = self.keychain[YTLaunchCount];
    NSInteger count = [(countVal ?: @0) integerValue];
    // trigger on 7th launch
    if (count > 6) {
        id requestedVal = self.keychain[YTRequestedReview];
        if ([requestedVal boolValue] == NO) {
            self.shouldRequestReview = YES;
        }
    }
#endif
}

- (void)updateBookmarksFromServer
{
    
    if (MyFeedsManager.userID == nil)
        return;
    
    NSArray <NSString *> *existingArr = [MyFeedsManager.bookmarks rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
        return obj.identifier.stringValue;
    }];
    
    NSString *existing = [existingArr componentsJoinedByString:@","];
    
    weakify(self);
    
    NSDictionary *params = @{}, *queryParams = @{};
    
    if (existing) {
        params = @{@"existing": existing};
    }
    
    if (self.userID) {
        queryParams = @{@"userID": MyFeedsManager.userID};
    }
    
    [self.backgroundSession POST:@"/bookmarked" queryParams:queryParams parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
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
                            @synchronized (MyFeedsManager) {
                                MyFeedsManager.bookmarks = bookmarks;
                            }
                        }
                        
                    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                       
                        count--;
                        
//                        if (count == 0) {
//                            MyFeedsManager.bookmarks = bookmarks;
//                        }
                        
                    }];
                    
                }];
                
            }
            else {
                @synchronized (self) {
                    self.bookmarks = bookmarks;
                }
            }
            
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        DDLogError(@"Failed to fetch bookmarks from the server.");
        DDLogError(@"%@", error.localizedDescription);
        
    }];
}

#ifndef SHARE_EXTENSION
#pragma mark - State Restoration

NSString *const kFoldersKey = @"key.folders";
NSString *const kFeedsKey = @"key.feeds";
NSString *const kSubscriptionKey = @"key.subscription";
NSString *const kBookmarksKey = @"key.bookmarks";
NSString *const kBookmarksCountKey = @"key.bookmarksCount";
NSString *const ktotalUnreadKey = @"key.totalUnread";
NSString *const kUnreadKey = @"key.unread";
NSString *const kUnreadLastUpdateKey = @"key.unreadLastUpdate";

- (Class)objectRestorationClass {
    return self.class;
}

+ (id <UIStateRestoring>)objectWithRestorationIdentifierPath:(NSArray<NSString *> *)identifierComponents coder:(NSCoder *)coder {
    return MyFeedsManager;
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    
    if (self.userIDManager.userID && self.userIDManager.UUID) {
        [coder encodeInteger:self.userIDManager.userID.integerValue forKey:kUserID];
        [coder encodeObject:self.userIDManager.UUIDString forKey:kAccountID];
        
        [coder encodeObject:self.folders forKey:kFoldersKey];
        [coder encodeObject:self.feeds forKey:kFeedsKey];
//        [coder encodeObject:self.subscription forKey:kSubscriptionKey];
        [coder encodeObject:self.bookmarks forKey:kBookmarksKey];
        [coder encodeObject:self.bookmarksCount forKey:kBookmarksCountKey];
        [coder encodeInteger:self.totalUnread forKey:ktotalUnreadKey];
        [coder encodeObject:self.unread forKey:kUnreadKey];
        
        if (self.unreadLastUpdate) {
            [coder encodeDouble:[self.unreadLastUpdate timeIntervalSince1970] forKey:kUnreadLastUpdateKey];
        }
    }
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    NSString * UUIDString = [coder decodeObjectForKey:kAccountID];
    NSInteger userID = [coder decodeIntegerForKey:kUserID];
    
    if (UUIDString != nil && userID > 0) {
        self.userIDManager.userID = @(userID);
        self.userIDManager.UUID = [[NSUUID alloc] initWithUUIDString:UUIDString];
        
        [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
        
        self.folders = [coder decodeObjectForKey:kFoldersKey];
        self.feeds = [coder decodeObjectForKey:kFeedsKey];
//        self.subscription = [coder decodeObjectForKey:kSubscriptionKey];
        self.bookmarks = [coder decodeObjectForKey:kBookmarksKey];
        self.bookmarksCount = [coder decodeObjectForKey:kBookmarksCountKey];
        self.totalUnread = [coder decodeIntegerForKey:ktotalUnreadKey];
        self.unread = [coder decodeObjectForKey:kUnreadKey];
        
        double unreadUpdate = [coder decodeDoubleForKey:kUnreadLastUpdateKey];
        if (unreadUpdate) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:unreadUpdate];
            self.unreadLastUpdate = date;
        }
    }
    
}

#endif

@end
