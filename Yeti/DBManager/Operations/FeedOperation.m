//
//  FeedOperation.m
//  Yeti
//
//  Created by Nikhil Nigade on 13/12/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedOperation.h"
#import "DBManager+CloudCore.h"

@implementation FeedOperation

- (void)start {
    
    DDLogDebug(@"Starting Operation: %@", self);
    
    // network IO happens here.
    if (self.feed && self.customTitle) {
        
        [MyFeedsManager renameFeed:self.feed title:self.customTitle success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            // on success
            // since this can be called later on app-launch or restore, handle additional logic here
            [MyDBManager.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
                
                [(YapDatabaseCloudCoreTransaction *)[transaction ext:cloudCoreExtensionName] completeOperationWithUUID:self.uuid];
                
            }];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            YapDatabaseCloudCorePipeline *pipeline = [MyDBManager.cloudCoreExtension pipelineWithName:self.pipeline];
            
            if (pipeline) {
                //  on network failure
                // retry after one minute with backoff implemented by the framework
                [pipeline setStatusAsPendingForOperationWithUUID:self.uuid retryDelay:60];
                
                //  in case of a conflict
                // [pipeline suspend];
            }
            
        }];
        
    }
    else {
        DDLogError(@"Nothing to do in operation: %@ for feed: %@", NSStringFromClass(self.class), self.feed ? self.feed.title : @"No feed");
        
        // close this request
        [MyDBManager.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
            
            [(YapDatabaseCloudCoreTransaction *)[transaction ext:cloudCoreExtensionName] completeOperationWithUUID:self.uuid];
            
        }];
    }
//  on API error, use the same
//    [MyDBManager.bgConnection readWriteWithBlock:^(YapDatabaseReadWriteTransaction * _Nonnull transaction) {
//
//        [(YapDatabaseCloudCoreTransaction *)[transaction ext:cloudCoreExtensionName] completeOperationWithUUID:self.uuid];
//
//    }];

    
}

#pragma mark -

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        self.feed = [aDecoder decodeObjectForKey:propSel(feed)];
        self.customTitle = [aDecoder decodeObjectForKey:propSel(customTitle)];
        self.customOrder = [aDecoder decodeIntegerForKey:propSel(customOrder)];
    }
    
    return self;
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.feed forKey:propSel(feed)];
    [aCoder encodeObject:self.customTitle forKey:propSel(customTitle)];
    [aCoder encodeInteger:self.customOrder forKey:propSel(customOrder)];
    
}

- (instancetype)copy {
    
    FeedOperation *op = [super copy];
    
    [op setValuesForKeysWithDictionary:self.dictionaryRepresentation];
    
    op.completionBlock = self.completionBlock;
    
    return op;
    
}

- (BOOL)isEqualToOperation:(YapDatabaseCloudCoreOperation *)operation {
    
    if (operation == nil) {
        return NO;
    }
    
    if ([operation isKindOfClass:FeedOperation.class] == NO) {
        return NO;
    }
    
    FeedOperation *op = (FeedOperation *)operation;
    
    if (self.feed && [op.feed isEqualToFeed:self.feed]) {
        
        if ([self.customTitle isEqualToString:op.customTitle]) {
            return YES;
        }
        
        if (self.customOrder == op.customOrder) {
            return YES;
        }
        
    }
    
    return NO;
    
}

- (NSDictionary *)dictionaryRepresentation {
    
    NSMutableDictionary *dict = @{}.mutableCopy;
    
    if (self.feed) {
        [dict setObject:self.feed forKey:propSel(feed)];
    }
    
    if (self.customTitle) {
        [dict setObject:self.customTitle forKey:propSel(customTitle)];
    }
    
    if (self.customOrder) {
        [dict setObject:@(self.customOrder) forKey:propSel(customOrder)];
    }
    
    return dict.copy;
    
}

- (NSString *)description {
    
    NSString *desc = [super description];
    
    desc = formattedString(@"%@ - %@", desc, self.dictionaryRepresentation);
    
    return desc;
    
}

@end
