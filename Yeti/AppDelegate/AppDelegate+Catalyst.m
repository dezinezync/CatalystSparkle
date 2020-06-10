//
//  AppDelegate+Catalyst.m
//  Yeti
//
//  Created by Nikhil Nigade on 08/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+Catalyst.h"
#import "FeedsVC+Actions.h"

#import <UIKit/NSToolbar+UIKitAdditions.h>

@implementation AppDelegate (Catalyst)

- (void)ct_setupToolbar:(UIWindowScene *)scene {
    
    NSToolbar *toolbar = [[NSToolbar alloc] initWithIdentifier:@"elytra-main-toolbar"];
    
    toolbar.delegate = self;
    
    scene.titlebar.toolbar = toolbar;
    
}

- (void)ct_setupAppKitBundle {
    
    NSString *pluginPath = [[[NSBundle mainBundle] builtInPlugInsPath] stringByAppendingPathComponent:@"elytramac.bundle"];
    
    NSBundle *macBundle = [NSBundle bundleWithPath:pluginPath];
    
    self.appKitBundle = macBundle;
    
    __unused BOOL unused = [self.appKitBundle load];
    
    Class appKitGlueClass = [self.appKitBundle classNamed:@"AppKitGlue"];
    
    __unused AppKitGlue *instance = [appKitGlueClass shared];
    
    self.sharedGlue = instance;

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

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    
    return @[kToolbarIdentifierGroups[0], NSToolbarSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, kToolbarIdentifierGroups[1], NSToolbarSpaceItemIdentifier, kToolbarIdentifierGroups[2]];
    
}

- (NSArray <NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    
    return [self toolbarDefaultItemIdentifiers:toolbar];
    
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    
    UIBarButtonItem *button = nil;
    NSString *title = nil;
    UIImage *image = nil;
    
    TOSplitViewController *splitVC = (TOSplitViewController *)[self.window rootViewController];
    UINavigationController *navVC = (UINavigationController *)[splitVC.viewControllers firstObject];
    FeedsVC *feedsVC = navVC.viewControllers.firstObject;
    
    if ([itemIdentifier isEqualToString:kFeedsToolbarGroup]) {
        
        title = kNewFeedToolbarIdentifier[1];
        
        image = [self dynamicImageWithLightImageName:@"new-feed" darkImageName:@"new-feed"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:feedsVC action:@selector(didTapAdd:)];
        
        NSToolbarItem *item1 = [self toolbarItemWithItemIdentifier:kNewFeedToolbarIdentifier[0] title:title button:button];
        
        //
        title = kNewFolderToolbarIdentifier[1];
        
        image = [self dynamicImageWithLightImageName:@"new-folder" darkImageName:@"new-folder"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:feedsVC action:@selector(didTapAddFolder:)];
        
        NSToolbarItem *item2 = [self toolbarItemWithItemIdentifier:kNewFolderToolbarIdentifier[0] title:title button:button];
        
        //
        title = kRefreshAllToolbarIdentifier[1];
        
        image = [self dynamicImageWithLightImageName:@"refresh-all" darkImageName:@"refresh-all"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:feedsVC action:@selector(beginRefreshing:)];
        
        NSToolbarItem *item3 = [self toolbarItemWithItemIdentifier:kRefreshAllToolbarIdentifier[0] title:title button:button];
        
        NSToolbarItemGroup *group = [[NSToolbarItemGroup alloc] initWithItemIdentifier:itemIdentifier];
               
        [group setSubitems:@[item1, item2, item3]];
        
        return group;
        
    }
    
    else if ([itemIdentifier isEqualToString:kFeedToolbarGroup]) {
        
        title = kRefreshFeedToolbarIdentifier[1];
        
        UIImage *image = [self dynamicImageWithLightImageName:@"refresh-feed" darkImageName:@"refresh-feed"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:nil];
        
        NSToolbarItem *item1 = [self toolbarItemWithItemIdentifier:kRefreshFeedToolbarIdentifier[0] title:title button:button];
        
        NSToolbarItemGroup *group = [[NSToolbarItemGroup alloc] initWithItemIdentifier:itemIdentifier];
               
        [group setSubitems:@[item1]];
        
        return group;
        
    }
    
    return nil;
    
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

- (UIImage *)dynamicImageWithLightImageName:(NSString *)lightImageName darkImageName:(NSString *)darkImageName {
    
    UITraitCollection *const scaleTraitCollection = [UITraitCollection currentTraitCollection];
    
    UITraitCollection *const lightUnscaledTraitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    UITraitCollection *const darkUnscaledTraitCollection = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
    
    UITraitCollection *const lightScaledTraitCollection = [UITraitCollection traitCollectionWithTraitsFromCollections:@[scaleTraitCollection, lightUnscaledTraitCollection]];
    UITraitCollection *const darkScaledTraitCollection = [UITraitCollection traitCollectionWithTraitsFromCollections:@[scaleTraitCollection, darkUnscaledTraitCollection]];
    
    __block UIImage *image = nil, *darkImage = nil;
    
    [darkScaledTraitCollection performAsCurrentTraitCollection:^{
       
        image = [UIImage imageNamed:lightImageName];
        
        if (image) {
            image = [image imageWithConfiguration:[image.configuration configurationWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]]];
        }
        
    }];
    
    [lightScaledTraitCollection performAsCurrentTraitCollection:^{

        darkImage = [UIImage imageNamed:darkImageName];
        
        if (darkImage) {
            
            darkImage = [darkImage imageWithConfiguration:[darkImage.configuration configurationWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]]];
            
        }

    }];
    
    if (image && darkImage) {
        
        [image.imageAsset registerImage:darkImage withTraitCollection:darkScaledTraitCollection];
        
    }
    
    return image;
    
}

@end
