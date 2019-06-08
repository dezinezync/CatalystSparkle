//
//  FeedsManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsManager+KVS.h"
#import "FeedItem.h"

#import "RMStore.h"
#import "RMStoreKeychainPersistence.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import <CommonCrypto/CommonHMAC.h>

#import <DZKit/AlertManager.h>

#ifndef DDLogError
#import <DZKit/DZLogger.h>
#import <CocoaLumberjack/CocoaLumberjack.h>
#endif

@import UserNotifications;

#import "YetiConstants.h"

FeedsManager * _Nonnull MyFeedsManager = nil;

@interface FeedsManager () <YTUserDelegate, UIStateRestoring, UIObjectRestoration>
{
    NSString *_receiptLastUpdatePath;
    Subscription * _subscription;
}

@property (nonatomic, strong, readwrite) DZURLSession *session, *backgroundSession;
@property (nonatomic, strong, readwrite) Reachability *reachability;

@property (nonatomic, strong, readwrite) YTUserID *userIDManager;
@property (nonatomic, strong, readwrite) Subscription *subscription;

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
        
        [DBManager initialize];
        [MyDBManager registerCloudCoreExtension];
        
        self.userIDManager = [[YTUserID alloc] initWithDelegate:self];
        
//        DDLogWarn(@"%@", MyFeedsManager.bookmarks);
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUpdateBookmarks:) name:BookmarksDidUpdate object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDidUpdate) name:UserDidUpdate object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
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
    }
    
    return self;
}

- (NSNumber *)userID
{
    return self.userIDManager.userID;
}

- (void)dealloc {
    
    
    
}

- (void)didReceiveMemoryWarning {
    self.bookmarks = nil;
    self.folders = nil;
    self.unread = nil;
    self.feeds = nil;
}

#pragma mark - Feeds

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
            @synchronized (self) {
                self.feeds = feeds;
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

                @synchronized (self) {
                    self.feeds = feeds;
                }
            }
            else {
                @synchronized (self) {
                    self.feeds = feeds;
                }
            }

        }
        
        if (successCB) {
//            DDLogDebug(@"Responding to successCB from network");
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
        
        Feed *feed = [Feed instanceFromDictionary:obj];
        
        NSString *localNameKey = formattedString(@"feed-%@", feed.feedID);
        
        __block NSString *localName = nil;
        
        [MyDBManager.bgConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
            
            localName = [transaction objectForKey:localNameKey inCollection:LOCAL_NAME_COLLECTION];
            
        }];
        
        feed.localName = localName;
        
        return feed;
        
    }] mutableCopy];
    
    NSDictionary *foldersStruct = [responseObject valueForKey:@"struct"];
    
    self->_feeds = feeds;
    
    // create the folders map
    NSArray <Folder *> *folders = [[foldersStruct valueForKey:@"folders"] rz_map:^id(id obj, NSUInteger idxxx, NSArray *array) {
       
        Folder *folder = [Folder instanceFromDictionary:obj];
        
        return folder;
        
    }];
    
    self->_folders = folders;
    
    return feeds;
}

- (Feed *)feedForID:(NSNumber *)feedID {
    
    if (feedID == nil) {
        return nil;
    }
    
    Feed *feed = [MyFeedsManager.feeds rz_reduce:^id(Feed *prev, Feed *current, NSUInteger idx, NSArray *array) {
        if ([current.feedID isEqualToNumber:feedID])
            return current;
        return prev;
    }];
    
    if (feed == nil && self.temporaryFeeds != nil && self.temporaryFeeds.count > 0) {
        
        feed = [MyFeedsManager.temporaryFeeds rz_reduce:^id(Feed *prev, Feed *current, NSUInteger idx, NSArray *array) {
            if ([current.feedID isEqualToNumber:feedID])
                return current;
            return prev;
        }];
        
    }
    
    return feed;
}

- (Folder *)folderForID:(NSNumber *)folderID {
    
    if (folderID == nil) {
        return nil;
    }
    
    Folder *folder = [self.folders rz_reduce:^id(Folder *prev, Folder *current, NSUInteger idx, NSArray *array) {
        if ([current.folderID isEqualToNumber:folderID]) {
            return current;
        }
        
        return prev;
    }];
    
    return folder;
    
}

- (void)getFeed:(Feed *)feed sorting:(YetiSortOption)sorting page:(NSInteger)page success:(successBlock)successCB error:(errorBlock)errorCB
{
    if (!page)
        page = 1;
    
    NSMutableDictionary *params = @{@"page": @(page)}.mutableCopy;
    
    if ([self userID] != nil) {
        params[@"userID"] = MyFeedsManager.userID;
    }
#if TESTFLIGHT == 0
    if ([self subscription] != nil && [self.subscription hasExpired] == YES) {
        params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
    }
#endif
    
    if (sorting) {
        params[@"sortType"] = @(sorting.integerValue);
    }
    
    [self.session GET:formattedString(@"/feeds/%@", feed.feedID) parameters:params success:^(NSDictionary * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSArray <NSDictionary *> * articles = [responseObject valueForKey:@"articles"];
        
        NSArray <FeedItem *> *items = [articles rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        if ([sorting integerValue] > 1) {
            items = [items rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                return obj.isRead == NO;
            }];
        }
        
        if (feed) {
            if (page == 1) {
                feed.articles = items;
            }
            else {
                feed.articles = [(feed.articles ?: @[]) arrayByAddingObjectsFromArray:items];
            }
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
        params = @{@"URL": url, @"userID": [self userID]}; // test/demo user: 93
    }

    weakify(self);

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
            
            strongify(self);
            [self addFeedByID:feedID success:successCB error:errorCB];
            
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

        strongify(self);

        self.keychain[YTSubscriptionHasAddedFirstFeed] = [@(YES) stringValue];
        
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

    weakify(self);

    [MyFeedsManager.session PUT:@"/feed" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {

        strongify(self);
        
        self.keychain[YTSubscriptionHasAddedFirstFeed] = [@(YES) stringValue];

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
    
    NSString *path = formattedString(@"/1.2/article/%@", articleID);
    
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

- (void)getMercurialArticle:(NSNumber *)articleID success:(successBlock)successCB error:(errorBlock)errorCB {
    
    if (articleID == nil || [articleID integerValue] == 0) {
        if (errorCB) {
            NSError *error = [NSError errorWithDomain:@"FeedsManager" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Invalid or no article ID"}];
            errorCB(error, nil, nil);
        }
        return;
    }
    
    NSString *path = formattedString(@"/1.3/mercurial/%@", articleID);
    
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
    
#if TESTFLIGHT == 0
    if ([self subscription] != nil && [self.subscription hasExpired] == YES) {
        params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
    }
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
        
        [self.session POST:path parameters:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            NSArray <NSNumber *> *feedIDs = [responseObject valueForKey:@"feeds"];
            
            // only post the notification if it's affecting a feed or folder
            // this avoids reducing or incrementing the count for unsubscribed feeds
            if (feedIDs != nil && feedIDs.count > 0) {
                
                // since all articles are being marked as read
                // the total count drops to 0 and no unread articles
                // will be available
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.totalUnread = 0;
                    self.unread = @[];
                });
                
                NSInteger const newFeedUnread = 0;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    for (NSNumber *feedID in feedIDs) {
                        
                        Feed *feed = [self feedForID:feedID];
                        
                        if (feed != nil) {
                            
                            feed.unread = @(newFeedUnread);
                            
                            if (feed.folderID != nil) {
                                Folder *folder = [self folderForID:feed.folderID];
                                
                                if (folder != nil) {
                                    [folder willChangeValueForKey:propSel(unreadCount)];
                                    // simply tell the unreadCount property that it has been updated.
                                    // KVO should handle the rest for us
                                    [folder didChangeValueForKey:propSel(unreadCount)];
                                }
                            }
                            
                        }
                    }
                });
            }
         
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
    
}

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

- (void)renameFeed:(Feed *)feed title:(NSString *)title success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSDictionary *query = @{};
    if ([self userID] != nil) {
        query = @{@"userID": [self userID]};
    }
    else {
        if (errorCB) {
            errorCB([NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"No user ID is currently available."}], nil, nil);
        }
        
        return;
    }
    
    if (feed == nil) {
        if (errorCB) {
            errorCB([NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : @"No feed provided."}], nil, nil);
        }
        return;
    }
    
    if (title == nil) {
        title = @"";
    }
    
    NSDictionary *body = @{@"feedID": feed.feedID,
                           @"title": title
                           };
    
    [self.session POST:@"/1.2/customFeed" queryParams:query parameters:body success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
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
       
        [self updateFeedsReadCount:folder.feeds.allObjects markedRead:markedRead];
        
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

- (void)getUnreadForPage:(NSInteger)page sorting:(YetiSortOption)sorting success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    if ([self userID] == nil) {
        if (errorCB)
            errorCB(nil, nil, nil);
        
        return;
    }
    
    NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"page": @(page), @"limit": @10, @"sortType":  @(sorting.integerValue)}.mutableCopy;
    
#if TESTFLIGHT == 0
    if ([self subscription] != nil && [self.subscription hasExpired] == YES) {
        params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
    }
#endif
    
    [self.session GET:@"/unread" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        NSArray <FeedItem *> * items = [[responseObject valueForKey:@"articles"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        self.unreadLastUpdate = NSDate.date;
        
        if (page == 1) {
            self.unread = items;
        }
        else {
            if (!self.unread) {
                self.unread = items;
            }
            else {
                NSArray *unread = MyFeedsManager.unread;
                NSArray *prefiltered = [unread rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                    return !obj.isRead;
                }];
                
                @try {
                    prefiltered = [prefiltered arrayByAddingObjectsFromArray:items];
                     self.unread = prefiltered;
                }
                @catch (NSException *exc) {}
            }
        }
        // the conditional takes care of filtered article items.
        self.totalUnread = MyFeedsManager.unread.count > 0 ? [[responseObject valueForKey:@"total"] integerValue] : 0;
        
        if (successCB) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successCB(items, response, task);
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

- (void)renameFolder:(Folder *)folder to:(NSString *)title success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    [self updateFolder:folder properties:@{@"title": title ?: @""} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
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
           
            if ([obj.folderID isEqualToNumber:folder.folderID]) {
                obj.title = title;
                *stop = YES;
            }
            
        }];
        
        // this will fire the notification
        MyFeedsManager.folders = folders;
        
        if (successCB) {
            successCB(responseObject, response, task);
        }
        
    } error:errorCB];
}

- (void)updateFolder:(Folder *)folder add:(NSArray<NSNumber *> *)add remove:(NSArray<NSNumber *> *)del success:(successBlock)successCB error:(errorBlock)errorCB
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
    
    [self updateFolder:folder properties:dict.copy success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        BOOL status = [[responseObject valueForKey:@"status"] boolValue];
        
        if (!status) {
            if (errorCB) {
                NSError *error = [NSError errorWithDomain:@"TTKit" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Failed to update the folder preferences. Please try again."}];
                errorCB(error, response, task);
            }
            return;
        }
        
        strongify(self);
        
        // check delete ops first
        if (del && del.count) {
            NSArray <Feed *> * removedFeeds = [folder.feeds.allObjects rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                return [del indexOfObject:obj.feedID] != NSNotFound;
            }];
            
            [removedFeeds enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.folderID = nil;
            }];
            
            NSArray *feeds = [folder.feeds allObjects];
            
            if (folder.feeds != nil && [folder.feeds count] > 0) {
                [folder.feeds removeAllObjects];
            }
            else {
                folder.feeds = [NSPointerArray weakObjectsPointerArray];
            }
            
            feeds = [feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                return [del indexOfObject:obj.feedID] == NSNotFound;
            }];
            
            [folder.feeds addObjectsFromArray:feeds];
        }
        
        // now run add ops
        if (add && add.count) {
            NSArray <Feed *> * addedFeeds = [MyFeedsManager.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                return [add indexOfObject:obj.feedID] != NSNotFound;
            }];
            
            [addedFeeds enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.folderID = folder.folderID;
            }];
            
            if (addedFeeds != nil && [addedFeeds isKindOfClass:NSArray.class] && addedFeeds.count) {
                [folder.feeds addObjectsFromArray:addedFeeds];
            }
        }
        
        // this pushes the update to FeedsVC
        dispatch_async(dispatch_get_main_queue(), ^{
            self.feeds = [self feeds];
        });
        
        if (successCB) {
            successCB(responseObject, response, task);
        }
        
    } error:errorCB];
}

- (void)removeFolder:(Folder *)folder success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSString *path = formattedString(@"/folder?userID=%@&folderID=%@", [self userID], folder.folderID);
    
    [self.session DELETE:path parameters:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        [[folder.feeds allObjects] enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            obj.folderID = nil;
            
        }];
     
        NSArray <Folder *> *folders = [self.folders rz_filter:^BOOL(Folder *obj, NSUInteger idx, NSArray *array) {
            return ![obj.folderID isEqualToNumber:folder.folderID];
        }];
        
        self.folders = folders;
        
        self.feeds = [self feeds];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
    }];
    
}

- (void)updateFolder:(Folder *)folder properties:(NSDictionary *)props success:(successBlock)successCB error:(errorBlock)errorCB {
    
    if (![props valueForKey:@"folderID"]) {
        NSMutableDictionary *temp = props.mutableCopy;
        
        [temp setValue:folder.folderID forKey:@"folderID"];
        
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

- (void)folderFeedFor:(Folder *)folder sorting:(YetiSortOption)sorting page:(NSInteger)page success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSString *path = formattedString(@"/1.1/folder/%@/feed", folder.folderID);
    
    NSMutableDictionary *params = @{@"page": @(page)}.mutableCopy;
    
    if ([self userID] != nil) {
        params[@"userID"] = MyFeedsManager.userID;
    }
    
    if (sorting) {
        params[@"sortType"] = @(sorting.integerValue);
    }
    
#if TESTFLIGHT == 0
    if ([self subscription] != nil && [self.subscription hasExpired] == YES) {
        params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
    }
#endif
    
    [self.session GET:path parameters:params success:^(NSArray <NSDictionary *> * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSArray <FeedItem *> *items = [responseObject rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
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

#pragma mark - Tags

- (void)getTagFeed:(NSString *)tag page:(NSInteger)page success:(successBlock)successCB error:(errorBlock)errorCB {
    
    if (tag == nil || [[tag stringByStrippingWhitespace] isBlank]) {
        if (errorCB) {
            errorCB([NSError errorWithDomain:NSNetServicesErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"An invalid or no tag was received."}], nil, nil);
        }
        
        return;
    }
    
    NSDictionary *params = @{@"userID": [self userID],
                             @"page": page ? @(page) : @(1),
                             @"tag": tag
                             };
    
    [self.session GET:@"/1.2/tagfeed" parameters:params success:^(NSDictionary * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (response.statusCode == 304) {
            if (successCB) {
                successCB(nil, response, task);
            }
            return;
        }
        
        if (successCB == nil) {
            return;
        }
        
        NSArray <NSDictionary *> *feedObjects = responseObject[@"feeds"];
        NSArray <NSDictionary *> *articleObjects = responseObject[@"articles"];
        
        NSArray <FeedItem *> *articles = [articleObjects rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        NSArray <Feed *> *feeds = [feedObjects rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [Feed instanceFromDictionary:obj];
        }];
        
        successCB(@{
                    @"feeds": feeds,
                    @"articles": articles
                    }, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

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

- (void)updateExpiryTo:(NSDate *)date isTrial:(BOOL)isTrial success:(successBlock)successCB error:(errorBlock)errorCB {
    
    if (!self.userID)
        return;
    
    weakify(self);
    
    NSDictionary *body = @{@"date": @([date timeIntervalSince1970]),
                           @"isTrial": @(isTrial)
                           };
    
    [self.session POST:@"/store/legacy" parameters:body success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            if ([[responseObject valueForKey:@"status"] boolValue]) {
                Subscription *sub = [Subscription instanceFromDictionary:[responseObject valueForKey:@"subscription"]];
                
                self.subscription = sub;
                
                if (successCB) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successCB(responseObject, response, task);
                    });
                }
            }
            else {
                Subscription *sub = [Subscription new];
                NSString *error = [responseObject valueForKey:@"message"] ?: @"An unknown error occurred when updating the subscription.";
                sub.error = [NSError errorWithDomain:@"Yeti" code:-200 userInfo:@{NSLocalizedDescriptionKey: error}];
                
                self.subscription = sub;
                
                if (errorCB) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        errorCB(sub.error, response, task);
                    });
                }
            }
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            DDLogError(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

- (void)postAppReceipt:(NSData *)receipt success:(successBlock)successCB error:(errorBlock)errorCB {
    
    if (!self.userID)
        return;
    
    NSString *receiptString = [receipt base64EncodedStringWithOptions:0];
    
    weakify(self);
    
    [self.session POST:@"/1.1/store" queryParams:@{@"userID": [self userID]} parameters:@{@"receipt": receiptString} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        strongify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            if ([[responseObject valueForKey:@"status"] boolValue]) {
                Subscription *sub = [Subscription instanceFromDictionary:[responseObject valueForKey:@"subscription"]];
                
                self.subscription = sub;
                
                if (successCB) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successCB(responseObject, response, task);
                    });
                }
            }
            else {
                Subscription *sub = [Subscription new];
                NSString *error = [responseObject valueForKey:@"message"] ?: @"An unknown error occurred when updating the subscription.";
                sub.error = [NSError errorWithDomain:@"Yeti" code:-200 userInfo:@{NSLocalizedDescriptionKey: error}];
                
                self.subscription = sub;
                
                if (errorCB) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        errorCB(sub.error, response, task);
                    });
                }
            }
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            DDLogError(@"Subscription Error: %@", error.localizedDescription);
            
            Subscription *sub = [Subscription new];
            sub.error = error;
            
            strongify(self);
            
            self.subscription = sub;
            
            NSError * err = [self errorFromResponse:error.userInfo];
            
            if (errorCB)
                errorCB(err, response, task);
            else {
                DDLogError(@"Unhandled network error: %@", error);
            }
            
        });
        
    }];
    
}

- (void)getSubscriptionWithSuccess:(successBlock)successCB error:(errorBlock)errorCB {

    weakify(self);

    
    [self.session GET:@"/store" parameters:@{@"userID": [MyFeedsManager userID]} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            if ([[responseObject valueForKey:@"status"] boolValue]) {
                Subscription *sub = [Subscription instanceFromDictionary:[responseObject valueForKey:@"subscription"]];
                
                self.subscription = sub;
                
                if (successCB) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        successCB(responseObject, response, task);
                    });
                }
            }
            else {
                Subscription *sub = [Subscription new];
                NSString *error = [responseObject valueForKey:@"message"] ?: @"An unknown error occurred when updating the subscription.";
                sub.error = [NSError errorWithDomain:@"Yeti" code:-200 userInfo:@{NSLocalizedDescriptionKey: error}];
                
                 self.subscription = sub;
                
                if (errorCB) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        errorCB(sub.error, response, task);
                    });
                }
            }
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            DDLogError(@"Subscription Error: %@", error.localizedDescription);
            
            Subscription *sub = [Subscription new];
            sub.error = error;
            
            strongify(self);
            
            self.subscription = sub;
            
            NSError * err = [self errorFromResponse:error.userInfo];
            
            if (errorCB)
                errorCB(err, response, task);
            else {
                DDLogError(@"Unhandled network error: %@", error);
            }
            
        });
        
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

#pragma mark - Sync

- (void)getSync:(NSString *)token success:(successBlock)successCB error:(errorBlock)errorCB {
    
    if (!self.userID) {
        
        if (errorCB) {
            errorCB([NSError errorWithDomain:NSNetServicesErrorDomain code:1 userInfo:@{NSLocalizedDescriptionKey: @"Try again in 2s"}], nil, nil);
        }
        
        return;
        
    }
    
    NSDictionary *query = @{@"token": token,
                            @"userID": self.userID
                            };
    
    [self.session GET:@"/1.2/sync" parameters:query success:^(NSDictionary * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (response.statusCode == 304) {
            // nothing changed. exit early
            return;
        }
        
        // server will respond with changes and changeToken
        NSString *changeToken = responseObject[@"changeToken"];
        NSArray <NSDictionary *> * changes = responseObject[@"changes"];
        
        if (successCB) {
            ChangeSet *changeSet = [[ChangeSet alloc] init];
            changeSet.changeToken = changeToken;
            
            NSMutableArray <SyncChange *> *changeMembers = [[NSMutableArray alloc] initWithCapacity:changes.count];
            
            for (NSDictionary *change in changes) {
                SyncChange *changeObj = [[SyncChange alloc] init];
                [changeObj setValuesForKeysWithDictionary:change];
                
                [changeMembers addObject:changeObj];
            }
            
            changeSet.changes = changeMembers.copy;
            
            successCB(changeSet, response, task);
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

#pragma mark - Search

- (NSURLSessionTask *)search:(NSString *)query scope:(NSInteger)scope page:(NSInteger)page success:(successBlock)successCB error:(errorBlock)errorCB {
    
    query = query ?: @"";
    
    NSDictionary *body = @{
                           @"query": query,
                           @"scope": @(scope),
                           @"page": @(page)
                           };
    
    NSDictionary *queryParams = @{@"userID": self.userID};
    
    return [self.session POST:@"/1.2/search" queryParams:queryParams parameters:body success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSArray <NSDictionary *> *feedObjs = [responseObject valueForKey:@"feeds"];
        
        NSArray <Feed *> *feeds = [feedObjs rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [Feed instanceFromDictionary:obj];
        }];
        
        if (successCB) {
            successCB(feeds, response, task);
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
    }
}

- (void)setSubscription:(Subscription *)subscription {
    _subscription = subscription;
    
    if (_subscription && [[(RMStoreKeychainPersistence *)[RMStore.defaultStore transactionPersistor] purchasedProductIdentifiers] containsObject:IAPLifetime]) {
        _subscription.lifetime = YES;
    }
    
#ifndef DEBUG
#if TESTFLIGHT == 1
    if (_subscription && _subscription.error == nil) {
        // Sat Aug 31 2019 23:59:59 GMT+0000 (UTC)
        _subscription.expiry = [NSDate dateWithTimeIntervalSince1970:1567295999];
    }
#endif
#endif
    
//#if TESTFLIGHT == 0
    [self setupSubscriptionNotification];
//#endif
    
    if (subscription && [subscription hasExpired] && [subscription preAppstore] == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:YTSubscriptionHasExpiredOrIsInvalid object:subscription];
        });
    }
    
}

- (void)setFeeds:(NSArray<Feed *> *)feeds
{
    _feeds = feeds ?: @[];
    
    // calling this invalidates the pointers we store in folders.
    // calling the folders setter will remap the feeds.
    self.folders = [self folders];
    
    if (_feeds) {
        [NSNotificationCenter.defaultCenter postNotificationName:FeedsDidUpdate object:MyFeedsManager userInfo:@{@"feeds" : _feeds, @"folders": self.folders ?: @[]}];
    }
}

- (void)setFolders:(NSArray<Folder *> *)folders {
    
    _folders = folders ?: @[];
    
    [_folders enumerateObjectsUsingBlock:^(Folder * _Nonnull folder, NSUInteger idxx, BOOL * _Nonnull stopx) {
       
        if (folder.feeds == nil) {
            folder.feeds = [NSPointerArray weakObjectsPointerArray];
            
            NSArray *feedIDs = folder.feedIDs.allObjects;
            
            [feedIDs enumerateObjectsUsingBlock:^(NSNumber * _Nonnull objx, NSUInteger idx, BOOL * _Nonnull stop) {
                
                [self->_feeds enumerateObjectsUsingBlock:^(Feed * _Nonnull feed, NSUInteger idxx, BOOL * _Nonnull stopx) {
                    
                    if ([feed.feedID isEqualToNumber:objx]) {
                        feed.folderID = folder.folderID;
                        if ([folder.feeds containsObject:feed] == NO) {
                            [folder.feeds addPointer:(__bridge void *)feed];
                        }
                    }
                    
                }];
                
            }];
        }
        
    }];
    
}

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

- (NSArray <Feed *> *)feedsWithoutFolders {
    
   NSArray <Feed *> * feeds = [self.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
        return obj.folderID == nil;
    }];
    
    return feeds;
}

- (Subscription *)getSubscription {
    return _subscription;
}

- (Reachability *)reachability {
    if (!_reachability) {
        _reachability = [Reachability reachabilityWithHostName:@"api.elytra.app"];
    }
    
    return _reachability;
}

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
        defaultConfig.timeoutIntervalForRequest = 60;

        DZURLSession *session = [[DZURLSession alloc] init];
        
        session.baseURL = [NSURL URLWithString:@"http://192.168.1.15:3000"];
        session.baseURL =  [NSURL URLWithString:@"https://api.elytra.app"];
#ifndef DEBUG
        session.baseURL = [NSURL URLWithString:@"https://api.elytra.app"];
#endif
        session.useOMGUserAgent = YES;
        session.useActivityManager = YES;
        session.responseParser = [DZJSONResponseParser new];

        weakify(self);
        session.requestModifier = ^NSMutableURLRequest *(NSMutableURLRequest *request) {
          
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

            // compute Authorization
            strongify(self);
            
            NSNumber *userID = self.userIDManager.userID ?: @0;
            
            NSString *UUID = (userID.integerValue > 0 && self.userIDManager.UUIDString) ? self.userIDManager.UUIDString : @"x890371abdgvdfggsnnaa=";
            NSString *encoded = [[UUID dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
            
            NSString *timecode = @([NSDate.date timeIntervalSince1970]).stringValue;
            NSString *stringToSign = formattedString(@"%@_%@_%@", userID, UUID, timecode);
            
            NSString *signature = [self hmac:stringToSign withKey:encoded];
            
            [request setValue:signature forHTTPHeaderField:@"Authorization"];
            [request setValue:userID.stringValue forHTTPHeaderField:@"x-userid"];
            [request setValue:timecode forHTTPHeaderField:@"x-timestamp"];
            return request;
            
        };
        
        session.redirectModifier = ^NSURLRequest *(NSURLSessionTask *task, NSURLRequest *request, NSHTTPURLResponse *redirectResponse) {
            NSURLRequest *retval = request;
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
    
//    if (MyFeedsManager.userID) {
//        
//        NSDate *lastUpdate = [NSKeyedUnarchiver unarchiveObjectWithFile:_receiptLastUpdatePath];
//        
//        if (lastUpdate != nil) {
//            // check every 3 days
//            NSTimeInterval threeDays = 86400 * 3;
//            if ([NSDate.date timeIntervalSinceDate:lastUpdate] < threeDays) {
//                return;
//            }
//        }
//        
//        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
//        
//        NSData *data = [[NSData alloc] initWithContentsOfURL:receiptURL];
//        
//        if (data) {
//            [self postAppReceipt:data success:nil error:nil];
//        }
//        
//        lastUpdate = NSDate.date;
//        
//        if (![NSKeyedArchiver archiveRootObject:lastUpdate toFile:_receiptLastUpdatePath]) {
//            DDLogError(@"Failed to archive receipt update date");
//        }
//        
//    }
    
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

- (void)setupSubscriptionNotification {
    
    // clear all existing notifications
    [self clearExistingNotifications];
    
    // now based on the current subscription expiry setup the new Notification
    if ([self.subscription hasExpired] == NO) {
        
        NSDate *expiry = self.subscription.expiry;
        
        if (expiry == nil) {
            return;
        }
        
        BOOL isTrial = [[self.subscription status] integerValue] == 2 ? YES : NO;
        
        NSString *text;
        
        if (isTrial) {
            text = @"Your Trail period ends tomorrow. Subscribe today to keep reading your RSS Feeds.";
        }
        else {
            text = @"Your Elytra Subscription expires tomorrow. Subscribe today to keep reading your RSS Feeds.";
        }
        
        NSDateComponents *triggerDate = [[NSCalendar currentCalendar]
                                         components:NSCalendarUnitYear +
                                         NSCalendarUnitMonth + NSCalendarUnitDay +
                                         NSCalendarUnitHour + NSCalendarUnitMinute +
                                         NSCalendarUnitSecond fromDate:expiry];
        
        // we need this to fire one day early
        triggerDate.day -= 1;
        
        UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:triggerDate repeats:NO];
        
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.title = isTrial ? @"Elytra Trial" : @"Your Pro Subscription";
        content.subtitle = text;
        content.sound = [UNNotificationSound defaultSound];
        
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:YTSubscriptionNotification content:content trigger:trigger];
        
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
           
            if (error) {
                DDLogError(@"Error scheduling notification: %@", error);
            }
            
        }];
        
    }
    
}

- (void)clearExistingNotifications {
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    [center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
        
        if (requests.count) {
            NSMutableArray *pending = [NSMutableArray arrayWithCapacity:requests.count];
            
            for (UNNotificationRequest *request in requests) { @autoreleasepool {
                
                if ([request.identifier containsString:YTSubscriptionNotification]) {
                    [pending addObject:request.identifier];
                }
                
            } }
            
            if (pending.count) {
                [center removePendingNotificationRequestsWithIdentifiers:pending];
            }
        }
        
    }];
    
}

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
    keychain[kHasShownOnboarding] = nil;
    
    self.userIDManager.UUID = nil;
    self.userIDManager.userID = nil;
}

#pragma mark - <YTUserDelegate>

- (void)getUserInformation:(successBlock)successCB error:(errorBlock)errorCB
{
    weakify(self);
    
    NSDictionary *params;
    
    if (MyFeedsManager.userID != nil) {
        params = @{@"userID": MyFeedsManager.userID};
    }

    else if ([MyFeedsManager userIDManager]->_UUID) {
        params = @{@"userID" : [MyFeedsManager.userIDManager UUIDString]};
    }

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

    id countVal = self.keychain[YTLaunchCount];
    NSInteger count = [(countVal ?: @0) integerValue];
    // trigger on 7th launch
    if (count > 6) {
        id requestedVal = self.keychain[YTRequestedReview];
        if ([requestedVal boolValue] == NO) {
            self.shouldRequestReview = YES;
        }
    }

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
        
//        DDLogDebug(@"Bookmarked: %@\nDeleted:%@", bookmarked, deleted);
        
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
                    
//                    DDLogDebug(@"Index of bookmark: %@", @(index));
                    
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
        
        self->_folders = [coder decodeObjectForKey:kFoldersKey];
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

@end
