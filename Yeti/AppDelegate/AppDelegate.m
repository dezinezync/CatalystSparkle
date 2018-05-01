//
//  AppDelegate.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+Routing.h"
#import "AppDelegate+Push.h"
#import "FeedsVC.h"
#import <DZKit/EFNavController.h>
#import <JLRoutes/JLRoutes.h>

#import "YetiConstants.h"
#import "EmptyVC.h"

#import <UserNotifications/UNUserNotificationCenter.h>

#import "SplitVC.h"

AppDelegate *MyAppDelegate = nil;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MyAppDelegate = self;
    });
    
    // Override point for customization after application launch.
    [ADZLogger initialize];
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    NSString *theme = [[NSUserDefaults standardUserDefaults] valueForKey:kDefaultsTheme];
    if ([theme isEqualToString:LightTheme]) {
        [self setupLightTheme];
    }
    else {
        [self setupDarkTheme];
    }
    
    [UNUserNotificationCenter currentNotificationCenter].delegate = (id <UNUserNotificationCenterDelegate>)self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [application registerForRemoteNotifications];
    });
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

#pragma mark - <DZAppDelegateProtocol>

- (NSDictionary *)appDefaults {
    return @{kDefaultsTheme: @"light",
             kDefaultsBackgroundRefresh: @YES,
             kDefaultsNotifications: @NO,
             kDefaultsImageLoading: ImageLoadingMediumRes,
             kDefaultsImageBandwidth: ImageLoadingAlways,
             kDefaultsArticleFont: ALPSystem
             };
}

- (void)setupRootController {
    
    FeedsVC *vc = [[FeedsVC alloc] initWithStyle:UITableViewStylePlain];
    EmptyVC *vc2 = [[EmptyVC alloc] initWithNibName:NSStringFromClass(EmptyVC.class) bundle:nil];
    
    UINavigationController *nav1 = [[UINavigationController alloc] initWithRootViewController:vc];
    
    SplitVC *splitVC = [[SplitVC alloc] init];
    
    if (self.window.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        UINavigationController *nav2 = [[UINavigationController alloc] initWithRootViewController:vc2];
        
        splitVC.viewControllers = @[nav1, nav2];
    }
    else {
        splitVC.viewControllers = @[nav1];
    }
    
    self.window.rootViewController = splitVC;
    
}

#pragma mark - Theming

- (void)setupLightTheme {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillUpdateTheme object:nil];
    
    self.window.tintColor = [UIColor colorWithDisplayP3Red:0.f green:122/255.f blue:1.f alpha:1.f];
    
    UINavigationBar *navBar = [UINavigationBar appearance];
    [navBar setBarStyle:UIBarStyleDefault];
    
    UITableView *tableView = [UITableView appearance];
    tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    
    UITableViewCell *cell = [UITableViewCell appearance];
    cell.backgroundColor = [UIColor whiteColor];
    
    [self refreshViews];
    
}

- (void)setupDarkTheme {
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kWillUpdateTheme object:nil];
    
    self.window.tintColor = [UIColor colorWithDisplayP3Red:1.f green:149/255.f blue:0.f alpha:1.f];
    
    UINavigationBar *navBar = [UINavigationBar appearance];
    [navBar setBarStyle:UIBarStyleBlackTranslucent];
    
    UITableView *tableView = [UITableView appearance];
    tableView.backgroundColor = [UIColor colorWithDisplayP3Red:93/255.f green:93/255.f blue:93/255.f alpha:1.f];
    
    UITableViewCell *cell = [UITableViewCell appearance];
    cell.backgroundColor = [UIColor colorWithDisplayP3Red:100/255.f green:100/255.f blue:100/255.f alpha:1.f];
    
    [self refreshViews];
    
}

// https://ngs.io/2014/10/26/refresh-ui-appearance/

- (void)refreshViews {

    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        for (UIView *view in window.subviews) {
            [view removeFromSuperview];
            [window addSubview:view];
        }
    }
    
    [[[[UIApplication sharedApplication] keyWindow] rootViewController] setNeedsStatusBarAppearanceUpdate];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDidUpdateTheme object:nil];
    
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
