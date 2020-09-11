//
//  AppDelegate+BackgroundRefresh.m
//  Yeti
//
//  Created by Nikhil Nigade on 04/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+BackgroundRefresh.h"

#import "DBManager+CloudCore.h"

#import "SplitVC.h"

#define backgroundRefreshIdentifier @"com.yeti.refresh"

@implementation AppDelegate (BackgroundRefresh)

- (dispatch_queue_t)bgTaskDispatchQueue {
    
    if (_bgTaskDispatchQueue == nil) {
        _bgTaskDispatchQueue = dispatch_queue_create("BGTaskScheduler", DISPATCH_QUEUE_SERIAL);
    }
    
    return _bgTaskDispatchQueue;
    
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(nonnull NSString *)identifier completionHandler:(nonnull void (^)(void))completionHandler {
    
    NSLogDebug(@"Got a fresh background completion handler");
    
    MyFeedsManager.backgroundSession.backgroundCompletionHandler = completionHandler;
    
}

@end
