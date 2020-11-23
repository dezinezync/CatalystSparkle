//
//  ChangeSet.h
//  Yeti
//
//  Created by Nikhil Nigade on 23/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncChange.h"
#import "Feed.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChangeSet : NSObject

@property (nonatomic, copy) NSString *changeToken;
@property (nonatomic, strong) NSArray <SyncChange *> *customFeeds;
@property (nonatomic, strong) NSArray <NSNumber *> * feedsWithNewArticles;
@property (nonatomic, strong) NSArray <NSNumber *> * reads;

// The following is automatically managed by FeedsManager. 
//@property (nonatomic, strong) NSArray <Feed *> * feeds;

@end

NS_ASSUME_NONNULL_END
