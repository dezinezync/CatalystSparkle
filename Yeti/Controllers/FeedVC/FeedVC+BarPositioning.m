//
//  FeedVC+BarPositioning.m
//  Yeti
//
//  Created by Nikhil Nigade on 19/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+BarPositioning.h"

@implementation FeedVC (BarPositioning)

- (NSArray <UIBarButtonItem *> *)rightBarButtonItems {
    
    // Subscribe Button appears in the navigation bar
    if (self.isExploring == YES) {
        return @[];
    }
 
    UIBarButtonItem *allRead = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"text.badge.checkmark"] style:UIBarButtonItemStylePlain target:self action:@selector(didTapAllRead:)];
    allRead.accessibilityValue = @"Mark all articles as read";
    allRead.accessibilityHint = @"Mark all current articles as read.";
    allRead.width = 32.f;
    
    UIBarButtonItem *allReadBackDated = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"checkmark"] style:UIBarButtonItemStylePlain target:self action:@selector(didLongPressOnAllRead:)];
    allReadBackDated.accessibilityValue = @"Mark all articles as read";
    allReadBackDated.accessibilityHint = @"Mark all articles as well as backdated articles as read.";
    allReadBackDated.width = 32.f;
    
    
    // sorting button
    YetiSortOption option = SharedPrefs.sortingOption;
    
    if (self.type == FeedVCTypeUnread || self.type == FeedVCTypeBookmarks) {
        
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
    
    UIColor *tintColor = nil;
    UIImage *sortingImage = [SortImageProvider imageForSortingOption:option tintColor:&tintColor];
    
    UIBarButtonItem *sorting = [[UIBarButtonItem alloc] initWithImage:sortingImage style:UIBarButtonItemStylePlain target:self action:@selector(didTapSortOptions:)];
    sorting.tintColor = tintColor;
    sorting.width = 32.f;
    
    if (!(self.feed.hubSubscribed && self.feed.hub)) {
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
