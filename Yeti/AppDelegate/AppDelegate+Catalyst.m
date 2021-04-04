//
//  AppDelegate+Catalyst.m
//  Yeti
//
//  Created by Nikhil Nigade on 08/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+CatalystActions.h"

#import "UITableView+Sugar.h"
#import "Elytra-Swift.h"

// Closed at the end of the file.
#if TARGET_OS_MACCATALYST

#import "AppKitGlue.h"

#import "ArticleVC+Toolbar.h"

#import "ArticleVC.h"
#import "ArticleProvider.h"

#import <UIKit/NSToolbar+UIKitAdditions.h>
#import <UIKit/UIMenuSystem.h>
#import <AppKit/NSToolbarItemGroup.h>
#import <DZKit/DZMessagingController.h>
#import <DZKit/AlertManager.h>

@implementation AppDelegate (Catalyst)

- (void)ct_setupAppKitBundle {
   
#if TARGET_OS_MACCATALYST
    NSString *pluginPath = [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent:@"elytramac.bundle"];
        
    NSBundle *macBundle = [NSBundle bundleWithPath:pluginPath];
    
    self.appKitBundle = macBundle;
    
    if ([self.appKitBundle load] == NO) {
        return;
    }
    
    Class appKitGlueClass = [self.appKitBundle classNamed:@"AppKitGlue"];

    __unused AppKitGlue *instance = [appKitGlueClass shared];
    
    self.sharedGlue = instance;
    self.sharedGlue.appUserDefaults = [NSUserDefaults standardUserDefaults];
//    self.sharedGlue.feedsManager = MyFeedsManager;
#endif
    
}

- (void)ct_setupMenu:(id<UIMenuBuilder>)builder {
    
    if (builder == nil) {
        return;
    }
    
    self.mainMenuBuilder = builder;
    
    // remove some menu items
    [builder removeMenuForIdentifier:UIMenuFormat];
    
    Coordinator *coordinator = self.coordinator;

    UIKeyCommand *preferences = [UIKeyCommand commandWithTitle:@"Preferences" image:nil action:@selector(openSettings:) input:@"," modifierFlags:UIKeyModifierCommand propertyList:nil];

    UIMenu *customPreferencesMenu = [UIMenu menuWithTitle:@"Preferences" image:nil identifier:UIMenuPreferences options:UIMenuOptionsDisplayInline children:@[preferences]];

    [builder replaceMenuForIdentifier:UIMenuPreferences withMenu:customPreferencesMenu];

    // Add items for File menu
    UIKeyCommand *feedsMenuItem = [UIKeyCommand commandWithTitle:@"New Window" image:nil action:@selector(showMainScene) input:@"n" modifierFlags:UIKeyModifierAlternate propertyList:nil];

    UIKeyCommand *newFeed = [UIKeyCommand commandWithTitle:@"New Feed" image:nil action:@selector(createNewFeed) input:@"n" modifierFlags:UIKeyModifierCommand propertyList:nil];

    UIKeyCommand *newFolder = [UIKeyCommand commandWithTitle:@"New Folder" image:nil action:@selector(createNewFolder) input:@"n" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift propertyList:nil];

    UICommandAlternate *hardRefresh = [UICommandAlternate alternateWithTitle:@"Force Re-Sync" action:@selector(__refreshAll) modifierFlags:UIKeyModifierAlternate];

    UICommandAlternate *feedsRefresh = [UICommandAlternate alternateWithTitle:@"Force Re-Sync Feeds" action:@selector(__refreshFeeds) modifierFlags:UIKeyModifierShift|UIKeyModifierAlternate];

    UIKeyCommand *refresh = [UIKeyCommand commandWithTitle:@"Refresh" image:nil action:@selector(refreshAll) input:@"r" modifierFlags:UIKeyModifierCommand propertyList:nil alternates:@[hardRefresh, feedsRefresh]];

    UIMenu *newFeedMenu = [UIMenu menuWithTitle:@"New Items" image:nil identifier:@"NewFeedInlineMenuItem" options:UIMenuOptionsDisplayInline children:@[newFeed, newFolder, refresh]];

    UICommand *importSubscriptions = [UICommand commandWithTitle:@"Import Subscriptions" image:nil action:@selector(didClickImportSubscriptions) propertyList:nil];

    UIKeyCommand *exportSubscriptions = [UIKeyCommand commandWithTitle:@"Export Subscriptions" image:nil action:@selector(didClickExportSubscriptions) input:@"e" modifierFlags:UIKeyModifierCommand|UIKeyModifierAlternate propertyList:nil];

    UIMenu *subscriptionsMenu = [UIMenu menuWithTitle:@"Subscriptions" image:nil identifier:@"SubscriptionsMenuIdentifier" options:UIMenuOptionsDisplayInline children:@[importSubscriptions, exportSubscriptions]];

    UIMenu *newSceneMenu = [UIMenu menuWithTitle:@"New Scene" image:nil identifier:UIMenuNewScene options:UIMenuOptionsDisplayInline children:@[feedsMenuItem]];

    [builder replaceMenuForIdentifier:UIMenuNewScene withMenu:newSceneMenu];

    [builder insertSiblingMenu:newFeedMenu afterMenuForIdentifier:UIMenuNewScene];

    [builder insertSiblingMenu:subscriptionsMenu afterMenuForIdentifier:@"NewFeedInlineMenuItem"];

    FeedVC *feedVC = coordinator.feedVC;

    UIKeyCommand *toggleSidebar = [UIKeyCommand commandWithTitle:@"Toggle Sidebar" image:nil action:@selector(toggleSidebar:) input:@"s" modifierFlags:UIKeyModifierCommand|UIKeyModifierAlternate  propertyList:nil];

    UIMenu *toggleSidebarMenu = [UIMenu menuWithTitle:@"Toggle Sidebar" image:nil identifier:@"ToggleSidebar" options:UIMenuOptionsDisplayInline children:@[toggleSidebar]];

    [builder insertChildMenu:toggleSidebarMenu atStartOfMenuForIdentifier:UIMenuView];

    // Go menu

    ArticleVC *articleVC = coordinator.articleVC;

    UIKeyCommand *nextArticle = [UIKeyCommand commandWithTitle:@"Next Article" image:nil action:@selector(switchToNextArticle) input:UIKeyInputDownArrow modifierFlags:UIKeyModifierCommand propertyList:nil];

    UIKeyCommand *previousArticle = [UIKeyCommand commandWithTitle:@"Previous Article" image:nil action:@selector(switchToPreviousArticle) input:UIKeyInputUpArrow modifierFlags:UIKeyModifierCommand propertyList:nil];

    // If the article VC is not visible, leave them disabled
    if (feedVC == nil) {

        nextArticle.attributes = UIMenuElementAttributesDisabled;
        previousArticle.attributes = UIMenuElementAttributesDisabled;

    }
    else {

        NSIndexPath *selected = feedVC.tableView.indexPathForSelectedRow;
        NSIndexPath *lastIndexPath = feedVC.tableView.indexPathForLastRow;

        if (lastIndexPath != nil) {

            if (selected.section == lastIndexPath.section && selected.row == lastIndexPath.row) {

                nextArticle.attributes = UIMenuElementAttributesDisabled;

            }

        }

        if (selected.row == 0) {

            previousArticle.attributes = UIMenuElementAttributesDisabled;

        }

    }

    UIMenu *articlesGoToMenu = [UIMenu menuWithTitle:@"" image:nil identifier:@"ArticlesGoTo" options:UIMenuOptionsDisplayInline children:@[nextArticle, previousArticle]];

    NSMutableArray *goToMenuItems = [NSMutableArray arrayWithCapacity:3];

    UIKeyCommand *goUnread = [UIKeyCommand commandWithTitle:@"Unread" image:nil action:@selector(goToUnread) input:@"1" modifierFlags:UIKeyModifierCommand propertyList:nil];

    UIKeyCommand *goToday = [UIKeyCommand commandWithTitle:@"Today" image:nil action:@selector(goToToday) input:@"2" modifierFlags:UIKeyModifierCommand propertyList:nil];

    [goToMenuItems addObjectsFromArray:@[goUnread, goToday]];

    if (SharedPrefs.hideBookmarks == NO) {

        UIKeyCommand *goBookmarks = [UIKeyCommand commandWithTitle:@"Bookmarks" image:nil action:@selector(goToBookmarks) input:@"3" modifierFlags:UIKeyModifierCommand propertyList:nil];

        [goToMenuItems addObject:goBookmarks];

    }

    UIMenu *goToMenu = [UIMenu menuWithTitle:@"" image:nil identifier:@"GoToMenu" options:UIMenuOptionsDisplayInline children:goToMenuItems];

    UIMenu *topLevelGoMenu = [UIMenu menuWithTitle:@"Go" children:@[articlesGoToMenu, goToMenu]];

    [builder insertSiblingMenu:topLevelGoMenu afterMenuForIdentifier:UIMenuView];

    // Article Top-Level Menu
    NSString *markReadTitle = articleVC ? ((Article *)articleVC.item).read ? @"Mark Unread" : @"Mark Read" : @"Mark Read";

    UIKeyCommand *markRead = [UIKeyCommand commandWithTitle:markReadTitle image:nil action:@selector(markArticleRead) input:@"u" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift propertyList:nil];

    NSString *markBookmarkTitle = articleVC ? ((Article *)articleVC.item).bookmarked ? @"Unbookmark" : @"Bookmark" : @"Bookmark";

    UIKeyCommand *markBookmark = [UIKeyCommand commandWithTitle:markBookmarkTitle image:nil action:@selector(markArticleBookmark) input:@"l" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift propertyList:nil];

    UIKeyCommand *openInBrowser = [UIKeyCommand commandWithTitle:@"Open in Browser" image:nil action:@selector(openArticleInBrowser) input:UIKeyInputRightArrow modifierFlags:UIKeyModifierCommand propertyList:nil];

    UIKeyCommand *closeArticle = [UIKeyCommand commandWithTitle:@"Close Article" image:nil action:@selector(closeArticle) input:UIKeyInputLeftArrow modifierFlags:UIKeyModifierCommand propertyList:nil];

    UIKeyCommand *shareArticle = [UIKeyCommand commandWithTitle:@"Share Article" image:nil action:@selector(shareArticle) input:@"i" modifierFlags:UIKeyModifierCommand propertyList:nil];

    UIKeyCommand *searchArticle = [UIKeyCommand commandWithTitle:@"Find in Article" image:nil action:@selector(didTapSearch) input:@"f" modifierFlags:UIKeyModifierCommand propertyList:nil];

    UIMenu *articlesMenu = [UIMenu menuWithTitle:@"Article" children:@[markRead, markBookmark, openInBrowser, closeArticle, shareArticle, searchArticle]];

    [builder insertSiblingMenu:articlesMenu beforeMenuForIdentifier:UIMenuWindow];

    UICommand *subsWindow = [UICommand commandWithTitle:@"View Subscription" image:nil action:@selector(showSubscriptionsInterface) propertyList:nil];

//    UICommand *attrsWindow = [UICommand commandWithTitle:@"Attributions" image:nil action:@selector(showAttributionsInterface) propertyList:nil];

    UIMenu *subsMenu = [UIMenu menuWithTitle:@"" image:nil identifier:@"SubsMenu" options:UIMenuOptionsDisplayInline children:@[subsWindow]];

    [builder insertSiblingMenu:subsMenu afterMenuForIdentifier:UIMenuAbout];

    UICommand *contactsupport = [UICommand commandWithTitle:@"Email Support" image:nil action:@selector(contactSupport) propertyList:nil];

    UICommand *faqItem = [UICommand commandWithTitle:@"Elytra Help" image:nil action:@selector(openFAQ) propertyList:nil];

    UIMenu *helpMenu = [UIMenu menuWithTitle:@"" image:nil identifier:@"SupportMenu" options:UIMenuOptionsDisplayInline children:@[faqItem, contactsupport]];

    [builder replaceChildrenOfMenuForIdentifier:UIMenuHelp fromChildrenBlock:^NSArray<UIMenuElement *> * _Nonnull(NSArray<UIMenuElement *> * _Nonnull originalItems) {

        if (originalItems.count == 1) {
            return @[helpMenu];
        }

        return originalItems;

    }];
    
    [builder insertChildMenu:helpMenu atEndOfMenuForIdentifier:UIMenuHelp];
    
}

- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder {
    
    if (([builder system] == UIMenuSystem.mainSystem) == NO) {
        return;
    }
    
    [self ct_setupMenu:builder];
    
}

- (void)validateCommand:(UICommand *)command {
    
    NSLogDebug(@"%@ - %@: %@", command.title, NSStringFromSelector(command.action), @([self respondsToSelector:command.action]));
    
    if (self.mainScene != nil && self.mainScene.windows.firstObject.isKeyWindow == NO) {
        
        command.attributes = UIMenuElementAttributesHidden|UIMenuElementAttributesDisabled;
        
    }
    
    if ([command.title isEqualToString:@"New Window"]) {
        
        command.attributes = self.mainScene == nil ? 0 : UIMenuElementAttributesDisabled;
        
    }
    
    else if ([command.title isEqualToString:@"Open in Browser"]
             || [command.title isEqualToString:@"Close Article"]
             || [command.title isEqualToString:@"Share Article"]
             || [command.title isEqualToString:@"Mark Read"]
             || [command.title isEqualToString:@"Mark Unread"]
             || [command.title isEqualToString:@"Bookmark"]
             || [command.title isEqualToString:@"Unbookmark"]
             || [command.title isEqualToString:@"Find in Article"]) {
        
        command.attributes = self.coordinator.articleVC != nil ? 0 : UIMenuElementAttributesDisabled;
        
    }

}

- (void)contactSupport {
    [self.coordinator showContactInterface];
}

- (void)__refreshAll {
    
    [self.coordinator prepareForFullResync];
    
}

- (void)__refreshFeeds {
    [self.coordinator prepareForFeedsResync];
}

- (void)showMainScene {
    
    NSUserActivity *main = [[NSUserActivity alloc] initWithActivityType:@"main"];
    
    [UIApplication.sharedApplication requestSceneSessionActivation:nil userActivity:main options:nil errorHandler:^(NSError * _Nonnull error) {
       
        if (error != nil) {
            
            [AlertManager showGenericAlertWithTitle:@"Error Opening Window" message:error.localizedDescription];
            
        }
        
    }];
    
}

@end

#endif
