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

FeedsManager * _Nonnull MyFeedsManager = nil;

NSString * _Nonnull const FeedDidUpReadCount = @"com.yeti.note.feedDidUpdateReadCount";

@interface FeedsManager () <YTUserDelegate>

@property (nonatomic, strong, readwrite) DZURLSession *session;
@property (nonatomic, strong, readwrite) YTUserID *userIDManager;

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
        self.userIDManager = [[YTUserID alloc] initWithDelegate:self];
    }
    
    return self;
}

- (NSNumber *)userID
{
    return self.userIDManager.userID;
}

#pragma mark - Feeds

- (void)getFeeds:(successBlock)successCB error:(errorBlock)errorCB
{
    weakify(self);
    
    NSString *docsDir;
    NSArray *dirPaths;
    
    if (!self.userID) {
        // if the following error is thrown, it casues an undesirable user experience.
//        if (errorCB) {
//            NSError *error = [NSError errorWithDomain:@"FeedManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"No user account present."}];
//            errorCB(error, nil, nil);
//        }
        if (errorCB)
            errorCB(nil, nil, nil);
        return;
    }
    
    dirPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    docsDir = [dirPaths objectAtIndex:0];
    NSString *path = [[NSString alloc] initWithString: [docsDir stringByAppendingPathComponent:@"feedscache.json"]];
    
    __block NSError *error = nil;
    
    if ([NSFileManager.defaultManager fileExistsAtPath:path]) {
        NSData *data = [NSData dataWithContentsOfFile:path];
        
        if (data) {
            NSArray *responseObject = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
            
            if (error) {
                DDLogError(@"%@", error);
                if (errorCB)
                    errorCB(error, nil, nil);
            }
            else if (successCB) {
                DDLogDebug(@"Responding to successCB from disk cache");
                NSArray <Feed *> * feeds = [self parseFeedResponse:responseObject];
                
                self.feeds = feeds;
                
                successCB(@1, nil, nil);
            }
        }
    }
    
    [self.session GET:@"/feeds" parameters:@{@"userID": self.userID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        strongify(self);
        
        NSArray <Feed *> * feeds = [self parseFeedResponse:responseObject];
        
        // cache
        {
            NSData *data = [NSJSONSerialization dataWithJSONObject:responseObject options:kNilOptions error:&error];
            
            if (error) {
                DDLogError(@"%@", error);
            }
            else {
                if (![data writeToFile:path atomically:YES]) {
                    DDLogError(@"Writing feeds cache to %@ failed.", path);
                }
            }
        }
        
        self.feeds = feeds;
        
        if (successCB) {
            DDLogDebug(@"Responding to successCB from network");
            successCB(@2, response, task);
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
    NSArray <Feed *> *feeds = [responseObject rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
        return [Feed instanceFromDictionary:obj];
    }];
    
//    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    
//    for (Feed *feed in feeds) { @autoreleasepool {
//        
//        for (FeedItem *item in feed.articles) {
////            NSString *key = item.guid.length > 32 ? item.guid.md5 : item.guid;
////            item.read = [defaults boolForKey:key];
//        }
//        
//    } }
    
    return feeds;
}

- (void)getFeed:(Feed *)feed page:(NSInteger)page success:(successBlock)successCB error:(errorBlock)errorCB
{
    if (!page)
        page = 1;
    
    [self.session GET:formattedString(@"/feeds/%@", feed.feedID) parameters:@{@"page": @(page), @"userID": self.userID} success:^(NSDictionary * responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSArray <NSDictionary *> * articles = [responseObject valueForKey:@"articles"];
        
        NSArray <FeedItem *> *items = [articles rz_map:^id(NSDictionary *obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
//        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        
//        for (FeedItem *item in items) {
//            NSString *key = item.guid.length > 32 ? item.guid.md5 : item.guid;
////            item.read = [defaults boolForKey:key];
//        }
        
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
    
    [self.session PUT:@"/feed" parameters:@{@"URL": url, @"userID": @1} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
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

#pragma mark - Getters

- (DZURLSession *)session
{
    if (!_session) {
        DZURLSession *session = [[DZURLSession alloc] init];
        session.baseURL = [NSURL URLWithString:@"https://yeti.dezinezync.com"];
        session.useOMGUserAgent = YES;
        session.useActivityManager = YES;
        session.responseParser = [DZJSONResponseParser new];
        _session = session;
    }
    
    return _session;
}

#pragma mark - <YTUserDelegate>

- (void)getUserInformation:(successBlock)successCB error:(errorBlock)errorCB
{
    
//    if (!self.userID) {
//        if (errorCB) {
//            NSError *error = [NSError errorWithDomain:@"FeedManager" code:-1 userInfo:@{NSLocalizedDescriptionKey: @"No user ID currently present"}];
//            errorCB(error, nil, nil);
//        }
//
//        return;
//    }
    
    [self.session GET:@"/user" parameters:@{@"userID": self.userID ?: @""} success:successCB error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
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
    
    return nil;
    
}

@end
