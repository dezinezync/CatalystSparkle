//
//  DBManager+CloudCore.m
//  Yeti
//
//  Created by Nikhil Nigade on 13/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "DBManager+CloudCore.h"

@interface YapDatabaseCloudCoreOperation (StartMethodExtension)

- (void)start;

@end

@implementation DBManager (CloudCore)

- (void)registerCloudCoreExtension {
    
    [self.database asyncRegisterExtension:self.cloudCoreExtension withName:cloudCoreExtensionName completionQueue:dispatch_get_main_queue() completionBlock:^(BOOL ready) {
        
        NSLog(@"Cloud core extension registered !");
        
    }];
    
}

#pragma mark - Getters

- (YapDatabaseCloudCore *)cloudCoreExtension {
    
    if (_cloudCoreExtension == nil) {
        
        YapDatabaseCloudCore *ext = [[YapDatabaseCloudCore alloc] initWithVersionTag:cloudCoreVersion options:nil];
         
        YapDatabaseCloudCorePipeline *pipeline = [[YapDatabaseCloudCorePipeline alloc] initWithName:YapDatabaseCloudCoreDefaultPipelineName delegate:self];
        pipeline.maxConcurrentOperationCount = 5;
         
         [ext registerPipeline:pipeline];
        
        _cloudCoreExtension = ext;
        
    }
    
    return _cloudCoreExtension;
    
}

#pragma mark - <YapDatabaseCloudCorePipelineDelegate>

- (void)startOperation:(YapDatabaseCloudCoreOperation *)operation forPipeline:(YapDatabaseCloudCorePipeline *)pipeline {
    
    NSLogDebug(@"CloudCore:[Pipeline] %@ > %@", pipeline.name, operation);
    
    [operation start];

}

@end
