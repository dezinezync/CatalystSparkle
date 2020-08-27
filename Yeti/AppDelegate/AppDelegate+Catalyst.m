//
//  AppDelegate+Catalyst.m
//  Yeti
//
//  Created by Nikhil Nigade on 08/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+CatalystActions.h"

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

- (void)ct_setupToolbar:(UIWindowScene *)scene {
    
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"elytra-main-toolbar"];
    
    toolbar.delegate = self;
    
    scene.titlebar.toolbar = toolbar;
    
    scene.titlebar.toolbarStyle = UITitlebarToolbarStyleUnifiedCompact;
    
    scene.titlebar.separatorStyle = UITitlebarSeparatorStyleAutomatic;
    
    scene.titlebar.titleVisibility = UITitlebarTitleVisibilityHidden;
    
    self.toolbar = toolbar;
    
}

- (void)ct_setupAppKitBundle {
    
}

- (void)ct_setupMenu:(id<UIMenuBuilder>)builder {
    
    if (builder == nil) {
        return;
    }
    
    self.mainMenuBuilder = builder;
    
    // remove some menu items
    [builder removeMenuForIdentifier:UIMenuFormat];
    
    SplitVC *splitVC = (SplitVC *)[[MyAppDelegate window] rootViewController];
    
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
    
    if (splitVC.viewControllers.count >= 2) {
        
        UINavigationController *navVC = (UINavigationController *)[splitVC.viewControllers objectAtIndex:1];
        
        if ([[navVC.viewControllers firstObject]  isKindOfClass:FeedVC.class]) {
            
            FeedVC *feedVC = [navVC.viewControllers firstObject];
            
            if (feedVC.type == FeedVCTypeUnread || feedVC.type == FeedVCTypeBookmarks) {
                
                unreadAsc.attributes = UIMenuElementAttributesDisabled;
                unreadDesc.attributes = UIMenuElementAttributesDisabled;
                
            }
            else {
                
                unreadAsc.attributes = 0;
                unreadDesc.attributes = 0;
                
            }
            
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
    
    ArticleVC *articleVC = nil;
    
    UIKeyCommand *nextArticle = [UIKeyCommand commandWithTitle:@"Next Article" image:nil action:@selector(switchToNextArticle) input:UIKeyInputDownArrow modifierFlags:UIKeyModifierCommand propertyList:nil];
    
    UIKeyCommand *previousArticle = [UIKeyCommand commandWithTitle:@"Previous Article" image:nil action:@selector(switchToPreviousArticle) input:UIKeyInputUpArrow modifierFlags:UIKeyModifierCommand propertyList:nil];
    
    // If the article VC is not visible, leave them disabled
    if (splitVC.viewControllers.count != 3) {
        
        nextArticle.attributes = UIMenuElementAttributesDisabled;
        previousArticle.attributes = UIMenuElementAttributesDisabled;
        
    }
    else {
        
        ArticleVC *vc = (ArticleVC *)[(UINavigationController *)[[splitVC viewControllers] lastObject] visibleViewController];
        
        if ([vc isKindOfClass:ArticleVC.class] == YES) {
            
            articleVC = vc;
            
            // we have a ArticleVC so check with its ArticleProvider for prev/next info
            id <ArticleProvider> articleProvider = vc.providerDelegate;
            
            if ([articleProvider hasNextArticleForArticle:vc.currentArticle] == NO) {
                
                nextArticle.attributes = UIMenuElementAttributesDisabled;
                
            }
            
            if ([articleProvider hasPreviousArticleForArticle:vc.currentArticle] == NO) {
                
                previousArticle.attributes = UIMenuElementAttributesDisabled;
                
            }
            
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
    
    for (UIKeyCommand *command in @[markRead, markBookmark, openInBrowser, closeArticle, shareArticle]) {
        
        if (articleVC == nil) {
            
            command.attributes = UIMenuElementAttributesDisabled;
            
        }
        
    }
    
    UIMenu *articlesMenu = [UIMenu menuWithTitle:@"Article" children:@[markRead, markBookmark, openInBrowser, closeArticle, shareArticle]];
    
    [builder insertSiblingMenu:articlesMenu beforeMenuForIdentifier:UIMenuWindow];
    
}

- (void)buildMenuWithBuilder:(id<UIMenuBuilder>)builder {
    
    if (([builder system] == UIMenuSystem.mainSystem) == NO) {
        return;
    }
    
    [self ct_setupMenu:builder];
    
}

#pragma mark - <NSToolbarDelegate>

#define kFeedsToolbarGroup      @"FeedsToolbarGroup"
#define kFeedToolbarGroup       @"FeedToolbarGroup"
#define kArticleToolbarGroup    @"ArticleToolbarGroup"
#define kToolbarIdentifierGroups @[kFeedsToolbarGroup, kFeedToolbarGroup, kArticleToolbarGroup]

#define kNewFeedToolbarIdentifier       @[@"com.yeti.toolbar.newFeed", @"New Feed"]
#define kNewFolderToolbarIdentifier     @[@"com.yeti.toolbar.newFolder", @"New Folder"]
#define kRefreshAllToolbarIdentifier    @[@"com.yeti.toolbar.refreshAll", @"Refresh All"]

#define kRefreshFeedToolbarIdentifier   @[@"com.yeti.toolbar.refreshFeed", @"Refresh Feed"]

#define kShareArticleToolbarIdentifier   @[@"com.yeti.toolbar.shareArticle", @"Share Article"]

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    
    NSArray *items = @[
        NSToolbarToggleSidebarItemIdentifier,
        kNewFeedToolbarIdentifier[0],
        kNewFolderToolbarIdentifier[0],
        kRefreshAllToolbarIdentifier[0],
        NSToolbarPrimarySidebarTrackingSeparatorItemIdentifier,
        kRefreshFeedToolbarIdentifier[0],
        NSToolbarSupplementarySidebarTrackingSeparatorItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        kShareArticleToolbarIdentifier[0]
    ];
    
    return items;
    
}

- (NSArray <NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    
    return [self toolbarDefaultItemIdentifiers:toolbar];
    
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    
    UIBarButtonItem *button = nil;
    NSString *title = nil;
    UIImage *image = nil;
    NSToolbarItem *item = nil;
    
    if ([itemIdentifier isEqualToString:@"com.yeti.toolbar.articleWindow"]) {
        
        image = [UIImage systemImageNamed:@"macwindow.on.rectangle"];
        
        title = @"Open in New Window";
        
        UIBarButtonItem * button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:@selector(openArticleInNewWindow)];
        
        item = [self toolbarItemWithItemIdentifier:@"com.yeti.toolbar.articleWindow" title:@"New Window" button:button];
        
    }
    
    if ([itemIdentifier isEqualToString:kNewFeedToolbarIdentifier[0]]) {
        
        title = kNewFeedToolbarIdentifier[1];
        
        image = [UIImage systemImageNamed:@"plus"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(createNewFeed)];
        
        item = [self toolbarItemWithItemIdentifier:kNewFeedToolbarIdentifier[0] title:title button:button];
        
    }
    else if ([itemIdentifier isEqualToString:kNewFolderToolbarIdentifier[0]]) {
        
        title = kNewFolderToolbarIdentifier[1];
        
        image = [UIImage systemImageNamed:@"folder.badge.plus"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(createNewFolder)];
        
        item = [self toolbarItemWithItemIdentifier:kNewFolderToolbarIdentifier[0] title:title button:button];
        
    }
    else if ([itemIdentifier isEqualToString:kRefreshAllToolbarIdentifier[0]]) {
        
        title = kRefreshAllToolbarIdentifier[1];
        
        image = [UIImage systemImageNamed:@"bolt.circle"];

        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(refreshAll)];

        item = [self toolbarItemWithItemIdentifier:kRefreshAllToolbarIdentifier[0] title:title button:button];
        
    }
    else if ([itemIdentifier isEqualToString:kRefreshFeedToolbarIdentifier[0]]) {
        
        title = kRefreshFeedToolbarIdentifier[1];
        
        image = [UIImage systemImageNamed:@"arrow.triangle.2.circlepath.circle"];

        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:@selector(didBeginRefreshing:)];

        item = [self toolbarItemWithItemIdentifier:kRefreshFeedToolbarIdentifier[0] title:title button:button];
        
    }
    else if ([itemIdentifier isEqualToString:kShareArticleToolbarIdentifier[0]]) {
        
        title = kShareArticleToolbarIdentifier[1];
        
        image = [UIImage systemImageNamed:@"square.and.arrow.up"];

        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:@selector(didTapShare:)];

        item = [self toolbarItemWithItemIdentifier:kShareArticleToolbarIdentifier[0] title:title button:button];
        
    }
    
#ifdef DEBUG
    NSAssert(item != nil, @"Item should be non-nil");
#endif
    
    return item;
    
}

- (NSToolbarItem *)toolbarItemWithItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier title:(NSString *)title button:(UIBarButtonItem *)button {
    
    NSToolbarItem *item = [NSToolbarItem itemWithItemIdentifier:itemIdentifier barButtonItem:button];
    
    if (title) {
        item.paletteLabel = title;
    }
    
    item.label = @"";
    item.toolTip = nil;
    
    return item;
    
}

#pragma mark - Actions

- (void)ct_didTapShareArticle:(NSToolbarItem *)sender {
    
    ArticleVC *vc = self.coordinator.articleVC;
    
    if (vc != nil && [vc isKindOfClass:ArticleVC.class] == NO) {
        return;
    }
    
    [vc didTapShare:(UIBarButtonItem *)sender];
    
}

@end

#endif
