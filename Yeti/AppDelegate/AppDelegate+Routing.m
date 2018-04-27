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

#import "FeedsVC.h"
#import "FeedVC.h"

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
    
    [JLRoutes addRoute:@"/feed/:feedID/article/:articleID" handler:^BOOL(NSDictionary *parameters) {
       
        NSNumber *feedID = @([[parameters valueForKey:@"feedID"] integerValue]);
        NSNumber *articleID = @([[parameters valueForKey:@"articleID"] integerValue]);
        
        [self openFeed:feedID article:articleID];
        
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

- (void)openFeed:(NSNumber *)feedID article:(NSNumber *)articleID
{
    
    if (![NSThread isMainThread]) {
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            [self openFeed:feedID article:articleID];
        });
        
        return;
    }
    
    weakify(self);
    
    __block BOOL isFolder = NO;
    __block BOOL isFolderExpanded = NO;
    __block NSUInteger folderIndex = NSNotFound;
    
    // get the primary navigation controller
    UINavigationController *nav = [[(UISplitViewController *)[[UIApplication.sharedApplication keyWindow] rootViewController] viewControllers] firstObject];
    
    if ([[nav topViewController] isKindOfClass:FeedVC.class]) {
        // check if the current topVC is the same feed
        if ([[[(FeedVC *)[nav topViewController] feed] feedID] isEqualToNumber:feedID]) {
            
            if (articleID) {
                asyncMain(^{
                    strongify(self);
                    
                    [self showArticle:articleID];
                });
            }
            
            return;
        }
    }
    
    [self popToRoot];
    
    FeedsVC *feedsVC = [[nav viewControllers] firstObject];
    
    DZBasicDatasource *DS = [feedsVC valueForKeyPath:@"DS"];
    
    __block NSUInteger index = NSNotFound;
    
    [(NSArray <Feed *> *)[DS data] enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([obj isKindOfClass:Feed.class]) {
            Feed *feed = obj;
            
            if ([feed.feedID isEqualToNumber:feedID]) {
                index = idx;
                *stop = YES;
            }
        }
        else {
            // folder
            Folder *folder = obj;
            
            [folder.feeds enumerateObjectsUsingBlock:^(Feed * _Nonnull obj, NSUInteger idxx, BOOL * _Nonnull stopx) {
                
                if ([obj.feedID isEqualToNumber:feedID]) {
                    index = idx;
                    folderIndex = idxx;
                    
                    isFolder = YES;
                    isFolderExpanded = folder.isExpanded;
                    
                    *stop = YES;
                    *stopx = YES;
                }
                
            }];
        }
        
    }];
    
    if (index == NSNotFound)
        return;
    
    // it is either not a folder
    // or it's a folder and we need to expand it
    if (!isFolder || (isFolder && !isFolderExpanded)) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        
        [feedsVC.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
        [feedsVC tableView:feedsVC.tableView didSelectRowAtIndexPath:indexPath];
    }
    
    // if it is a folder, it's expanded at this point
    if (isFolder) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(index + folderIndex + 1) inSection:0];
        
        asyncMain(^{
            [feedsVC.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            [feedsVC tableView:feedsVC.tableView didSelectRowAtIndexPath:indexPath];
        });
    }
    
    if (articleID) {
        asyncMain(^{
            strongify(self);
            
            [self showArticle:articleID];
        });
    }
}

- (void)showArticle:(NSNumber *)articleID {
    
    if (!articleID)
        return;
    
    UINavigationController *nav = [[(UISplitViewController *)[[UIApplication.sharedApplication keyWindow] rootViewController] viewControllers] firstObject];
    
    FeedVC *feedVC = (FeedVC *)[nav topViewController];
    
    feedVC.loadOnReady = articleID;
}

@end
