//
//  ArticleVC+Keyboard.m
//  Yeti
//
//  Created by Nikhil Nigade on 04/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "ArticleVC+Toolbar.h"

@implementation ArticleVC (Keyboard)

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray <UIKeyCommand *> *)keyCommands {
    
    UIKeyCommand *close = [UIKeyCommand keyCommandWithInput:@"w" modifierFlags:UIKeyModifierCommand action:@selector(didTapClose) discoverabilityTitle:@"Close Article"];
    UIKeyCommand *bookmark = [UIKeyCommand keyCommandWithInput:@"b" modifierFlags:UIKeyModifierCommand action:@selector(didTapBookmark:) discoverabilityTitle:(self.item.isBookmarked ? @"Unbookmark Article" : @"Bookmark Article")];
    UIKeyCommand *read = [UIKeyCommand keyCommandWithInput:@"r" modifierFlags:UIKeyModifierCommand action:@selector(didTapRead:) discoverabilityTitle:(self.item.isRead ? @"Mark as Unread" : @"Mark as Read")];
    
    UIKeyCommand *search = [UIKeyCommand keyCommandWithInput:@"f" modifierFlags:UIKeyModifierCommand action:@selector(didTapSearch) discoverabilityTitle:@"Search article"];
    
    return @[close, bookmark, read, search];
    
}

@end
