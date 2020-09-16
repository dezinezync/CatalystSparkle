//
//  DBManager+CloudCore.h
//  Yeti
//
//  Created by Nikhil Nigade on 13/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DBManager.h"

NS_ASSUME_NONNULL_BEGIN

#define cloudCoreVersion @"1.2"

@interface DBManager (CloudCore) <YapDatabaseCloudCorePipelineDelegate>

- (void)registerCloudCoreExtension;

@end

NS_ASSUME_NONNULL_END
