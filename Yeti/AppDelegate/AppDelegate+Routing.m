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

#import "FeedVC.h"
#import "ArticleVC.h"

#import <DZKit/AlertManager.h>
#import <SafariServices/SafariServices.h>

#import <DZKit/UIAlertController+Extended.h>
#import <DZKit/NSString+Extras.h>

@implementation AppDelegate (Routing)

- (void)popToRoot {
    
    SceneDelegate *scene = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    UISplitViewController *splitVC = (UISplitViewController *)[scene.window rootViewController];
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
        
        NSURL *url = [NSURL URLWithString:[[[parameters valueForKey:JLRouteURLKey] absoluteString] stringByReplacingOccurrencesOfString:@"feed:" withString:@""]];
        
        return [self addFeed:url];
        
    }];
    
    [[JLRoutes globalRoutes] addRoute:@"/addFeedConfirm" handler:^BOOL(NSDictionary<NSString *,id> * _Nonnull parameters) {
       
        strongify(self);
        
        NSString *path = [parameters valueForKey:@"URL"];
        
        if (path) {
            NSURL *url = [NSURL URLWithString:path];
            
            if (!url) {
                [AlertManager showGenericAlertWithTitle:@"Invalid Link" message:@"The link seems to be invalid or Yeti was unable to process it correctly."];
                return YES;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                weakify(self);
                
                UIAlertController *avc = [UIAlertController alertControllerWithTitle:@"Add Feed?" message:path preferredStyle:UIAlertControllerStyleAlert];
                
                [avc addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    
                    strongify(self);
                    
                    [self addFeed:url];
                    
                }]];
                
                [avc addAction:[UIAlertAction actionWithTitle:@"Open in Browser" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    
                    strongify(self);
                    
                    [self openURL:path];
                    
                }]];
                
                [avc addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                
                [self.window.rootViewController presentViewController:avc animated:YES completion:nil];
                
            });
            
        }
        
        return YES;
        
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
    
    [JLRoutes.globalRoutes addRoute:@"/twitter/:type/:identifer" handler:^BOOL(NSDictionary *parameters) {
       
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
    
    [JLRoutes.globalRoutes addRoute:@"/feed/:feedID" handler:^BOOL(NSDictionary *parameters) {
        
        NSNumber *feedID = @([[parameters valueForKey:@"feedID"] integerValue]);
        
        [self openFeed:feedID article:nil];
        
        return YES;
        
    }];
    
    [JLRoutes.globalRoutes addRoute:@"/feed/:feedID/article/:articleID" handler:^BOOL(NSDictionary *parameters) {
       
        NSNumber *feedID = @([[parameters valueForKey:@"feedID"] integerValue]);
        NSNumber *articleID = @([[parameters valueForKey:@"articleID"] integerValue]);
        
        [self openFeed:feedID article:articleID];
        
        return YES;
        
    }];
    
    [JLRoutes.globalRoutes addRoute:@"/article/:articleID" handler:^BOOL(NSDictionary<NSString *,id> * _Nonnull parameters) {

        NSNumber *articleID = @([[parameters valueForKey:@"articleID"] integerValue]);

        [self showArticle:articleID];

        return YES;

    }];
    
    [JLRoutes.globalRoutes addRoute:@"/external" handler:^BOOL(NSDictionary *parameters) {
        
        NSString *link = [[(NSURL *)[parameters valueForKey:JLRouteURLKey] absoluteString] stringByReplacingOccurrencesOfString:@"yeti://external?link=" withString:@""];
        
//#if TARGET_OS_OSX
//        [self.sharedGlue openURL:[NSURL URLWithString:link] inBackground:YES];
//        return YES;
//#endif
        
        // check and optionally handle twitter URLs
        if ([link containsString:@"twitter.com"]) {
            NSError *error = nil;
            NSRegularExpression *exp = [NSRegularExpression regularExpressionWithPattern:@"https?\\:\\/\\/w{0,3}\\.?twitter.com\\/([a-zA-Z0-9]*)$" options:NSRegularExpressionCaseInsensitive error:&error];
            NSArray *matches = nil;
            
            if (error == nil && exp) {
                matches = [exp matchesInString:link options:kNilOptions range:NSMakeRange(0, link.length)];
                if (matches && matches.count > 0) {
                    NSString *username = [link lastPathComponent];
                    [self twitterOpenUser:username];
                    
                    return YES;
                }
            }
            
            exp = [NSRegularExpression regularExpressionWithPattern:@"https?\\:\\/\\/w{0,3}\\.?twitter.com\\/([a-zA-Z0-9]*)\\/status\\/([0-9]*)$" options:NSRegularExpressionCaseInsensitive error:&error];
            
            if (error == nil && exp) {
                matches = [exp matchesInString:link options:kNilOptions range:NSMakeRange(0, link.length)];
                if (matches && matches.count > 0) {
                    NSString *status = [link lastPathComponent];
                    [self twitterOpenStatus:status];
                    
                    return YES;
                }
            }
        }
        
        if ([link containsString:@"reddit.com"]) {
            NSString *redditClient = [[NSUserDefaults standardUserDefaults] valueForKey:ExternalRedditAppScheme];
            
            if (redditClient != nil) {
                // Reference: https://www.reddit.com/r/redditmobile/comments/526ede/ios_url_schemes_for_ios_app/
                NSURLComponents *comp = [NSURLComponents componentsWithString:link];
                comp.scheme = [redditClient lowercaseString];
                comp.host = @"";
                
                if ([redditClient isEqualToString:@"Narwhal"]) {
                    NSString *encoded = [link stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
                    comp.path = formattedString(@"/open-url/%@", encoded);
                }
                
                NSURL *prepared = comp.URL;
                
                if (prepared) {
                    [UIApplication.sharedApplication openURL:prepared options:@{} completionHandler:nil];
                }
                return YES;
            }
            
        }
        
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
        
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
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
    
    UIViewController *vc = [UIApplication.keyWindow rootViewController];
    
    while (vc.presentedViewController != nil) {
        vc = vc.presentedViewController;
    }
    
    [vc presentViewController:alert animated:YES completion:nil];
    
    self.addFeedDialog = alert;
    
    weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        
        [self _dismissAddingFeedDialog];
    });
    
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
    
    weakify(self);
    
    [self.addFeedDialog dismissViewControllerAnimated:YES completion:^{
        strongify(self);
        self.addFeedDialog = nil;
    }];
    
}

- (NSTimeInterval)popRootToRoot {
    
    NSTimeInterval delay = 0;
    
    UISplitViewController *splitVC = self.coordinator.splitViewController;
    
    if ([splitVC presentedViewController] != nil) {
        [[splitVC presentedViewController] dismissViewControllerAnimated:YES completion:nil];
        delay += 0.75;
    }
    
    UINavigationController *nav = self.coordinator.sidebarVC.navigationController;
    
    if ([nav presentedViewController] != nil) {
        [[nav presentedViewController] dismissViewControllerAnimated:YES completion:nil];
        delay += 0.25;
    }
    
    if ([[nav topViewController] isKindOfClass:SidebarVC.class] == NO) {
        [nav popViewControllerAnimated:YES];
        delay += 0.25;
    }
    
    return delay;
}

- (BOOL)addFeed:(NSURL *)url {
    // check if we already have this feed
    Feed * have = nil;
    
    @try {
        if (ArticlesManager.shared != nil && ArticlesManager.shared.feeds != nil) {
            for (Feed *item in ArticlesManager.shared.feeds) { @autoreleasepool {
                
                if (item.url && [item.url isKindOfClass:NSURL.class]) {
                    item.url = [(NSURL *)url absoluteString];
                }
                
                if ([item.url isEqualToString:url.absoluteString]) {
                    have = item;
                    break;
                }
            } }
        }
    }
    @catch (NSException *exc) {}
    
    if (have) {
        
        [AlertManager showGenericAlertWithTitle:@"Feed Exists" message:formattedString(@"You are already subscribed to %@", have.title)];
        
        return YES;
    }
    
    NSTimeInterval delay = [self popRootToRoot];
    
    weakify(self);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        [self _showAddingFeedDialog];
    });
    
    if ([url.absoluteString containsString:@"youtube.com"] == YES && [url.absoluteString containsString:@"videos.xml"] == NO) {
        
        [MyFeedsManager _checkYoutubeFeed:url success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            if (responseObject != nil && [responseObject isKindOfClass:NSString.class]) {
                responseObject = [NSURL URLWithString:responseObject];
            }
            
            [self addFeed:responseObject];
            
        } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
           
            [AlertManager showGenericAlertWithTitle:@"An Error Occurred" message:@"An error occurred when trying to fetch the Youtube URL."];
            
        }];
        
    }
    else {
        [MyFeedsManager addFeed:url success:^(Feed *responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
            
            // check again if we have the feed
            BOOL haveItem = NO;
            if (responseObject != nil && [responseObject isKindOfClass:Feed.class]) {
                for (Feed *item in ArticlesManager.shared.feeds) {
                    if ([item.title isEqualToString:responseObject.title]) {
                        haveItem = YES;
                        break;
                    }
                }
            }
            
            strongify(self);
            
            [self _dismissAddingFeedDialog];
            
            if (!haveItem) {
                // we don't have it.
                ArticlesManager.shared.feeds = [ArticlesManager.shared.feeds arrayByAddingObject:responseObject];
                
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
    }
    
    return YES;
}

- (BOOL)addFeedByID:(NSNumber *)feedID
{
    
    NSTimeInterval delay = [self popRootToRoot];
    weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        strongify(self);
        [self _showAddingFeedDialog];
    });
    
    [MyFeedsManager addFeedByID:feedID success:^(Feed *responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        // check again if we have the feed
        BOOL haveItem = NO;
        for (Feed *item in ArticlesManager.shared.feeds) {
            if (item.feedID.integerValue == feedID.integerValue) {
                haveItem = YES;
                break;
            }
        }
        
        strongify(self);
        
        [self _dismissAddingFeedDialog];
        
        if (!haveItem) {
            // we don't have it.
            NSArray <Feed *> *feeds = ArticlesManager.shared.feeds;
            feeds = [feeds arrayByAddingObject:responseObject];
            
            ArticlesManager.shared.feeds = feeds;
            
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            [self openFeed:feedID article:articleID];
        });
        
        return;
    }
    
    weakify(self);
    
    // check if the current feedVC is the same feed
    
    SceneDelegate * scene = (id)[[UIApplication.sharedApplication.connectedScenes.allObjects firstObject] delegate];
    
    if (scene.coordinator.feedVC != nil
        && scene.coordinator.feedVC.type == FeedVCTypeNatural
        && [scene.coordinator.feedVC.feed.feedID isEqualToNumber:feedID])
    {
        
        if (articleID != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongify(self);
                
                [self showArticle:articleID];
            });
        }
        
    }
    
    else if (scene.coordinator.feedVC != nil) {
        
        FeedVC *feedVC = scene.coordinator.feedVC;
        
        if (feedVC.feed != nil && [feedVC.feed.feedID isEqualToNumber:feedID]) {
            
            if (articleID != nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    strongify(self);
                    
                    [self showArticle:articleID];
                });
            }
            
            return;
            
        }
        else {
            
            /*
             * The feedID is clearly different or is a custom feed. So deselect the selected items.
             */
            
            NSArray <NSIndexPath *> * selectedItems = [feedVC.tableView indexPathsForSelectedRows];
            
            dispatch_async(dispatch_get_main_queue(), ^{
               
                for (NSIndexPath *indexPath in selectedItems) {
                    
                    [feedVC.tableView deselectRowAtIndexPath:indexPath animated:NO];
                    
                }
                
            });
            
        }
        
    }
    
#if !TARGET_OS_MACCATALYST
    [self popToRoot];
#endif
    
    if (scene.coordinator.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad
        && scene.coordinator.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        
        if (feedID != nil && scene.coordinator.feedVC == nil) {
            
            Feed *feed = [MyFeedsManager feedForID:feedID];
            
            if (feed != nil) {
                [scene.coordinator showFeedVC:feed];
            }
            
        }
        
    }
    
    if (articleID != nil) {
        
        FeedItem *item = [[FeedItem alloc] init];
        item.feedID = feedID;
        item.identifier = articleID;
        
        ArticleVC *articleVC = [[ArticleVC alloc] initWithItem:item];
        
        [scene.coordinator showArticleVC:articleVC];
        
    }
    else {
        
        Feed *feed = [MyFeedsManager feedForID:feedID];
        
        if (feed != nil) {
            [scene.coordinator showFeedVC:feed];
        }
        
    }
    
}

- (void)showArticle:(NSNumber *)articleID {
    
    if (articleID == nil) {
        return;
    }
    
    if (![articleID integerValue]) {
        return;
    }
    
    SceneDelegate * scene = (id)[[UIApplication.sharedApplication.connectedScenes.allObjects firstObject] delegate];
    
    if (scene.coordinator.feedVC != nil) {
        scene.coordinator.feedVC.loadOnReady = articleID;
    }
    else {
        
        FeedItem *item = [FeedItem new];
        item.identifier = articleID;
        
        ArticleVC *instance = [[ArticleVC alloc] initWithItem:item];
        
        [scene.coordinator showArticleVC:instance];
    }
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
    
    if (uri == nil || [uri isBlank])
        return;
    
    NSString *browserScheme = [([NSUserDefaults.standardUserDefaults valueForKey:ExternalBrowserAppScheme] ?: @"safari") lowercaseString];
    NSURL *URL;
    
    if ([browserScheme isEqualToString:@"safari"]) {
        URL = [NSURL URLWithString:uri];
        
        if (URL == nil || [URL host] == nil)
            return;
        
        SFSafariViewController *sfvc = [[SFSafariViewController alloc] initWithURL:URL];
        
        SceneDelegate *delegate = (SceneDelegate *)(UIApplication.sharedApplication.connectedScenes.allObjects.firstObject.delegate);
        
        sfvc.preferredControlTintColor = delegate.window.tintColor;
        
        // get the top VC
        UISplitViewController *splitVC = (UISplitViewController *)[[delegate window] rootViewController];
        
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
