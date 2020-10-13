//
//  FeedVC+BarPositioning.m
//  Yeti
//
//  Created by Nikhil Nigade on 19/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+BarPositioning.h"
#import "Coordinator.h"

@implementation FeedVC (BarPositioning)

- (NSArray <UIBarButtonItem *> *)rightBarButtonItems {
    
    // Subscribe Button appears in the navigation bar
    if (self.isExploring == YES) {
        return @[];
    }
 
    UIBarButtonItem *allRead = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"text.badge.checkmark"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapAllRead:)];
    allRead.accessibilityValue = @"Mark all articles as read";
    allRead.accessibilityHint = @"Mark all current articles as read.";
    allRead.title = @"Mark Read";
    allRead.width = 32.f;
    
    UIBarButtonItem *allReadBackDated = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"checkmark"] style:UIBarButtonItemStylePlain target:self action:@selector(didLongPressOnAllRead:)];
    allReadBackDated.accessibilityValue = @"Mark all articles as read";
    allReadBackDated.accessibilityHint = @"Mark all articles as well as backdated articles as read.";
    allReadBackDated.width = 32.f;
    allReadBackDated.title = @"Mark All Read";
    
    // sorting button
    YetiSortOption option = SharedPrefs.sortingOption;
    
    NSArray *enabledOptions = @[];
    
    if (self.type == FeedVCTypeUnread) {
        
        enabledOptions = @[YTSortUnreadDesc, YTSortUnreadAsc];
        
        // when the active option is either of these two, we don't need
        // to do anything extra
        if ([option isEqualToString:YTSortUnreadAsc] == NO && [option isEqualToString:YTSortUnreadDesc] == NO) {
            
            // map it to whatever the selected option is
            if ([option isEqualToString:YTSortAllAsc]) {
                option = YTSortUnreadAsc;
            }
            else if ([option isEqualToString:YTSortAllDesc]) {
                option = YTSortUnreadDesc;
            }
            
        }
        
    }
    else {
        
        enabledOptions = @[YTSortUnreadDesc, YTSortUnreadAsc, YTSortAllDesc, YTSortAllAsc];
        
    }
    
    UIImage *sortingImage = [self.mainCoordinator imageForSortingOption:option];
    
    enabledOptions = [enabledOptions rz_map:^id(YetiSortOption obj, NSUInteger idx, NSArray *array) {
        
        UIAction *__action = nil;
       
        if ([obj isEqualToString:YTSortUnreadDesc]) {
            
            __action = [UIAction actionWithTitle:@"Unread - Latest First" image:[self.mainCoordinator imageForSortingOption:YTSortUnreadDesc] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
               
                [self updateSortingOptionTo:YTSortUnreadDesc sender:action.sender];
                
            }];
            
        }
        
        else if ([obj isEqualToString:YTSortUnreadAsc]) {
            
            __action = [UIAction actionWithTitle:@"Unread - Oldest First" image:[self.mainCoordinator imageForSortingOption:YTSortUnreadAsc] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                [self updateSortingOptionTo:YTSortUnreadAsc sender:action.sender];
                
            }];
            
        }
        
        else if ([obj isEqualToString:YTSortAllDesc]) {
            
            __action = [UIAction actionWithTitle:@"All - Latest First" image:[self.mainCoordinator imageForSortingOption:YTSortAllDesc] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                [self updateSortingOptionTo:YTSortAllDesc sender:action.sender];
                
            }];
            
        }
        
        else {
            
            __action = [UIAction actionWithTitle:@"All - Oldest First" image:[self.mainCoordinator imageForSortingOption:YTSortAllAsc] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
                
                [self updateSortingOptionTo:YTSortAllAsc sender:action.sender];
                
            }];
            
        }
        
        return __action;
        
    }];

    UIMenu *menu = [UIMenu menuWithChildren:enabledOptions];
    
    UIBarButtonItem *sorting = [[UIBarButtonItem alloc] initWithImage:sortingImage menu:menu];
    sorting.width = 32.f;
    sorting.title = @"Sorting Options";
    sorting.accessibilityLabel = @"Sorting Options";
    
    BOOL isPushFromHub = (self.feed.hubSubscribed && self.feed.hub);
    BOOL isPushFromRPC = self.feed.rpcCount > 0;
    
    if (isPushFromHub == NO && isPushFromRPC == NO) {
        NSMutableArray *buttons = @[allReadBackDated, allRead].mutableCopy;
        
        if ([self showsSortingButton]) {
            [buttons addObject:sorting];
        }
        
        return buttons;
    }
    else {
        // push notifications are possible
        NSString *imageString = self.feed.isSubscribed ? @"bell.fill" : @"bell.slash";
        
        UIBarButtonItem *notifications = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:imageString] style:UIBarButtonItemStylePlain target:self action:@selector(didTapNotifications:)];
        notifications.accessibilityValue = self.feed.isSubscribed ? @"Subscribe" : @"Unsubscribe";
        notifications.accessibilityHint = self.feed.isSubscribed ? @"Unsubscribe from notifications" : @"Subscribe to notifications";
        notifications.width = 32.f;
        
        NSMutableArray *buttons = @[allReadBackDated, allRead, notifications].mutableCopy;
        
        if ([self showsSortingButton]) {
            [buttons addObject:sorting];
        }
        
        return buttons;
    }
    
}

- (NSArray <UIBarButtonItem *> *)toolbarItems {
    
    if (PrefsManager.sharedInstance.useToolbar == NO) {
        return nil;
    }
    
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *fixed = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixed.width = 24.f;
    
    NSArray *right = [[self.rightBarButtonItems rz_map:^id(UIBarButtonItem *obj, NSUInteger idx, NSArray *array) {
        
        if (idx == 0) {
            return obj;
        }
        
        return @[flex, obj];
        
    }] rz_flatten];
    
    return right;
}

@end
