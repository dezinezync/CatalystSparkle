//
//  FeedsVC+Keyboard.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Keyboard.h"
#import "FeedsVC+Actions.h"
#import "UITableView+APL.h"

#import <DZKit/DZBasicDatasource.h>

@implementation FeedsVC (Keyboard)

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray <UIKeyCommand *> *)keyCommands {
    
    // New Feed
    UIKeyCommand *newFeed = [UIKeyCommand keyCommandWithInput:@"N" modifierFlags:UIKeyModifierCommand action:@selector(didTapAdd:) discoverabilityTitle:@"New Feed"];
    UIKeyCommand *newFolder = [UIKeyCommand keyCommandWithInput:@"F" modifierFlags:UIKeyModifierCommand action:@selector(didTapAddFolder:) discoverabilityTitle:@"New Folder"];
    UIKeyCommand *settings = [UIKeyCommand keyCommandWithInput:@"," modifierFlags:UIKeyModifierCommand action:@selector(didTapSettings) discoverabilityTitle:@"Settings"];
    
    UIKeyCommand *upItem = [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(didTapPrev) discoverabilityTitle:@"Previous Item"];
    UIKeyCommand *downItem = [UIKeyCommand keyCommandWithInput:UIKeyInputDownArrow modifierFlags:0 action:@selector(didTapNext) discoverabilityTitle:@"Next Item"];
    UIKeyCommand *space = [UIKeyCommand keyCommandWithInput:@"\r" modifierFlags:0 action:@selector(didTapEnter) discoverabilityTitle:@"Confirm Selection"];
    
    return @[newFeed, newFolder, settings, upItem, downItem, space];
    
}

- (void)didTapPrev {
    NSIndexPath *indexPath = self->_highlightedRow;
    
    if (!indexPath) {
        indexPath = [NSIndexPath indexPathForRow:(self.DS.data.count - 1) inSection:0];
    }
    else {
        indexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:0];
    }
    
    if (indexPath.row < 0) {
        indexPath = nil;
    }
    
    if (indexPath) {
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            
            if (self->_highlightedRow != nil) {
                [self.tableView unhighlightRowAtIndexPath:self->_highlightedRow animated:YES];
            }
            
            [self.tableView highlightRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            
            self->_highlightedRow = indexPath;
        });
    }
    
}

- (void)didTapNext {
    NSIndexPath *indexPath = self->_highlightedRow;
    
    if (!indexPath) {
        indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    else {
        indexPath = [NSIndexPath indexPathForRow:(indexPath.row + 1) inSection:0];
    }
    
    if (indexPath.row > (self.DS.data.count - 1)) {
        indexPath = nil;
    }
    
    if (indexPath) {
        weakify(self);
        
        asyncMain(^{
            strongify(self);
            
            if (self->_highlightedRow != nil) {
                [self.tableView unhighlightRowAtIndexPath:self->_highlightedRow animated:YES];
            }
            
            [self.tableView highlightRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
            
            self->_highlightedRow = indexPath;
        });
    }
}

- (void)didTapEnter {
    if (!self->_highlightedRow) {
        return;
    }
    
    [self.tableView selectRowAtIndexPath:self->_highlightedRow animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    [self tableView:self.tableView didSelectRowAtIndexPath:self->_highlightedRow];
    
    [self.tableView highlightRowAtIndexPath:self->_highlightedRow animated:NO scrollPosition:UITableViewScrollPositionMiddle];
}

@end
