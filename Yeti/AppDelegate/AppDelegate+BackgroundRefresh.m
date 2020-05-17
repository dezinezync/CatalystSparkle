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

@implementation AppDelegate (BackgroundRefresh)

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [self scheduleBackgroundRefresh];
    
    [SharedImageLoader.cache removeAllObjects];
    
//#ifdef DEBUG
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//    [[BGTaskScheduler sharedScheduler] performSelector:NSSelectorFromString(@"_simulateLaunchForTaskWithIdentifier:") withObject:@"com.yeti.refresh"];
//#pragma clang diagnostic pop
//#endif
    
}

- (void)scheduleBackgroundRefresh {
    
    BGAppRefreshTaskRequest *request = [[BGAppRefreshTaskRequest alloc] initWithIdentifier:@"com.yeti.refresh"];
    
    // 1 hour from backgrounding
    request.earliestBeginDate = [NSDate dateWithTimeIntervalSinceNow:(3600)];
    
    NSError *error = nil;
    
    if ([[BGTaskScheduler sharedScheduler] submitTaskRequest:request error:&error] == NO) {
        
        NSLog(@"Error submitting bg refresh request: %@", error.localizedDescription);
        
    }
    
}

- (void)setupBackgroundRefresh {
    
    [MyDBManager setValue:@(NO) forKey:@"syncSetup"];
    
    BOOL registered = [[BGTaskScheduler sharedScheduler] registerForTaskWithIdentifier:@"com.yeti.refresh" usingQueue:nil launchHandler:^(__kindof BGAppRefreshTask * _Nonnull task) {
       
        [MyDBManager setupSync:task];
        
    }];
    
    NSLog(@"Registered background refresh task: %@", @(registered));
    
    if (registered && [UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        [self scheduleBackgroundRefresh];
    }
    
}

@end
