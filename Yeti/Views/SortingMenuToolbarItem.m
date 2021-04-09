//
//  SortingMenuToolbarItem.m
//  Elytra
//
//  Created by Nikhil Nigade on 09/04/21.
//  Copyright © 2021 Dezine Zync Studios. All rights reserved.
//

#if TARGET_OS_MACCATALYST

#import "SortingMenuToolbarItem.h"
#import "Elytra-Swift.h"
#import "AppDelegate.h"

@implementation SortingMenuToolbarItem

- (instancetype)initWithItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier {
    
    if (self = [super initWithItemIdentifier:itemIdentifier]) {
        
        Coordinator *coordinator = MyAppDelegate.coordinator;
    
        FeedSorting sorting = SharedPrefs.sortingOption.integerValue;
        
        UIImage *image = [coordinator imageForSortingOption:sorting];

        self.showsIndicator = YES;
        self.image = image;
        self.autovalidates = NO;
        
        [self validate];
        
    }
    
    return self;
    
}

- (void)validate {
    
    [super validate];
    
    Coordinator *coordinator = MyAppDelegate.coordinator;
    
    weakify(self);

    UIAction *unreadLatest = [UIAction actionWithTitle:@"Unread - Latest First" image:[coordinator imageForSortingOption:FeedSortingUnreadDescending] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {

        [UIApplication.sharedApplication sendAction:@selector(setSortingUnreadDesc) to:nil from:nil forEvent:nil];

        strongify(self);
        self.image = [coordinator imageForSortingOption:FeedSortingUnreadDescending];

    }];

    UIAction *unreadOldest = [UIAction actionWithTitle:@"Unread - Oldest First" image:[coordinator imageForSortingOption:FeedSortingUnreadAscending] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {

        [UIApplication.sharedApplication sendAction:@selector(setSortingUnreadAsc) to:nil from:nil forEvent:nil];

        strongify(self);
        self.image = [coordinator imageForSortingOption:FeedSortingUnreadAscending];

    }];

    UIAction *allLatest = [UIAction actionWithTitle:@"All - Latest First" image:[coordinator imageForSortingOption:FeedSortingDescending] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {

        [UIApplication.sharedApplication sendAction:@selector(setSortingAllDesc) to:nil from:nil forEvent:nil];

        strongify(self);
        self.image = [coordinator imageForSortingOption:FeedSortingDescending];

    }];

    UIAction *allOldest = [UIAction actionWithTitle:@"All - Oldest First" image:[coordinator imageForSortingOption:FeedSortingAscending] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {

        [UIApplication.sharedApplication sendAction:@selector(setSortingAllAsc) to:nil from:nil forEvent:nil];

        strongify(self);
        self.image = [coordinator imageForSortingOption:FeedSortingAscending];

    }];
    
    if (coordinator.feedVC != nil && coordinator.feedVC.type == FeedTypeUnread) {
        allLatest.attributes = UIMenuElementAttributesHidden;
        allOldest.attributes = UIMenuElementAttributesHidden;
        
        NSInteger sorting = [[NSUserDefaults standardUserDefaults] integerForKey:@"unreadFeedSorting"];
        self.image = [coordinator imageForSortingOption:sorting];
        
    }
    else {
        NSInteger sorting = [[NSUserDefaults standardUserDefaults] integerForKey:@"feedSorting"];
        self.image = [coordinator imageForSortingOption:sorting];
    }

    UIMenu *menu = [UIMenu menuWithChildren:@[allLatest, allOldest, unreadLatest, unreadOldest]];

    self.itemMenu = menu;
    
}

@end

#endif
