//
//  FeedsVC+Keyboard.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Keyboard.h"
#import "FeedsVC+Actions.h"
#import "UITableViewController+KeyboardScroll.h"
#import "FolderCell.h"

@implementation FeedsVC (Keyboard)

- (NSArray *)data {
    return [self.DDS.snapshot itemIdentifiersInSectionWithIdentifier:MainSection];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray <UIKeyCommand *> *)keyCommands {
    
    // New Feed
    UIKeyCommand *newFeed = [UIKeyCommand keyCommandWithInput:@"N" modifierFlags:UIKeyModifierCommand action:@selector(didTapAdd:)];
    newFeed.title = @"New Feed";
    newFeed.discoverabilityTitle = newFeed.title;
    
    UIKeyCommand *newFolder = [UIKeyCommand keyCommandWithInput:@"F" modifierFlags:UIKeyModifierCommand action:@selector(didTapAddFolder:)];
    newFolder.title = @"New Folder";
    newFolder.discoverabilityTitle = newFolder.title;
    
    UIKeyCommand *settings = [UIKeyCommand keyCommandWithInput:@"," modifierFlags:UIKeyModifierCommand action:@selector(didTapSettings)];
    settings.title = @"Settings";
    settings.discoverabilityTitle = settings.title;
    
    UIKeyCommand *upItem = [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(didTapPrev)];
    upItem.title = @"Previous Item";
    upItem.discoverabilityTitle = upItem.title;
    
    UIKeyCommand *downItem = [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(didTapNext)];
    downItem.title = @"Next Item";
    downItem.discoverabilityTitle = downItem.title;
    
    UIKeyCommand *returnItem = [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:0 action:@selector(didTapEnter)];
    returnItem.title = @"Select";
    returnItem.discoverabilityTitle = returnItem.title;
    
    UIKeyCommand *toggleItem = [UIKeyCommand keyCommandWithInput:@" " modifierFlags:0 action:@selector(didTapSpace)];
    toggleItem.title = @"Toggle";
    toggleItem.discoverabilityTitle = @"Toggle";
    
    return @[newFeed, newFolder, settings, upItem, downItem, returnItem, toggleItem];
    
}

- (void)didTapSpace {
    
    if (!self.highlightedRow) {
        return;
    }
    
    FolderCell *cell = (id)[self.DDS tableView:self.tableView cellForRowAtIndexPath:self.highlightedRow];
    
    if ([cell isKindOfClass:FolderCell.class] == NO) {
        return;
    }
    
    [cell performSelectorOnMainThread:@selector(didTapIcon:) withObject:nil waitUntilDone:NO];
    
}

@end
