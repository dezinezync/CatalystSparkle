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
#import "YTNavigationController.h"

#import <DZKit/AlertManager.h>
#import <SafariServices/SafariServices.h>

#import <DZKit/UIAlertController+Extended.h>

@implementation AppDelegate (Routing)

- (void)popToRoot
{
    UISplitViewController *splitVC = (UISplitViewController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    YTNavigationController *nav = (YTNavigationController *)[[splitVC viewControllers] firstObject];
    
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
                [AlertManager showGenericAlertWithTitle:@"Invalid Link" message:@"The link seems to be invalid or Yeti was unable to process it correctly."];
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
    
    [JLRoutes addRoute:@"/external" handler:^BOOL(NSDictionary *parameters) {
        
        NSString *link = [[(NSURL *)[parameters valueForKey:kJLRouteURLKey] absoluteString] stringByReplacingOccurrencesOfString:@"yeti://external?link=" withString:@""];
        
        [self openURL:link];
        
        return YES;
        
    }];
}

#pragma mark - Internal

- (void)_showAddingFeedDialog {
    
    if (![NSThread isMainThread]) {
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            [self _showAddingFeedDialog];
        });
        return;
    }
    
    if (self.addFeedDialog != nil) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Adding Feed" message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alert dz_configureContentView:^(UIView *contentView) {
        
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activity.color = UIColor.lightGrayColor;
        [activity sizeToFit];
        activity.translatesAutoresizingMaskIntoConstraints = NO;
        
        [contentView addSubview:activity];
        
        [activity.widthAnchor constraintEqualToConstant:activity.bounds.size.width].active = YES;
        [activity.heightAnchor constraintEqualToConstant:activity.bounds.size.height].active = YES;
        
        [activity.centerXAnchor constraintEqualToAnchor:contentView.centerXAnchor].active = YES;
        [activity.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:12.f].active = YES;
        
        [activity startAnimating];
        
    }];
    
    UIViewController *vc = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    while (vc.presentedViewController != nil) {
        vc = vc.presentedViewController;
    }
    
    [vc presentViewController:alert animated:YES completion:nil];
    
    self.addFeedDialog = alert;
    
}

- (void)_dismissAddingFeedDialog {
    
    if (![NSThread isMainThread]) {
        weakify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            [self _dismissAddingFeedDialog];
        });
        return;
    }
    
    if (self.addFeedDialog == nil) {
        return;
    }
    
    [self.addFeedDialog dismissViewControllerAnimated:YES completion:nil];
    
    self.addFeedDialog = nil;
    
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
    
    [self _showAddingFeedDialog];
    
    weakify(self);
    
    [MyFeedsManager addFeed:url success:^(Feed *responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        // check again if we have the feed
        BOOL haveItem = NO;
        for (Feed *item in MyFeedsManager.feeds) {
            if ([item.title isEqualToString:responseObject.title]) {
                haveItem = YES;
                break;
            }
        }
        
        strongify(self);
        
        [self _dismissAddingFeedDialog];
        
        if (!haveItem) {
            // we don't have it.
            MyFeedsManager.feeds = [MyFeedsManager.feeds arrayByAddingObject:responseObject];
            
            weakify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                strongify(self);
                [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
                [self.notificationGenerator prepare];
            });
            
        }
        else {
            
            weakify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                strongify(self);
                [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeWarning];
                [self.notificationGenerator prepare];
            });
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [AlertManager showGenericAlertWithTitle:@"Feed Exists" message:formattedString(@"You are already subscribed to %@", responseObject.title)];
            });
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        [self _dismissAddingFeedDialog];
        
        weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeError];
            [self.notificationGenerator prepare];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [AlertManager showGenericAlertWithTitle:@"Error Adding Feed" message:error.localizedDescription];
        });
        
    }];
    
    return YES;
}

- (BOOL)addFeedByID:(NSNumber *)feedID
{
    
    [self _showAddingFeedDialog];
    
    weakify(self);
    
    [MyFeedsManager addFeedByID:feedID success:^(Feed *responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        // check again if we have the feed
        BOOL haveItem = NO;
        for (Feed *item in MyFeedsManager.feeds) {
            if (item.feedID.integerValue == feedID.integerValue) {
                haveItem = YES;
                break;
            }
        }
        
        strongify(self);
        
        [self _dismissAddingFeedDialog];
        
        if (!haveItem) {
            // we don't have it.
            NSArray <Feed *> *feeds = MyFeedsManager.feeds;
            feeds = [feeds arrayByAddingObject:responseObject];
            
            MyFeedsManager.feeds = feeds;
            
            weakify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                strongify(self);
                [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeSuccess];
                [self.notificationGenerator prepare];
            });
            
        }
        else {
            
            weakify(self);
            dispatch_async(dispatch_get_main_queue(), ^{
                strongify(self);
                [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeWarning];
                [self.notificationGenerator prepare];
            });
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [AlertManager showGenericAlertWithTitle:@"Feed Exists" message:formattedString(@"You are already subscribed to %@", responseObject.title)];
            });
        }
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        strongify(self);
        
        [self _dismissAddingFeedDialog];
        
        weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            [self.notificationGenerator notificationOccurred:UINotificationFeedbackTypeError];
            [self.notificationGenerator prepare];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            NSString *title = @"Error Adding Feed";
            
            if (error.code == kFMErrorExisting) {
                title = @"Already Subscribed.";
            }
            
            [AlertManager showGenericAlertWithTitle:title message:error.localizedDescription];
        });
        
    }];
    
    return YES;
    
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
    YTNavigationController *nav = [[(UISplitViewController *)[[UIApplication.sharedApplication keyWindow] rootViewController] viewControllers] firstObject];
    
    if ([[nav topViewController] isKindOfClass:FeedVC.class]) {
        // check if the current topVC is the same feed
        if ([[[(FeedVC *)[nav topViewController] feed] feedID] isEqualToNumber:feedID]) {
            
            if (articleID != nil) {
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
    
    DZSectionedDatasource *DSS = [feedsVC valueForKeyPath:@"DS"];
    DZBasicDatasource *DS = [[DSS datasources] lastObject];
    
    if (!DS.data || DS.data.count == 0) {
        weakify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            strongify(self);
            
            [self openFeed:feedID article:articleID];
        });
        return;
    }
    
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
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:1];
        
        dispatch_async(dispatch_get_main_queue(), ^{
//            [feedsVC.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            [feedsVC tableView:feedsVC.tableView didSelectRowAtIndexPath:indexPath];
        });
    }
    
    // if it is a folder, it's expanded at this point
    if (isFolder) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(index + folderIndex + 1) inSection:1];
        
        dispatch_async(dispatch_get_main_queue(), ^{
//            [feedsVC.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
            [feedsVC tableView:feedsVC.tableView didSelectRowAtIndexPath:indexPath];
        });
    }
    
    if (articleID != nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            
            [self showArticle:articleID];
        });
    }
}

- (void)showArticle:(NSNumber *)articleID {
    
    if (articleID == nil)
        return;
    
    YTNavigationController *nav = [[(UISplitViewController *)[[UIApplication.sharedApplication keyWindow] rootViewController] viewControllers] firstObject];
    
    FeedVC *feedVC = (FeedVC *)[nav topViewController];
    
    feedVC.loadOnReady = articleID;
}

#pragma mark - External

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
    
    if (!URL)
        return;
    
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
    
    if (!URL)
        return;
    
    [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
}

- (void)openURL:(NSString *)uri {
    
    if (!uri || [uri isBlank])
        return;
    
    NSString *browserScheme = [([NSUserDefaults.standardUserDefaults valueForKey:ExternalBrowserAppScheme] ?: @"safari") lowercaseString];
    NSURL *URL;
    
    if ([browserScheme isEqualToString:@"safari"]) {
        URL = [NSURL URLWithString:uri];
        
        if (!URL)
            return;
        
        SFSafariViewController *sfvc = [[SFSafariViewController alloc] initWithURL:URL];
        
        // get the top VC
        UISplitViewController *splitVC = (UISplitViewController *)[[self window] rootViewController];
        
        UINavigationController *navVC = nil;
        
        if (splitVC.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad && splitVC.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
            navVC = [splitVC.viewControllers lastObject];
        }
        else {
            navVC = [splitVC.viewControllers firstObject];
        }
        
        [navVC presentViewController:sfvc animated:YES completion:nil];
        
        return;
    }
    
    if ([browserScheme isEqualToString:@"chrome"]) {
        // googlechromes for https, googlechrome for http
        if ([uri containsString:@"https:"]) {
            URL = formattedURL(@"googlechromes://%@", [uri stringByReplacingOccurrencesOfString:@"https://" withString:@""]);
        }
        else {
            URL = formattedURL(@"googlechrome://%@", [uri stringByReplacingOccurrencesOfString:@"http://" withString:@""]);
        }
    }
    else if ([browserScheme isEqualToString:@"firefox"]) {
        URL = formattedURL(@"firefox://open-url?url=%@", uri);
    }
    
    if (!URL)
        return;

    [UIApplication.sharedApplication openURL:URL options:@{} completionHandler:nil];
    
}

@end
