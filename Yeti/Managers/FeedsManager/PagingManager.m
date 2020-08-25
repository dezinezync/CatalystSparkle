//
//  PagingManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 07/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "PagingManager.h"

@interface PagingManager ()

/// The base path to request the data on
@property (nonatomic, copy, readwrite) NSString *path;

/// The static query parameters
@property (nonatomic, strong, readwrite) NSDictionary *queryParams;

/// The key name which contains the items. Eg. @"articles"
@property (nonatomic, copy, readwrite) NSString *itemsKey;

@property (nonatomic, strong, readwrite) NSMutableOrderedSet *uniqueItems;

/// The latest page that has been loaded.
@property (nonatomic, assign, readwrite) NSInteger page;

/// The total number of items available on this resrouce.
@property (nonatomic, assign, readwrite) NSInteger total;

@property (nonatomic, assign, readwrite) BOOL hasNextPage;

@property (nonatomic, copy) NSString *nextPageURL;

@property (nonatomic, assign, getter=isLoading) BOOL loading;

@property (nonatomic, copy) NSDictionary *HTTPBody;
@property (nonatomic, copy) NSString *HTTPMethod;

@end

@implementation PagingManager

- (instancetype)initWithPath:(NSString *)path queryParams:(NSDictionary *)queryParams itemsKey:(NSString *)itemsKey {
    
    if (self = [super init]) {
        
        self.path = path;
        self.queryParams = queryParams;
        self.itemsKey = itemsKey;
        self.HTTPMethod = @"GET";
        
        [self commonSetup];
        
    }
    
    return self;
    
}

- (instancetype)initWithPath:(NSString *)path queryParams:(NSDictionary *)queryParams body:(NSDictionary *)body itemsKey:(NSString *)itemsKey method:(NSString *)method {
    
    if (self = [super init]) {
        
        self.path = path;
        self.queryParams = queryParams;
        self.itemsKey = itemsKey;
        self.HTTPMethod = method;
        self.HTTPBody = body;
        
        [self commonSetup];
        
    }
    
    return self;
    
}

- (void)commonSetup {
    
    self.uniqueItems = [NSMutableOrderedSet new];
    self.page = 1;
    self.total = 0;
    self.hasNextPage = YES;
    
}

- (NSArray *)items {
    return self.uniqueItems.objectEnumerator.allObjects;
}

- (void)dealloc {
    
    self.preProcessorCB = nil;
    self.successCB = nil;
    self.errorCB = nil;
    
}

- (void)loadNextPage {
    
    if (self.hasNextPage == NO) {
        return;
    }
    
    if (self.isLoading == YES) {
        return;
    }
    
    self.loading = YES;
    
    NSMutableDictionary *params = self.queryParams.mutableCopy;
    params[@"page"] = @(self.page);
    
    if (self.nextPageURL != nil) {
        
        NSURLComponents *components = [NSURLComponents componentsWithString:self.nextPageURL];
        
        for (NSURLQueryItem *item in components.queryItems) {
            params[item.name] = item.value;
        }
        
    }
    
#ifdef DEBUG
//    NSLog(@"Paging params: %@", params);
#endif
    
    weakify(self);
    
    if ([params[@"page"] integerValue] > 1) {
        params[@"total"] = @(self.total);
    }
    
    NSString *path = self.path;
    
    NSString *url = [NSURL URLWithString:path relativeToURL:MyFeedsManager.session.baseURL].absoluteString;;
    
    id queryString = [MyFeedsManager.session stringifyQueryParams:params];
    
    if (queryString) {
        url = [url stringByAppendingFormat:@"?%@", queryString];
    }
    
    [MyFeedsManager.session performRequestWithURI:url method:self.HTTPMethod params:self.HTTPBody success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        self.loading = NO;
        
        self.page = [params[@"page"] integerValue];
        
        NSArray *items = self.itemsKey ? [responseObject valueForKey:self.itemsKey] : responseObject;
        
        NSNumber *total = [responseObject isKindOfClass:NSDictionary.class] ? [responseObject valueForKey:@"total"] : nil;
        
        responseObject = nil;
        
        if (total != nil) {
            self.total = total.integerValue;
        }
        else {
            
            if (items != nil) {
                self.total = items.count;
            }
            
        }
        
        [self processHeaders:response];
        
        if (items != nil && self.preProcessorCB) {
            items = self.preProcessorCB(items);
        }
        
        [self.uniqueItems addObjectsFromArray:items];
        
        if (self.successCB) {
            self.successCB();
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        self.loading = NO;
        
        if (self.errorCB) {
            self.errorCB(error);
        }
        
    }];
    
}

- (void)processHeaders:(NSHTTPURLResponse *)response {
    
    NSString *links = nil;
    
    links = [response valueForHTTPHeaderField:@"link"];
    
    if (links != nil) {
        
        NSMutableDictionary <NSString *, NSString *> *linkItems = [NSMutableDictionary new];
        
        NSArray <NSString *> *parts = [links componentsSeparatedByString:@","];
        
        [parts enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
            NSArray <NSString *> *linkParts = [obj componentsSeparatedByString:@";"];
            NSString *link = [linkParts firstObject];
            
            if (link.length) {
                link = [link substringFromIndex:1];
                link = [link substringToIndex:link.length - 1];
                link = [link stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            }
            
            NSString *key = [linkParts lastObject];
            key = [key stringByReplacingOccurrencesOfString:@"rel=\"" withString:@""];
            key = [key substringToIndex:key.length-1];
            key = [key stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            
            linkItems[key] = link;
            
        }];
        
        NSString *nextPageURL = [linkItems valueForKey:@"next"];
        
        if (nextPageURL != nil) {
            self.nextPageURL = [linkItems valueForKey:@"next"];
            self.hasNextPage = YES;
        }
        else {
            self.nextPageURL = nil;
            self.hasNextPage = NO;
        }
        
    }
    else {
        self.nextPageURL = nil;
        self.hasNextPage = NO;
    }
    
}

- (void)reset {
    
    self.page = 0;
    [self.uniqueItems removeAllObjects];
    
}

#pragma mark - <NSCoding>

+ (BOOL)supportsSecureCoding {
    
    return YES;
    
}

- (void)encodeWithCoder:(NSCoder *)coder {
    
    [coder encodeObject:self.path forKey:propSel(path)];
    
    if (self.queryParams) {
        [coder encodeObject:self.queryParams forKey:propSel(queryParams)];
    }
    
    [coder encodeObject:self.nextPageURL forKey:propSel(nextPageURL)];
    [coder encodeObject:self.itemsKey forKey:propSel(itemsKey)];
    [coder encodeInteger:self.page forKey:propSel(page)];
    [coder encodeInteger:self.total forKey:propSel(total)];
    [coder encodeBool:self.hasNextPage forKey:propSel(hasNextPage)];
    [coder encodeObject:self.uniqueItems forKey:propSel(uniqueItems)];
    
    if (self.objectClass) {
        [coder encodeObject:NSStringFromClass(self.objectClass) forKey:propSel(objectClass)];
    }
    
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    
    NSString *path = [coder decodeObjectOfClass:NSString.class forKey:propSel(path)];
    NSDictionary *queryParams = [coder decodeObjectOfClass:NSDictionary.class forKey:propSel(queryParams)];
    NSString *itemsKey = [coder decodeObjectOfClass:NSString.class forKey:propSel(itemsKey)];
    NSInteger page = [coder decodeIntegerForKey:propSel(page)];
    NSInteger total = [coder decodeIntegerForKey:propSel(total)];
    NSString *nextPageURL = [coder decodeObjectOfClass:NSString.class forKey:propSel(nextPageURL)];
    BOOL hasNextPage = [coder decodeBoolForKey:propSel(hasNextPage)];
    
    NSString *objectClassString = [coder decodeObjectOfClass:NSString.class forKey:propSel(objectClass)];
    Class objectClass;
    
    if (objectClassString != nil) {
        
        objectClass = NSClassFromString(objectClassString);
        
    }
    
    NSMutableSet <Class> *uniqueItemClasses = [[NSMutableSet alloc] initWithObjects:NSMutableOrderedSet.class, nil];
    
    if (objectClass != nil) {
        [uniqueItemClasses addObject:objectClass];
    }
    
    NSMutableOrderedSet *uniqueItems = [coder decodeObjectOfClasses:uniqueItemClasses forKey:propSel(uniqueItems)];
    
    PagingManager *instance = [[PagingManager alloc] initWithPath:path queryParams:queryParams itemsKey:itemsKey];
    instance.page = page;
    instance.total = total;
    instance.hasNextPage = hasNextPage;
    instance.uniqueItems = uniqueItems;
    instance.nextPageURL = nextPageURL;
    
    return instance;
    
    
}

@end