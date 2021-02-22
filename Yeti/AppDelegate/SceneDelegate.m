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

#import "DZWebViewController.h"
#import "UIColor+HEX.h"

#import <CoreSpotlight/CoreSpotlight.h>

#import "Elytra-Swift.h"

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
    
#if TARGET_OS_MACCATALYST
    NSSet *DEFAULT_ACTIVITIES = [NSSet setWithObjects:@"main", @"restoration", nil];
    
    if (activity != nil && [DEFAULT_ACTIVITIES containsObject:activity.activityType] == NO) {
        
        [self handleSceneActivity:activity scene:windowScene];
        
        return;
        
    }
    
    if (MyAppDelegate.mainScene != nil) {
        
        [[UIApplication sharedApplication] requestSceneSessionDestruction:session options:nil errorHandler:nil];
        
        return;
    }
    
#endif
    
#if !TARGET_OS_MACCATALYST
    [self setupBackgroundRefresh];
#endif
    
    self.coordinator = MyAppDelegate.coordinator;
    
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.tintColor = SharedPrefs.tintColor;
    
#if !TARGET_OS_MACCATALYST
    UIColor *selectedColor = [[YetiThemeKit colours] objectAtIndex:SharedPrefs.iOSTintColorIndex];
    
     for (UIWindow *window in [UIApplication.sharedApplication windows]) {
         window.tintColor = selectedColor;
     };
#endif
    
    if (activity != nil && [activity.activityType isEqualToString:@"restoration"]) {
        
        [MyFeedsManager continueActivity:activity];
        
        [ArticlesManager.shared continueActivity:activity];
        
    }
    
    [self setupRootViewController];
    
    [self.coordinator start];
    
    if (activity != nil && [activity.activityType isEqualToString:@"restoration"]) {
        
        [self.window.rootViewController continueActivity:activity];
        
    }
    
#if TARGET_OS_MACCATALYST
    
    [self ct_setupToolbar:(UIWindowScene *)scene];
    
    MyAppDelegate.mainScene = (id)scene;
    
    MyAppDelegate.mainScene.titlebar.titleVisibility = UITitlebarTitleVisibilityVisible;
    MyAppDelegate.mainScene.titlebar.toolbarStyle = UITitlebarToolbarStyleUnifiedCompact;
    
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
    
//    [MyDBManager setFeeds:ArticlesManager.shared.feeds];
    
    [BGTaskScheduler.sharedScheduler getPendingTaskRequestsWithCompletionHandler:^(NSArray<BGTaskRequest *> * _Nonnull taskRequests) {
        
        BOOL cancelling = NO;
        
        if (taskRequests != nil && taskRequests.count > 0) {
            
            [BGTaskScheduler.sharedScheduler cancelAllTaskRequests];
            
            cancelling = YES;
            
        }
        
        [self scheduleBackgroundRefresh];
        
        if (cancelling == YES) {
            
//#ifdef DEBUG
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//
//            dispatch_async(self.bgTaskDispatchQueue, ^{
//                [[BGTaskScheduler sharedScheduler] performSelector:NSSelectorFromString(@"_simulateLaunchForTaskWithIdentifier:") withObject:backgroundRefreshIdentifier];
//            });
//
//#pragma clang diagnostic pop
//#endif
            
        }
        
    }];
    
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
    
    if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
        
        NSString *uniqueIdentifier = [userActivity.userInfo valueForKey:CSSearchableItemActivityIdentifier];
        
        if (uniqueIdentifier == nil) {
            return;
        }
        
        if ([uniqueIdentifier containsString:@"feed:"]) {
            
            NSString *feedID = [uniqueIdentifier stringByReplacingOccurrencesOfString:@"feed:" withString:@""];
            
            NSURL *url = [NSURL URLWithFormat:@"elytra://feed/%@", feedID];
            
            runOnMainQueueWithoutDeadlocking(^{
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
            });
            
        }
        
    }
    
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
            [ArticlesManager.shared saveRestorationActivity:restorationActivity];

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
            
            [vc.refreshControl setAttributedTitle:[vc lastUpdateAttributedString]];
            
//            [MyFeedsManager getCountersWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//                [vc setupData];
//
//                [vc.refreshControl setAttributedTitle:[vc lastUpdateAttributedString]];
//
//            } error:nil];
            
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

#if TARGET_OS_MACCATALYST

- (void)handleSceneActivity:(NSUserActivity *)activity scene:(UIWindowScene *)windowScene {
    
    UIWindow *window = nil;
    
    if ([activity.activityType isEqualToString:@"viewImage"] == YES) {
        
        window = [[UIWindow alloc] initWithWindowScene:windowScene];
        window.canResizeToFitContent = YES;
        
        PhotosController *photosVC = [[PhotosController alloc] initWithUserInfo:activity.userInfo];
        
        window.rootViewController = photosVC;
        
        CGSize size = CGSizeFromString([activity.userInfo valueForKey:@"size"]);
        
        windowScene.sizeRestrictions.minimumSize = size;
        windowScene.titlebar.titleVisibility = UITitlebarTitleVisibilityHidden;
        windowScene.titlebar.toolbar = nil;
        
    }
    
    else if ([activity.activityType isEqualToString:@"openArticle"] == YES) {
        
        window = [[UIWindow alloc] initWithWindowScene:windowScene];
        
        windowScene.sizeRestrictions.minimumSize = CGSizeMake(480.f, 600.f);
        windowScene.titlebar.toolbar = nil;
        
        FeedItem *item = [FeedItem instanceFromDictionary:activity.userInfo];
        
        ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];

        vc.externalWindow = YES;
        
        Feed *feed = [ArticlesManager.shared feedForID:item.feedID];
        
        if (item.articleTitle) {
            windowScene.title = formattedString(@"%@ - %@", item.articleTitle, feed.displayTitle);
        }
        else {
            windowScene.title = feed.displayTitle;
        }
        
        window.rootViewController = vc;
        
    }
    else if ([activity.activityType isEqualToString:@"subscriptionInterface"]) {
        
        window = [[UIWindow alloc] initWithWindowScene:windowScene];
        window.canResizeToFitContent = NO;
        
        CGSize fixedSize = CGSizeMake(375.f, 480.f);
        
        windowScene.sizeRestrictions.maximumSize = fixedSize;
        windowScene.sizeRestrictions.minimumSize = fixedSize;
        
        windowScene.title = @"Your Subscription";
        
        StoreVC *vc = [[StoreVC alloc] initWithStyle:UITableViewStyleGrouped];
        
        window.rootViewController = vc;
        
    }
    else if ([activity.activityType isEqualToString:@"attributionsScene"]) {
        
        window = [[UIWindow alloc] initWithWindowScene:windowScene];
        window.canResizeToFitContent = NO;
        
        CGSize fixedSize = CGSizeMake(375.f, 480.f);
        
        windowScene.sizeRestrictions.minimumSize = fixedSize;
        
        windowScene.title = @"Attributions";
        
        DZWebViewController *webVC = [[DZWebViewController alloc] init];
        webVC.title = @"Attributions";
        
        webVC.URL = [[NSBundle bundleForClass:self.class] URLForResource:@"attributions" withExtension:@"html"];
        
        NSString *tint = [UIColor hexFromUIColor:SharedPrefs.tintColor];
        NSString *js = formattedString(@"anchorStyle(\"%@\")", tint);
        
        webVC.evalJSOnLoad = js;
        
        window.rootViewController = webVC;
        
    }
    else if ([activity.activityType isEqualToString:@"newFeedScene"]) {
        
        window = [[UIWindow alloc] initWithWindowScene:windowScene];
        window.canResizeToFitContent = NO;
        
        CGSize fixedSize = CGSizeMake(480.f, 600.f);
        
        windowScene.sizeRestrictions.minimumSize = fixedSize;
        windowScene.sizeRestrictions.maximumSize = fixedSize;
        
        windowScene.titlebar.titleVisibility = UITitlebarTitleVisibilityVisible;
        windowScene.titlebar.toolbarStyle = UITitlebarToolbarStyleUnified;
        windowScene.title = @"New Feed";
        
        NewFeedVC *vc = [[NewFeedVC alloc] initWithCollectionViewLayout:NewFeedVC.gridLayout];
        vc.mainCoordinator = self.coordinator;
        vc.moveFoldersDelegate = self.coordinator.sidebarVC;
        
        window.rootViewController = [[UINavigationController alloc] initWithRootViewController:vc];
        
    }
    
    if (window != nil && window.rootViewController != nil) {
            
        self.window = window;
        self.window.tintColor = SharedPrefs.tintColor;
        
        [window makeKeyAndVisible];
    
    }
    else {
        window = nil;
    }
    
}

#endif

@end
