//
//  AppDelegate+Routing.m
//  Yeti
//
//  Created by Nikhil Nigade on 20/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+Routing.h"
#import <JLRoutes/JLRoutes.h>
#import "FeedsManager.h"

#import <DZKit/AlertManager.h>

@implementation AppDelegate (Routing)

- (void)setupRouting
{
    JLRoutes *feedsRouting = [JLRoutes routesForScheme:@"feed"];
    
    [feedsRouting addRoute:@"*" handler:^BOOL(NSDictionary *parameters) {
       
        NSURL *url = [NSURL URLWithString:[[[parameters valueForKey:kJLRouteURLKey] absoluteString] stringByReplacingOccurrencesOfString:@"feed:" withString:@""]];
        
        // check if we already have this feed
        Feed * have = nil;
        for (Feed *item in MyFeedsManager.feeds) {
            if ([item.url isEqualToString:url.absoluteString]) {
                have = item;
                break;
            }
        }
        
        if (have) {
         
            [AlertManager showGenericAlertWithTitle:@"Feed Exists" message:formattedString(@"You are already subscribed to %@", have.title)];
            
            return YES;
        }
        
        [MyFeedsManager addFeed:url success:^(Feed *responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            // check again if we have the feed
            BOOL haveItem = NO;
            for (Feed *item in MyFeedsManager.feeds) {
                if ([item.title isEqualToString:responseObject.title]) {
                    haveItem = YES;
                    break;
                }
            }
            
            if (!haveItem) {
                // we don't have it.
                MyFeedsManager.feeds = [MyFeedsManager.feeds arrayByAddingObject:responseObject];
            }
            else {
                [AlertManager showGenericAlertWithTitle:@"Feed Exists" message:formattedString(@"You are already subscribed to %@", responseObject.title)];
            }
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            [AlertManager showGenericAlertWithTitle:@"Error adding feed" message:error.localizedDescription];
            
        }];
        
        return YES;
    }];
}

@end
