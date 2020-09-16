//
//  AppDelegate+BackgroundRefresh.h
//  Yeti
//
//  Created by Nikhil Nigade on 04/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate (BackgroundRefresh)

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(nonnull NSString *)identifier completionHandler:(nonnull void (^)(void))completionHandler;

@end

NS_ASSUME_NONNULL_END
