//
//  SceneDelegate+Catalyst.m
//  Elytra
//
//  Created by Nikhil Nigade on 07/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SceneDelegate+Catalyst.h"

#if TARGET_OS_MACCATALYST

@implementation SceneDelegate (Catalyst)

- (void)ct_setupToolbar:(UIWindowScene *)scene {
    
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"elytra-main-toolbar"];
    
    toolbar.delegate = self;
    
    scene.titlebar.toolbar = toolbar;
    
    scene.titlebar.toolbarStyle = UITitlebarToolbarStyleUnifiedCompact;
    
    scene.titlebar.separatorStyle = UITitlebarSeparatorStyleAutomatic;
    
    scene.titlebar.titleVisibility = UITitlebarTitleVisibilityHidden;
    
    self.toolbar = toolbar;
    
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

#define kAppearanceToolbarIdentifier @"appearanceToolbarIdentifier"
#define kOpenInBrowserToolbarIdentifier @"openInBrowserToolbarIdentifier"

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
        kOpenInBrowserToolbarIdentifier,
        kAppearanceToolbarIdentifier,
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
    
    else if ([itemIdentifier isEqualToString:kNewFeedToolbarIdentifier[0]]) {
        
        title = kNewFeedToolbarIdentifier[1];
        
        image = [UIImage systemImageNamed:@"plus"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:@selector(didTapAdd:)];
        
        item = [self toolbarItemWithItemIdentifier:kNewFeedToolbarIdentifier[0] title:title button:button];
        
    }
    else if ([itemIdentifier isEqualToString:kNewFolderToolbarIdentifier[0]]) {
        
        title = kNewFolderToolbarIdentifier[1];
        
        image = [UIImage systemImageNamed:@"folder.badge.plus"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:@selector(didTapAddFolder:)];
        
        item = [self toolbarItemWithItemIdentifier:kNewFolderToolbarIdentifier[0] title:title button:button];
        
    }
    else if ([itemIdentifier isEqualToString:kRefreshAllToolbarIdentifier[0]]) {
        
        title = kRefreshAllToolbarIdentifier[1];
        
        image = [UIImage systemImageNamed:@"bolt.circle"];

        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:@selector(beginRefreshingAll:)];

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
    else if ([itemIdentifier isEqualToString:kAppearanceToolbarIdentifier]) {
        
        title = @"Appearance";
        
        image = [UIImage systemImageNamed:@"doc.richtext"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:@selector(didTapCustomize:)];
        
        item = [self toolbarItemWithItemIdentifier:kAppearanceToolbarIdentifier title:title button:button];
        
    }
    else if ([itemIdentifier isEqualToString:kOpenInBrowserToolbarIdentifier]) {
        
        title = @"Open in Browser";
        
        image = [UIImage systemImageNamed:@"safari"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:@selector(openInBrowser)];
        
        item = [self toolbarItemWithItemIdentifier:kOpenInBrowserToolbarIdentifier title:title button:button];
        
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
    
    item.paletteLabel = title;
//    item.title = title;
    item.label = @"";
    item.toolTip = title;
    
    return item;
    
}

@end

#endif
