//
//  AppDelegate+BackgroundRefresh.m
//  Yeti
//
//  Created by Nikhil Nigade on 04/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+BackgroundRefresh.h"

#import "Elytra-Swift.h"

#define backgroundRefreshIdentifier @"com.yeti.refresh"

@implementation AppDelegate (BackgroundRefresh)

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(nonnull NSString *)identifier completionHandler:(nonnull void (^)(void))completionHandler {
    
    NSLogDebug(@"Got a fresh background completion handler");
    
    [self.coordinator setBackgroundCompletionBlockWithCompletion:completionHandler];
    
}

@end
