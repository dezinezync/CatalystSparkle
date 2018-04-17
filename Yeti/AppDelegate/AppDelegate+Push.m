//
//  AppDelegate+Push.m
//  Yeti
//
//  Created by Nikhil Nigade on 17/04/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+Push.h"
#import "FeedsManager.h"

@implementation AppDelegate (Push)

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    const char *data = [deviceToken bytes];
    NSMutableString *token = [NSMutableString string];
    
    for (NSUInteger i = 0; i < [deviceToken length]; i++) {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    
    DDLogInfo(@"Registered for Push notifications with token: %@", token);
    
    MyFeedsManager.pushToken = token;
}

- (void)application:(UIApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    DDLogError(@"Failed to register for push notifications: %@", error.localizedDescription);
}

#pragma mark - <UNUserNotificationCenterDelegate>

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    completionHandler(UNNotificationPresentationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler
{
    if ([[response actionIdentifier] isEqualToString:UNNotificationDefaultActionIdentifier]) {
        // open the article
        UNNotification *notification = [response notification];
        UNNotificationRequest *request = [notification request];
        
        UNNotificationContent *content = [request content];
        
        NSDictionary *payload = [content userInfo];
        NSNumber *feedID = [payload valueForKey:@"feedID"];
        NSNumber *articleID = [payload valueForKey:@"articleID"];
        
        NSURL *url = formattedURL(@"yeti://feed/%@/article/%@", feedID, articleID);
        
        [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
    }
}

@end
