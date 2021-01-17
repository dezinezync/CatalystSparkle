//
//  PagingManager.h
//  Yeti
//
//  Created by Nikhil Nigade on 07/10/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FeedsManager.h"
#import <DZKit/NSArray+RZArrayCandy.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSArray * _Nonnull(^preProcessorBlock)(NSArray * _Nonnull);
typedef void (^genericSuccessBlock)(void);
typedef void (^genericErrorBlock)(NSError *error);
typedef void (^dbFetchBlock)(void(^ completion)(NSArray * _Nullable items));

@interface PagingManager : NSObject <NSSecureCoding>

- (instancetype)initWithPath:(NSString * _Nonnull)path queryParams:(NSDictionary * _Nonnull)queryParams itemsKey:(NSString * _Nullable)itemsKey;

- (instancetype)initWithPath:(NSString * _Nonnull)path queryParams:(NSDictionary * _Nonnull)queryParams body:(NSDictionary * _Nullable)body itemsKey:(NSString * _Nonnull)itemsKey method:(NSString * _Nonnull)method;

@property (nonatomic, assign) BOOL fromDB;

/// The base path to request the data on
@property (nonatomic, copy, readonly) NSString *path;

/// The static query parameters
@property (nonatomic, strong, readonly) NSDictionary *queryParams;

/// The key name which contains the items. Eg. @"articles"
@property (nonatomic, copy, readonly) NSString *itemsKey;

/// The latest page that has been loaded.
@property (atomic, assign, readonly) NSInteger page;

/// The total number of items available on this resrouce.
@property (nonatomic, assign, readonly) NSInteger total;

@property (nonatomic, assign, readonly) BOOL hasNextPage;

@property (nonatomic, strong, readonly) NSMutableOrderedSet *uniqueItems;

- (NSArray *)items;

/// This block is called for the response with an array of items before adding them to the items array.
@property (nonatomic, copy) preProcessorBlock _Nullable preProcessorCB;

/// The success callback to call when items are updated
@property (nonatomic, copy) genericSuccessBlock _Nullable successCB;

/// The error callback to call when an network or misc. error occurs.
@property (nonatomic, copy) genericErrorBlock _Nullable errorCB;

@property (nonatomic, copy) dbFetchBlock _Nullable dbFetchingCB;

- (void)loadNextPage;

/// Resets the paging manager by setting page = 0 and removing all items from the uniqueItems set. 
- (void)reset;

/// This is used when restoring the object using state restoration. You can skip assignment to this property if you do not use it. 
@property (nonatomic, assign) Class objectClass;

@end

NS_ASSUME_NONNULL_END
