//
//  OPMLDeckController.m
//  Yeti
//
//  Created by Nikhil Nigade on 05/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "OPMLDeckController.h"
#import <DZTextKit/YetiThemeKit.h>

@interface OPMLDeckController ()

@end

@implementation OPMLDeckController

- (instancetype)init {
    
    OPMLVC *vc1 = [[OPMLVC alloc] initWithNibName:NSStringFromClass(OPMLVC.class) bundle:nil];
    
    if (self = [super initWithRootViewController:vc1]) {
        self.view.backgroundColor = [[YTThemeKit theme] backgroundColor];
    }
    
    return self;
    
}

- (BOOL)shouldShowDropShadow {
    return YES;
}

#pragma mark - <DeckPresentation>

- (BOOL)dp_shouldPushPresentingView {
    return NO;
}

- (BOOL)dp_shouldDimPresentingView {
    return YES;
}

- (UIEdgeInsets)dp_additionalInsets {
    return UIEdgeInsetsMake(12.f, 0, 0, 0);
}

- (BOOL)dp_panGestureEnabled {
    return NO;
}

@end
