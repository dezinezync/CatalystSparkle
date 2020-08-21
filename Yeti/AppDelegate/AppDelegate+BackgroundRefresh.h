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

- (void)sceneDidEnterBackground:(UIScene *)scene;

- (void)setupBackgroundRefresh;

@end

NS_ASSUME_NONNULL_END
