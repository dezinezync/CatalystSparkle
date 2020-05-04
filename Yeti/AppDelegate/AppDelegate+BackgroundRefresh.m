//
//  AppDelegate+BackgroundRefresh.m
//  Yeti
//
//  Created by Nikhil Nigade on 04/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+BackgroundRefresh.h"

#import "DBManager+CloudCore.h"

@implementation AppDelegate (BackgroundRefresh)

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    [self scheduleBackgroundRefresh];
    
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
