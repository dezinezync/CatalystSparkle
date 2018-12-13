//
//  FeedOperation.h
//  Yeti
//
//  Created by Nikhil Nigade on 13/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <YapDatabase/YapDatabaseCloudCore.h>

NS_ASSUME_NONNULL_BEGIN

@interface FeedOperation : YapDatabaseCloudCoreOperation

/**
 If this is set to blank, and an existing custom title exists, it is removed
 */
@property (nonatomic, copy) NSString *customTitle;

/**
 If this is set to NSNotFound, any exisiting reordering info is removed.
 */
@property (nonatomic, assign) NSInteger customOrder;

@end

NS_ASSUME_NONNULL_END
