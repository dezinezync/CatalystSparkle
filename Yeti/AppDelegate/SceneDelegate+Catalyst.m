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
    
    scene.titlebar.toolbarStyle = UITitlebarToolbarStyleAutomatic;
    
    scene.titlebar.separatorStyle = UITitlebarSeparatorStyleAutomatic;
    
    scene.titlebar.titleVisibility = UITitlebarTitleVisibilityHidden;
    
    self.toolbar = toolbar;
    
}

#pragma mark - <NSToolbarDelegate>

#define kRefreshAllToolbarIdentifier    @[@"com.yeti.toolbar.refreshAll", @"Refresh All"]

#define kRefreshFeedToolbarIdentifier   @[@"com.yeti.toolbar.refreshFeed", @"Refresh Feed"]

#define kShareArticleToolbarIdentifier   @[@"com.yeti.toolbar.shareArticle", @"Share Article"]

#define kNewItemToolbarIdentifier @"newItemToolbarIdentifier"
#define kAppearanceToolbarIdentifier @"appearanceToolbarIdentifier"
#define kOpenInBrowserToolbarIdentifier @"openInBrowserToolbarIdentifier"
#define kOpenInNewWindowToolbarIdentifier @"com.yeti.toolbar.articleWindow"
#define kFeedTitleViewToolbarIdentifier @"com.yeti.toolbar.feedTitle"
#define kSortingMenuToolbarIdentifier @"com.yeti.toolbar.sortingMenu"
#define kMarkItemsMenuToolbarIdentifier @"com.yeti.toolbar.markItems"

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    
    NSArray *items = @[
        NSToolbarFlexibleSpaceItemIdentifier,
        kNewItemToolbarIdentifier,
        NSToolbarPrimarySidebarTrackingSeparatorItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        kRefreshFeedToolbarIdentifier[0],
        kSortingMenuToolbarIdentifier,
        kMarkItemsMenuToolbarIdentifier,
        NSToolbarSupplementarySidebarTrackingSeparatorItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        kOpenInNewWindowToolbarIdentifier,
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
    
    if ([itemIdentifier isEqualToString:kNewItemToolbarIdentifier]) {
        
        image = [UIImage systemImageNamed:@"plus"];
        
        title = @"New";
        
        UIAction *newFeedAction = [UIAction actionWithTitle:@"New Feed" image:[UIImage systemImageNamed:@"plus"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
           
            [self.coordinator.sidebarVC didTapAdd:nil];
            
        }];
        
        UIAction *newFolderAction = [UIAction actionWithTitle:@"New Folder" image:[UIImage systemImageNamed:@"folder.badge.plus"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
            [self.coordinator.sidebarVC didTapAddFolder:nil];
            
        }];
        
        UIAction *reccomendationsAction = [UIAction actionWithTitle:@"Recommendations" image:[UIImage systemImageNamed:@"flame"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
           
            [self.coordinator.sidebarVC didTapRecommendations:nil];
            
        }];
        
        UIMenu *menu = [UIMenu menuWithChildren:@[newFeedAction, newFolderAction, reccomendationsAction]];
        
//        UIBarButtonItem *menuItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd menu:menu];
        
        NSMenuToolbarItem *menuToolbarItem = [[NSMenuToolbarItem alloc] initWithItemIdentifier:kNewItemToolbarIdentifier];
        menuToolbarItem.showsIndicator = YES;
        menuToolbarItem.itemMenu = menu;
        menuToolbarItem.image = [UIImage systemImageNamed:@"plus"];
        
        item = menuToolbarItem;
        
    }
    else if ([itemIdentifier isEqualToString:kOpenInNewWindowToolbarIdentifier]) {
        
        image = [UIImage systemImageNamed:@"macwindow.on.rectangle"];
        
        title = @"Open in New Window";
        
        UIBarButtonItem * button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:@selector(openArticleInNewWindow)];
        
        item = [self toolbarItemWithItemIdentifier:@"com.yeti.toolbar.articleWindow" title:@"New Window" button:button];
        
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
    else if ([itemIdentifier isEqualToString:kFeedTitleViewToolbarIdentifier]) {
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120.f, 24.f)];
        label.textColor = UIColor.blackColor;
        label.font = [UIFont systemFontOfSize:13.f weight:UIFontWeightSemibold];
        label.text = @"Feed Title";
        label.numberOfLines = 0;
        label.backgroundColor = UIColor.redColor;

        label.translatesAutoresizingMaskIntoConstraints = YES;
        [label setContentCompressionResistancePriority:999 forAxis:UILayoutConstraintAxisHorizontal];
        [label setContentCompressionResistancePriority:999 forAxis:UILayoutConstraintAxisVertical];
        [label.widthAnchor constraintEqualToConstant:120.f].active = YES;
        [label.heightAnchor constraintEqualToConstant:24.f].active = YES;
        
        UIBarButtonItem *viewBarItem = [[UIBarButtonItem alloc] initWithCustomView:label];
        
        item = [self toolbarItemWithItemIdentifier:kFeedTitleViewToolbarIdentifier title:@"Feed Title" button:viewBarItem];
        
    }
    else if ([itemIdentifier isEqualToString:kSortingMenuToolbarIdentifier]) {
        
        image = [self.coordinator imageForSortingOption:SharedPrefs.sortingOption];
        
        title = @"Sort Feed";
        
        UIAction *unreadLatest = [UIAction actionWithTitle:@"Unread - Latest First" image:[self.coordinator imageForSortingOption:YTSortUnreadDesc] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
           
            [UIApplication.sharedApplication sendAction:@selector(setSortingUnreadDesc) to:nil from:nil forEvent:nil];
            
            self.sortingItem.image = [self.coordinator imageForSortingOption:YTSortUnreadDesc];
            
        }];
        
        UIAction *unreadOldest = [UIAction actionWithTitle:@"Unread - Oldest First" image:[self.coordinator imageForSortingOption:YTSortUnreadAsc] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            
            [UIApplication.sharedApplication sendAction:@selector(setSortingUnreadAsc) to:nil from:nil forEvent:nil];
            
            self.sortingItem.image = [self.coordinator imageForSortingOption:YTSortUnreadAsc];
            
        }];
        
        UIAction *allLatest = [UIAction actionWithTitle:@"All - Latest First" image:[self.coordinator imageForSortingOption:YTSortAllDesc] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
           
            [UIApplication.sharedApplication sendAction:@selector(setSortingAllDesc) to:nil from:nil forEvent:nil];
            
            self.sortingItem.image = [self.coordinator imageForSortingOption:YTSortAllDesc];
            
        }];
        
        UIAction *allOldest = [UIAction actionWithTitle:@"All - Oldest First" image:[self.coordinator imageForSortingOption:YTSortAllAsc] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
           
            [UIApplication.sharedApplication sendAction:@selector(setSortingAllAsc) to:nil from:nil forEvent:nil];
            
            self.sortingItem.image = [self.coordinator imageForSortingOption:YTSortAllAsc];
            
        }];
        
        if (self.coordinator.feedVC != nil && self.coordinator.feedVC.type == FeedVCTypeUnread) {
            allLatest.attributes = UIMenuElementAttributesHidden;
            allOldest.attributes = UIMenuElementAttributesHidden;
        }
        
        UIMenu *menu = [UIMenu menuWithChildren:@[allLatest, allOldest, unreadLatest, unreadOldest]];
        
        NSMenuToolbarItem *menuToolbarItem = [[NSMenuToolbarItem alloc] initWithItemIdentifier:kSortingMenuToolbarIdentifier];
        menuToolbarItem.showsIndicator = YES;
        menuToolbarItem.itemMenu = menu;
        menuToolbarItem.image = [UIImage systemImageNamed:@"arrow.up.arrow.down"];
        
        item = menuToolbarItem;
        
        self.sortingItem = (NSMenuToolbarItem *)item;
        
    }
    else if ([itemIdentifier isEqualToString:kMarkItemsMenuToolbarIdentifier]) {
        
        UIAction *markCurrent = [UIAction actionWithTitle:@"Mark Current Read" image:[UIImage systemImageNamed:@"text.badge.checkmark"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
           
            if (self.coordinator.feedVC == nil) {
                return;
            }
            
            [self.coordinator.feedVC didTapAllRead:nil];
            
        }];
        
        UIAction *markAll = [UIAction actionWithTitle:@"Mark All Read" image:[UIImage systemImageNamed:@"checkmark"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
           
            if (self.coordinator.feedVC == nil) {
                return;
            }
            
            [self.coordinator.feedVC didLongPressOnAllRead:nil];
            
        }];
        
        UIMenu *menu = [UIMenu menuWithChildren:@[markCurrent, markAll]];
        
        NSMenuToolbarItem *menuToolbarItem = [[NSMenuToolbarItem alloc] initWithItemIdentifier:kMarkItemsMenuToolbarIdentifier];
        menuToolbarItem.showsIndicator = YES;
        menuToolbarItem.itemMenu = menu;
        menuToolbarItem.image = [UIImage systemImageNamed:@"checkmark"];
        
        item = menuToolbarItem;
        
    }
    
#ifdef DEBUG
    NSAssert(item != nil, @"Item should be non-nil");
#endif
    
    return item;
    
}

#pragma mark - Helpers

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
