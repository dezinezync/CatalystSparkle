//
//  FeedsVC+Keyboard.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Keyboard.h"
#import "FeedsVC+Actions.h"

@implementation FeedsVC (Keyboard)

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (NSArray <UIKeyCommand *> *)keyCommands {
    
    // New Feed
    UIKeyCommand *newFeed = [UIKeyCommand keyCommandWithInput:@"N" modifierFlags:UIKeyModifierCommand action:@selector(didTapAdd:) discoverabilityTitle:@"New Feed"];
    UIKeyCommand *newFolder = [UIKeyCommand keyCommandWithInput:@"F" modifierFlags:UIKeyModifierCommand action:@selector(didTapAddFolder:) discoverabilityTitle:@"New Folder"];
    UIKeyCommand *settings = [UIKeyCommand keyCommandWithInput:@"," modifierFlags:UIKeyModifierCommand action:@selector(didTapSettings) discoverabilityTitle:@"Settings"];
    
    UIKeyCommand *upItem = [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(didTapPrev) discoverabilityTitle:@"Prev Item"];
    UIKeyCommand *downItem = [UIKeyCommand keyCommandWithInput:UIKeyInputUpArrow modifierFlags:0 action:@selector(didTapNext) discoverabilityTitle:@"Next Item"];
    
    return @[newFeed, newFolder, settings, upItem, downItem];
    
}

- (void)didTapPrev {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
}

- (void)didTapNext {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    
}

@end
