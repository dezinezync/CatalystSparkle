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

@interface FeedsManager ()

@property (nonatomic, strong) DZURLSession *session;

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
        self.userID = @1;
    }
    
    return self;
}

#pragma mark - Feeds

- (NSArray <Feed *> *)feeds
{
    if (!_feeds) {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self getFeeds:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                dispatch_semaphore_signal(sema);
                
            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                _feeds = @[];
                dispatch_semaphore_signal(sema);
            }];
            
        });
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        
        dispatch_semaphore_signal(sema);
    }
    
    return _feeds;
}

- (void)getFeeds:(successBlock)successCB error:(errorBlock)errorCB
{
    weakify(self);
    
    [self.session GET:@"/feeds" parameters:@{@"userID": self.userID} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
      
        NSArray <Feed *> *feeds = [responseObject rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [Feed instanceFromDictionary:obj];
        }];
        
        strongify(self);
        
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        
        for (Feed *feed in feeds) {
            
            for (FeedItem *item in feed.articles) {
                NSString *key = item.guid.length > 32 ? item.guid.md5 : item.guid;
                item.read = [defaults boolForKey:key];
            }
            
        }
        
        self.feeds = feeds;
        
        if (successCB)
            successCB(self.feeds, response, task);
        
    } error:errorCB];
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
        
        NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
        
        for (FeedItem *item in items) {
            NSString *key = item.guid.length > 32 ? item.guid.md5 : item.guid;
            item.read = [defaults boolForKey:key];
        }
        
        if (feed)
            feed.articles = [feed.articles arrayByAddingObjectsFromArray:items];
        
        if (successCB)
            successCB(items, response, task);
        
    } error:errorCB];
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
    
    [self.session PUT:@"/feed" parameters:@{@"URL": url} success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        NSDictionary *feedObj = [responseObject valueForKey:@"feed"];
        NSArray *articlesObj = [responseObject valueForKey:@"articles"];
        
        NSArray <FeedItem *> *articles = [articlesObj rz_map:^id(id obj, NSUInteger idx, NSArray *array) {
            return [FeedItem instanceFromDictionary:obj];
        }];
        
        Feed *feed = [Feed instanceFromDictionary:feedObj];
        feed.articles = articles;
        
        if (successCB)
            successCB(feed, response, task);
        
    } error:errorCB];
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

@end
