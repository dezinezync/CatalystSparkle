//
//  AppDelegate+Catalyst.m
//  Yeti
//
//  Created by Nikhil Nigade on 08/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+Catalyst.h"
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

#define kNewFeedToolbarIdentifier @[@"com.yeti.toolbar.newFeed", @"New Feed"]
#define kNewFolderToolbarIdentifier @[@"com.yeti.toolbar.newFolder", @"New Folder"]
#define kRefreshAllToolbarIdentifier @[@"com.yeti.toolbar.refreshAll", @"Refresh All"]
#define kRefreshFeedToolbarIdentifier @[@"com.yeti.toolbar.refreshFeed", @"Refresh Feed"]

- (NSArray<NSToolbarItemIdentifier> *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    
    return @[kNewFeedToolbarIdentifier[0], kNewFolderToolbarIdentifier[0], kRefreshAllToolbarIdentifier[0], NSToolbarSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, kRefreshFeedToolbarIdentifier[0]];
    
}

- (NSArray <NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    
    return [self toolbarDefaultItemIdentifiers:toolbar];
    
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    
    UIBarButtonItem *button = nil;
    NSString *title = nil;
    
    if ([itemIdentifier isEqualToString:kNewFeedToolbarIdentifier[0]]) {
        
        title = kNewFeedToolbarIdentifier[1];
        
        UIImage *image = [self dynamicImageWithLightImageName:@"new-feed" darkImageName:@"new-feed"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:nil];
        
    }
    else if ([itemIdentifier isEqualToString:kNewFolderToolbarIdentifier[0]]) {
        
        title = kNewFolderToolbarIdentifier[1];
        
        UIImage *image = [self dynamicImageWithLightImageName:@"new-folder" darkImageName:@"new-folder"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:nil];
        
    }
    else if ([itemIdentifier isEqualToString:kRefreshAllToolbarIdentifier[0]]) {
        
        title = kRefreshAllToolbarIdentifier[1];
        
        UIImage *image = [self dynamicImageWithLightImageName:@"refresh-all" darkImageName:@"refresh-all"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:nil];
        
    }
    else if ([itemIdentifier isEqualToString:kRefreshFeedToolbarIdentifier[0]]) {
        
        title = kRefreshFeedToolbarIdentifier[1];
        
        UIImage *image = [self dynamicImageWithLightImageName:@"refresh-feed" darkImageName:@"refresh-feed"];
        
        button = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:nil action:nil];
        
    }
    
    if (button != nil) {
        
        NSToolbarItem *item = [NSToolbarItem itemWithItemIdentifier:itemIdentifier barButtonItem:button];
        
        if (title) {
            item.paletteLabel = title;
        }
        
        item.label = @"";
        item.toolTip = nil;
        
        return item;
        
    }
    
    return nil;
    
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
