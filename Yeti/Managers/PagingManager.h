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

@interface PagingManager : NSObject <NSSecureCoding>

- (instancetype)initWithPath:(NSString * _Nonnull)path queryParams:(NSDictionary * _Nonnull)queryParams itemsKey:(NSString * _Nonnull)itemsKey;

/// The base path to request the data on
@property (nonatomic, copy, readonly) NSString *path;

/// The static query parameters
@property (nonatomic, strong, readonly) NSDictionary *queryParams;

/// The key name which contains the items. Eg. @"articles"
@property (nonatomic, copy, readonly) NSString *itemsKey;

/// The latest page that has been loaded.
@property (nonatomic, assign, readonly) NSInteger page;

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

- (void)loadNextPage;

@end

NS_ASSUME_NONNULL_END
