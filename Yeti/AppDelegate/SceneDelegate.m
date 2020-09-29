//
//  SceneDelegate.m
//  AuthTest
//
//  Created by Nikhil Nigade on 23/07/20.
//

#import "SceneDelegate+Catalyst.h"
#import "PhotosController.h"
#import <JLRoutes/JLRoutes.h>

#import "YetiThemeKit.h"
#import "AppDelegate.h"
#import "StoreVC.h"

#define backgroundRefreshIdentifier @"com.yeti.refresh"

@interface UIViewController (ElytraStateRestoration)

- (void)continueActivity:(NSUserActivity *)activity;

@end

@interface SceneDelegate () {
    dispatch_queue_t _bgTaskDispatchQueue;
}

@end

@implementation SceneDelegate

- (dispatch_queue_t)bgTaskDispatchQueue {
    
    if (_bgTaskDispatchQueue == nil) {
        _bgTaskDispatchQueue = dispatch_queue_create("BGTaskScheduler", DISPATCH_QUEUE_SERIAL);
    }
    
    return _bgTaskDispatchQueue;
    
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    
    if ([scene isKindOfClass:UIWindowScene.class] == NO) {
        return;
    }
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    
    NSUserActivity *activity = connectionOptions.userActivities.allObjects.firstObject ?: session.stateRestorationActivity;

    if (activity != nil) {
        
        UIWindow *window = nil;
        
        if ([activity.activityType isEqualToString:@"viewImage"] == YES) {
            
            window = [[UIWindow alloc] initWithWindowScene:windowScene];
            window.canResizeToFitContent = YES;
            
            PhotosController *photosVC = [[PhotosController alloc] initWithUserInfo:activity.userInfo];
            
            window.rootViewController = photosVC;
            
            windowScene.sizeRestrictions.minimumSize = CGSizeMake(600.f, 338.f);
            
        }
        
        else if ([activity.activityType isEqualToString:@"openArticle"] == YES) {
            
            window = [[UIWindow alloc] initWithWindowScene:windowScene];
            window.canResizeToFitContent = YES;
            
            FeedItem *item = [FeedItem instanceFromDictionary:activity.userInfo];
            
            ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];
#if TARGET_OS_MACCATALYST
            vc.externalWindow = YES;
#endif
            
            Feed *feed = [ArticlesManager.shared feedForID:item.feedID];
            
            if (item.articleTitle) {
                scene.title = formattedString(@"%@ - %@", item.articleTitle, feed.displayTitle);
            }
            else {
                scene.title = feed.displayTitle;
            }
            
            windowScene.sizeRestrictions.minimumSize = CGSizeMake(600.f, 400.f);
            
            window.rootViewController = vc;
            
        }
        else if ([activity.activityType isEqualToString:@"subscriptionInterface"]) {
            
            window = [[UIWindow alloc] initWithWindowScene:windowScene];
            window.canResizeToFitContent = NO;
            
            CGSize fixedSize = CGSizeMake(375.f, 480.f);
            
            windowScene.sizeRestrictions.maximumSize = fixedSize;
            windowScene.sizeRestrictions.minimumSize = fixedSize;
            
            scene.title = @"Your Subscription";
            
            StoreVC *vc = [[StoreVC alloc] initWithStyle:UITableViewStyleGrouped];
            
            window.rootViewController = vc;
            
        }
        
        if (window != nil && window.rootViewController != nil) {
                
            self.window = window;
            
            [window makeKeyAndVisible];
            
            return;
        }
        else {
            window = nil;
        }
        
    }
    
    [self setupBackgroundRefresh];
    
    self.coordinator = MyAppDelegate.coordinator;
    
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
#if !TARGET_OS_MACCATALYST
    UIColor *selectedColor = [[YetiThemeKit colours] objectAtIndex:SharedPrefs.iOSTintColorIndex];
    
     for (UIWindow *window in [UIApplication.sharedApplication windows]) {
         window.tintColor = selectedColor;
     };
#endif
    
    [self setupRootViewController];
    
    [self.coordinator start];
    
    if (activity != nil && [activity.activityType isEqualToString:@"restoration"]) {
        
        [self.window.rootViewController continueActivity:activity];
        
    }
    
#if TARGET_OS_MACCATALYST
    [self ct_setupToolbar:(UIWindowScene *)scene];
#endif
        
    [self.window makeKeyAndVisible];
    
    if (connectionOptions.URLContexts != nil) {
        
        [self scene:scene openURLContexts:connectionOptions.URLContexts];
        
    }
    
}

- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.

    [self _checkForAppResetPref];

}

- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
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

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    
    if (URLContexts.count) {
        
        UIOpenURLContext *ctx = [URLContexts allObjects].firstObject;
        
        NSURL *URL = ctx.URL;
        
        __unused BOOL unused = [JLRoutes routeURL:URL];
        
    }
    
}

- (NSUserActivity *)stateRestorationActivityForScene:(UIScene *)scene {

    NSUserActivity *restorationActivity = nil;

    if (self.window.rootViewController != nil && [self.window.rootViewController isKindOfClass:SplitVC.class] == YES) {

        restorationActivity = [(SplitVC *)[self.window rootViewController] continuationActivity];

        if (restorationActivity != nil) {

            [MyFeedsManager saveRestorationActivity:restorationActivity];

        }

    }

    return restorationActivity;

}

#pragma mark -

- (void)setupRootViewController {
    
    SplitVC *splitVC = [[SplitVC alloc] init];
    
    splitVC.mainCoordinator = self.coordinator;
    
    self.window.rootViewController = splitVC;
    
    self.coordinator.splitViewController = (SplitVC *)[self.window rootViewController];
    
    [splitVC loadViewIfNeeded];
    
}

#pragma mark - Background Refresh

- (void)scheduleBackgroundRefresh {
    
#if TARGET_OS_MACCATALYST
    return;
#endif
    
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
    
    if (MyAppDelegate.bgTaskHandlerRegistered == YES) {
        return;
    }
    
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
            
            SceneDelegate * scene = (id)[[UIApplication.sharedApplication.connectedScenes.allObjects firstObject] delegate];
            
            SidebarVC *vc = scene.coordinator.sidebarVC;
            
            if (vc == nil) {
                return;
            }
            
            [MyFeedsManager getCountersWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
                
                [vc setupData];

                [vc.refreshControl setAttributedTitle:[vc lastUpdateAttributedString]];
                
            } error:nil];
            
        }];

        
    }];
    
    MyAppDelegate.bgTaskHandlerRegistered = registered;
    
    NSLog(@"Registered background refresh task: %@", @(registered));
    
}

- (void)_checkForAppResetPref {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL reset = [defaults boolForKey:kResetAccountSettingsPref];
    
//#ifdef DEBUG
//    reset = YES;
//#endif
    
    if (reset) {
        [MyFeedsManager resetAccount];
        
        SplitVC *v = self.coordinator.splitViewController;
        [v userNotFound];
        
        [defaults setBool:NO forKey:kResetAccountSettingsPref];
        [defaults synchronize];
    }
    
}

@end
