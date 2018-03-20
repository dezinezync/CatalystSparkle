//
//  AppDelegate.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+Routing.h"
#import "FeedsVC.h"
#import <DZKit/EFNavController.h>
#import <JLRoutes/JLRoutes.h>

#import "YetiConstants.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [ADZLogger initialize];
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

#pragma mark - <DZAppDelegateProtocol>

- (NSDictionary *)appDefaults {
    return @{kDefaultsTheme: @"light",
             kDefaultsBackgroundRefresh: @YES,
             kDefaultsNotifications: @NO,
             kDefaultsImageLoading: ImageLoadingMediumRes,
             kDefaultsImageBandwidth: ImageLoadingAlways
             };
}

- (void)setupRootController {
    
    FeedsVC *vc = [[FeedsVC alloc] initWithStyle:UITableViewStylePlain];
    EFNavController *nav1 = [[EFNavController alloc] initWithRootViewController:vc];
    EFNavController *nav2 = [[EFNavController alloc] init];
    
    UISplitViewController *splitVC = [[UISplitViewController alloc] init];
    splitVC.viewControllers = @[nav1, nav2];
    self.window.rootViewController = splitVC;
    
}

#pragma mark -

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return [JLRoutes routeURL:url];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
