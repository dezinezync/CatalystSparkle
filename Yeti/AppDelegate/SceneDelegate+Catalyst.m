//
//  SceneDelegate+Catalyst.m
//  Elytra
//
//  Created by Nikhil Nigade on 07/09/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "SceneDelegate+Catalyst.h"
#import "AppDelegate.h"
#import "SortingMenuToolbarItem.h"
#import "Elytra-Swift.h"

#if TARGET_OS_MACCATALYST

@interface UIImage (CatalystToolbarSymbol)

- (UIImage *)symbolForNSToolbar:(UIImageSymbolConfiguration *)additionalConfig;

@end

@implementation UIImage (CatalystToolbarSymbol)

- (UIImage *)symbolForNSToolbar:(UIImageSymbolConfiguration *)additionalConfig {

    if (self.symbolConfiguration == nil) {
        return nil;
    }

    UIImage *symbol = [self imageByApplyingSymbolConfiguration:additionalConfig];

    UIGraphicsImageRendererFormat * format = [UIGraphicsImageRendererFormat new];
    format.preferredRange = UIGraphicsImageRendererFormatRangeStandard;

    return [[[[UIGraphicsImageRenderer alloc] initWithSize:symbol.size format:format] imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        
        [symbol drawAtPoint:CGPointZero];
        
    }] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

}

@end

@implementation SceneDelegate (Catalyst)

- (void)ct_setupToolbar:(UIWindowScene *)scene {
    
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"elytra-main-toolbar"];
    
    toolbar.displayMode = NSToolbarDisplayModeIconOnly;
    
    toolbar.delegate = self;
    
    scene.titlebar.toolbar = toolbar;
    
    self.toolbar = toolbar;
    
}

- (UIImageSymbolConfiguration *)toolbarSymbolConfiguration {
    
    if (_toolbarSymbolConfiguration == nil) {
        _toolbarSymbolConfiguration = [UIImageSymbolConfiguration configurationWithPointSize:13.f weight:UIImageSymbolWeightMedium];
    }
    
    return _toolbarSymbolConfiguration;
    
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
    
    Coordinator *coordinator = MyAppDelegate.coordinator;
    
    if ([itemIdentifier isEqualToString:kNewItemToolbarIdentifier]) {

        title = @"New";

        UIAction *newFeedAction = [UIAction actionWithTitle:@"New Feed" image:[UIImage systemImageNamed:@"plus"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {

            [self.coordinator showNewFeedVC];

        }];

        UIAction *newFolderAction = [UIAction actionWithTitle:@"New Folder" image:[UIImage systemImageNamed:@"folder.badge.plus"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {

            [self.coordinator showNewFolderVC];

        }];

        UIMenu *menu = [UIMenu menuWithChildren:@[newFeedAction, newFolderAction]];

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

        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:@selector(beginRefreshingAll:)];

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
    else if ([itemIdentifier isEqualToString:kSortingMenuToolbarIdentifier]) {

        item = [[SortingMenuToolbarItem alloc] initWithItemIdentifier:kSortingMenuToolbarIdentifier];

        self.sortingItem = (NSMenuToolbarItem *)item;

    }
    else if ([itemIdentifier isEqualToString:kMarkItemsMenuToolbarIdentifier]) {

        title = @"Mark all Read";

        image = [UIImage systemImageNamed:@"checkmark"];

        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:@selector(didTapMarkAll:)];

        item = [self toolbarItemWithItemIdentifier:kOpenInBrowserToolbarIdentifier title:title button:button];

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
        item.toolTip = title;
//        item.title = title;
    }

    item.label = @"";
    
    return item;
    
}

#pragma mark - Actions

@end

#endif
