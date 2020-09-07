//
//  SceneDelegate.m
//  AuthTest
//
//  Created by Nikhil Nigade on 23/07/20.
//

#import "SceneDelegate.h"
#import "PhotosController.h"
#import <JLRoutes/JLRoutes.h>

@interface SceneDelegate ()

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    
    if ([scene isKindOfClass:UIWindowScene.class] == NO) {
        return;
    }
    
    MainCoordinator *coordinator = [MainCoordinator new];
    
    self.coordinator = coordinator;
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    
    NSUserActivity *activity = connectionOptions.userActivities.allObjects.firstObject ?: session.stateRestorationActivity;

    if (activity != nil && [activity.activityType isEqualToString:@"restoration"] == NO) {
        
        UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
        window.canResizeToFitContent = YES;
        
        if ([activity.activityType isEqualToString:@"viewImage"] == YES) {
            
            PhotosController *photosVC = [[PhotosController alloc] initWithUserInfo:activity.userInfo];
            
            window.rootViewController = photosVC;
            
        }
        
        else if ([activity.activityType isEqualToString:@"openArticle"] == YES) {
            
            FeedItem *item = [FeedItem instanceFromDictionary:activity.userInfo];
            
            ArticleVC *vc = [[ArticleVC alloc] initWithItem:item];
#if TARGET_OS_MACCATALYST
            vc.externalWindow = YES;
#endif
            scene.title = item.articleTitle ?: @"Untitled";
            
            window.rootViewController = vc;
            
        }
        
        if (window.rootViewController != nil) {
                
            self.window = window;
            
            [window makeKeyAndVisible];
        }
        else {
            window = nil;
        }
        
        return;
        
    }
    
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    [self setupRootViewController];
    
    [self.coordinator start];
        
    [self.window makeKeyAndVisible];
    
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
// @TODO Implement from AppDelegate
//    [self _checkForAppResetPref];

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
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    
    if (URLContexts.count) {
        
        UIOpenURLContext *ctx = [URLContexts allObjects].firstObject;
        
        NSURL *URL = ctx.URL;
        
        __unused BOOL unused = [JLRoutes routeURL:URL];
        
    }
    
}

#pragma mark -

- (void)setupRootViewController {
    
    SplitVC *splitVC = [[SplitVC alloc] init];
    
    splitVC.mainCoordinator = self.coordinator;
    
    self.window.rootViewController = splitVC;
    
    self.coordinator.splitViewController = (SplitVC *)[self.window rootViewController];
    
    [splitVC loadViewIfNeeded];
    
}

@end
