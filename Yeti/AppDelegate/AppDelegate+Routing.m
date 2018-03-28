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
#import "YetiConstants.h"

#import <DZKit/AlertManager.h>

@implementation AppDelegate (Routing)

- (void)popToRoot
{
    UISplitViewController *splitVC = (UISplitViewController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    UINavigationController *nav = (UINavigationController *)[[splitVC viewControllers] firstObject];
    
    if ([[nav viewControllers] count] > 1) {
        asyncMain(^{
            [nav popViewControllerAnimated:NO];
        });
    }
}

#pragma mark - Routing

- (void)setupRouting
{
    
    weakify(self);
    
    [[JLRoutes routesForScheme:@"feed"] addRoute:@"*" handler:^BOOL(NSDictionary *parameters) {
        
        strongify(self);
        
        [self popToRoot];
        
        NSURL *url = [NSURL URLWithString:[[[parameters valueForKey:kJLRouteURLKey] absoluteString] stringByReplacingOccurrencesOfString:@"feed:" withString:@""]];
        
        return [self addFeed:url];
        
    }];
    
    [[JLRoutes globalRoutes] addRoute:@"/addFeed" handler:^BOOL(NSDictionary *parameters) {
       
        strongify(self);
        
        [self popToRoot];
        
        NSString *path = [parameters valueForKey:@"URL"];
        
        if (path) {
            NSURL *url = [NSURL URLWithString:path];
            
            if (!url) {
                [AlertManager showGenericAlertWithTitle:@"Invalid link" message:@"The link seems to be invalid or Yeti was unable to process it correctly."];
                return YES;
            }
            
            [self addFeed:url];
            
        }
        else if ([parameters valueForKey:@"feedID"]) {
            
            NSNumber *feedID = @([[parameters valueForKey:@"feedID"] integerValue]);
            
            return [self addFeedByID:feedID];
            
        }
        
        return YES;
    }];
    
    [JLRoutes addRoute:@"/twitter/:type/:identifer" handler:^BOOL(NSDictionary *parameters) {
       
        NSString *type = [parameters valueForKey:@"type"];
        NSString *identifer = [parameters valueForKey:@"identifer"];
        
        if ([type isEqualToString:@"user"] || [type isEqualToString:@"user_mention"]) {
            [self twitterOpenUser:identifer];
        }
        else if ([type isEqualToString:@"status"]) {
            [self twitterOpenStatus:identifer];
        }
        
        return YES;
        
    }];
}

- (BOOL)addFeed:(NSURL *)url {
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
}

- (BOOL)addFeedByID:(NSNumber *)feedID
{
    
    [MyFeedsManager addFeedByID:feedID success:^(Feed *responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        // check again if we have the feed
        BOOL haveItem = NO;
        for (Feed *item in MyFeedsManager.feeds) {
            if (item.feedID.integerValue == feedID.integerValue) {
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
    
}

- (void)twitterOpenUser:(NSString *)username {
    
    NSString *twitterScheme = [[NSUserDefaults.standardUserDefaults valueForKey:ExternalTwitterAppScheme] lowercaseString];
    NSURL *URL;
    
    if ([twitterScheme isEqualToString:@"tweetbot"]) {
         URL = formattedURL(@"%@://dummyname/user_profile/%@", twitterScheme, username);
    }
    else if ([twitterScheme isEqualToString:@"twitter"]) {
         URL = formattedURL(@"%@://user?screen_name=%@", twitterScheme, username);
    }
    else if ([twitterScheme isEqualToString:@"twitterrific"]) {
         URL = formattedURL(@"%@://current/profile?screen_name=%@", twitterScheme, username);
    }
    
    [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
}

- (void)twitterOpenStatus:(NSString *)status {
    NSString *twitterScheme = [[NSUserDefaults.standardUserDefaults valueForKey:ExternalTwitterAppScheme] lowercaseString];
    NSURL *URL;
    
    if ([twitterScheme isEqualToString:@"tweetbot"]) {
        URL = formattedURL(@"%@://dummyname/status/%@", twitterScheme, status);
    }
    else if ([twitterScheme isEqualToString:@"twitter"]) {
        URL = formattedURL(@"%@://status?id=%@", twitterScheme, status);
    }
    else if ([twitterScheme isEqualToString:@"twitterrific"]) {
        URL = formattedURL(@"%@://current/tweet?id=%@", twitterScheme, status);
    }
    
    [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
}

@end
