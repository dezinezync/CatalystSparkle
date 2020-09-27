//
//  AppDelegate+Catalyst.m
//  Yeti
//
//  Created by Nikhil Nigade on 08/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+CatalystActions.h"

#import "UITableView+Sugar.h"

#if TARGET_OS_MACCATALYST

#import "AppKitGlue.h"

#import "FeedsVC+Actions.h"
#import "ArticleVC+Toolbar.h"

#import "SplitVC.h"
#import "FeedVC.h"
#import "ArticleVC.h"
#import "ArticleProvider.h"

#import <UIKit/NSToolbar+UIKitAdditions.h>
#import <UIKit/UIMenuSystem.h>
#import <AppKit/NSToolbarItemGroup.h>

@implementation AppDelegate (Catalyst)

- (void)ct_setupAppKitBundle {
   
#if TARGET_OS_MACCATALYST
    NSString *pluginPath = [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent:@"elytramac.bundle"];
        
    NSBundle *macBundle = [NSBundle bundleWithPath:pluginPath];
    
    self.appKitBundle = macBundle;
    
    __unused BOOL unused = [self.appKitBundle load];
    
    Class appKitGlueClass = [self.appKitBundle classNamed:@"AppKitGlue"];

    __unused AppKitGlue *instance = [appKitGlueClass shared];
    
    self.sharedGlue = instance;
    self.sharedGlue.appUserDefaults = [NSUserDefaults standardUserDefaults];
    self.sharedGlue.feedsManager = MyFeedsManager;
#endif
    
}

- (void)ct_setupMenu:(id<UIMenuBuilder>)builder {
    
    if (builder == nil) {
        return;
    }
    
    self.mainMenuBuilder = builder;
    
    // remove some menu items
    [builder removeMenuForIdentifier:UIMenuFormat];
    
    SceneDelegate *sceneDelegate = (id)[UIApplication.sharedApplication.connectedScenes.allObjects.firstObject delegate];
    
    MainCoordinator *coordinator = sceneDelegate.coordinator;
    
    UIKeyCommand *preferences = [UIKeyCommand commandWithTitle:@"Preferences" image:nil action:@selector(openSettings:) input:@"," modifierFlags:UIKeyModifierCommand propertyList:nil];
    
    UIMenu *customPreferencesMenu = [UIMenu menuWithTitle:@"Preferences" image:nil identifier:UIMenuPreferences options:UIMenuOptionsDisplayInline children:@[preferences]];
    
    [builder replaceMenuForIdentifier:UIMenuPreferences withMenu:customPreferencesMenu];
    
    // Add items for File menu
    UIKeyCommand *newFeed = [UIKeyCommand commandWithTitle:@"New Feed" image:nil action:@selector(createNewFeed) input:@"n" modifierFlags:UIKeyModifierCommand propertyList:nil];
    
    UIKeyCommand *newFolder = [UIKeyCommand commandWithTitle:@"New Folder" image:nil action:@selector(createNewFolder) input:@"n" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift propertyList:nil];
    
    UIKeyCommand *refresh = [UIKeyCommand commandWithTitle:@"Refresh" image:nil action:@selector(refreshAll) input:@"r" modifierFlags:UIKeyModifierCommand propertyList:nil];
    
    UIMenu *newFeedMenu = [UIMenu menuWithTitle:@"New Items" image:nil identifier:@"NewFeedInlineMenuItem" options:UIMenuOptionsDisplayInline children:@[newFeed, newFolder, refresh]];
    
    [builder replaceMenuForIdentifier:UIMenuNewScene withMenu:newFeedMenu];
    

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
    NSString *markReadTitle = articleVC ? articleVC.currentArticle.isRead ? @"Mark Unread" : @"Mark Read" : @"Mark Read";
    
    UIKeyCommand *markRead = [UIKeyCommand commandWithTitle:markReadTitle image:nil action:@selector(markArticleRead) input:@"u" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift propertyList:nil];
    
    NSString *markBookmarkTitle = articleVC ? articleVC.currentArticle.isBookmarked ? @"Unbookmark" : @"Bookmark" : @"Bookmark";
    
    UIKeyCommand *markBookmark = [UIKeyCommand commandWithTitle:markBookmarkTitle image:nil action:@selector(markArticleBookmark) input:@"l" modifierFlags:UIKeyModifierCommand|UIKeyModifierShift propertyList:nil];
    
    UIKeyCommand *openInBrowser = [UIKeyCommand commandWithTitle:@"Open in Browser" image:nil action:@selector(openArticleInBrowser) input:UIKeyInputRightArrow modifierFlags:UIKeyModifierCommand propertyList:nil];
    
    UIKeyCommand *closeArticle = [UIKeyCommand commandWithTitle:@"Close Article" image:nil action:@selector(closeArticle) input:UIKeyInputLeftArrow modifierFlags:UIKeyModifierCommand propertyList:nil];
    
    UIKeyCommand *shareArticle = [UIKeyCommand commandWithTitle:@"Share Article" image:nil action:@selector(shareArticle) input:@"i" modifierFlags:UIKeyModifierCommand propertyList:nil];
    
    UIKeyCommand *searchArticle = [UIKeyCommand commandWithTitle:@"Find in Article" image:nil action:@selector(didTapSearch) input:@"f" modifierFlags:UIKeyModifierCommand propertyList:nil];
    
    for (UIKeyCommand *command in @[markRead, markBookmark, openInBrowser, closeArticle, shareArticle, searchArticle]) {
        
        if (articleVC == nil) {
            
            command.attributes = UIMenuElementAttributesDisabled;
            
        }
        
    }
    
    UIMenu *articlesMenu = [UIMenu menuWithTitle:@"Article" children:@[markRead, markBookmark, openInBrowser, closeArticle, shareArticle, searchArticle]];
    
    [builder insertSiblingMenu:articlesMenu beforeMenuForIdentifier:UIMenuWindow];
    
}

- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder {
    
    if (([builder system] == UIMenuSystem.mainSystem) == NO) {
        return;
    }
    
    [self ct_setupMenu:builder];
    
}

@end

#endif
