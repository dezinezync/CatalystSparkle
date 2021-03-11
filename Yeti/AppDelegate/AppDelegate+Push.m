//
//  AppDelegate+Push.m
//  Yeti
//
//  Created by Nikhil Nigade on 17/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+Push.h"
#import "Elytra-Swift.h"

@implementation AppDelegate (Push)

- (void)registerNotificationCategories {
    
    UNNotificationAction *viewAction = [UNNotificationAction actionWithIdentifier:@"com.yeti.notification.action.view" title:@"View" options:UNNotificationActionOptionForeground];
    
    UNNotificationAction *cancel = [UNNotificationAction actionWithIdentifier:@"com.yeti.notification.action.cancel" title:@"Cancel" options:kNilOptions];
    
    UNNotificationCategory *articleCategory = [UNNotificationCategory categoryWithIdentifier:@"NOTE_CATEGORY_ARTICLE" actions:@[viewAction, cancel] intentIdentifiers:@[] options:UNNotificationCategoryOptionAllowAnnouncement&UNNotificationCategoryOptionCustomDismissAction];
    
    [[UNUserNotificationCenter currentNotificationCenter] setNotificationCategories:[NSSet setWithObject:articleCategory]];
    
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];
    
    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    
    NSLog(@"Registered for Push notifications with token: %@", token);
    // @TODO
//    MyFeedsManager.pushToken = token;
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Failed to register for push notifications: %@", error.localizedDescription);
}

#pragma mark - <UNUserNotificationCenterDelegate>

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    
    completionHandler(UNNotificationPresentationOptionBanner|UNNotificationPresentationOptionSound);
    
}

- (BOOL)application:(UIApplication *)application didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
    
    NSDictionary *types = [userInfo valueForKey:@"types"];
    // @TODO
//    BOOL isReads = [[types valueForKey:@"reads"] boolValue];
//
//    if (isReads) {
//
//        [MyDBManager setValue:@(NO) forKey:@"syncSetup"];
//        MyDBManager.backgroundFetchHandler = completionHandler;
//        [MyDBManager setupSync];
//
//        return YES;
//
//    }
//
//    BOOL isFeeds = [[types valueForKey:@"feeds"] boolValue];
//
//    if (isFeeds) {
//
//        self.coordinator.sidebarVC.backgroundFetchHandler = completionHandler;
//
//        [self.coordinator prepareFeedsForFullResync];
//
//        return YES;
//
//    }
//
//    BOOL isSubscription = [[types valueForKey:@"subscription"] boolValue];
//
//    if (isSubscription) {
//
//        [MyFeedsManager getSubscriptionWithSuccess:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//            completionHandler(response.statusCode == 304 ? UIBackgroundFetchResultNoData : UIBackgroundFetchResultNewData);
//
//        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//            completionHandler(UIBackgroundFetchResultFailed);
//
//        }];
//
//        return YES;
//
//    }
//
//    BOOL isArticle = [[types valueForKey:@"article"] boolValue];
//
//    if (isArticle) {
//
//        NSNumber *articleID = [userInfo valueForKey:@"articleID"];
//        NSNumber *feedID = [userInfo valueForKey:@"feedID"];
//
//        if (articleID != nil && feedID != nil) {
//
//            [MyFeedsManager getArticle:articleID feedID:feedID noAuth:NO success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//                completionHandler(UIBackgroundFetchResultNewData);
//
//            } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
//
//                completionHandler(UIBackgroundFetchResultFailed);
//
//            }];
//
//        }
//
//        return YES;
//
//    }
    
    return NO;
    
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    
    if ([response.notification.request.content.categoryIdentifier isEqualToString:@"NOTE_CATEGORY_ARTICLE"]) {
        // open the article
        
        if ([response.actionIdentifier containsString:@"action.cancel"]) {
            // do nothing
            completionHandler();
            return;
        }
        
        UNNotification *notification = [response notification];
        UNNotificationRequest *request = [notification request];
        
        UNNotificationContent *content = [request content];
        
        NSDictionary *payload = [content userInfo];
        
        if (payload == nil) {
            // do nothing
            completionHandler();
            return;
        }
        
        NSNumber *feedID = [payload valueForKey:@"feedID"];
        NSNumber *articleID = [payload valueForKey:@"articleID"];
        
        if (feedID == nil || articleID == nil) {
            
            // check if URL args exists
            if ([payload valueForKeyPath:@"aps.url-args"]  != nil) {
                
                // this will be an array.
                NSArray <NSNumber *> *args = [payload valueForKeyPath:@"aps.url-args"];
                
                feedID = [args firstObject];
                articleID = [args lastObject];
                
            }
            
            if (feedID == nil || articleID == nil) {
                // do nothing
                completionHandler();
                return;
            }
            
        }
        
        NSURL *url = formattedURL(@"yeti://feed/%@/article/%@", feedID, articleID);
        
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:^(BOOL success) {
            completionHandler();
        }];
    }
    else {
        completionHandler();
    }
    
//    else if ([[response actionIdentifier] isEqualToString:UNNotificationDefaultActionIdentifier]) {
//
//
//    }
    
    // else do nothing special.
}

@end
