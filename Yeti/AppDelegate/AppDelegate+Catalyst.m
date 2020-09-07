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
    
    UIMenu *newFeedMenu = [UIMenu menuWithTitle:@"" image:nil identifier:@"NewFeedMenuItem" options:UIMenuOptionsDisplayInline children:@[newFeed, newFolder, refresh]];
    
    [builder insertChildMenu:newFeedMenu atStartOfMenuForIdentifier:UIMenuFile];
    
    // Add items for View Menu
    UICommand * sortAllDesc = [UICommand commandWithTitle:@"All - Newest First" image:nil action:@selector(setSortingAllDesc) propertyList:nil];
    UICommand * sortAllAsc = [UICommand commandWithTitle:@"All - Oldest First" image:nil action:@selector(setSortingAllAsc) propertyList:nil];
    
    UICommand * unreadDesc = [UICommand commandWithTitle:@"Unread - Newest First" image:nil action:@selector(setSortingUnreadDesc) propertyList:nil];
    UICommand * unreadAsc = [UICommand commandWithTitle:@"Unread - Oldest First" image:nil action:@selector(setSortingUnreadAsc) propertyList:nil];
    
    FeedVC *feedVC = coordinator.feedVC;
    
    if (feedVC != nil) {
        
        if (feedVC.type == FeedVCTypeUnread || feedVC.type == FeedVCTypeBookmarks) {
            
            unreadAsc.attributes = UIMenuElementAttributesDisabled;
            unreadDesc.attributes = UIMenuElementAttributesDisabled;
            
        }
        else {
            
            unreadAsc.attributes = 0;
            unreadDesc.attributes = 0;
            
        }
        
        UICommand *active = nil;
        
        switch (SharedPrefs.sortingOption.integerValue) {
            case 0:
                active = sortAllDesc;
                break;
            case 1:
                active = sortAllAsc;
                break;
            case 2:
                active = unreadDesc;
                break;
            default:
                active = unreadAsc;
                break;
        }
        
        active.state = UIMenuElementStateOn;
        
        NSArray *inactive = [@[sortAllDesc, sortAllAsc, unreadDesc, unreadAsc] rz_filter:^BOOL(UICommand * obj, NSUInteger idx, NSArray *array) {
            
            return obj != active;
            
        }];
        
        for (UICommand *obj in inactive) {
            obj.state = UIMenuElementStateOff;
        }
        
    }
    
    UIMenu *sortingMenu = [UIMenu menuWithTitle:@"Sort By" image:nil identifier:@"SortingMenu" options:kNilOptions children:@[sortAllDesc, sortAllAsc, unreadDesc, unreadAsc]];
    
    [builder insertChildMenu:sortingMenu atStartOfMenuForIdentifier:UIMenuView];
    
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
