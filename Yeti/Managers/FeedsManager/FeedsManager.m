//
//  FeedsManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsManager+KVS.h"
#import "FeedItem.h"

#import "AppDelegate.h"

#import "RMStore.h"
#import "StoreKeychainPersistence.h"

#import <DZKit/NSString+Extras.h>
#import <DZKit/NSArray+RZArrayCandy.h>

#import <CommonCrypto/CommonHMAC.h>

#import "NSPointerArray+AbstractionHelpers.h"

#import <DZKit/AlertManager.h>
#import "Keychain.h"

@import UserNotifications;

#import "YetiConstants.h"
#import <DeviceCheck/DeviceCheck.h>

#import "Elytra-Swift.h"

FeedsManager * _Nonnull MyFeedsManager = nil;

NSArray <NSString *> * _defaultsKeys;

@interface FeedsManager () <UIStateRestoring, UIObjectRestoration>

@property (nonatomic, strong, readwrite) DZURLSession * _Nonnull session, * _Nullable backgroundSession;
@property (nonatomic, strong, readwrite) Reachability * _Nonnull reachability;

@property (nonatomic, strong, readwrite) User * _Nullable user;

@property (nonatomic, copy, readwrite) NSString *deviceID;
@property (nonatomic, strong) NSString *appFullVersion, *appMajorVersion;

@property (nonatomic, strong) NSTimer *widgetCountersUpdateTimer;

@end

@implementation FeedsManager

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @synchronized (MyFeedsManager) {
            MyFeedsManager = [[FeedsManager alloc] init];
        }
    });
}

+ (NSArray <NSString *> *)defaultsKeys {
    
    if (_defaultsKeys == nil) {
        _defaultsKeys = @[kDefaultsArticleFont, kDefaultsBackgroundRefresh, kShowMarkReadPrompt, kShowUnreadCounts, kDetailFeedSorting, kPreviewLines, kUseImageProxy, kDefaultsImageBandwidth, kDefaultsImageLoading, kShowArticleCoverImages, kDefaultsTheme, @"theme-light-color"];
    }
    
    return _defaultsKeys;
    
}

#pragma mark -

- (instancetype)init {
    
    if (self = [super init]) {
        
        [self setupNotifications];
        
        [DBManager.sharedInstance registerCloudCoreExtension];
        
        self.user = [MyDBManager getUser];
        
        NSError *error = nil;
        
        NSString *deviceID = [Keychain stringFor:@"deviceID" error:&error];
        
        if (error == nil && deviceID != nil) {
            self.deviceID = deviceID;
        }
        else {
            
            DCDevice *device = DCDevice.currentDevice;
            
            if ([device isSupported]) {
                
                [device generateTokenWithCompletionHandler:^(NSData * _Nullable token, NSError * _Nullable error) {
                    
                    NSData *encoded = [token base64EncodedDataWithOptions:kNilOptions];
                    
                    NSString *tokenString = [[NSString alloc] initWithData:encoded encoding:NSUTF8StringEncoding];
                    
                    NSString *tokenMD5 = [tokenString md5];
                    
                    self.deviceID = tokenMD5;
                    
                    [Keychain add:@"deviceID" string:self.deviceID];
                    [Keychain add:@"rawDeviceID" data:token];
                    
                }];
                
            }
            else {
                
                self.deviceID = [[NSUUID UUID] UUIDString];
                
                [Keychain add:@"deviceID" string:self.deviceID];
                
            }
            
        }
    
    }
    
    return self;
}

- (void)setupNotifications {
    
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center addObserver:self selector:@selector(didUpdateBookmarks:) name:BookmarksDidUpdate object:nil];
    [center addObserver:self selector:@selector(userDidUpdate) name:UserDidUpdate object:nil];
    
}

- (NSNumber *)userID {
    return self.user.userID;
}

#pragma mark - Feeds

- (void)getCountersWithSuccess:(successBlock)successCB error:(errorBlock)errorCB {
    
    weakify(self);
        
    if (MyFeedsManager.userID == nil) {
        if (errorCB)
            errorCB(nil, nil, nil);
        return;
    }
    
    NSDate *today = [NSDate date];
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:today];
    
    NSString *todayString = [NSString stringWithFormat:@"%@-%@-%@", @(comps.year), @(comps.month), @(comps.day)];
    
    NSDictionary *params = @{@"userID": MyFeedsManager.userID,
                             @"version": @"1.7",
                             @"date": todayString
    };
    
    __block DZURLSession *session = self.session;
    
    runOnMainQueueWithoutDeadlocking(^{
        
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            
            // use the background session for sync.
            NSLog(@"Setup getCounters task in background mode");
            
            session = self.backgroundSession;
            
        }
        
    });
    
    [session GET:@"/1.7/feeds" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        strongify(self);

        NSNumber *unread = [responseObject valueForKey:@"unread"];
        NSNumber *today = [responseObject valueForKey:@"todayCount"];
        
        NSDictionary *feedCounters = [responseObject valueForKey:@"feeds"];
        
        self.totalUnread = MAX(0, unread.integerValue);
        self.totalToday = MAX(0, today.integerValue);
        
        [self updateSharedUnreadCounters];
        
        if (feedCounters != nil) {
            
            // No unread
            if (feedCounters.allKeys.count == 0) {
                // set all feeds to 0
                
                for (Feed *feed in ArticlesManager.shared.feeds) {
                    
                    feed.unread = @(0);
                    
                }
                
            }
            else {
                
                [feedCounters enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, NSNumber *  _Nonnull obj, BOOL * _Nonnull stop) {
                   
                    Feed *feed = [ArticlesManager.shared feedForID:@(key.integerValue)];
                    
                    if (feed != nil) {
                        feed.unread = obj;
                    }
                    
                }];
            }
            
        }

        if (successCB) {
            
            runOnMainQueueWithoutDeadlocking(^{
                successCB(responseObject, response, task);
            });
            
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB) {
            errorCB(error, response, task);
        }
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

- (void)getFeedsWithSuccess:(successBlock)successCB error:(errorBlock)errorCB
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
    
    NSDate *today = [NSDate date];
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:today];
    
    NSString *todayString = [NSString stringWithFormat:@"%@-%@-%@", @(comps.year), @(comps.month), @(comps.day)];
    
    NSDictionary *params = @{@"userID": MyFeedsManager.userID,
                             @"version": @"1.7",
                             @"date": todayString
    };
    
    __block DZURLSession *session = self.session;
    
    runOnMainQueueWithoutDeadlocking(^{
        
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            
            // use the background session for sync.
            NSLog(@"Setup get feeds task in background mode");
            
            session = self.backgroundSession;
            
        }
        
    });
    
    [session GET:@"/feeds" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        strongify(self);

        NSArray <Feed *> * feeds = [self parseFeedResponse:responseObject];
        
        NSNumber *unread = [responseObject valueForKey:@"unread"];
        NSNumber *today = [responseObject valueForKey:@"todayCount"];
        
        self.totalUnread = MAX(0, unread.integerValue);
        self.totalToday = MAX(0, today.integerValue);
        
        BOOL hasAddedFirstFeed = [Keychain boolFor:YTSubscriptionHasAddedFirstFeed error:nil];
        
        if (hasAddedFirstFeed == NO) {
            // check if feeds count is higher than 2
            if (feeds.count >= 2) {
                hasAddedFirstFeed = YES;
            }
            else if (ArticlesManager.shared.folders.count) {
                // check count of feeds in folders
                NSNumber *total = (NSNumber *)[ArticlesManager.shared.folders rz_reduce:^id(id prev, Folder *current, NSUInteger idx, NSArray *array) {
                    
                    return @(((NSNumber *)prev).integerValue + current.feeds.count);
                    
                } initialValue:@(0)];
                
                if (total.integerValue >= 2) {
                    hasAddedFirstFeed = YES;
                }
            }
            
            [Keychain add:YTSubscriptionHasAddedFirstFeed boolean:hasAddedFirstFeed];
        }
        
        @synchronized (self) {
            ArticlesManager.shared.feeds = feeds;
        }
        
        if (successCB) {
//            NSLogDebug(@"Responding to successCB from network");
            asyncMain(^{
                successCB(@2, response, task);
            });
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
    }];
}

- (void)updateFeedWithLocalName:(Feed *)feed {
    
    if (feed == nil) {
        return;
    }
    
    NSString *localNameKey = formattedString(@"feed-%@", feed.feedID);
    
    __block NSString *localName = nil;
    
    [MyDBManager.bgConnection readWithBlock:^(YapDatabaseReadTransaction * _Nonnull transaction) {
        
        localName = [transaction objectForKey:localNameKey inCollection:LOCAL_NAME_COLLECTION];
        
    }];
    
    feed.localName = localName;
    
}

- (NSArray <Feed *> *)parseFeedResponse:(NSArray <NSDictionary *> *)responseObject {
    
    NSMutableArray <Feed *> *feeds = [[[responseObject valueForKey:@"feeds"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
        
        Feed *feed = [Feed instanceFromDictionary:obj];
        
        [self updateFeedWithLocalName:feed];
        
        return feed;
        
    }] mutableCopy];
    
    NSDictionary *foldersStruct = [responseObject valueForKey:@"struct"];
    
    // create the folders map
    NSArray <Folder *> *folders = [[foldersStruct valueForKey:@"folders"] rz_map:^id(id obj, NSUInteger idxxx, NSArray *array) {
       
        Folder *folder = [Folder instanceFromDictionary:obj];
        
        if (folder.feedIDs != nil && folder.feedIDs.count > 0) {
                            
            folder.feeds = [NSPointerArray weakObjectsPointerArray];
            
            NSArray *feedIDs = folder.feedIDs.allObjects;
            
            NSMutableArray *allFeeds = [NSMutableArray arrayWithCapacity:folder.feedIDs.count];
            
            [feedIDs enumerateObjectsUsingBlock:^(NSNumber * _Nonnull objx, NSUInteger idx, BOOL * _Nonnull stop) {
                
                Feed *feed = [feeds rz_find:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                   
                    return [obj.feedID isEqualToNumber:objx];
                    
                }];
                
                if (feed != nil) {
                    
                    [allFeeds addObject:feed];
                    feed.folderID = folder.folderID;
                    feed.folder = folder;
                    
                }
                
            }];
            
            [folder.feeds addObjectsFromArray:allFeeds];
            
        }
        
        return folder;
        
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        [ArticlesManager.shared willBeginUpdatingStore];
        
        [MyDBManager setFeeds:feeds];
        [MyDBManager setFolders:folders];
        
        ArticlesManager.shared.folders = folders;
        
        ArticlesManager.shared.feeds = feeds;
        
        [ArticlesManager.shared didFinishUpdatingStore];
        
    });
    
    return feeds;
}

- (Feed *)feedForID:(NSNumber *)feedID {
    
    if (feedID == nil) {
        return nil;
    }
    
    Feed *feed = [ArticlesManager.shared.feeds rz_reduce:^id(Feed *prev, Feed *current, NSUInteger idx, NSArray *array) {
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
    
    Folder *folder = [ArticlesManager.shared.folders rz_reduce:^id(Folder *prev, Folder *current, NSUInteger idx, NSArray *array) {
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

    if ([self subscription] != nil && [self.subscription hasExpired] == YES) {
        params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
    }
    
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
        
//        if (feed) {
//            if (page == 1) {
//                feed.articles = items;
//            }
//            else {
//                feed.articles = [(feed.articles ?: @[]) arrayByAddingObjectsFromArray:items];
//            }
//        }
        
        if (successCB)
            successCB(items, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
    }];
}

- (void)addFeed:(NSURL *)url success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    NSArray <Feed *> *existing = [ArticlesManager.shared.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
        return [obj.url isEqualToString:url.absoluteString];
    }];
    
    if (existing.count) {
        if (errorCB) {
            errorCB([NSError errorWithDomain:@"FeedsManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"You already have this feed in your list."}], nil, nil);
        }
        
        return;
    }
    
    NSString *urlString = [url absoluteString];
    
    if (!urlString) {
        
        if (errorCB) {
            errorCB([NSError errorWithDomain:@"FeedsManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"Please check the URL you have entered."}], nil, nil);
        }
        
        return;
        
    }
    
    NSDictionary *params = @{@"URL" : urlString};
    
    if ([self userID] != nil) {
        params = @{@"URL": urlString, @"userID": [self userID]}; // test/demo user: 93
    }

    weakify(self);

    [MyFeedsManager.session PUT:@"/feed?version=2" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
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

        [Keychain add:YTSubscriptionHasAddedFirstFeed boolean:YES];
        
        NSDictionary *feedObj = [responseObject valueForKey:@"feed"];
//        NSArray *articlesObj = [responseObject valueForKey:@"articles"];
        
//        NSArray <FeedItem *> *articles = [articlesObj rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
//            return [FeedItem instanceFromDictionary:obj];
//        }];
        
        Feed *feed = [Feed instanceFromDictionary:feedObj];
//        feed.articles = articles;
        
        if (successCB)
            successCB(feed, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
    }];
}

- (void)_checkYoutubeFeed:(NSURL *)url success:(successBlock)successCB error:(errorBlock)errorCB {
    
    if (!url || ([url.absoluteString isBlank] == YES)) {
        
        if (errorCB) {
            errorCB([NSError errorWithDomain:DZErrorDomain code:403 userInfo:@{NSLocalizedDescriptionKey: @"Please enter a valid URL."}], nil, nil);
        }
        
        return;
        
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithString:url.absoluteString];
    
    if (!components.scheme) {
        components.scheme = @"http";
        components.host = components.host ?: components.path;
        components.path = nil;
    }
    
    url = components.URL;
    
    // check if it's a Youtube URL
    if ([components.host containsString:@"youtube.com"]) {
        
        NSRange pathRange = NSMakeRange(0, components.path.length);
        NSString *pattern = @"\\/c(hannel)?\\/(.+)";
        NSRegularExpression *youtubeChannelURL = [NSRegularExpression regularExpressionWithPattern:pattern options:kNilOptions error:nil];
        
        if ([components.path containsString:@"/user/"] == YES) {
            
            // get it from the canonical head tag
            [MyFeedsManager getYoutubeCanonicalID:url success:successCB error:errorCB];
            
            return;
            
        }
        else if ([youtubeChannelURL numberOfMatchesInString:components.path options:kNilOptions range:pathRange] > 0) {
            
            __block NSString *youtubeChannelID;
            __block BOOL isChannelID = NO;
            
            [youtubeChannelURL enumerateMatchesInString:components.path options:kNilOptions range:pathRange usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
                
                NSRange matchingGroupRange = [result rangeAtIndex:result.numberOfRanges - 1];
                
                youtubeChannelID = [components.path substringWithRange:matchingGroupRange];
                isChannelID = [result rangeAtIndex:1].location != NSNotFound;
                
                NSLogDebug(@"Youtube Channel ID: %@", youtubeChannelID);
                
                *stop = YES;
                
            }];
            
            if (youtubeChannelID != nil) {
                
                if (isChannelID == NO) {
                    
                    // get it from the canonical head tag
                    [MyFeedsManager getYoutubeCanonicalID:url success:successCB error:errorCB];
                    
                    return;
                    
                }
                
                url = [NSURL URLWithFormat:@"https://www.youtube.com/feeds/videos.xml?channel_id=%@", youtubeChannelID];
                
            }
            
        }
        
    }
    
    if (successCB) {
        successCB(url, nil, nil);
    }
    
}

- (void)addFeedByID:(NSNumber *)feedID success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSArray <Feed *> *existing = [ArticlesManager.shared.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
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

    [MyFeedsManager.session PUT:@"/feed" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {

        [Keychain add:YTSubscriptionHasAddedFirstFeed boolean:YES];

        NSDictionary *feedObj = [responseObject valueForKey:@"feed"] ?: responseObject;
//        NSArray *articlesObj = [responseObject valueForKey:@"articles"];
        
//        NSArray <FeedItem *> *articles = [articlesObj rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
//            return [FeedItem instanceFromDictionary:obj];
//        }];
        
        Feed *feed = [Feed instanceFromDictionary:feedObj];
//        feed.articles = articles;
        
        if (successCB)
            successCB(feed, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
    }];
    
}

- (void)getArticle:(NSNumber *)articleID feedID:(NSNumber *)feedID noAuth:(BOOL)noAuth  success:(successBlock)successCB error:(errorBlock)errorCB {
    
    if (articleID == nil || [articleID integerValue] == 0) {
        if (errorCB) {
            NSError *error = [NSError errorWithDomain:@"FeedsManager" code:404 userInfo:@{NSLocalizedDescriptionKey: @"Invalid or no article ID"}];
            errorCB(error, nil, nil);
        }
        return;
    }
    
    if (feedID != nil) {
        
        FeedItem *item = [MyDBManager articleForID:articleID feedID:feedID];
        
        if (item != nil && item.content && successCB) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                successCB(item, nil, nil);
            });
            
            return;
            
        }
        
    }
    
    NSString *path = formattedString(@"/1.2/article/%@", articleID);
    
    NSMutableDictionary *params = @{@"noauth": @(noAuth)}.mutableCopy;
    
    if (MyFeedsManager.userID) {
        params[@"userID"] = MyFeedsManager.userID;
    }
    
    [self.session GET:path parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (successCB) {
            
            FeedItem *item = [FeedItem instanceFromDictionary:responseObject];
            
            item.read = NO;
            
            [MyDBManager addArticle:item];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                successCB(item, response, task);
            });
            
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
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
            NSLog(@"Unhandled network error: %@", error);
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
    

    if ([self subscription] != nil && [self.subscription hasExpired] == YES) {
        params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
    }
    
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
            NSLog(@"Unhandled network error: %@", error);
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
                NSLog(@"Unhandled network error: %@", error);
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
                    self.totalToday = 0;
//                    ArticlesManager.shared.unread = @[];
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
                                    
                                    [folder updateUnreadCount];
                                    
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
                NSLog(@"Unhandled network error: %@", error);
            }
            
        }];
    }
    
}

- (void)getRecommendations:(NSInteger)count noAuth:(BOOL)noAuth success:(successBlock)successCB error:(errorBlock)errorCB {
    
    count = count ?: 9;
    
    NSMutableDictionary *params = @{@"count": @(count)}.mutableCopy;
    params[@"noauth"] = @(noAuth);
    
    [self.session GET:@"/recommendations" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (!successCB)
            return;
        
        NSMutableDictionary *dict = [responseObject mutableCopy];
        
        NSArray <Feed *> *trending = [dict[@"trending"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            Feed * feed = [Feed instanceFromDictionary:obj];
            [self updateFeedWithLocalName:feed];
            return feed;
        }];
        
        NSArray <Feed *> *subs = [dict[@"highestSubs"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            Feed * feed = [Feed instanceFromDictionary:obj];
            [self updateFeedWithLocalName:feed];
            return feed;
        }];
        
        NSArray <Feed *> *read = [dict[@"mostRead"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            Feed * feed = [Feed instanceFromDictionary:obj];
            [self updateFeedWithLocalName:feed];
            return feed;
        }];
        
        NSArray <Feed *> *similar = [dict[@"similar"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            Feed * feed = [Feed instanceFromDictionary:obj];
            [self updateFeedWithLocalName:feed];
            return feed;
        }];
        
        dict[@"trending"] = trending;
        dict[@"highestSubs"] = subs;
        dict[@"mostRead"] = read;
        dict[@"similar"] = similar;
        
        if (successCB) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                successCB(dict, response, task);
            });
            
            dict = nil;
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                errorCB(error, response, task);
            });
            
        }
        else {
            NSLog(@"Unhandled network error: %@", error);
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
            NSLog(@"Unhandled network error: %@", error);
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
            NSLog(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

- (void)getYoutubeCanonicalID:(NSURL *)originalURL success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSURLRequest *request = [NSURLRequest requestWithURL:originalURL];
    
    [self.session GET:request success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSString *html = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        NSString *canonical = nil;
        
        // HTML
        NSString *startString = @"<link rel=\"canonical\" href=\"";
        
        NSScanner *scanner = [[NSScanner alloc] initWithString:html];
        
        [scanner scanUpToString:startString intoString:nil];
        
        scanner.scanLocation += startString.length;
        
        [scanner scanUpToString:@"\"" intoString:&canonical];
        
        scanner = nil;
        html = nil;
        
        if (successCB) {
            successCB(canonical, response, task);
        }
        
    } error:errorCB];
    
}

- (void)markRead:(NSString *)feedID articleID:(NSNumber *)articleID direction:(NSUInteger)direction sortType:(YetiSortOption)sortType success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSString *path = formattedString(@"/2.0/feeds/%@/markReadBatch", feedID);
    
    NSMutableDictionary *params = @{@"articleID": articleID,
                                    @"direction": @(direction),
                                    @"sortType": sortType
    }.mutableCopy;
    
    if ([feedID isEqualToString:@"today"]) {
        
        NSDate *today = [NSDate date];
        NSDateComponents *comps = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:today];
        
        NSString *todayString = [NSString stringWithFormat:@"%@-%@-%@", @(comps.year), @(comps.month), @(comps.day)];
        
        params[@"date"] = todayString;
        
    }
    
    [self.session POST:path parameters:params success:^(NSDictionary * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        BOOL status = [[responseObject valueForKey:@"status"] boolValue];
        
        if (status == NO) {
            
            if (successCB) {
                
                runOnMainQueueWithoutDeadlocking(^{
                    successCB(@0, response, task);
                });
                
                
            }
            
            return;
            
        }
        
        NSNumber *changed = [responseObject valueForKey:@"rows"];
        
        self.totalUnread = MAX(0, self.totalUnread - changed.integerValue);
        
        if ([feedID isEqualToString:@"unread"] == NO && [feedID isEqualToString:@"today"] == NO) {
            
            NSNumber *feedIDNumber = @([feedID integerValue]);
            
            Feed *feed = [ArticlesManager.shared feedForID:feedIDNumber];
            
            if (feed != nil) {
                
                feed.unread = @(MAX(0, feed.unread.integerValue - changed.integerValue));
                
                if (feed.folderID != nil) {
                    
                    Folder *folder = [self folderForID:feed.folderID];
                    
                    if (folder != nil) {
                        
                        [folder updateUnreadCount];
                        
                    }
                    
                }
                
            }
            
        }
        
        if (successCB) {
            
            runOnMainQueueWithoutDeadlocking(^{
                successCB(changed, response, task);
            });
            
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

#pragma mark - Custom Feeds

- (void)updateUnreadArray
{
//    NSMutableArray <NSNumber *> * markedRead = @[].mutableCopy;
//    
//    NSArray <FeedItem *> *newUnread = [ArticlesManager.shared.unread rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
//        BOOL isRead = obj.isRead;
//        if (isRead) {
//            [markedRead addObject:obj.identifier];
//        }
//        return !isRead;
//    }];
//    
//    if (!markedRead.count)
//        return;
//    
//    ArticlesManager.shared.unread = newUnread;
//    
//    // propagate changes to the feeds object as well
//    [self updateFeedsReadCount:ArticlesManager.shared.feeds markedRead:markedRead];
//    
//    for (Folder *folder in ArticlesManager.shared.folders) { @autoreleasepool {
//       
//        [self updateFeedsReadCount:folder.feeds.allObjects markedRead:markedRead];
//        
//    } }
    
}

- (void)updateFeedsReadCount:(NSArray <Feed *> *)feeds markedRead:(NSArray <NSNumber *> *)markedRead {
    if (!feeds || feeds.count == 0)
        return;
    
    for (Feed *obj in feeds) { @autoreleasepool {
        
        BOOL marked = NO;
        NSNumber *feedID = obj.feedID.copy;
        
//        for (FeedItem *item in obj.articles) {
//            
//            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF == %d", item.identifier.integerValue];
//            NSArray *filteredArray = [markedRead filteredArrayUsingPredicate:predicate];
//            NSLogDebug(@"Index: %@", filteredArray);
//            
//            if (filteredArray.count > 0 && !item.read) {
//                item.read = YES;
//                
//                if (!marked)
//                    marked = YES;
//            }
//        }
        
        if (marked) {
            [[NSNotificationCenter defaultCenter] postNotificationName:FeedDidUpReadCount object:feedID];
        }
        
    }}
}

- (void)getUnreadForPage:(NSInteger)page limit:(NSInteger)limit sorting:(YetiSortOption)sorting success:(successBlock)successCB error:(errorBlock)errorCB {
    
    if ([self userID] == nil) {
        if (errorCB)
            errorCB(nil, nil, nil);

        return;
    }

    NSMutableDictionary *params = @{@"userID": MyFeedsManager.userID, @"page": @(page), @"limit": @(limit), @"sortType":  @(sorting.integerValue)}.mutableCopy;

#if TESTFLIGHT == 0
    if ([self subscription] != nil && [self.subscription hasExpired] == YES) {
        params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
    }
#endif

    [self.session GET:@"/unread" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {

        NSArray <FeedItem *> * items = [[responseObject valueForKey:@"articles"] rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];

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
            NSLog(@"Unhandled network error: %@", error);
        }
    }];
}

- (void)getBookmarksWithSuccess:(successBlock)successCB error:(errorBlock)errorCB
{
    
    NSString *existing = @"";
    
    if (ArticlesManager.shared.bookmarks.count) {
        NSArray <FeedItem *> *bookmarks = ArticlesManager.shared.bookmarks;
        existing = [[bookmarks rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
            return obj.identifier.stringValue;
        }] componentsJoinedByString:@","];
    }
    
    [self.session POST:formattedString(@"/bookmarked?userID=%@", MyFeedsManager.userID) parameters:@{@"existing": existing} success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
    }];
}

#pragma mark - Folders

- (void)addFolder:(NSString *)title success:(successBlock)successCB error:(errorBlock)errorCB
{
    
    if (!title || (title && [title isBlank] == YES)) {
        
        if (errorCB) {
            errorCB([NSError errorWithDomain:DZErrorDomain code:403 userInfo:@{NSLocalizedDescriptionKey: @"Please enter a title for the Folder."}], nil, nil);
        }
        
        return;
    }
    
    [self.session PUT:@"/folder" queryParams:@{@"userID": [self userID]} parameters:@{@"title": title} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        id retval = [responseObject valueForKey:@"folder"];
        
        Folder *instance = [Folder instanceFromDictionary:retval];
        
        NSArray <Folder *> *folders = [ArticlesManager.shared folders];
        folders = [folders arrayByAddingObject:instance];
        
        @synchronized (MyFeedsManager) {
            ArticlesManager.shared.folders = folders;
        }
        
        if (successCB)
            successCB(instance, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
    }];
}

- (void)renameFolder:(Folder *)folder to:(NSString *)title success:(successBlock)successCB error:(errorBlock)errorCB {
    
    [self updateFolder:folder properties:@{@"title": title ?: @""} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        BOOL status = [[responseObject valueForKey:@"status"] boolValue];
        
        if (!status) {
            if (errorCB) {
                NSError *error = [NSError errorWithDomain:FeedsManagerDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Failed to update the folder title. Please try again."}];
                errorCB(error, response, task);
            }
            return;
        }
      
        NSArray <Folder *> *folders = [ArticlesManager.shared folders];
        
        // update our caches
        [folders enumerateObjectsUsingBlock:^(Folder * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
           
            if ([obj.folderID isEqualToNumber:folder.folderID]) {
                obj.title = title;
                *stop = YES;
            }
            
        }];
        
        // this will fire the notification
        ArticlesManager.shared.folders = folders;
        
        if (successCB) {
            successCB(responseObject, response, task);
        }
        
    } error:errorCB];
}

- (void)updateFolder:(Folder *)folder add:(NSArray<NSNumber *> *)add remove:(NSArray<NSNumber *> *)del success:(successBlock)successCB error:(errorBlock)errorCB {
    
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
    
    [self updateFolder:folder properties:dict.copy success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        BOOL status = [[responseObject valueForKey:@"status"] boolValue];
        
        if (!status) {
            if (errorCB) {
                NSError *error = [NSError errorWithDomain:FeedsManagerDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Failed to update the folder preferences. Please try again."}];
                errorCB(error, response, task);
            }
            return;
        }
        
        // check delete ops first
        if (del && del.count) {
            NSArray <Feed *> * removedFeeds = [folder.feeds.allObjects rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                return [del indexOfObject:obj.feedID] != NSNotFound;
            }];
            
            [removedFeeds enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.folderID = nil;
                obj.folder = nil;
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
            NSArray <Feed *> * addedFeeds = [ArticlesManager.shared.feeds rz_filter:^BOOL(Feed *obj, NSUInteger idx, NSArray *array) {
                return [add indexOfObject:obj.feedID] != NSNotFound;
            }];
            
            if (addedFeeds != nil && addedFeeds.count) {
                    
                [addedFeeds enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    obj.folderID = folder.folderID;
                    obj.folder = folder;
                }];
                
                if (addedFeeds != nil && [addedFeeds isKindOfClass:NSArray.class] && addedFeeds.count) {
                    
                    [folder.feeds addObjectsFromArray:addedFeeds];
                    
                }
                
            }

        }
        
        // this pushes the update to FeedsVC
        dispatch_async(dispatch_get_main_queue(), ^{
            ArticlesManager.shared.feeds = [ArticlesManager.shared feeds];
        });
        
        if (successCB) {
            
            runOnMainQueueWithoutDeadlocking(^{
                successCB(responseObject, response, task);
            });
            
        }
        
    } error:errorCB];
}

- (void)removeFolder:(Folder *)folder success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSString *path = formattedString(@"/folder?userID=%@&folderID=%@", [self userID], folder.folderID);
    
    [self.session DELETE:path parameters:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        [[folder.feeds allObjects] enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            obj.folderID = nil;
            obj.folder = nil;
            
        }];
     
        NSArray <Folder *> *folders = [ArticlesManager.shared.folders rz_filter:^BOOL(Folder *obj, NSUInteger idx, NSArray *array) {
            return ![obj.folderID isEqualToNumber:folder.folderID];
        }];
        
        ArticlesManager.shared.folders = folders;
        
        ArticlesManager.shared.feeds = [ArticlesManager.shared feeds];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
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
            NSLog(@"Unhandled network error: %@", error);
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
    
    if ([self subscription] != nil && [self.subscription hasExpired] == YES) {
        params[@"upto"] = @([MyFeedsManager.subscription.expiry timeIntervalSince1970]);
    }
    
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
            NSLog(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

- (void)markFolderRead:(Folder *)folder success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSString *path;
    NSNumber *userID = [self userID] ?: @(0);
    
    NSNumber *folderID = folder.folderID;
    
    path = formattedString(@"/folder/%@/allread", folderID);
    
    [self.session GET:path parameters:@{@"userID": userID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        self.totalUnread = MAX(0, self.totalUnread - folder.unreadCount.integerValue);
        
        for (Feed *feed in folder.feeds.allObjects) {
            
            feed.unread = @(0);
            
        }
        
        [folder updateUnreadCount];
        
        if (successCB) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                successCB(responseObject, response, task);
            });
            
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
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
            NSLog(@"Unhandled network error: %@", error);
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
            NSLog(@"Unhandled network error: %@", error);
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
            NSLog(@"Unhandled network error: %@", error);
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
            NSLog(@"Unhandled network error: %@", error);
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
            NSLog(@"Unhandled network error: %@", error);
        }
        
    }];
}

- (void)getAllWebSubWithSuccess:(successBlock)successCB error:(errorBlock)errorCB {
    
    [self.session GET:@"/user/subscriptions" parameters:@{@"userID": self.userID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (!successCB) {
            return;
        }
        
        NSArray <Feed *> *feeds = [responseObject rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            Feed * feed = [Feed instanceFromDictionary:obj];
            [self updateFeedWithLocalName:feed];
            
            return feed;
        }];
        
        successCB(feeds, response, task);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
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
            NSLog(@"Unhandled network error: %@", error);
        }
        
    }];
}

- (void)unsubscribe:(Feed *)feed success:(successBlock)successCB error:(errorBlock)errorCB {
    
    [self.session DELETE:@"/user/subscriptions" parameters:@{@"userID": [self userID], @"feedID": feed.feedID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        feed.subscribed = NO;
        
        [MyDBManager updateFeed:feed];
        
        [ArticlesManager.shared.feeds enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (obj.feedID.unsignedIntegerValue == feed.feedID.unsignedIntegerValue) {
                
                obj.subscribed = NO;
                
                *stop = YES;
            }
            
        }];
        
        if (successCB) {
            
            runOnMainQueueWithoutDeadlocking(^{
                successCB(responseObject, response, task);
            });
            
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
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
                
                self.user.subscription = sub;
                
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
                
                self.user.subscription = sub;
                
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
            NSLog(@"Unhandled network error: %@", error);
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
            
//            if ([[responseObject valueForKey:@"status"] boolValue]) {
                Subscription *sub = [Subscription instanceFromDictionary:[responseObject valueForKey:@"subscription"]];
                
                self.user.subscription = sub;
            
            [MyDBManager setUser:self.user completion:^{
                
                if (successCB) {
                    successCB(responseObject, response, task);
                }
                
            }];
            
            [NSNotificationCenter.defaultCenter postNotificationName:YTSubscriptionPurchased object:nil];
//            }
//            else {
//                Subscription *sub = [Subscription new];
//                NSString *error = [responseObject valueForKey:@"message"] ?: @"An unknown error occurred when updating the subscription.";
//                sub.error = [NSError errorWithDomain:@"Yeti" code:-200 userInfo:@{NSLocalizedDescriptionKey: error}];
//                
//                self.subscription = sub;
//                
//                if (errorCB) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        errorCB(sub.error, response, task);
//                    });
//                }
//            }
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSLog(@"Subscription Error: %@", error.localizedDescription);
            
            Subscription *sub = [Subscription new];
            sub.error = error;
            
            strongify(self);
            
            self.user.subscription = sub;
            
            NSError * err = [self errorFromResponse:error.userInfo];
            
            if (errorCB)
                errorCB(err, response, task);
            else {
                NSLog(@"Unhandled network error: %@", error);
            }
            
        });
        
    }];
    
}

- (void)getSubscriptionWithSuccess:(successBlock)successCB error:(errorBlock)errorCB {

    weakify(self);

    [self.session GET:@"/store" parameters:@{@"userID": self.user.userID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            if ([[responseObject valueForKey:@"status"] boolValue]) {
                
                NSMutableDictionary *dict = [(NSDictionary *)[responseObject valueForKey:@"subscription"] mutableCopy];
                NSDictionary *stripeData = nil;
                
                // we remove this info so we can set it later.
                // this way, values get overriden.
                if ([dict valueForKey:@"stripe"]) {
                    stripeData = [dict valueForKey:@"stripe"];
                    [dict removeObjectForKey:@"stripe"];
                }
                
                Subscription *sub = [Subscription instanceFromDictionary:dict];
                
                if (stripeData != nil) {
                    [sub setValue:stripeData forKey:@"stripe"];
                }
                
                self.user.subscription = sub;
                
                [MyDBManager setUser:self.user completion:^{
                        
                    if (successCB) {
                        
                        successCB(responseObject, response, task);
                        
                    }
                    
                }];

            }
            else {
                Subscription *sub = [Subscription new];
                NSString *error = [responseObject valueForKey:@"message"] ?: @"An unknown error occurred when updating the subscription.";
                sub.error = [NSError errorWithDomain:@"Yeti" code:-200 userInfo:@{NSLocalizedDescriptionKey: error}];
                
                 self.user.subscription = sub;
                
                if (errorCB) {
                    
                    runOnMainQueueWithoutDeadlocking(^{
                        errorCB(sub.error, response, task);
                    });
                }
            }
        });
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            NSLog(@"Subscription Error: %@", error.localizedDescription);
            
            Subscription *sub = [Subscription new];
            sub.error = error;
            
            strongify(self);
            
            self.user.subscription = sub;
            
            NSError * err = [self errorFromResponse:error.userInfo];
            
            if (errorCB)
                errorCB(err, response, task);
            else {
                NSLog(@"Unhandled network error: %@", error);
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
            NSLog(@"Unhandled network error: %@", error);
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
    
    __block DZURLSession *session = self.session;
    
    runOnMainQueueWithoutDeadlocking(^{
        
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            
            // use the background session for sync.
            NSLog(@"Setup getSync task in background mode");
            
            session = self.backgroundSession;
            
        }
        
    });
    
    [session GET:@"/1.7/sync" parameters:query success:^(NSDictionary * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (response.statusCode == 304) {
            // nothing changed. exit early
            
            if (successCB) {
                successCB(nil, response, task);
            }
            
            return;
        }
        
        // server will respond with changes and changeToken
        NSString *changeToken = responseObject[@"changeToken"];
        NSDictionary <NSString *, NSArray *> * changes = responseObject[@"changes"];
        
        if (successCB) {
            
            ChangeSet *changeSet = [[ChangeSet alloc] init];
            changeSet.changeToken = changeToken;
            
            NSArray *customFeeds = [changes valueForKey:@"customFeeds"];
            
            if (customFeeds != nil) {
                
                NSMutableArray <SyncChange *> *changeMembers = [[NSMutableArray alloc] initWithCapacity:customFeeds.count];
                
                for (NSDictionary *change in customFeeds) {
                    SyncChange *changeObj = [[SyncChange alloc] init];
                    [changeObj setValuesForKeysWithDictionary:change];
                    
                    [changeMembers addObject:changeObj];
                }
                
                changeSet.customFeeds = changeMembers.copy;
                
            }
            
            dispatch_group_t group = dispatch_group_create();

            NSArray *newFeeds = [changes valueForKey:@"newFeeds"];
            
            if (newFeeds != nil && newFeeds.count > 0 && session.isBackgroundSession == NO) {
                
                dispatch_group_enter(group);
                
                NSLogDebug(@"Getting feeds from sync");

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                   
                    [self getFeedsWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {

                        NSLogDebug(@"Got feeds response");
                        
                        if (responseObject != nil && [(NSNumber *)responseObject integerValue] == 2) {
                            dispatch_group_leave(group);
                        }
                        
                    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {

                        NSLogDebug(@"Got feeds response with error");

                        dispatch_group_leave(group);
                        
                    }];
                    
                });
                
            }
            
            NSArray *feedsWithNewArticles = [changes valueForKey:@"feedsWithNewArticles"];
            
            if (feedsWithNewArticles != nil && feedsWithNewArticles.count) {
                
                changeSet.feedsWithNewArticles = feedsWithNewArticles;
                
            }
            
            dispatch_group_notify(group, dispatch_get_main_queue(), ^ {
                successCB(changeSet, response, task);
            });
        
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

- (void)syncSettings {
    
    NSDictionary *allSettings = [NSUserDefaults.standardUserDefaults dictionaryRepresentation];
    
    // refine the scope to only our keys
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:allSettings.allKeys.count];
    
    NSMutableDictionary *existingKeys = [NSMutableDictionary new];
    
    for (NSString *key in self.class.defaultsKeys) {
        
        if (allSettings[key] != nil) {
            [arr addObject:@[key, allSettings[key]]];
            existingKeys[key] = [arr.lastObject lastObject];
        }
        
    }
    
    NSLogDebug(@"Current Settings: %@", arr);
    
    NSDictionary *params;
    
    if (MyFeedsManager.userID != nil) {
        params = @{@"userID": MyFeedsManager.userID};
    }
    
    __block DZURLSession *session = self.session;
    
    runOnMainQueueWithoutDeadlocking(^{
        
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            
            // use the background session for sync.
            NSLog(@"Setup getSync task in background mode");
            
            session = self.backgroundSession;
            
        }
        
    });
    
    // Get the existing items
    [session GET:@"/user/settings" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSLogDebug(@"Exsiting settings: %@", responseObject);
        
        if ([(NSArray *)responseObject count] == 0) {
            [self _putSyncSettings:arr];
        }
        else {
            
            NSMutableArray *settings = [NSMutableArray new];
            
            for (NSDictionary *dict in responseObject) {
                
                NSString *key = dict[@"name"];
                id value = dict[@"value"];
                NSString *type = dict[@"type"];
                
                if ([type isEqualToString:@"boolean"]) {
                    value = @([(NSNumber *)value boolValue]);
                }
                else if ([type isEqualToString:@"integer"]) {
                    value = @([(NSNumber *)value integerValue]);
                }
                else if ([type isEqualToString:@"double"]) {
                    value = @([(NSNumber *)value doubleValue]);
                }
                else if ([type isEqualToString:@"data"]) {
                    value = [NSJSONSerialization JSONObjectWithData:value options:kNilOptions error:nil];
                }
                else {}
                
                [settings addObject:@[key, value]];
                
            }
            
            NSSet <NSArray *> * existing = [NSSet setWithArray:arr];
            NSSet <NSArray *> * newKeys = [NSSet setWithArray:settings];
            
            NSMutableSet <NSArray *> * newToLocal = newKeys.mutableCopy;
            [newToLocal minusSet:existing];
            
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
            // update newToLocal to the sever
            for (NSArray *newItem in newToLocal) {
//                [defaults set]
                [defaults setObject:newItem.lastObject forKey:newItem.firstObject];
            }
            
            [defaults synchronize];
            
            NSMutableSet <NSArray *> * newToServer = existing.mutableCopy;
            [newToServer minusSet:newKeys];
            
            for (NSArray *newItem in newToServer) {
                [self _postSyncSetting:newItem];
            }
            
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSLog(@"Error fetching sync defaults: %@", error);
        
    }];
    
}

- (NSArray <NSDictionary *> *)_formatSettings:(NSArray <NSArray *> *)settings {
    
    NSMutableArray *formatted = [NSMutableArray arrayWithCapacity:settings.count];
    
    for (NSArray *item in settings) {
        
        NSMutableDictionary * retItem = [NSMutableDictionary new];
        retItem[@"userID"] = self.userID;
        retItem[@"name"] = item.firstObject;
        
        id value = item.lastObject;
        NSString *type = @"string";
        
        if ([value isKindOfClass:NSArray.class] || [value isKindOfClass:NSDictionary.class]) {
            
            value = [NSJSONSerialization dataWithJSONObject:value options:kNilOptions error:nil];
            value = [[NSString alloc] initWithData:value encoding:NSUTF8StringEncoding];
            type = @"data";
            
        }
        else if ([value isKindOfClass:NSNumber.class]) {
            
            NSNumber *number = value;
            
            CFNumberType numberType = CFNumberGetType((CFNumberRef)number);
            
            if (numberType == kCFNumberCharType) {
                type = @"boolean";
            }
            else if (numberType == kCFNumberFloat32Type || numberType == kCFNumberFloat64Type || numberType == kCFNumberLongType || numberType == kCFNumberLongLongType || numberType == kCFNumberFloatType || numberType == kCFNumberDoubleType || numberType == kCFNumberCGFloatType) {
                type = @"double";
            }
            else {
                type = @"integer";
            }
            
        }
        
        retItem[@"type"] = type;
        retItem[@"value"] = value;
        
        [formatted addObject:retItem];
        
    }
    
    return formatted;
    
}

- (void)_putSyncSettings:(NSArray <NSArray *> *)settings {
    
    NSArray <NSDictionary *> * settingItems = [self _formatSettings:settings];
    
    __block DZURLSession *session = self.session;
    
    runOnMainQueueWithoutDeadlocking(^{
        
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            
            // use the background session for sync.
            NSLog(@"Setup getSync task in background mode");
            
            session = self.backgroundSession;
            
        }
        
    });
    
    [session PUT:@"/user/settings" queryParams:@{@"userID": self.userID} parameters:@{@"settings": settingItems} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSLog(@"Added sync defaults with response: %@", responseObject);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSLog(@"Error updating sync defaults: %@", error);
        
    }];
    
}

- (void)_postSyncSetting:(NSArray *)setting {
    
    NSArray *items = [self _formatSettings:@[setting]];
    NSDictionary *item = items.firstObject;
    
    __block DZURLSession *session = self.session;
    
    runOnMainQueueWithoutDeadlocking(^{
        
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            
            // use the background session for sync.
            NSLog(@"Setup getSync task in background mode");
            
            session = self.backgroundSession;
            
        }
        
    });
    
    [session POST:@"/user/settings" queryParams:@{@"userID": self.userID} parameters:item success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSLog(@"Added sync default with response: %@", responseObject);
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSLog(@"Error updating sync default: %@", error);
        
    }];
    
}

- (void)getSyncArticles:(NSDictionary *)params success:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSNumber *feedID = [params valueForKey:@"feedID"];
    
    if (feedID == nil || feedID.integerValue == 0) {
        
        if (errorCB) {
            
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:405 userInfo:@{NSLocalizedDescriptionKey: @"Invalid or no Feed ID was provided."}];
            
            runOnMainQueueWithoutDeadlocking(^{
                errorCB(error, nil, nil);
            });
            
        }
        
        return;
        
    }
    
    NSString *path = [NSString stringWithFormat:@"/2.2/feeds/%@", feedID];
    
    __block DZURLSession *session = self.session;
    
    runOnMainQueueWithoutDeadlocking(^{
        
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            
            // use the background session for sync.
            NSLog(@"Setup sync Articles task in background mode");
            
            session = self.backgroundSession;
            
        }
        
    });
    
    [session GET:path parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (!successCB) {
            return;
        }
        
        NSArray <NSDictionary *> *objects = [responseObject valueForKey:@"articles"];
        
        NSMutableArray <FeedItem *> *articles = [NSMutableArray arrayWithCapacity:objects.count];
        
        for (NSDictionary *obj in objects) {
            
            FeedItem *item = [FeedItem instanceFromDictionary:obj];
            
            [articles addObject:item];
            
        }
        
        if (successCB) {
            successCB(articles, response, task);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
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
            NSLog(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

- (NSURLSessionTask *)search:(NSString *)query feedID:(NSNumber *)feedID author:(NSString *)author success:(successBlock)successCB error:(errorBlock)errorCB {
    
    query = query ?: @"";
    
    NSMutableDictionary *body = @{@"search": query}.mutableCopy;
    
    if (author) {
        body[@"author"] = author;
    }
    
    NSDictionary *queryParams = @{@"userID": self.userID};
    
    NSString *path = [NSString stringWithFormat:@"/1.8/feed/%@/search", feedID];
    
    return [self.session POST:path queryParams:queryParams parameters:body success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSArray <NSDictionary *> *articleObjs = [responseObject valueForKey:@"articles"];
        
        NSArray <FeedItem *> *articles = [articleObjs rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        if (successCB) {
            successCB(articles, response, task);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

- (NSURLSessionTask *)searchUnread:(NSString *)query success:(successBlock)successCB error:(errorBlock)errorCB {
    
    query = query ?: @"";
    
    NSDictionary *body = @{@"search": query};
    
    NSDictionary *queryParams = @{@"userID": self.userID};
    
    NSString *path = [NSString stringWithFormat:@"/1.8/unread/search"];
    
    return [self.session POST:path queryParams:queryParams parameters:body success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSArray <NSDictionary *> *articleObjs = [responseObject valueForKey:@"articles"];
        
        NSArray <FeedItem *> *articles = [articleObjs rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        if (successCB) {
            successCB(articles, response, task);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

- (NSURLSessionTask *)searchToday:(NSString *)query success:(successBlock)successCB error:(errorBlock)errorCB {
    
    query = query ?: @"";
    
    NSDate *today = [NSDate date];
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay) fromDate:today];
    
    NSString *todayString = [NSString stringWithFormat:@"%@-%@-%@", @(comps.year), @(comps.month), @(comps.day)];
    
    NSDictionary *body = @{@"search": query, @"date": todayString};
    
    NSDictionary *queryParams = @{@"userID": self.userID};
    
    NSString *path = [NSString stringWithFormat:@"/1.8/today/search"];
    
    return [self.session POST:path queryParams:queryParams parameters:body success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSArray <NSDictionary *> *articleObjs = [responseObject valueForKey:@"articles"];
        
        NSArray <FeedItem *> *articles = [articleObjs rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        if (successCB) {
            successCB(articles, response, task);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

- (NSURLSessionTask *)search:(NSString *)query folderID:(NSNumber *)folderID success:(successBlock)successCB error:(errorBlock)errorCB {
    
    query = query ?: @"";
    
    NSDictionary *body = @{@"search": query};
    
    NSDictionary *queryParams = @{@"userID": self.userID};
    
    NSString *path = [NSString stringWithFormat:@"/1.8/folder/%@/search", folderID];
    
    return [self.session POST:path queryParams:queryParams parameters:body success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSArray <NSDictionary *> *articleObjs = [responseObject valueForKey:@"articles"];
        
        NSArray <FeedItem *> *articles = [articleObjs rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        if (successCB) {
            successCB(articles, response, task);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
        
    }];
    
}

#pragma mark - Setters

- (void)setTotalUnread:(NSUInteger)totalUnread {
    
    if (NSThread.isMainThread == NO) {
     
        [self performSelectorOnMainThread:@selector(setTotalUnread:) withObject:@(totalUnread) waitUntilDone:NO];
        
        return;
        
    }
    
    @synchronized (self) {
        if (totalUnread >= 999999999) {
            self->_totalUnread = 0;
        }
        else {
            self->_totalUnread = MAX(totalUnread, 0);
        }
    }
    
    if (SharedPrefs.badgeAppIcon) {
        
        UIApplication.sharedApplication.applicationIconBadgeNumber = self.totalUnread;
        
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:UnreadCountDidUpdate object:self userInfo:nil];
    
}

- (void)setTotalToday:(NSUInteger)totalToday {
    
    if (NSThread.isMainThread == NO) {
        
        [self performSelectorOnMainThread:@selector(setTotalUnread:) withObject:@(totalToday) waitUntilDone:NO];
        return;
        
    }
    
    if (totalToday > self.totalUnread) {
        totalToday = self.totalUnread;
    }
    
    if (totalToday >= 999999999) {
        self->_totalToday = 0;
    }
    else {
        self->_totalToday = MAX(totalToday, 0);
    }
    
    [NSNotificationCenter.defaultCenter postNotificationName:TodayCountDidUpdate object:self userInfo:nil];
    
}

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
            
            NSLogDebug(@"added push token: %@", responseObject);
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            NSLog(@"Add push token error: %@", error);
        }];
    }
}

- (void)setUserID:(NSNumber *)userID {
    self.user.userID = userID;
}

- (void)setUser:(User *)user {
    
    if (NSThread.isMainThread == NO) {
        return [self performSelectorOnMainThread:@selector(setUser:) withObject:user waitUntilDone:NO];
    }
    
    _user = user;
    
    [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
    
    if (user == nil) {
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    @synchronized (self) {
        
#if TARGET_OS_MACCATALYST
#ifndef DEBUG
        [self setupSubscriptionNotification];
#endif
#endif
        
        [defaults setValue:user.uuid forKey:@"accountID"];
        [defaults synchronize];
        
    }
    
}

#pragma mark - Getters

- (NSUInteger)totalToday {
    
    return _totalToday ?: 0;
    
}

- (NSString *)appFullVersion {
    
    if (_appFullVersion == nil) {
        _appFullVersion = [NSBundle.mainBundle.infoDictionary valueForKey:@"CFBundleShortVersionString"];
    }
    
    return _appFullVersion;
    
}

- (NSString *)appMajorVersion {
    
    if (_appMajorVersion == nil) {
        _appMajorVersion = [[self.appFullVersion componentsSeparatedByString:@"."] firstObject];
    }
    
    return _appMajorVersion;
    
}

- (Subscription *)subscription {
    return self.user.subscription;
}

- (Reachability *)reachability {
    if (!_reachability) {
        _reachability = [Reachability reachabilityWithHostName:@"api.elytra.app"];
    }
    
    return _reachability;
}

- (DZURLSession *)session {
    
    if (_session == nil) {

        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        defaultConfig.HTTPMaximumConnectionsPerHost = 10;

        NSDictionary *const additionalHTTPHeaders = @{
                                                      @"Accept": @"application/json",
                                                      @"Content-Type": @"application/json",
                                                      @"Accept-Encoding": @"gzip",
                                                      @"X-App-FullVersion": self.appFullVersion,
                                                      @"X-App-MajorVersion": self.appMajorVersion
                                                      };

        [defaultConfig setHTTPAdditionalHeaders:additionalHTTPHeaders];

        defaultConfig.allowsCellularAccess = YES;
        defaultConfig.HTTPShouldUsePipelining = YES;
        defaultConfig.waitsForConnectivity = NO;
        defaultConfig.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        defaultConfig.timeoutIntervalForRequest = 60;
        defaultConfig.HTTPShouldSetCookies = NO;
        defaultConfig.HTTPCookieAcceptPolicy = NSHTTPCookieAcceptPolicyNever;
        defaultConfig.URLCache = nil;

        DZURLSession *session = [[DZURLSession alloc] initWithSessionConfiguration:defaultConfig];
        
        session.baseURL = [NSURL URLWithString:@"http://127.0.0.1:3000"];
        session.baseURL =  [NSURL URLWithString:@"https://api-acc.elytra.app"];
#ifndef DEBUG
        session.baseURL = [NSURL URLWithString:@"https://api-acc.elytra.app"];
#endif
        session.useOMGUserAgent = YES;
        session.useActivityManager = YES;
        session.responseParser = [DZJSONResponseParser new];

        weakify(self);
        session.requestModifier = ^NSMutableURLRequest *(NSMutableURLRequest *request) {
          
            [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];

            // compute Authorization
            strongify(self);
            
            NSNumber *userID = self.userID ?: @0;
            
            NSString *UUID = (userID.integerValue > 0 && self.user.uuid) ? self.user.uuid : @"x890371abdgvdfggsnnaa=";
            NSString *encoded = [[UUID dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
            
            NSString *timecode = @([NSDate.date timeIntervalSince1970]).stringValue;
            NSString *stringToSign = formattedString(@"%@_%@_%@", userID, UUID, timecode);
            
            NSString *signature = [self hmac:stringToSign withKey:encoded];
            
            [request setValue:signature forHTTPHeaderField:@"x-authorization"];
            [request setValue:userID.stringValue forHTTPHeaderField:@"x-userid"];
            [request setValue:timecode forHTTPHeaderField:@"x-timestamp"];
            
            if (request.allHTTPHeaderFields[@"User-Agent"] != nil) {
                [request setValue:[request valueForHTTPHeaderField:@"User-Agent"] forHTTPHeaderField:@"x-user-agent"];
            }
            
            if (self.deviceID != nil) {
                [request setValue:self.deviceID forHTTPHeaderField:@"x-device"];
            }
            
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
        
        NSString *identifier = @"com.yeti.backgroundSession"; //stringByAppendingFormat:@":%@", @([NSDate.date timeIntervalSince1970])];
        
        NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        // one for unread and the other for bookmarks
        defaultConfig.HTTPMaximumConnectionsPerHost = 2;
        // tell the OS not to manage these, but let them continue in the background
        defaultConfig.discretionary = YES;
        // we always want fresh data from the background service
        defaultConfig.requestCachePolicy = NSURLRequestUseProtocolCachePolicy;
        
        defaultConfig.allowsCellularAccess = YES;
        defaultConfig.waitsForConnectivity = NO;
        defaultConfig.HTTPShouldUsePipelining = YES;
        defaultConfig.shouldUseExtendedBackgroundIdleMode = YES;
//        defaultConfig.discretionary = NO;
        
        [defaultConfig setHTTPAdditionalHeaders:@{
                                                  @"Accept": @"application/json",
                                                  @"Content-Type": @"application/json",
                                                  @"Accept-Encoding": @"gzip",
                                                  @"X-App-FullVersion": self.appFullVersion,
                                                  @"X-App-MajorVersion": self.appMajorVersion
                                                  }];
        
        DZURLSession *session = [[DZURLSession alloc] initWithSessionConfiguration:defaultConfig];
        
        session.baseURL = self.session.baseURL;
        session.useOMGUserAgent = YES;
        session.useActivityManager = YES;
        session.responseParser = [DZJSONResponseParser new];
        session.isBackgroundSession = YES;
        
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
                    NSLog(@"Error creating bookmarks directory: %@", error);
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

//#endif

#pragma mark - Notifications

- (void)didUpdateBookmarks:(NSNotification *)note {
    
    FeedItem *item = [note object];
    
    @synchronized(self) {
        self->_bookmarksCount = nil;
    }
    
    if (!item) {
        NSLog(@"A bookmark notification was posted but did not include a FeedItem object.");
        return;
    }
    
    BOOL isBookmarked = [[[note userInfo] valueForKey:@"bookmarked"] boolValue];
    
    if (isBookmarked) {
        // it was added
        @try {
            NSArray *bookmarks = [ArticlesManager.shared.bookmarks arrayByAddingObject:item];
            @synchronized (self) {
                ArticlesManager.shared.bookmarks = bookmarks;
            }
        }
        @catch (NSException *exc) {}
    }
    else {
        NSInteger itemID = item.identifier.integerValue;
        
        @try {
            NSArray <FeedItem *> *bookmarks = ArticlesManager.shared.bookmarks;
            bookmarks = [bookmarks rz_filter:^BOOL(FeedItem *obj, NSUInteger idx, NSArray *array) {
                return obj.identifier.integerValue != itemID;
            }];
            
            @synchronized (self) {
                ArticlesManager.shared.bookmarks = bookmarks;
            }
        } @catch (NSException *excp) {}
    }
    
    @synchronized (self) {
        self.bookmarksCount = @(ArticlesManager.shared.bookmarks.count);
    }
    
}

- (void)userDidUpdate {
    
    if (self.user == nil) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UserDidUpdate object:nil];
    
    weakify(self);
    
    // user ID can be nil at this point
    
    // this is called from the sync block now.
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        strongify(self);
//
//        [self updateBookmarksFromServer];
//
//    });
    
    if ((self.user.subscription == nil || self.user.subscription.expiry == nil)
        || (self.user.subscription != nil && [self.user.subscription hasExpired] == YES)) {
        
        [self getSubscriptionWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
         
            NSLog(@"Successfully fetched subscription: %@", self.user.subscription);
            
//            [MyDBManager setUser:self.user];
            
            if ([self.user.subscription hasExpired] == YES) {
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [NSNotificationCenter.defaultCenter postNotificationName:YTSubscriptionHasExpiredOrIsInvalid object:nil];
                });
                
            }
            
//            [MyDBManager setUser:self.user];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            UIViewController *presented = [(NSObject *)[[[[[UIApplication sharedApplication] connectedScenes] allObjects] firstObject] delegate] valueForKeyPath:@"coordinator.splitViewController.presentedViewController"];
            
            if (presented != nil && [presented isKindOfClass:UINavigationController.class]) {
                
                UINavigationController *nav = (id)presented;
                
                if ([nav.viewControllers.firstObject isKindOfClass:NSClassFromString(@"LaunchVC")]) {
                    return;
                }
                
            }
            
            [AlertManager showGenericAlertWithTitle:@"Error Fetching Subscription" message:error.localizedDescription];
            
        }];
        
    }
//    else {
//
//        if ([self.user.subscription hasExpired] == YES) {
//
//            self.user.subscription = nil;
//
//            [MyDBManager setUser:self.user];
//
//            [self performSelectorOnMainThread:@selector(userDidUpdate) withObject:nil waitUntilDone:NO];
//
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
    
    if (self.subscription == nil) {
        return;
    }
    
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
//        else {
//            text = @"Your Elytra Subscription expires tomorrow. Subscribe today to keep reading your RSS Feeds.";
//        }
        
        if (text == nil) {
            return;
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
                NSLog(@"Error scheduling notification: %@", error);
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
    ArticlesManager.shared.folders = nil;
    ArticlesManager.shared.feeds = nil;
//    ArticlesManager.shared.unread = nil;
    self.totalUnread = 0;
    
    [self.bookmarksManager _removeAllBookmarks:nil];
    
    [MyDBManager setUser:nil];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (defaults) {
        [defaults removeObjectForKey:kAccountID];
        [defaults removeObjectForKey:kUserID];
        [defaults removeObjectForKey:kUUIDString];
    }
    
    for (NSString *key in self.class.defaultsKeys) {
        
        @try {
            [defaults removeObjectForKey:key];
        }
        @catch (NSException * exc) {}
        
    }
    
    [defaults synchronize];
    
    [Keychain removeAllItems];
    
    self.user = nil;
    
    [MyAppDelegate.coordinator showLaunchVC];
    
}

- (void)deactivateAccountWithSuccess:(successBlock)successCB error:(errorBlock)errorCB {
    
    if (!MyFeedsManager.userID) {
        if (errorCB) {
            NSError *error = [NSError errorWithDomain:@"FeedManager" code:-401 userInfo:@{NSLocalizedDescriptionKey : @"No user account exists on this device."}];
            errorCB(error, nil, nil);
        }
        
        return;
    }
    
    NSString *path = formattedString(@"/1.4/%@/deactivate", self.user.uuid);
    
    [self.session POST:path queryParams:nil parameters:nil success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSNumber *statusVal = [responseObject valueForKey:@"status"];
        BOOL status = statusVal.boolValue;
        
        if (!status) {
            NSError *error = [NSError errorWithDomain:@"FeedManager" code:500 userInfo:@{NSLocalizedDescriptionKey: @"An unknown error occurred when deactivating your account. Please try again."}];
            
            if (errorCB)
                errorCB(error, response, task);
            else {
                NSLog(@"Unhandled network error: %@", error);
            }
            
            return;
        }
        
        if (successCB) {
            successCB(responseObject, response, task);
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
        }
    }];
    
}

#pragma mark - <YTUserDelegate>

- (void)signInWithApple:(NSString *)uuid success:(successBlock)successCB error:(errorBlock)errorCB {
    
    if (uuid == nil || [uuid isBlank] == YES) {
        
        if (errorCB) {
            NSError *error = [NSError errorWithDomain:FeedsManagerDomain code:402 userInfo:@{NSLocalizedDescriptionKey: @"An invalid or no user key was received."}];
            
            errorCB(error, nil, nil);
        }
        
        return;
    }
    
    NSDictionary *sub = @{@"sub": uuid};
    NSMutableDictionary *query = [NSMutableDictionary new];
    
    if (self.userID != nil) {
        query[@"userID"] = self.userID;
    }
    
    __unused NSURLSessionTask *task = [self.session POST:@"/user/appleid" queryParams:query parameters:sub success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        BOOL status = [([responseObject valueForKey:@"status"] ?: @(NO)) boolValue];
        
        if (status) {
            self.user.uuid = uuid;
        }
        
        if (successCB) {
            dispatch_async(dispatch_get_main_queue(), ^{
                successCB(successCB, response, task);
            });
        }
        
    } error:errorCB];
    
}

- (void)getUserInformation:(successBlock)successCB error:(errorBlock)errorCB {
    weakify(self);
    
    NSDictionary *params;
    
    if (MyFeedsManager.userID != nil) {
        params = @{@"userID": MyFeedsManager.userID};
    }

    else if (MyFeedsManager.user.uuid) {
        params = @{@"userID" : MyFeedsManager.user.uuid};
    }

    __unused NSURLSessionTask *task = [self.session GET:@"/user" parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
     
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
                NSLog(@"Unhandled network error: %@", error);
            }
        }
    }];
    
}

- (void)createUser:(NSString *)uuid success:(successBlock)successCB error:(errorBlock)errorCB {
    
    [self.session PUT:@"/user" parameters:@{@"uuid": uuid} success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        error = [self errorFromResponse:error.userInfo];
        
        if (errorCB)
            errorCB(error, response, task);
        else {
            NSLog(@"Unhandled network error: %@", error);
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
        
        NSDictionary *userObj = [responseObject objectForKey:@"user"];
        
        NSNumber * userID = [userObj valueForKey:@"id"];
         
        User *user = [User instanceFromDictionary:userObj];
        user.userID = userID;
        user.uuid = uuid;
        
        if (successCB) {
            
            runOnMainQueueWithoutDeadlocking(^{
                successCB(user, response, task);
            });
            
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        strongify(self);
        error = [self errorFromResponse:error.userInfo];
        
        if (error) {
            if (errorCB)
                errorCB(error, response, task);
            else {
                NSLog(@"Unhandled network error: %@", error);
            }
        }
    }];
}

- (void)startUserFreeTrial:(successBlock)successCB error:(errorBlock)errorCB {
    
    NSDate *date = NSDate.date;
    NSCalendar *calendar = [NSCalendar currentCalendar];
    calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    
    NSDateComponents *comps = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:date];
    
    comps.day += 14;
    
    NSDate *expiry = [calendar dateFromComponents:comps];
    
    NSDateFormatter *formatter = [NSDateFormatter new];
    formatter.dateFormat = @"YYYY-MM-dd HH:mm:ss";
    
    NSString *expiryString = [formatter stringFromDate:expiry];
    
    NSDictionary *body = @{@"expiry": expiryString};
    
    weakify(self);
    
    [self.session PUT:@"/1.7/trial" queryParams:@{} parameters:body success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        [self getSubscriptionWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            if (successCB) {
                
                runOnMainQueueWithoutDeadlocking(^{
                   
                    successCB(responseObject, response, task);
                    
                });
                
            }
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            strongify(self);
            error = [self errorFromResponse:error.userInfo];
            
            if (error) {
                if (errorCB)
                    errorCB(error, response, task);
                else {
                    NSLog(@"Unhandled network error: %@", error);
                }
            }
            
        }];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        error = [self errorFromResponse:error.userInfo];
        
        if (error) {
            if (errorCB)
                errorCB(error, response, task);
            else {
                NSLog(@"Unhandled network error: %@", error);
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
        
        return [NSError errorWithDomain:FeedsManagerDomain code:status userInfo:@{NSLocalizedDescriptionKey: errorString}];
    }
    else {
        errorString = [userInfo valueForKey:NSLocalizedDescriptionKey];
    }
    
    if (errorString)
        return [NSError errorWithDomain:FeedsManagerDomain code:0 userInfo:userInfo];
    
    return [NSError errorWithDomain:FeedsManagerDomain code:0 userInfo:@{NSLocalizedDescriptionKey: @"An unknown error has occurred."}];
    
}

#pragma mark - Misc

- (void)checkConstraintsForRequestingReview {
    
    if (self.shouldRequestReview == YES) {
        return;
    }
    
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
    
    NSString *countKey = [NSString stringWithFormat:@"launchCount-%@", appVersion];
    NSString *requestedReviewKey = [NSString stringWithFormat:@"requestedReview-%@", appVersion];

    NSInteger count = [Keychain integerFor:countKey error:nil];
    // trigger on 7th launch
    if (count > 6) {
        BOOL requestedVal = [Keychain boolFor:requestedReviewKey error:nil];
        if (requestedVal == NO) {
            self.shouldRequestReview = YES;
        }
    }

}

- (void)updateBookmarksFromServer
{
    
    if (MyFeedsManager.userID == nil) {
        return;
    }
    
    NSArray <NSString *> *existingArr = [self.bookmarksManager.bookmarks rz_map:^id(FeedItem *obj, NSUInteger idx, NSArray *array) {
        return obj.identifier.stringValue;
    }];
    
    // we no longer need the bookmarks in memory. 
    [self.bookmarksManager setValue:nil forKey:@"_bookmarks"];
    
    NSString *existing = [existingArr componentsJoinedByString:@","];
    
    weakify(self);
    
    NSDictionary *params = @{}, *queryParams = @{};
    
    if (existing) {
        params = @{@"existing": existing};
    }
    
    if (self.userID) {
        queryParams = @{@"userID": MyFeedsManager.userID};
    }
    
    [self.session POST:@"/bookmarked" queryParams:queryParams parameters:params success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (response.statusCode >= 300) {
            // no changes.
            return;
        }
        
        NSArray <NSNumber *> * bookmarked = [responseObject valueForKey:@"bookmarks"];
        NSArray <NSNumber *> * deleted = [responseObject valueForKey:@"deleted"];
        
//        NSLogDebug(@"Bookmarked: %@\nDeleted:%@", bookmarked, deleted);
        
        strongify(self);
        
        if (self.bookmarksManager != nil && ((bookmarked && bookmarked.count) || (deleted && deleted.count))) {
            
            self.bookmarksManager->_migrating = YES;
            
            if (deleted && deleted.count) {
                
                for (NSNumber *articleID in deleted) {
                    
                    [self.bookmarksManager removeBookmarkForID:articleID completion:nil];
                    
                }
                
            }
            
            if (bookmarked && bookmarked.count) {
                
                bookmarked = [bookmarked rz_filter:^BOOL(NSNumber *obj, NSUInteger idx, NSArray *array) {
                   
                    return [existingArr indexOfObject:obj.stringValue] == NSNotFound;
                    
                }];
                
                __block NSUInteger count = bookmarked.count;
                
                if (count == 0) {
                    
                    return [self bookmarksUpdateFromServerCompleted];
                    
                }
                
                [bookmarked enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    
                    // this article needs to be downloaded and cached
                    
                    weakify(self);
                    
                    [self getArticle:obj feedID:nil noAuth:NO success:^(FeedItem * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                        
                        strongify(self);
                        
                        [self.bookmarksManager addBookmark:responseObject completion:nil];
                        
                        count--;
                        
                        if (count == 0) {
                            [self bookmarksUpdateFromServerCompleted];
                        }
                        
                    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                       
                        count--;
                        
                        if (count == 0) {
                            [self bookmarksUpdateFromServerCompleted];
                        }
                        
                    }];
                    
                }];
                
            }
            else {
                [self bookmarksUpdateFromServerCompleted];
            }
            
        }
        else {
            [self bookmarksUpdateFromServerCompleted];
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        NSLog(@"Failed to fetch bookmarks from the server.");
        NSLog(@"%@", error.localizedDescription);
        
    }];
    
}

- (void)bookmarksUpdateFromServerCompleted {
    
    self.bookmarksManager->_migrating = NO;
    
    weakify(self);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        strongify(self);
        
        @try {
           [self.bookmarksManager postNotification:BookmarksDidUpdateNotification object:nil];
        } @catch (NSException *exception) {
            NSLog(@"Exception when posting bookmarks notification, %@", exception);
        } @finally {
            
        }
    });
    
}

#pragma mark - Shared Containers

- (NSURL *)sharedContainerURL {
    
    return [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:@"group.elytra"];
    
}

- (void)writeToSharedFile:(NSString *)fileName data:(NSDictionary *)data {
    
    NSURL * baseURL = self.sharedContainerURL;
    
    NSURL *fileURL = [baseURL URLByAppendingPathComponent:fileName];
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    NSString *path = fileURL.filePathURL.path;
    
    NSError *error = nil;
    
    if ([fileManager fileExistsAtPath:path]) {
        // first remove the existing file
        NSLogDebug(@"Removing existing file from: %@", path);
        
        if ([fileManager removeItemAtPath:path error:&error] == NO) {
            
            NSLog(@"Error removing file: %@\nError: %@", path, error.localizedDescription);
            
            return;
        }
        
    }
    
    if (data == nil) {
        return;
    }
    
    NSData *dataRep = [NSJSONSerialization dataWithJSONObject:data options:kNilOptions error:&error];
    
    if (error != nil) {
        
        NSLog(@"Error serialising data: %@", error.localizedDescription);
        return;
        
    }
    
    if ([dataRep writeToFile:path atomically:YES] == NO) {
        
        NSLog(@"Failed to write data to %@", path);
        
    }
    
}

- (void)updateSharedUnreadCounters {
    
    if (self.widgetCountersUpdateTimer != nil) {
        
        [self.widgetCountersUpdateTimer invalidate];
        
        self.widgetCountersUpdateTimer = nil;
        
    }
    
    self.widgetCountersUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:10 repeats:NO block:^(NSTimer * _Nonnull timer) {
        
        NSMutableDictionary *dict = @{}.mutableCopy;
        
        dict[@"unread"] = @(self.totalUnread ?: 0);
        
        dict[@"today"] = @(self.totalToday ?: 0);
        
        dict[@"bookmarks"] = @(self.bookmarksManager.bookmarksCount ?: 0);
        
        dict[@"date"] = @([NSDate.date timeIntervalSince1970]);
        
        [self writeToSharedFile:@"counters.json" data:dict];
        
        [WidgetManager reloadTimelineWithName:@"CountersWidget"];
        
    }];
    
    [[NSRunLoop currentRunLoop] addTimer:self.widgetCountersUpdateTimer forMode:NSRunLoopCommonModes];
    
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
    
    if (self.user.userID != nil && self.user.uuid != nil) {
        [coder encodeInteger:self.userID.integerValue forKey:kUserID];
        [coder encodeObject:self.user.uuid forKey:kAccountID];
        
        [coder encodeObject:ArticlesManager.shared.folders forKey:kFoldersKey];
        [coder encodeObject:ArticlesManager.shared.feeds forKey:kFeedsKey];
//        [coder encodeObject:self.subscription forKey:kSubscriptionKey];
        [coder encodeObject:ArticlesManager.shared.bookmarks forKey:kBookmarksKey];
        [coder encodeObject:self.bookmarksCount forKey:kBookmarksCountKey];
        [coder encodeInteger:self.totalUnread forKey:ktotalUnreadKey];
//        [coder encodeObject:ArticlesManager.shared forKey:NSStringFromClass(ArticlesManager.class)];
        
        if (self.unreadLastUpdate) {
            [coder encodeDouble:[self.unreadLastUpdate timeIntervalSince1970] forKey:kUnreadLastUpdateKey];
        }
    }
    
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    
    NSString * UUIDString = [coder decodeObjectForKey:kAccountID];
    NSInteger userID = [coder decodeIntegerForKey:kUserID];
    
    if (UUIDString != nil && userID > 0) {
        self.user.userID = @(userID);
        self.user.uuid = UUIDString;
        
        [NSNotificationCenter.defaultCenter postNotificationName:UserDidUpdate object:nil];
        
        ArticlesManager.shared.folders = [coder decodeObjectForKey:kFoldersKey];
        ArticlesManager.shared.feeds = [coder decodeObjectForKey:kFeedsKey];
//        self.subscription = [coder decodeObjectForKey:kSubscriptionKey];
        ArticlesManager.shared.bookmarks = [coder decodeObjectForKey:kBookmarksKey];
        self.bookmarksCount = [coder decodeObjectForKey:kBookmarksCountKey];
        self.totalUnread = [coder decodeIntegerForKey:ktotalUnreadKey];
        
        double unreadUpdate = [coder decodeDoubleForKey:kUnreadLastUpdateKey];
        if (unreadUpdate) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:unreadUpdate];
            self.unreadLastUpdate = date;
        }
    }
    
}

- (void)continueActivity:(NSUserActivity *)activity {
    
    NSDictionary *manager = [activity.userInfo valueForKey:@"feedsManager"];
    
    self.totalUnread = [[manager valueForKey:@"totalUnread"] unsignedIntegerValue];
    self.totalToday = [[manager valueForKey:@"totalToday"] unsignedIntegerValue];
    
}

- (void)saveRestorationActivity:(NSUserActivity * _Nonnull)activity {
    
    if (self.userID == nil) {
        return;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    [dict setObject:@(self.totalUnread) forKey:@"totalUnread"];
    [dict setObject:@(self.totalToday) forKey:@"totalToday"];
    
    [activity addUserInfoEntriesFromDictionary:@{@"feedsManager":dict}];
    
}

@end
