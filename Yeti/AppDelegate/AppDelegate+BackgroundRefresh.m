//
//  AppDelegate+BackgroundRefresh.m
//  Yeti
//
//  Created by Nikhil Nigade on 04/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+BackgroundRefresh.h"

#import "DBManager+CloudCore.h"

#import <DZNetworking/ImageLoader.h>

#import "SplitVC.h"

#define backgroundRefreshIdentifier @"com.yeti.refresh"

@implementation AppDelegate (BackgroundRefresh)

- (dispatch_queue_t)bgTaskDispatchQueue {
    
    if (_bgTaskDispatchQueue == nil) {
        _bgTaskDispatchQueue = dispatch_queue_create("BGTaskScheduler", DISPATCH_QUEUE_SERIAL);
    }
    
    return _bgTaskDispatchQueue;
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [SharedImageLoader.cache removeAllObjects];
    
    [BGTaskScheduler.sharedScheduler getPendingTaskRequestsWithCompletionHandler:^(NSArray<BGTaskRequest *> * _Nonnull taskRequests) {
        
        BOOL cancelling = NO;
        
        if (taskRequests != nil && taskRequests.count > 0) {
            
            [BGTaskScheduler.sharedScheduler cancelAllTaskRequests];
            
            cancelling = YES;
            
        }
        
        [self scheduleBackgroundRefresh];
        
        if (cancelling == YES) {
            
#ifdef DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

            dispatch_async(self.bgTaskDispatchQueue, ^{
                [[BGTaskScheduler sharedScheduler] performSelector:NSSelectorFromString(@"_simulateLaunchForTaskWithIdentifier:") withObject:backgroundRefreshIdentifier];
            });

#pragma clang diagnostic pop
#endif
            
        }
        
    }];
    
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(nonnull NSString *)identifier completionHandler:(nonnull void (^)(void))completionHandler {
    
#ifdef DEBUG
    NSLog(@"Got a fresh background completion handler");
#endif
    
    MyFeedsManager.backgroundSession.backgroundCompletionHandler = completionHandler;
//    MyDBManager.backgroundCompletionHandler = completionHandler;
    
}

- (void)scheduleBackgroundRefresh {
    
    // Note from NetNewsWire code
    // We send this to a dedicated serial queue because as of 11/05/19 on iOS 13.2 the call to the
    // task scheduler can hang indefinitely.
    dispatch_async(self.bgTaskDispatchQueue, ^{
        
        BGAppRefreshTaskRequest *request = [[BGAppRefreshTaskRequest alloc] initWithIdentifier:backgroundRefreshIdentifier];
//    request.requiresExternalPower = NO;
//    request.requiresNetworkConnectivity = YES;

            // 1 hour from backgrounding
        #ifdef DEBUG
            request.earliestBeginDate = [NSDate dateWithTimeIntervalSinceNow:1];
        #else
            request.earliestBeginDate = [NSDate dateWithTimeIntervalSinceNow:(60 * 60)];
        #endif

        NSError *error = nil;

        BOOL done = [[BGTaskScheduler sharedScheduler] submitTaskRequest:request error:&error];

        if (done == NO) {

            if (error != nil && error.code != 1) {

                NSLog(@"Error submitting bg refresh request: %@", error.localizedDescription);

            }

        }
        
    });
    
}

- (void)setupBackgroundRefresh {
    
    weakify(self);
    
    BOOL registered = [[BGTaskScheduler sharedScheduler] registerForTaskWithIdentifier:backgroundRefreshIdentifier usingQueue:nil launchHandler:^(__kindof BGAppRefreshTask * _Nonnull task) {
        
        NSLog(@"Woken to perform account refresh.");
        
        strongify(self);
        
        // schedule next refresh
        [self scheduleBackgroundRefresh];
       
        [MyDBManager setupSync:task completionHandler:^(BOOL completed) {
            
            if (completed == NO) {
                return;
            }
            
            SplitVC *vc = (SplitVC *)(self.window.rootViewController);

            if (!vc) {
                return;
            }

            UINavigationController *nav = (UINavigationController *)[[vc viewControllers] firstObject];

            if (!nav) {
                return;
            }

            FeedsVC *feedsVC = [[nav viewControllers] firstObject];

            if (!feedsVC) {
                return;
            }
            
            [MyFeedsManager getCountersWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                [feedsVC setupData];

                [feedsVC.refreshControl setAttributedTitle:[feedsVC lastUpdateAttributedString]];
                
            } error:nil];
            
        }];

        
    }];
    
    NSLog(@"Registered background refresh task: %@", @(registered));
    
}

@end
